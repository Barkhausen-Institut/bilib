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
from abc import ABC, abstractmethod
from asyncio import Condition, Event, Lock
import asyncio
from enum import Enum
import logging
from typing import Callable, Iterator
import choc
from bilib.fn import etype, uniqueName

class PipeType:
    typ:type        #type of the values transferred
    name:str        #name of the type
    extra:any       #extra information about the type
    def __init__(self, typ:type=None, name:str=None, extra:any=None):
        etype((typ, (type,None)), (name,(str,None)))
        self.typ = typ
        self.name = name
        self.extra = extra

    def __repr__(self) -> str:
        args = ["None" if self.typ is None else self.typ.__name__]
        if self.name is not None:
            args.append(self.name)
        if self.extra is not None:
            args.append(str(self.extra))
        return f"PT({','.join(args)})"

    def __eq__(self, other:PipeType) -> bool:
        etype((other,PipeType))
        return self.typ == other.typ and self.name == other.name and self.extra == other.extra
    
    def match(self, other:PipeType) -> bool:
        etype((other,PipeType))
        def match(a, b):
            if a is None or b is None:
                return True
            return a == b
        return match(self.typ, other.typ) and match(self.name, other.name) and match(self.extra, other.extra)
    
    def update(self, other:PipeType):
        etype((other,PipeType))
        if other.typ is not None:
            self.typ = other.typ
        if other.name is not None:
            self.name = other.name
        if other.extra is not None:
            self.extra = other.extra
    
    @classmethod
    def fromObject(cls, obj:any) -> PipeType:
        try:
            extra = obj.getTypeExtra()
        except AttributeError:
            extra = None
        try:
            name = obj.getTypeName()
        except AttributeError:
            name = None
        return PipeType(type(obj), name=name, extra=extra)

class Direction(Enum):
    Sender = 0
    Receiver = 1
    def opposing(self) -> Direction:
        return Direction.Sender if self == Direction.Receiver else Direction.Receiver

class PipeOffband(Enum):
    Noop = 0
    FrameStart = 1
    FrameEnd = 2
    PipeEnd = 3

class Plugable(ABC):
    @abstractmethod
    def iterSockets(self) -> Iterator[Socket]:
        pass

    def forgeRecvSocket(self, typ:PipeType):
        return None

    # self >> peer
    def __rshift__(self, peer:Plugable) -> Plugable:
        etype((peer, (Plugable)))
        connect(self, peer)
        return peer

    # self << peer
    def __lshift__(self, peer:Plugable) -> Plugable:
        etype((peer, (Plugable)))
        connect(peer, self)
        return peer
    
    def __or__(self, peer:Plugable) -> Plugable:
        etype((peer, (Plugable)))
        par = Parallel()
        par.add(self)
        par.add(peer)
        return par
    
    def __xor__(self, peer:Plugable) -> Plugable:
        etype((peer, Plugable))
        connect(self, peer)
        connect(peer, self)
        return peer

