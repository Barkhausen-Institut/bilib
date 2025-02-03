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

from abc import ABC, abstractmethod
from asyncio import Queue
import asyncio
import logging
from pathlib import Path
import queue
from typing import Iterable
import choc
from bilib.fn import etype
from choc.pipe import Item, PipeOffband, PipeType, Request, Socket
from choc.types import L9, Bits, Change, Edge, NotPureSignal, Tme


class RequestInput(Item):
    def __init__(self, typ:PipeType|type, name:str="RequestInput"):
        etype((name,str), (typ,(PipeType,type)))
        super().__init__(name)
        self.queue = asyncio.Queue()
        self.itemAddSender("req", typ)
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        reqSocket = self.itemGet("req")
        while True:
            req = await self.queue.get()
            await reqSocket.send(req)

    async def process(self, req:Request):
        await self.queue.put(req)
        await req.wait()
        return req.result
    
    def post(self, req:Request) -> choc.Task:
        return choc.submit(self.process(req), f"{self.name}~process")

# sockets:
# IO name   type      
# -> in     <fromType>      (forged if multiplexer)
# <- out    <toType>     

class Converter(Item, ABC):
    def __init__(self, name:str, fromType:PipeType, toType:PipeType, multiplexer:bool=False):
        super().__init__(name)
        self.itemAddSender("out", toType)
        self.fromType = fromType if multiplexer else None
        self.nPorts = 0
        if not multiplexer:
            sock = self.itemAddReceiver("in", fromType)
            choc.submit(self.run(sock), name=f"{self.name}~run")

    async def run(self, inSocket:Socket):
        outSocket = self.itemGet("out")
        while True:
            inVal = await inSocket.recv()
            if isinstance(inVal, PipeOffband):
                await outSocket.send(inVal)
                return
            outVal = self.convert(inVal)
            await outSocket.send(outVal)

    def forgeRecvSocket(self, typ:PipeType):
        if self.fromType is None or not typ.match(self.fromType):
            return None
        sock = self.itemAddReceiver(f"in{self.nPorts}", self.fromType)
        choc.submit(self.run(sock), name=f"{self.name}~run{self.nPorts}")
        self.nPorts += 1
        return sock

    @abstractmethod
    def convert(self, val:any) -> any:
        pass

class Multiplexer(Item):
    def __init__(self, typ:PipeType|type, name:str="Multiplexer"):
        etype((typ, (PipeType,type)), (name, str))
        super().__init__(name)
        self.itemAddSender("out", typ)
        self.nPorts = 0
        #self.typ = typ

    def newPort(self) -> Socket:
        myTyp = self.itemGet('out').typ
        socket = self.itemAddReceiver(f"in{self.nPorts}", myTyp)
        self.nPorts += 1
        choc.submit(self.receiver(socket), f"{self.name}~receiver")
        return socket

    async def receiver(self, socket:Socket):
        send = self.itemGet("out")
        log = logging.getLogger(self.name)
        while True:
            itm = await socket.recv()
            log.debug(f"multiply item:{itm}")
            await send.send(itm)

    def forgeRecvSocket(self, typ:PipeType) -> Socket:
        myTyp = self.itemGet('out').typ
        if not typ.match(myTyp):
            return None
        return self.newPort()

class Input(Item):
    class InputRequest(Request):
        LOGNAME = "InputReq"
        def __init__(self, value:any):
            super().__init__()
            self.value = value

    def __init__(self, typ:PipeType|type, name:str):
        etype((name,str), (typ,(PipeType,type)))
        super().__init__(name)
        self.itemAddSender("synth", typ)
        self.queue = Queue()
        choc.submit(self.run(), f"{self.name}~run")

    async def process(self, req:InputRequest):
        etype((req, self.InputRequest))
        log = logging.getLogger(self.name)
        #log.debug(f"submitting request {req}")
        await self.queue.put(req)
        #log.debug(f"waiting for request {req}")
        await req.wait()
        log.debug(f"Synth request {req} finished")
        return req.result

    async def run(self):
        log = logging.getLogger(self.name)
        socket = self.itemGet("synth")
        while True:
            req = await self.queue.get()
            log.debug(f"Synth processing request {req}")
            value = req.value
            await socket.send(value)
            log.debug(f"Synth processing finished - value:{value}")
            req.commit(0)

    def feed(self, value:any) -> choc.Task:
        req = self.InputRequest(value)
        return choc.submit(self.process(req), f"{self.name}~process")

    def feeds(self, values:Iterable) -> choc.Task:
        etype((values, Iterable))
        for val in values:
            self.feed(val)

    def close(self):
        self.feed(PipeOffband.PipeEnd)

class Output(Item):
    def __init__(self, typ:PipeType|type, name:str):
        etype((name,str), (typ,(PipeType,type)))
        super().__init__(name)
        self.itemAddReceiver("blend", typ)
        self.tdcQueue = queue.Queue() #thread domain crossing queue
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        log = logging.getLogger(self.name)
        socket = self.itemGet("blend")
        while True:
            val = await socket.recv()
            log.debug(f"Blend received {val}")
            self.tdcQueue.put(val)

    def consume(self, timeout:float=None) -> any:
        try:
            return self.tdcQueue.get(timeout=timeout)
        except queue.Empty:
            pass
        raise choc.TimedOut()

