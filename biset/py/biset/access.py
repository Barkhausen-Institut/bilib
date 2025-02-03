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

from bilib.fn import Packer
from biset import BiSetRequest
import choc
from choc.pipe import Item
from choc.types import Bits, NotPureSignal

# -> BiSetRequest
# -> Bits
# <- Bits
class BiSetBitsTrafo(Item):
    def __init__(self, name:str="BiSetBitsTrafo"):
        super().__init__(name)
        self.itemAddReceiver("req", BiSetRequest)
        self.itemAddSender("send", Bits)
        self.itemAddReceiver("recv", Bits)
        choc.submit(self.run(), name=f"{self.name}~run")
        
    async def run(self):
        sendSock = self.itemGet("send")
        recvSock = self.itemGet("recv")
        reqSock = self.itemGet("req")
        log = self.log()
        while True:
            req = await reqSock.recv()
            log.debug(f"got request:{req} addr:{req.addr:x} data:{req.data or 0:x} write:{req.write}")
            p = Packer()
            p.add(req.data or 0, 32)
            p.add(req.addr, 8)
            p.add(req.write, 1)
            log.debug(f"sending bits:{p.val:x}")
            await sendSock.send(Bits(p.val, 41))
            repl = await recvSock.recv()
            try:
                intVal = repl.toInt()
            except NotPureSignal:
                log.warning(f"received non-pure signal:{repl} - replaced with 0")
                intVal = 0
            p = Packer(intVal)
            log.debug(f"received bits:{p.val:x}")
            req.commit(p.get(32))

