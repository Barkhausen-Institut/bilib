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
from sico.comm import Control
from bilib.errors import Errors
from choc.types import Tme

err = Errors()

logging.basicConfig(level=logging.DEBUG)

ctrl = Control()

ctrl.simWaitConn()

finishTime = Tme("1m")
print(f"set absolute finish at {finishTime}")
ctrl.simFinishAt(finishTime)

ctrl.simRelease()

ctrl.simWaitFinish()

print(f"finished at:{ctrl.now}")

if ctrl.now == finishTime:
    err.success("finished at expected time")
else:
    err.fail(f"finished at {ctrl.now}, expected {finishTime}")

err.exit()

