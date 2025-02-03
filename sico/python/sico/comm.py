####    ############    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
####    ############    
####                    This source describes Open Hardware and is licensed under the
####                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
############    ####    
############    ####    
####    ####    ####    
####    ####    ####    
############            Authors:
############            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)

from __future__ import annotations
from enum import Enum
import logging
import threading
import weakref

from choc.pipe import Item, Gate, PipeOffband
from choc.types import Bits, Change, Tme, MEGA
import choc
from bilib.fn import etype
import asyncio

class Nothing(Exception):
    pass

class SimFinished(Exception):
    def __init__(self, fin:Tme):
        self.finish = fin
    pass

class Message:
    channel:str
    data:bytes
    BASE_LENGTH = 8 #message length + channel length

    def __init__(self, channel:str=None, data:bytes= None):
        etype((channel, (str, None)), (data, (bytes, None)))
        self.channel = channel
        self.data = data

    @classmethod
    def fromBytes(cls, raw:bytes) -> Message:
        #raw[0:4] msgLength
        chanLength = int.from_bytes(raw[4:8], 'big')
        #channel
        channel = raw[8:8+chanLength].decode('utf-8')
        data = raw[8+chanLength:]
        return Message(channel, data)

    #message format:
    # offset | size     | description
    # 0      | 4        | message length (m)
    # 4      | 4        | channel length (n)
    # 8      | n        | channel name
    # 8+n    | m-n-8    | data
    def toBytes(self) -> bytes:
        chanBytes = self.channel.encode('utf-8')
        chanLength = len(chanBytes)
        dataLength = len(self.data) if self.data else 0
        msgLength = self.BASE_LENGTH + chanLength + dataLength
        ret = msgLength.to_bytes(4, 'big')
        ret += chanLength.to_bytes(4, 'big')
        ret += chanBytes
        if self.data:
            ret += self.data
        return ret

    def __str__(self):
        return f"Message({self.channel},len:{self.nBytes()})"

    def nBytes(self) -> int:
        return self.BASE_LENGTH + len(self.channel) + len(self.data)

class Connection:
    DEFAULT_SOCK_NAME = "SiCo.sock"
    logName = "SiCoConnection"
    CONN_ABORT_EXCEPT = (BrokenPipeError, ConnectionResetError, asyncio.IncompleteReadError)
    def __init__(self):
        super().__init__()
        self.socketName = self.DEFAULT_SOCK_NAME
        self.connected = asyncio.Event()
        self.connMutex = asyncio.Lock()
        self.connCond = asyncio.Condition(self.connMutex)
        self.connEst = 0    #number of the last established connection 
        self.connTerm = 0   #number of the last terminated connection
        self.connReader = None
        self.connWriter = None
        self.recvPipe = Gate(f"{self.logName}.recvPipe")
        self.sendPipe = Gate(f"{self.logName}.sendPipe")
        choc.submit(self.ccRunConnect(), f"{self.logName}~ccRunConnect")
        choc.submit(self.ccRunSend(), f"{self.logName}~ccRunSend")
        choc.submit(self.ccRunRecv(), f"{self.logName}~ccRunRecv")

    async def ccRunConnect(self):
        log = logging.getLogger(self.logName)
        while True:
            log.info("open UNIX socket")
            while True:
                try:
                    reader, writer = await asyncio.open_unix_connection(self.socketName)
                    break
                except (ConnectionRefusedError, FileNotFoundError):
                    await asyncio.sleep(1)
            #connection established
            log.info("connection established")
            async with self.connCond:
                self.socketReader = reader
                self.socketWriter = writer
                self.connEst += 1
                self.connCond.notify_all()
            self.connected.set()
            async with self.connCond:
                await self.connCond.wait_for(lambda: self.connEst <= self.connTerm)
                self.socketWriter.close()
            log.info("connection terminated - again...")
            self.connected.clear()

    async def ccRunRecv(self):
        log = logging.getLogger(self.logName)
        connCurr = 0
        while True:
            async with self.connCond:
                await self.connCond.wait_for(lambda: self.connEst > self.connTerm)
                connCurr = self.connEst
                reader = self.socketReader
            try:
                log.log(5, "receiving a message...")
                raw = await reader.readexactly(4)
                size = int.from_bytes(raw, 'big')
                raw += await reader.readexactly(size-4)
                msg = Message.fromBytes(raw)
                assert isinstance(msg, Message)
                log.log(5, f"message received:{msg} raw:{raw}")
                await self.recvPipe.push(msg)
            except self.CONN_ABORT_EXCEPT:
                log.info("reader failt read")
                async with self.connCond:
                    self.connTerm = connCurr
                    self.connCond.notify_all()

    async def ccRunSend(self):
        log = logging.getLogger(self.logName)
        connCurr = 0
        while True:
            msg = await self.sendPipe.pull()
            async with self.connCond:
                await self.connCond.wait_for(lambda: self.connEst > self.connTerm)
                connCurr = self.connEst
                writer = self.socketWriter
            try:
                log.log(5, f"sending a message... {msg}")
                raw = msg.toBytes()
                log.log(5, f"raw len:{len(raw)} message:{raw}")
                writer.write(raw)
                log.log(5, f"sent a message:{msg}")
            except self.CONN_ABORT_EXCEPT:
                log.info("reader failt read")
                async with self.connCond:
                    self.connTerm = connCurr
                    self.connCond.notify_all()