class Socket(Plugable):
    direction: Direction
    typ: PipeType
    pipe: Pipe
    name: str
    connected: Event

    def __init__(self, name:str, dir:Direction, typ:PipeType|type=None):
        etype((name,str), (dir,Direction), (typ,(PipeType,type,None)))
        self.name = name
        self.direction = dir
        if isinstance(typ, type):
            self.typ = PipeType(typ)
        elif isinstance(typ, PipeType):
            self.typ = typ
        elif typ is None:
            self.typ = PipeType()
        else:
            raise Exception("invalid typ")
        self.pipe = None
        self.parent = None #prevent parent from being garbacge collected
        self.peer = None #prevent peer from being garbage collected
        self.connected = Event()

    def __repr__(self) -> str:
        dir = "Send" if self.direction == Direction.Sender else "Recv"
        return f"{dir}Socket({self.name},{self.typ})"

    async def send(self, val:any):
        assert self.direction == Direction.Sender, "cannot send on receiver"
        log = logging.getLogger(self.name)
        valTyp = PipeType.fromObject(val)
        if valTyp.typ != PipeOffband:
            assert self.typ.match(valTyp), f"socket detected type change in:{self} val:{val} valTyp:{valTyp}"
            self.typ.update(valTyp)
        #log.debug(f"Socket sending val:{val}")
        #if not self.connected.is_set():
        #    log.debug("Socket waiting for connection (send)")
        await self.connected.wait()
        await self.pipe.push(val)

    async def recv(self) -> any:
        assert self.direction == Direction.Receiver, "cannot recv on sender"
        log = logging.getLogger(self.name)
        #if not self.connected.is_set():
        #    log.debug("Socket waiting for connection (send)")
        await self.connected.wait()
        val = await self.pipe.pull()
        valTyp = PipeType.fromObject(val)
        if valTyp.typ != PipeOffband:
            assert valTyp.typ == PipeOffband or self.typ.match(valTyp), f"socket detected type change in:{self} val:{val} valTyp:{valTyp}"
            self.typ.update(valTyp)
        #log.debug(f"Socket recving val:{val}")
        return val

    def connectForward(self, peer:Socket):
        etype((peer, Socket))
        assert self.pipe is None, "socket already connected"
        pipe = Gate(f"{self.name}+{peer.name}")
        self.pipe = pipe
        peer.pipe = pipe
        self.peer = peer #prevent garbage collection
        peer.peer = self #prevent garbage collection
        choc.do(self.connected.set, name="Socket.connectForward")
        choc.do(peer.connected.set, name="Socket.connectForward")

    def iterSockets(self) -> Iterator[Socket]:
        yield self

class Item(Plugable):
    name:str
    sockets:dict[str,Socket]
    def __init__(self, name:str=None):
        etype((name, (str,None)))
        self.name = uniqueName("Item" if name is None else name)
        logging.getLogger("Item").debug(f"creating Item:{self.name}")
        self.sockets = {}

    def __del__(self):
        log = logging.getLogger(self.name)
        log.debug("deleting")

    def log(self) -> logging.Logger:
        return logging.getLogger(self.name)

    def itemAdd(self, name:str, dir:Direction, typ:PipeType|type=None) -> Socket:
        etype((name,str), (dir,Direction), (typ,(PipeType,type,None)))
        sock = Socket(f"{self.name}{'+' if dir == Direction.Sender else '-'}{name}", dir, typ)
        if name in self.sockets:
            raise Exception(f"sockets {name} already exists")
        sock.parent = self #make sure that the Item is not garbage collected
        self.sockets[name] = sock
        return sock

    def itemAddSender(self, name:str, typ:PipeType|type=None) -> Socket:
        return self.itemAdd(name, Direction.Sender, typ)

    def itemAddReceiver(self, name:str, typ:PipeType|type=None) -> Socket:
        return self.itemAdd(name, Direction.Receiver, typ)

    def itemGet(self, name:str) -> Socket:
        etype((name,str))
        if name not in self.sockets:
            raise Exception(f"socket {name} does not exist")
        return self.sockets[name]

    def iterSockets(self) -> Iterator[Socket]:
        yield from self.sockets.values()

class Parallel(Plugable):
    items:Plugable
    def __init__(self):
        self.items = []

    def add(self, item:Plugable):
        etype((item,Plugable))
        self.items.append(item)

    def iterSockets(self) -> Iterator[Socket]:
        for item in self.items:
            yield from item.iterSockets()

    def forgeRecvSocket(self, typ: PipeType):
        for item in self.items:
            sock = item.forgeRecvSocket(typ)
            if sock:
                return sock
        else:
            return None

#connect a -> b
def connect(a:Plugable, b:Plugable):
    etype((a,Plugable), (b,Plugable))
    log = logging.getLogger("PipeConnect")
    nConnected = 0
    for aSock in a.iterSockets():
        if aSock.direction == Direction.Receiver or aSock.connected.is_set():
            continue
        for bSock in b.iterSockets():
            if bSock.direction == Direction.Sender or bSock.connected.is_set():
                continue
            if aSock.typ.match(bSock.typ):
                aSock.connectForward(bSock)
                nConnected += 1
                log.debug(f"Connected {aSock} -> {bSock}")
                break
        else:
            socket = b.forgeRecvSocket(aSock.typ)
            if socket:
                aSock.connectForward(socket)
                nConnected += 1
                log.debug(f"Connected {aSock} -> new {socket}")
    if nConnected == 0:
        msg = f"connected nothing A:{a} -> B:{b}"
        for aSock in a.iterSockets():
            if aSock.direction == Direction.Receiver or aSock.connected.is_set():
                continue
            msg += f"\nA: {aSock}"
        for bSock in b.iterSockets():
            if bSock.direction == Direction.Sender or bSock.connected.is_set():
                continue
            msg += f"\nB: {bSock}"
        raise Exception(msg)

