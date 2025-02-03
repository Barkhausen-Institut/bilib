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

from choc.items import Clock, Input, IntToBits, Output, Range, TimedSignal
from sico.comm import Channel, Control
from bilib.errors import Errors
from choc import TimedOut
from choc.types import Bits, Change, Tme
import logging
import rrenv

err = Errors()

logging.basicConfig(level=logging.INFO)
logging.getLogger("loop").setLevel(logging.DEBUG)
#logging.getLogger("iSignal").setLevel(logging.DEBUG)
#logging.getLogger("iClock").setLevel(logging.DEBUG)

log = logging.getLogger("test")

ctrl = Control()
ctrl.simWaitConn()

#loopback
recv = Output(Change, "recv")
wrongTimeFormat = hasattr(rrenv, "wrongTimeFormat")
if wrongTimeFormat:
    log.info("using wrong time format")
    met = Clock(Tme("10c"), Tme("17c"))
else:
    met = Clock(Tme("10n"), Tme("17n"))
(met | (Range(10, 1) >> IntToBits(16))) >> TimedSignal() >> Channel(ctrl, "loop") >> recv

#clocked loopback
cRecv = Output(Change, "cRecv")
(Clock(Tme("10c"), Tme("12c")) | ((Range(10, 1) >> IntToBits(16)))) >> TimedSignal() >> Channel(ctrl, "clkdLoop") >> cRecv

#interface loopback
iRecv = Output(Change, "iRecv")
(Clock(Tme("2c"), Tme("8c"), name="iClock") | ((Range(10, 1) >> IntToBits(16)))) >> TimedSignal("iSignal") >> Channel(ctrl, "ifLoop") >> iRecv

def checkConsume(recv:Output, i:int, expTme:Tme):
    chg = recv.consume(5.0)
    val, tme = chg.value, chg.time
    expVal = Bits(i, 16)
    if val == expVal and (expTme is None or (tme.typ() == expTme.typ() and tme == expTme)):
        err.success(f"on:{recv.name} recv:{val} at:{tme}")
    else:
        err.fail(f"on:{recv.name} recv:{val} at:{tme}, expected:{expVal} at:{expTme}")

try:
    for i in range(1, 10):
        if wrongTimeFormat:
            t = Tme("10p") * i + Tme("7p")
        else:
            t = Tme("10n") * i + Tme("7n")
        checkConsume(recv, i, t)
        checkConsume(cRecv, i, Tme("10c") * i + Tme("3c"))
        checkConsume(iRecv, i, None)
except TimedOut:
    err.fail("reading a value from the channel timed out")

#simulator will finish on its own

err.exit()