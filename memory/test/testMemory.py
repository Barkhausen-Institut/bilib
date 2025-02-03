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
from bimem import Memory, MemoryAccess

err = Errors()

mem = Memory()
access = MemoryAccess()

access >> mem

access.write(0, 0x1234)
access.write(1, 0x5678)
access.write(2, 0x9abc)

val = access.read(0)()
err.check(val == 0x1234, "read 0x1234", f"read failed - got:{val:x} exp:0x1234")
val = access.read(1)()
err.check(val == 0x5678, "read 0x5678", f"read failed - got:{val:x} exp:0x5678")
val = access.read(2)()
err.check(val == 0x9abc, "read 0x9abc", f"read failed - got:{val:x} exp:0x9abc")