class Command(Enum):
    tick = 0       #keep alive signal
    tock = 1       #keep alive signal answer
    exit = 2       #request exit of the simulator
    shutdown = 3   #request shutdown of the simulator
    set = 4        #set a config value
    addBreak = 5   #add a break threshold
    remBreak = 6   #remove a break threshhold
    ackBreak = 7   #acknowledge the break
    hitBreak = 8   #break was hit

    def toBytes(self) -> bytes:
        return self.value.to_bytes(4, 'big')
    
    def fromBytes(data:bytes) -> Command:
        return Command(int.from_bytes(data[0:4], 'big'))

class BreakType(Enum):
    hold = 0
    stop = 1
    finish = 2

    def toBytes(self) -> bytes:
        return self.value.to_bytes(1, 'big')
    
    def fromBytes(data:bytes) -> BreakType:
        return BreakType(data[0])
    
    def __str__(self) -> str:
        return str(self.name)

class Break:
    unqiue = 2
    def __init__(self, ctrl:Control, time:Tme, type:BreakType, relative:bool):
        self.ctrl = ctrl
        self.uid = self.unqiue
        self.__class__.unqiue += 1
        self.request = time #break we want to have
        self.relative = relative #is, what we want relative
        self.thresh = None  #break that was acknoledged
        self.stopped = None #where it actually stopped
        self.type = type
        self.hit = asyncio.Event() #set when the break was hit -> stopped set
        self.ack = asyncio.Event() #set when the break was acknoledged -> thresh set
        choc.submit(self.ccRequest(), "Break~ccRequest")

    def __repr__(self) -> str:
        msg = f"Break("
        if self.hit.is_set():
            msg += f"hit:{self.stopped}"
            if self.relative is False and self.request != self.stopped:
                msg += f"(req:{self.request})"
            if self.relative is False and self.request != self.thresh:
                msg += f"(ack:{self.thresh})"
        elif self.ack.is_set():
            msg += f"ack:{self.thresh}"
            if self.relative is False and self.request != self.thresh:
                msg += f"(req:{self.request})"
        else:
            msg += f"req:{self.request},rel:{self.relative}"
        msg += f",type:{self.type})"
        return msg

    async def ccRequest(self):
        self.ctrl.breaks[self.uid] = self
        data = Command.addBreak.toBytes()
        data += self.uid.to_bytes(4, 'big')
        data += self.request.toBytes()
        data += self.type.toBytes()
        data += int(self.relative).to_bytes(1, 'big')
        msg = Message(Control.SC_CHAN, data)
        await self.ctrl.ccPush(msg)

    async def ccRelease(self):
        del self.ctrl.breaks[self.uid]
        data = Command.remBreak.toBytes()
        data += self.uid.to_bytes(4, 'big')
        msg = Message(Control.SC_CHAN, data)
        await self.ctrl.ccPush(msg)

    #get the time the break actually stopped
    async def ccGetStopped(self) -> Tme:
        await self.hit.wait()
        return self.stopped

    #get the time the break is promised to Stop
    async def ccGetPromised(self) -> Tme:
        await self.ack.wait()
        return self.thresh

    def getStopped(self) -> Tme:
        return choc.call(self.ccGetStopped(), "Break~ccGetStopped")
    
    def getPromised(self) -> Tme:
        return choc.call(self.ccGetPromised(), "Break~ccGetPromised")

    def release(self):
        choc.call(self.ccRelease(), "Break~ccRelease")

    def setAck(self, time:Tme):
        self.thresh = time
        self.ack.set()

    def setHit(self, time:Tme):
        self.stopped = time
        self.hit.set()

