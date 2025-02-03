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

import choc
from choc.pipe import Gate, Synth, Blend, Tme
import logging

logging.basicConfig(level=logging.DEBUG)

log = logging.getLogger("test")

syn = Synth("input")
blnd = Blend("output")

syn >> blnd

log.info("feed")
syn.feeds(range(100), Tme.metronom(Tme("1c")))

log.info("consume")
for i in range(100):
    print(i, blnd.consume())


print("finished")