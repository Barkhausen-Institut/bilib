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

import asyncio
from bilib.fn import Interval, bitsel, mkmask, bitmask, mkList
import choc
from choc.items import RequestInput
from choc.pipe import Item, OutPort, PipeType
from biset import BiSetRequest

class Regfile(Item):
    def __init__(self, name:str="Regfile"):
        super().__init__(name)
        self.regs = []
        typ = PipeType(BiSetRequest)
        self.itemAddSender("req", typ)
        self.dirty = set()
        self.cache = {} #addr -> value
        self.volatile = {} #addr -> value - stuff that is read/written while locked
        self.locked = False
        self.lockedRead = False
    
    def gethandle(self, name:str):
        #registers
        for reg in self.regs:
            if name in reg.names:
                return reg
        #fields
        for reg in self.regs:
            for field in reg.fields:
                if field.name == name:
                    return field
        return None

    def __getattr__(self, name:str):
        hndl = self.gethandle(name)
        if hndl is None:
            raise AttributeError(f'cannot find register/field: {name}')
        return hndl

    def add(self, name:str, addr:int, reset:int=None, masked:int=None, volatile:bool=False, opaque:bool=False):
        rg = Register(name, addr, self)
        if masked:
            rg.masked = masked
        if reset is not None:
            rg.resetVal = reset
        rg.volatile = volatile
        rg.opaque = opaque
        self.regs.append(rg)
        return rg

    async def ccRead(self, addr:int, dontCache:bool=False, dontRead:bool=False) -> int:
        # first look in the volatile cache
        try:
            return self.volatile[addr]
        except KeyError:
            pass
        # then look in real cache
        if not dontCache:
            try:
                return self.cache[addr]
            except KeyError:
                pass
        # we are not allowed to query for the value :(
        if self.lockedRead or dontRead:
            return None
        # fetch
        req = BiSetRequest(addr)
        sock = self.itemGet("req")
        self.log().debug(f"fetching {addr:#x}")
        await sock.send(req)
        await req.wait()
        val = req.result
        self.log().debug(f"fetched {addr:#x} -> {val:#x}")
        if not dontCache:
            self.cache[addr] = val
        if self.locked:
            self.volatile[addr] = val
        #
        return val

    #dont cache - dont put the written value to main cache
    async def ccWrite(self, addr:int, value:int, dontCache:bool=False):
        curr = await self.ccRead(addr, dontRead=True)
        # did anything change?
        if curr is not None and curr == value:
            return
        # if locked write to dirty cache
        if self.locked:
            self.dirty.add(addr)
            self.volatile[addr] = value
        # write to cache
        if not dontCache:
            self.cache[addr] = value
        # honor lock
        if self.locked:
            return
        # push
        await self.ccPush(addr, value)

    async def ccPush(self, addr:int, value:int):
        req = BiSetRequest(addr, True, value)
        sock = self.itemGet("req")
        await sock.send(req)
        await req.wait()

    def invalidate(self, addr:int):
        if addr in self.cache:
            del self.cache[addr]

    def hold(self):
        if self.locked:
            raise Exception("already locked")
        self.locked = True
    
    async def ccRelease(self):
        if not self.locked:
            raise Exception("not locked")
        self.locked = False
        self.lockedRead = False
        for addr,val in self.volatile.items():
            if addr in self.dirty:
                await self.ccPush(addr, val)
        self.volatile = {}
        self.dirty = set()

    def release(self):
        choc.call(self.ccRelease(), name=f"{self.name}~release")

    def lockRead(self):
        self.lockedRead = True
        return self

    def __enter__(self):
        self.hold()
        return self

    def __exit__(self, _, __, ___) -> bool:
        self.release()
        return False #exceptions should be reraised

    async def __aenter__(self):
        self.hold()
        return self

    async def __aexit__(self, exc_type, __, ___) -> bool:
        #if we are shutting down skip the clean Release
        if exc_type == asyncio.CancelledError and choc.isShuttingDown():
            return False
        await self.ccRelease()

    def dump(self):
        print(f'Regfile @{self.base:#x}')
        for reg in self.regs:
            reg.dump()


class Register:
    def __init__(self, name:str|list[str], addr:int, regfile:Regfile):
        self.names = mkList(name)
        self.regfile = regfile
        self.addr = addr
        self.volatile = False   #value may change spontaneously
        self.opaque = False     #value cannot be read
        self.fields = []
        self.masked = 0x0 #bits to be masked out when writing
        self.resetVal = None

    def __enter__(self):
        self.regfile.hold()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.regfile.release()
        return False

    async def __aenter__(self):
        self.regfile.hold()
        return self

    async def __aexit__(self, exc_type, _, __):
        #if we are shutting down skip the clean Release
        if exc_type == asyncio.CancelledError and choc.isShuttingDown():
            return False
        await self.regfile.ccRelease()

    def gethandle(self, name:str):
        #fields
        for field in self.fields:
            if field.name == name:
                return field
        return None

    def __getattr__(self, name:str):
        hndl = self.gethandle(name)
        if hndl is None:
            raise AttributeError(f'cannot find field: {name}')
        return hndl

    def add(self, name:str, itvl:Interval, desc:str=None, reset:int=None):
        assert(isinstance(itvl, Interval))
        fd = Field(name, self)
        fd.interval = itvl
        if desc:
            fd.description = desc
        if reset is not None:
            fd.reset = reset
        self.fields.append(fd)
        return fd

    def invalidate(self):
        self.regfile.invalidate(self.addr)

    async def ccRd(self, invalid:bool=False):
        val = await self.regfile.ccRead(self.addr, self.volatile or invalid or self.opaque, self.opaque)
        val = self.resetVal if val is None else val
        return val

    def rd(self, invalid:bool=False):
        return choc.call(self.ccRd(invalid), f"{self.names[0]}~rd")

    async def ccWr(self, value:int):
        await self.regfile.ccWrite(self.addr, value, self.volatile or self.opaque)

    def wr(self, value:int):
        choc.call(self.ccWr(value), f"{self.names[0]}~wr")

    def dump(self):
        print(f'  {self.name:10s}:{self.rd():#x}')
        for field in self.fields:
            print(f'    {field.name:20s}: ({field.interval.low:2}:{field.interval.hi:2}) {field.rd(cached=True):#8x}')

class Field:
    def __init__(self, name:str, register:Register):
        self.name = name
        self.register = register
        self.interval = Interval(0,31)
        self.description = 'NA'
        self.canWrite = True
        self.canRead = True
        self.reset = None

    async def ccRd(self, invalid:bool=False):
        if not self.canRead:
            raise Exception("try to read non readable field")
        regval = await self.register.ccRd(invalid)
        return bitsel(regval, self.interval)

    def rd(self):
        return choc.call(self.ccRd(), f"{self.name}~rd")

    async def ccWr(self, val):
        if not self.canWrite:
            raise Exception("try to write non writable field")
        regval = await self.register.ccRd()
        mask = mkmask(self.interval)
        newval = (val << self.interval.low) & mask
        stripped = regval & ~mask
        await self.register.ccWr(stripped | newval)

    def wr(self, val):
        choc.call(self.ccWr(val), f"{self.name}~rd")