class Wait:
    def __init__(self, ctrl:Control, time:Tme, relative:True):
        self.ctrl = ctrl
        now = ctrl.now
        if relative:
            self.duration = time
            self.thresh = now + time
        else:
            self.duration = time - now
            self.thresh = time
        self.hitTime = None
        self.hit = asyncio.Event()
        choc.submit(self.ccRegister(), "Wait~ccRegister")

    async def ccRegister(self):
        self.ctrl.waits.append(self)

    async def ccWait(self) -> Tme:
        await self.hit.wait()
        return self.hitTime

    def wait(self) -> Tme:
        return choc.call(self.ccWait(), "Wait~ccWait")

class Control:
    SSC_LOGLEVEL = "loglevel"
    SC_CHAN = "ctrl"
    logName = "SiCoControl"
    def __init__(self):
        self.connection = Connection()
        self.recvQueues = {}
        self.sendQueue = asyncio.Queue()
        self.now = Tme.zero()
        self.breaks = {}
        self.waits = []
        #self.holding = None
        #self.isFinished = asyncio.Event()
        #self.isHolding = asyncio.Event()
        self.shutdownRequest = asyncio.Event()
        choc.submit(self.ccRunDispatch(), f"Control~ccRunDispatch")
        choc.submit(self.ccRunSender(), f"Control~ccRunSender")
        choc.submit(self.ccRunCtrl(), f"Control~ccRunCtrl")

    def getQueue(self, name:str) -> asyncio.Queue[Message]:
        try:
            return self.recvQueues[name]
        except KeyError:
            chan = asyncio.Queue()
            self.recvQueues[name] = chan
            logging.getLogger(self.logName).debug(f"new channel:{name}")
            return chan

    #push message to sendQueue
    async def ccPush(self, msg:Message):
        log = logging.getLogger(self.logName)
        await self.sendQueue.put(msg)
        log.log(5, "pushed to send queue")

    #the main dispatcher loop - sorts messages coming from the connection to recvQueues
    async def ccRunDispatch(self):
        log = logging.getLogger(self.logName)
        log.debug("starting dispatcher task")
        while True:
            msg = await self.connection.recvPipe.pull()
            assert isinstance(msg, Message), f"msg is not Message but:{type(msg)}"
            que = self.getQueue(msg.channel)
            await que.put(msg)
            log.log(5, f"dispatched to channel:{msg.channel} message:{msg}")

    #the command processor - processes messages from the recvQueue 'ctrl'
    async def ccRunCtrl(self):
        log = logging.getLogger(self.logName)
        log.debug("starting Ctrl task")
        await self.ccSendTick() #start tick tock
        queue = self.getQueue(self.SC_CHAN)
        while True:
            msg = await queue.get()
            await self.ccProcess(msg)

    #send messages from the sendQueue to the connection
    async def ccRunSender(self):
        log = logging.getLogger(self.logName)
        log.debug("starting sender task")
        while True:
            msg = await self.sendQueue.get()
            log.log(5, "took message from sendQueue")
            await self.connection.sendPipe.push(msg)
            log.log(5, "pushed message to connections sendPipe")

    #handles one control message
    async def ccProcess(self, msg):
        log = logging.getLogger(self.logName)
        cmd = Command.fromBytes(msg.data[0:4])
        if cmd == Command.tock:
            self.now = Tme.fromBytes(msg.data[4:])
            self.checkWaits()
            log.log(5, "recv tock!")
            await self.ccSendTick()
        elif cmd == Command.ackBreak:
            uid = int.from_bytes(msg.data[4:8], 'big')
            log.debug(f"recv break ack id:{uid}")
            self.breaks[uid].setAck(Tme.fromBytes(msg.data[8:]))
        elif cmd == Command.hitBreak:
            uid = int.from_bytes(msg.data[4:8], 'big')
            log.debug(f"recv break hit id:{uid}")
            self.breaks[uid].setHit(Tme.fromBytes(msg.data[8:]))
        elif cmd == Command.shutdown:
            self.shutdownRequest.set()
        else:
            log.warning(f"SimContol got unknown command {cmd}")

    #sends a tick message
    async def ccSendTick(self):
        log = logging.getLogger(self.logName)
        # FIXME need to check if the simulator is finished
        #if self.isFinished.is_set():
        #    log.debug("skip tick, sim is finished")
        #    return
        msg = Message(self.SC_CHAN, Command.tick.toBytes())
        log.log(5, "send tick!")
        await self.ccPush(msg)

    #wait for a simulator connection
    def simWaitConn(self):
        choc.call(self.connection.connected.wait(), "simWaitConn")

    def checkWaits(self):
        newlist = []
        for wait in self.waits:
            if wait.thresh <= self.now:
                wait.hitTime = self.now
                wait.hit.set()
            else:
                newlist.append(wait)
        self.waits = newlist

    def setBreak(self, typ:BreakType, time:Tme=None, relative:bool=None) -> Break:
        etype((typ, BreakType), (time, (Tme, None)), (relative, (bool, None)))
        if relative is None:
            relative = True if time is None else False
        if time is None:
            time = Tme.zero()
        return Break(self, time, typ, relative)

    def setFinish(self, time:Tme=None, relative:bool=None) -> Break:
        return self.setBreak(BreakType.finish, time, relative)
    
    def setHold(self, time:Tme=None, relative:bool=None) -> Break:
        return self.setBreak(BreakType.hold, time, relative)

    def setStop(self, time:Tme=None, relative:bool=None) -> Break:
        return self.setBreak(BreakType.stop, time, relative)
    
    def setWait(self, time:Tme, relative:bool=True) -> Wait:
        return Wait(self, time, relative)

