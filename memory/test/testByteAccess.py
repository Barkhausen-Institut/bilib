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
x = mem >> MemoryToBitsReq(10, 64, 8) >> BitsReqToInterface(name="r2i")
x ^ Channel(ctrl, "mem")

ctrl.simWaitConn()

mem.write(0, 0x1234)
mem.write(16, 0xaffedeadabcdabcd)

print("waiting for the result")
res = mem.read(0)()
err.checkValX(res, 0x1234, "read mem1")
res = mem.read(16)()
err.checkValX(res, 0xaffedeadabcdabcd, "read mem1")


ctrl.setFinish(Tme("10n"), relative=True).getStopped()

err.exit()