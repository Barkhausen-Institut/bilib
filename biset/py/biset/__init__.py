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

from typing import Callable
from bilib.fn import etype
from bimem import MemoryRequest
from choc.items import Converter
from choc.pipe import PipeType, Request

class BiSetRequest(Request):
    LOGNAME = "BSReq"
    def __init__(self, addr:int, write:bool=None, data:int=None):
        etype((addr, int), (write,(bool,None)), (data, (int,None)))
        super().__init__()
        if write is not None:
            if (write and data is None) or (not write and data is not None):
                self.log().warning(f"write:{write} data:{data} - inconsistent, it is recommended to not set write at all")
        self.addr = addr
        if write is None:
            self.write = data is not None
        else:
            self.write = write
        self.data = data


class BiSetToMemory(Converter):
    def __init__(self, name:str="BiSetToMemory"):
        etype((name, str))
        super().__init__(name, PipeType(BiSetRequest), PipeType(MemoryRequest))
    
    def convert(self, req:BiSetRequest) -> MemoryRequest:
        mreq = MemoryRequest(req.addr, req.write, req.data)
        mreq.setCallBack(self.commit, req)
        return mreq
    
    async def commit(self, mreq:MemoryRequest, req:BiSetRequest):
        req.commit(mreq.result)

class BiSetOffset(Converter):
    def __init__(self, offset:int, name:str="BiSetOffset"):
        etype((name, str), (offset, int))
        super().__init__(name, PipeType(BiSetRequest), PipeType(BiSetRequest))
        self.offset = offset

    def convert(self, req:BiSetRequest) -> BiSetRequest:
        out = BiSetRequest(req.addr + self.offset, req.write, req.data)
        out.setCallBack(self.commit, req)
        return out

    async def commit(self, out:BiSetRequest, req:BiSetRequest):
        req.commit(out.result)


class BiSetAddrConvert(Converter):
    def __init__(self, cvtFn:Callable, name:str="BiSetOffset"):
        etype((name, str), (cvtFn, Callable))
        super().__init__(name, PipeType(BiSetRequest), PipeType(BiSetRequest))
        self.fn = cvtFn

    def convert(self, req:BiSetRequest) -> BiSetRequest:
        out = BiSetRequest(self.fn(req.addr), req.write, req.data)
        out.setCallBack(self.commit, req)
        return out

    async def commit(self, out:BiSetRequest, req:BiSetRequest):
        req.commit(out.result)
