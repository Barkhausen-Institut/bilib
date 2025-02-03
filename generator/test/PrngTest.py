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

import sico.comm
import PRNG
from SiCo.signal import SignalBuffer, Player, Cut
from SiCo.types import Change, Tme, Signal
from SiCo.tools import Dumper


conn = sico.comm.Connection()
ctrl = sico.comm.Control(conn)

exp = SignalBuffer(PRNG.prng(), Tme.metronom("10n", end="200n"), width=16)

mon = Player(sico.comm.Channel(ctrl, "mon"), 16)
try:
    sig = SignalBuffer(Cut(mon, Tme("200n"), start=Tme("2u")))
except KeyboardInterrupt:
    print("keyboard --")

ret = Signal.compare(sig, exp)

ctrl.simExit()

dump = Dumper()
dump.addSignal("dut", "exp", exp)
dump.addSignal("dut", "mon", sig)
dump.writeVCD("tb.vcd")

print("done")

exit(ret)