class IntToBits(Converter):
    def __init__(self, width:int, name:str="IntToBits"):
        etype((width,int))
        self.width = width
        super().__init__(name, PipeType(int), PipeType(Bits))

    def convert(self, val:int) -> Bits:
        return Bits(val, width=self.width)

class BitsToInt(Converter):
    def __init__(self, name:str="BitsToInt"):
        super().__init__(name, PipeType(Bits), PipeType(int))

    def convert(self, val:Bits) -> int:
        try:
            return val.toInt()
        except NotPureSignal as e:
            self.log.warning(f"cannot convert {val} to int - send 0")
            return 0

class Clock(Item):
    def __init__(self, period:Tme, start:Tme=None, stop:Tme=None, name:str="Clock"):
        etype((period, Tme), (start, (Tme, None)), (stop, (Tme, None)), (name, str))
        super().__init__(name)
        self.period = period
        self.start = start or Tme.zero(period)
        self.stop = stop
        self.itemAddSender("out", Tme)
        self.log().debug(f"create clock start:{self.start} stop:{self.stop} period:{self.period}")
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        outSock = self.itemGet("out")
        now = self.start
        while self.stop is None or now < self.stop:
            self.log().debug(f"emit:{now}")
            await outSock.send(now)
            now += self.period
        await outSock.send(PipeOffband.PipeEnd)

class Range(Item):
    def __init__(self, stop:int, start:int=0, step:int=1, name:str="Range"):
        etype((start,int), (stop,int), (step,int), (name,str))
        super().__init__(name)
        self.start = start
        self.stop = stop
        self.step = step
        self.itemAddSender("out", int)
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        outSock = self.itemGet("out")
        for i in range(self.start, self.stop, self.step):
            await outSock.send(i)
        await outSock.send(PipeOffband.PipeEnd)

class TimedSignal(Item):
    def __init__(self, name:str="Signal", typ:PipeType|type=None):
        etype((name,str), (typ, (PipeType, type, None)))
        super().__init__(name)
        self.itemAddReceiver("clk", Tme)
        self.itemAddReceiver("in", typ)
        self.itemAddSender("out", Change)
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        log = self.log()
        outSock = self.itemGet("out")
        inSock = self.itemGet("in")
        clkSock = self.itemGet("clk")
        chg = None
        #offband handling
        async def offband(sock):
            val = await sock.recv()
            while isinstance(val, PipeOffband):
                if val == PipeOffband.PipeEnd:
                    log.info(f"Signal received PipeEnd on {sock}")
                    if chg.sync:
                        end = Change(chg.value, chg.time, sync=False)
                        log.info(f"repeat last value async:{end}")
                        await outSock.send(end)
                    await outSock.send(PipeOffband.PipeEnd)
                    return None
                else:
                    await outSock.send(val)
                val = await inSock.recv()
            return val
        while True:
            # new val item
            val = await offband(inSock)
            if val is None:
                return
            time = await offband(clkSock)
            if time is None:
                return
            #send change
            chg = Change(val, time)
            log.debug(f"created Change:{chg}")
            await outSock.send(chg)

class ClockedSignal(Converter):
    def __init__(self, name:str="ClockedSignal"):
        self.cycle = Tme("0c")
        super().__init__(name, None, PipeType(Change))

    def convert(self, val:any) -> Change:
        chg = Change(val, self.cycle, sync=False)
        self.cycle += Tme("1c")
        return chg

# unpack Change to its value
class SignalInterface(Converter):
    def __init__(self, name:str="SignalInterface"):
        self.cycle = None
        super().__init__(name, PipeType(Change), None)

    def convert(self, val:Change) -> any:
        log = logging.getLogger(self.name)
        if self.cycle is not None and self.cycle >= val.time:
            log.warning(f"interface provided values out of order")
        return val.value

class ToFile(Item):
    def __init__(self, fname:Path, typ:PipeType|type=None, name:str="Tee"):
        super().__init__(name)
        etype((fname,Path), (typ,(PipeType,type,None)), (name,str))
        self.itemAddReceiver("in", typ)
        choc.submit(self.process(), f"{self.name}.process")
        self.fname = fname

    async def process(self):
        inSock = self.itemGet("in")
        with open(self.fname, "w"):
            pass
        while True:
            item = await inSock.recv()
            with open(self.fname, "a") as fh:
                print(item, file=fh)

class Tee(Item):
    def __init__(self, fname:Path, typ:PipeType|type=None, name:str="Tee"):
        super().__init__(name)
        etype((fname,Path), (typ,(PipeType,type,None)), (name,str))
        self.itemAddReceiver("in", typ)
        self.itemAddSender("out", typ)
        self.fname = fname
        choc.submit(self.process(), f"{self.name}.process")

    async def process(self):
        inSock = self.itemGet("in")
        outSock = self.itemGet("out")
        with open(self.fname, "w"):
            pass
        while True:
            item = await inSock.recv()
            with open(self.fname, "a") as fh:
                print(item, file=fh)
            await outSock.send(item)

