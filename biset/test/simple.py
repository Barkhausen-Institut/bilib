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
import sys

from bilib.errors import Errors
from biset.register import Regfile
from choc.items import ClockedSignal, SignalInterface
from biset.access import BiSetBitsTrafo
from choc.types import Tme
from sico.comm import Control, Channel

err = Errors()
logging.basicConfig(level=logging.INFO)
logging.getLogger("BiSetBitsTrafo").setLevel(logging.DEBUG)

#constant
CONST_ADDR = 1
CONST_VALUE = 0xdeadaffe
REG_ADDR = 2
REG_RESET = 0xaffebabe
REG_DATA = 0xabbe2345
RF_ADDR = 3
RF_LEN = 2
RF_RESET = 0xabbadead
RF_DATA = [0xbaab, 0xbabe]
STAT_ADDR = 5
STAT_RESET = 0x1244

ctrl = Control()

cvt = BiSetBitsTrafo()
rf:Regfile = cvt << Regfile()
cvt >> ClockedSignal() >> Channel(ctrl, "biset") >> SignalInterface() >> cvt

rf.add("const", 1)
rf.add("reg",   2)
rf.add("rf0",   3)
rf.add("rf1",   4)
rf.add("stat",  5, volatile=True)

err.check(rf.const.rd() == CONST_VALUE, "good", "const value read wrong")
err.check(rf.reg.rd() == REG_RESET, "good", "reg value read wrong")
rf.reg.wr(REG_DATA)
rf.reg.invalidate()
err.check(rf.reg.rd() == REG_DATA, "good", "reg value read wrong")
err.check(rf.rf0.rd() == RF_RESET, "good", "rf0 value read wrong")
err.check(rf.rf1.rd() == RF_RESET, "good", "rf1 value read wrong")
rf.rf0.wr(RF_DATA[0])
rf.rf1.wr(RF_DATA[1])
rf.rf0.invalidate()
rf.rf1.invalidate()
err.check(rf.rf0.rd() == RF_DATA[0], "good", "rf0 value read after write wrong")
err.check(rf.rf1.rd() == RF_DATA[1], "good", "rf1 value read after write wrong")
err.check(rf.stat.rd() == STAT_RESET, "good", "stat value read wrong")
rf.stat.wr(1)
err.check(rf.stat.rd() == REG_DATA, "good", "stat value read wrong")

b = ctrl.setFinish(Tme("100u"), relative=True)
b.getStopped()

print("burbel burbel - burbel burbel")

err.exit()
