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

from choc.items import BitsReqToInterface
from choc.types import Tme
from bimem import MemoryAccess, MemoryToBitsReq
from sico.comm import Channel, Control
import logging
from bilib.errors import Errors

logging.basicConfig(level=logging.DEBUG)

err = Errors()

ctrl = Control()

mem = MemoryAccess("mem")
x = mem >> MemoryToBitsReq(4, 16, name="m2p") >> BitsReqToInterface(name="r2i")
x ^ Channel(ctrl, "mem")

mem2 = MemoryAccess("mem2")
x2 = mem2 >> MemoryToBitsReq(4, 16, 4, name="m2p2") >> BitsReqToInterface(name="r2i2")
x2 ^ Channel(ctrl, "mem2")

ctrl.simWaitConn()

mem.write(0, 0x1234)
mem2.write(0, 0)
mem2.write(0, 0x1234, 0x5)

print("waiting for the result")
res = mem.read(0)()
err.checkValX(res, 0x1234, "read mem1")

print("waiting for the result")
res = mem2.read(0)()
err.checkValX(res, 0x204, "read mem2")


ctrl.setFinish(Tme("10n"), relative=True).getStopped()

err.exit()