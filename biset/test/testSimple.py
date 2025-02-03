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

from bilib.errors import Errors
from bilib.fn import Interval
from bimem import Memory
from biset import BiSetToMemory
from biset.register import Regfile

err = Errors()

regfile = Regfile()

mem = Memory()
regfile >> BiSetToMemory() >> mem

regfile.add("reg1", 0)
regfile.reg1.add("b0", Interval(0, 7))
regfile.reg1.add("b1", Interval(8, 15))
regfile.add("reg2", 1, volatile=True)
regfile.add("reg3", 2, opaque=True, reset=0xbeefdead)

mem.write(0, 0xaffeaffe)
mem.write(1, 0xdeadbeef)
mem.write(2, 0x12345678)
mem.write(3, 0x9abcdef0)

# read from mem
rd = regfile.reg1.rd()
err.check(0xaffeaffe == rd, "read reg1", f"read failed - got:{rd:x} exp:0xaffeaffe")
rd = regfile.reg2.rd()
err.check(0xdeadbeef == rd, "read reg2", f"read failed - got:{rd:x} exp:0xdeadbeef")
rd = regfile.reg3.rd()
err.check(0xbeefdead == rd, "read reg3", f"read failed - got:{rd:x} exp:0xbeefdead")

# cached?
mem.write(0, 0x9abcdef0)
mem.write(1, 0xbbccddee)
mem.write(2, 0x11223344)
rd = regfile.reg1.rd()
err.check(0xaffeaffe == rd, "read reg1 cached", f"read reg1 failed - got:{rd:x} exp:0xaffeaffe")
rd = regfile.reg2.rd()
err.check(0xbbccddee == rd, "read reg2 cached volatile", f"read reg2 failed - got:{rd:x} exp:0xaffeaffe")
rd = regfile.reg3.rd()
err.check(0xbeefdead == rd, "read reg3 cached opaque", f"read reg3 failed - got:{rd:x} exp:0xbeefdead")


err.exit()