class Request:
    LOGNAME = "Request"
    def __init__(self, data=None):
        self.uid = uniqueName(self.LOGNAME)
        self.data = data
        self.result = None
        self.done = Event()
        self.callBack = None

    def setCallBack(self, cb:Callable, *args):
        etype((cb,Callable))
        self.callBack = (cb, args)

    def commit(self, result):
        self.result = result
        self.done.set()
        if self.callBack is not None:
            cb, args = self.callBack
            choc.submit(cb(self, *args), f"{self.uid}~callback")

    def __repr__(self):
        return f"Request({self.uid})"#, {self.data}, {self.result})"

    async def wait(self, timeout:float=None):
        await asyncio.wait_for(self.done.wait(), timeout) 

# pushing and pulling is coroutine safe
class Pipe(ABC):
    @abstractmethod
    async def push(self, val:any):
        pass
    @abstractmethod
    async def pull(self) -> any:
        pass


#transfer data from one thread to another only when both are ready
class Gate(Pipe):
    class State(Enum):
        idle = 0,
        pushing = 1,
        pulled = 2
    def __init__(self, name:str):
        etype((name,str))
        self.state = Gate.State.idle
        self.pushLock = Lock() #make sure only one coroutine pushes
        self.pullLock = Lock() #make sure only one coroutine pulls
        self.condition = Condition()
        self.store = None
        self.name = uniqueName(name)

    async def push(self, value:any):
        #log = logging.getLogger(self.name)
        #log.debug(f"push: pushing gate")
        async with self.pushLock, self.condition:
            #waiting until gate is free
            while self.state != Gate.State.idle:
                await self.condition.wait()
                #log.debug(f"push: woke up. gate={self.state} (idle?)")
            #log.debug("push: gate=idle->pushing")
            self.store = value
            #notify that gate is loaded
            #we cannot leave before the gate has been pulled
            self.state = Gate.State.pushing
            self.condition.notify()
            while self.state != Gate.State.pulled:
                await self.condition.wait()
                #log.debug(f"push: woke up. gate={self.state} (pulled?)")
            #now that data is retrieved we are allowed to leave
            #log.debug(f"push: gate=pulled->idle")
            self.state = Gate.State.idle
            self.condition.notify()
        #log.debug(f"push: push finished")

    async def pull(self) -> any:
        tmp = None
        #log.debug(f"pull: pulled gate")
        async with self.pullLock, self.condition:
            #wait until gate is loaded
            while self.state != Gate.State.pushing:
                await self.condition.wait()
                #log.debug(f"pull: woke up. gate={self.state} (pushing?)")
            tmp = self.store
            #notify that value has been retrieved
            #log.debug(f"pull: gate=pushing->pulled")
            self.state = Gate.State.pulled
            self.condition.notify()
        #log.debug("pull: pull finished")
        return tmp

class OutPort(Item):
    def __init__(self, port:Socket, name:str="OutPort"):
        etype((name,str), (port,Socket))
        assert port.direction == Direction.Sender
        super().__init__(name)
        self.port = port
        self.itemAddReceiver("in", port.typ)
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        inSocket = self.itemGet("in")
        while True:
            val = await inSocket.recv()
            await self.port.send(val)

class InPort(Item):
    def __init__(self, port:Socket, name:str="InPort"):
        etype((name,str), (port,Socket))
        assert port.direction == Direction.Receiver
        super().__init__(name)
        self.port = port
        self.itemAddSender("out", port.typ)
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        outSocket = self.itemGet("out")
        while True:
            val = await self.port.recv()
            await outSocket.send(val)

class OutTap(Item):
    def __init__(self, name:str):
        super().__init__(name)
        self.itemAddReceiver("in")

    def getSocket(self) -> Socket:
        return self.itemGet("in")