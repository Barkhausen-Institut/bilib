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
import time
from sico.comm import Control, Break
from bilib.errors import Errors
from choc.types import Tme

err = Errors()

logging.basicConfig(level=logging.DEBUG)

ctrl = Control()
ctrl.simWaitConn()

print("start holding")
hold = ctrl.setHold()

expected = hold.getStopped() + Tme("10u")
print(f"holding at:{hold}")

fin = ctrl.setFinish(expected)
fin.getPromised()
print(f"finish:{fin}")

time.sleep(1.0)

print("release")
hold.release()

stop = fin.getStopped()
print(f"finished at:{stop}")

if stop == expected:
    err.success("finished at expected time")
else:
    err.fail(f"finished at {stop}, expected {expected}")

err.exit()