class Printer(Item):
    def __init__(self, typ:PipeType|type=None, newlines:bool=True, name:str="Printer"):
        super().__init__(name)
        self.itemAddReceiver("in", typ)
        choc.submit(self.run(), f"{self.name}~run")
        self.endline = "\n" if newlines else ''

    async def run(self):
        inSock = self.itemGet("in")
        while True:
            val = await inSock.recv()
            print(val, end=self.endline)

class TeePrinter(Item):
    def __init__(self, typ:PipeType|type=None, name:str="Tee"):
        super().__init__(name)
        etype((typ,(PipeType,type,None)), (name,str))
        self.itemAddReceiver("in", typ)
        self.itemAddSender("out", typ)
        choc.submit(self.process(), f"{self.name}.process")

    async def process(self):
        inSock = self.itemGet("in")
        outSock = self.itemGet("out")
        while True:
            item = await inSock.recv()
            print(item)
            await outSock.send(item)

class BitsRequest(Request):
    LOGNAME = "BitsReq"
    def __init__(self, value:Bits):
        etype((value,Bits))
        super().__init__()
        self.data = value

class BitsReqToInterface(Item):
    def __init__(self, name:str="BitsReqToInterface"):
        super().__init__(name)
        self.itemAddReceiver("req", BitsRequest)
        self.itemAddSender("out", Change)
        self.itemAddReceiver("in", Change)
        self.queue = asyncio.Queue()
        choc.submit(self.send(), f"{self.name}~send")
        choc.submit(self.receive(), f"{self.name}~receive")

    async def send(self):
        reqSock = self.itemGet("req")
        outSock = self.itemGet("out")
        log = logging.getLogger(self.name)
        cycle = Tme("1c")
        while True:
            req = await reqSock.recv()
            log.debug(f"found a BitsRequest {req}")
            await self.queue.put(req)
            chg = Change(req.data, cycle, sync=False)
            await outSock.send(chg)
            cycle += Tme("1c")

    async def receive(self):
        inSock = self.itemGet("in")
        log = logging.getLogger(self.name)
        while True:
            chg = await inSock.recv()
            val = chg.value
            req = await self.queue.get()
            log.debug(f"found a value {val} for BitsRequest {req}")
            req.commit(val)

class Probe(Item):
    value:tuple[Change, Change]
    def __init__(self, name:str="Prober"):
        super().__init__(name)
        self.itemAddReceiver("in", Change)
        self.pos = Tme.zero()
        self.value = (None, None)

    def seek(self, pos:Tme, relative:bool=False):
        etype((pos,Tme))
        if relative:
            pos += self.pos
        assert pos >= self.pos, f"Prober cannot seek backwards to:{pos} from {self.pos}"
        self.pos = pos

    #makes sure that self.pos lies between the two current values
    # edge makes sure that there are really two values
    async def _align(self, edge:bool=False):
        inSock = self.itemGet("in")
        if self.value[0] is None:
            self.value = (await inSock.recv(), None)
        if self.pos == self.value[0].time and edge is False:
            return
        elif self.value[1] is None:
            self.value = (self.value[0], await inSock.recv())
        while self.pos >= self.value[1].time:
            chg = await inSock.recv()
            self.value = (self.value[1], chg)

    async def ccRead(self) -> Bits:
        await self._align()
        if self.pos == self.value[1].time:
            return self.value[1].value
        else:
            return self.value[0].value
    
    async def ccNextEdge(self, typ:Edge=Edge.any, maxTime:Tme=None) -> Change:
        log = logging.getLogger(self.name)
        etype((typ, Edge), (maxTime, (Tme,None)))
        #log.debug(f"initial align to:{self.pos}")
        await self._align(edge=True)
        while True:
            if maxTime is not None and self.value[1].time >= maxTime:
                self.pos = maxTime
                return None
            self.pos = self.value[1].time
            #log.debug(f"values:{self.value[0]}:{self.value[1]}")
            if self.value[1] is not None and self.value[0].value != self.value[1].value:
                #log.debug(f"this is some edge v0:{self.value[0].value[0]} v1:{self.value[1].value[0]}")
                #this is a change
                if typ == Edge.pos:
                    if self.value[0].value[0] == L9._0 and self.value[1].value[0] == L9._1:
                       #log.debug("found posedge")
                        return self.value[1]
                elif typ == Edge.neg:
                    if self.value[0].value[0] == L9._1 and self.value[1].value[0] == L9._0:
                        #log.debug("found negedge")
                        return self.value[1]
                else: #any
                    #log.debug("found any edge")
                    return self.value[1]
            await self._align(edge=True)

    def read(self) -> Bits:
        return choc.call(self.ccRead(), f"{self.name}~read")
    
    def nextEdge(self, typ:Edge=Edge.any, maxTime:Tme=None) -> Change:
        return choc.call(self.ccNextEdge(typ, maxTime), f"{self.name}~nextEdge")



