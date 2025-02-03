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

import logging
from pathlib import Path
from typing import Callable
import choc
from bilib.fn import Interval, Packer, etype, mkmask
from choc.items import BitsRequest, Converter, RequestInput
from choc.pipe import Item, OutPort, PipeType, Request
from choc.types import Bits, NotPureSignal

# sockets:
# IO name   type            port
# <- req    MemoryRequest

class MemoryPort(Item):
    def __init__(self, name:str="MemPort"):
        super().__init__(name)
        self.itemAddSender("req", MemoryRequest)

    async def ccRead(self, addr:int) -> int:
        etype((addr,int))
        req = MemoryRequest(addr, False)
        sock = self.itemGet("req")
        await sock.send(req)
        await req.wait()
        return req.result
    
    async def ccWrite(self, addr:int, data:int, mask:int=None):
        etype((addr,int), (data,int), (mask,(int,None)))
        req = MemoryRequest(addr, True, data, mask)
        sock = self.itemGet("req")
        await sock.send(req)
        await req.wait()

    def read(self, addr:int) -> int:
        return choc.call(self.ccRead(addr), f"{self.name}~ccRead")
    
    def write(self, addr:int, data:int, mask:int=True) -> int:
        return choc.call(self.ccWrite(addr, data, mask), f"{self.name}~ccWrite")

# wite is a write bit enable mask, or True for all bits 1
class MemoryRequest(Request):
    LOGNAME = "MemoryReq"
    def __init__(self, addr:int, write:bool, data:int=None, mask:int=True):
        etype((addr,int), (write,bool), (data,(int,None)), (mask,(int,bool)))
        super().__init__()
        self.addr = addr
        self.write = write
        self.data = data
        self.mask = mask

    def getByteMask(self) -> int:
        byteMask = 0
        bitMask = self.mask
        pos = 0
        while bitMask != 0:
            low = bitMask & 0xff
            if low == 0:
                pass
            elif low == 0xff:
                byteMask = byteMask | (1 << pos)
            else:
                raise Exception(f"bitmask:{bitMask:#x} is not a byte mask")
            bitMask = bitMask >> 8
            pos += 1
        return byteMask

class MemoryAccess(Item):
    def __init__(self, name:str="MemAccess"):
        super().__init__(name)
        
        typ = PipeType(MemoryRequest)
        self.req = RequestInput(typ)
        self.req >> OutPort(self.itemAddSender("req", typ), name=f"{self.name}OutPort")

    def read(self, addr:int) -> choc.Task:
        etype((addr,int))
        req = MemoryRequest(addr, False)
        return self.req.post(req)
    
    def write(self, addr:int, data:int, mask:int=True) -> choc.Task:
        etype((addr,int), (data,int), (mask,(int,bool)))
        assert mask != False, "write mask must be True or an integer != 0"
        req = MemoryRequest(addr, True, data, mask)
        return self.req.post(req)

class MemoryToBitsReq(Converter):
    def __init__(self, addrWith:int, dataWidth:int, maskWidth:int=None, name:str="MemToPar"):
        etype((addrWith,int), (dataWidth,int), (maskWidth,(int,None)), (name,str))
        super().__init__(name, PipeType(MemoryRequest), PipeType(BitsRequest))
        self.addrWith = addrWith
        self.dataWidth = dataWidth
        self.maskWidth = maskWidth

    def convert(self, req:MemoryRequest) -> BitsRequest:
        pack = Packer()
        if self.maskWidth is not None:
            if isinstance(req.mask, bool):
                mask = mkmask(Interval(size=self.maskWidth)) if req.mask is True else 0
            else:
                mask = req.mask
            pack.add(mask, self.maskWidth)
        if req.write:
            pack.add(req.data, self.dataWidth)
        else:
            pack.add(0, self.dataWidth)
        pack.add(req.addr, self.addrWith)
        pack.add(req.write, 1)
        bits = Bits(pack.val, pack.pos)
        sreq = BitsRequest(bits)
        sreq.setCallBack(self.commit, req)
        return sreq
    
    async def commit(self, sreq:BitsRequest, req:MemoryRequest):
        try:
            val = sreq.result.toInt()
        except NotPureSignal:
            val = None
        req.commit(val)

class MemoryAddrConvert(Converter):
    def __init__(self, offset:int=None, fn:Callable=None, name:str="MemoryAddrConvert"):
        super().__init__(name, PipeType(MemoryRequest), PipeType(MemoryRequest))
        etype((offset, (int,None)), (fn, (Callable,None)))
        self.call = fn
        if offset is not None:
            if self.call is not None:
                raise Exception("only an offset or an call")
            self.call = lambda x: x + offset
    
    def convert(self, req:MemoryRequest) -> MemoryRequest:
        cvt = MemoryRequest(self.call(req.addr), req.write, req.data, req.mask)
        cvt.setCallBack(self.commit, req)
        return cvt

    async def commit(self, cvt:MemoryRequest, req:MemoryRequest):
        req.commit(cvt.result)
        
class Memory(Item):
    def __init__(self, name:str="Memory"):
        super().__init__(name)
        self.mem = {}
        self.itemAddReceiver("req", MemoryRequest)
        choc.submit(self.run(), f"{self.name}~run")

    async def run(self):
        reqSocket = self.itemGet("req")
        log = logging.getLogger(self.name)
        while True:
            req = await reqSocket.recv()
            if req.write:
                log.debug(f"Writing {req.addr:#x} - {req.data:#x}")
                self.mem[req.addr] = req.data
                req.commit(0)
            else:
                try:
                    val = self.mem[req.addr]
                    log.debug(f"Reading {req.addr:#x} - {val:#x}")
                except KeyError:
                    val = 0x0
                    log.debug(f"Reading {req.addr:#x} - new:{val:#x}")
                req.commit(val)

    def write(self, addr:int, data:int):
        self.mem[addr] = data

    def read(self, addr:int) -> int:
        try:
            return self.mem[addr]
        except KeyError:
            return 0x0

    def readHexDump(self, fname:Path, offset:int=0):
        log = logging.getLogger(self.name)
        addr = None
        log.info(f"read hexdump:{fname} to:{offset}")
        with open(fname, 'r') as fh:
            for line in fh:
                if line[0] == '@':
                    addr = int(line[1:], 16) * 8 + offset
                elif line[0] == 'z':
                    pass
                else:
                    data = int(line, 16)
                    self.mem[addr] = data
                    #log.debug(f"mem addr:{addr:#x} data:{data:#x}")
                    addr += 8