class Channel(Item):
    def __init__(self, ctrl:Control, name:str, asyncSample:Tme=None):
        etype((ctrl, Control), (name, str), (asyncSample, (Tme, None)))
        super().__init__(name)
        self.name = name
        self.ctrl = ctrl
        self.queue = ctrl.getQueue(name)
        self.offset = None
        self.pos = Tme.zero()
        self.breakPoint = None
        self.breakMargin = Tme.fromFreq(MEGA)
        self.sampleCycle = asyncSample
        self.sample = None
        self.sampleLock = asyncio.Lock()
        self.itemAddSender("income", Change)
        self.itemAddReceiver("outgo", Change)
        choc.submit(self.ccRunSend(), f"{self.name}~ccRunSend")
        choc.submit(self.ccRunRecv(), f"{self.name}~ccRunRecv")
        if self.sampleCycle:
            choc.submit(self.ccRunSampler(), f"{self.name}~ccRunSampler")

    async def ccRunSend(self):
        sock = self.itemGet("outgo")
        log = logging.getLogger(self.name)
        while True:
            chg:Change = await sock.recv()
            if isinstance(chg, PipeOffband):
                if chg == PipeOffband.PipeEnd:
                    break
                elif chg == PipeOffband.FrameStart:
                    assert self.breakPoint is None, "Frame start! but frame already started"
                    self.breakPoint = self.ctrl.setHold(Tme.zero(), relative=True)
                    promise = await self.breakPoint.ccGetPromised() + self.breakMargin
                    self.offset = max(promise, self.pos)
                    log.debug(f"Frame start at:{self.offset}!")
                    continue
                elif chg == PipeOffband.FrameEnd:
                    assert self.breakPoint is not None, "Frame end! but no frame opened"
                    log.debug("try to release break")
                    await self.breakPoint.ccRelease()
                    self.breakPoint = None
                    self.offset = None
                    log.debug(f"Frame stop at:{self.pos}!")
                    continue
                else:
                    continue
            assert isinstance(chg.value, Bits), f"channel:{self.name} must transport Bits, not:{type(chg.value)}"
            if self.offset:
                chg = chg.shifted(self.offset)
                self.pos = chg.time
            log.debug(f"Change:{chg} -> Simulator")
            msg = Message(self.name, chg.toBytes())
            await self.ctrl.ccPush(msg)

    async def ccRunRecv(self):
        sock = self.itemGet("income")
        log = logging.getLogger(self.name)
        while True:
            msg = await self.queue.get()
            self.sample = Change.fromBytes(msg.data, Bits)
            if self.sample.sync:
                chg = self.sample
            else:
                chg = Change(self.sample.value, self.sample.time)
            log.debug(f"Simulator -> {self.sample} -> Change:{chg}")
            await sock.send(chg)

    async def ccRunSampler(self):
        log = logging.getLogger(self.name)
        sock = self.itemGet("income")
        while True:
            sTime = self.ctrl.now - self.sampleCycle #time we want to synthesize a sample
            if self.sample is not None and not self.sample.sync and sTime > self.sample.time:
                chg = Change(self.sample.value, sTime)
                #log.debug(f"Simulator -> Sample:{self.sample} -> Change:{chg}")
                await sock.send(chg)
            wait = self.ctrl.setWait(self.sampleCycle)
            await wait.ccWait()
