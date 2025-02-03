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

import sys

import sico.comm
from SiCo.signal import Cut, Player, Recorder, Scale, SignalBuffer
from SiCo.tools import Dumper
from SiCo.types import MEGA, Signal, Tme

#buf
bufIn = SignalBuffer([
    "1'b0n",
    "1'b1@1u1n",
    "1'b0@1u23n",
    "1'bd@0n"        #release
])

bufOutExp = SignalBuffer([
    "1'b0@0n",
    "1'b1@1u20n",
    "1'bd@1u40n"
])

#mutex
mtxLRelease = SignalBuffer([
    "1'b0@0c",
    "1'b1@105c",
    "1'b0@106c",
    "1'bd@0c"
])

mtxRRelease = SignalBuffer([
    "1'b0@0c",
    "1'b1@110c",
    "1'b0@111c",
    "1'bd@0c"
])

mtxLLockedExp = SignalBuffer([
    "1'bd@0c",
    "1'b1@100c",
    "1'b0@106c",
    "1'b1@113c"
])

mtxRLockedExp = SignalBuffer([
    "1'bd@0c",
    "1'b1@108c",
    "1'b0@111c"
])

#event
evtRequest = SignalBuffer([
    "1'b0@0c",
    "1'b1@105c",
    "1'b0@106c",
    "1'bd@0c"
])

evtReadyExp = SignalBuffer([
    "1'bd@0c",
    "1'b1@100c",
    "1'b0@106c",
    "1'b1@111c",
    "1'bd@0c"
])

evtEventExp = SignalBuffer([
    "1'bd@0c",
    "1'b0@100c",
    "1'b1@108c",
    "1'b0@109c",
    "1'bd@0c"
])

#gate
gteWrite = SignalBuffer([
    "1'b0@0c",
    "1'b1@105c",
    "1'b0@106c",
    "1'bd@0c"
])

gteIn = SignalBuffer([
    "8'bd@0c",
    "8'd17@105c",
    "8'b0@106c",
    "8'bd@0c"
])

gteRead = SignalBuffer([
    "1'bd@0c",
    "1'b0@100c",
    "1'b1@113c",
    "1'b0@114c",
    "1'bd@0c"
])

#stream
stmIn = SignalBuffer([
    "8'bd@0c",
    "8'b0@100c",
    "8'd23@103c",
    "8'b0@104c",
    "8'bd@0c"
])

stmInValid = SignalBuffer([
    "1'bd@0c",
    "1'b0@100c",
    "1'b1@103c",
    "1'b0@104c",
    "1'bd@0c"
])

stmOutStall = SignalBuffer([
    "1'bd@0c",
    "1'b0@100c",
    "1'bd@0c"
])

stmInStallExp = SignalBuffer([
    "1'bd@0c",
    "1'b0@103c",
    "1'bd@104c",
    "1'bd@0c"
])

stmOutExp = SignalBuffer([
    "8'bd@0c",
    "8'd23@106c",
    "8'bd@107c"
])

stmOutValidExp = SignalBuffer([
    "1'bd@0c",
    "1'b1@106c",
    "1'bd@107c"
])

conn = sico.comm.Connection()
ctrl = sico.comm.Control(conn)

bufInRec = Recorder(sico.comm.Channel(ctrl, "bufIn"))
bufInRec.stream(bufIn)
bufOutPly = Player(sico.comm.Channel(ctrl, "bufOut"), 1)

mtxLReleaseRec = Recorder(sico.comm.Channel(ctrl, "mtxLRelease"))
mtxLReleaseRec.stream(mtxLRelease)
mtxRReleaseRec = Recorder(sico.comm.Channel(ctrl, "mtxRRelease"))
mtxRReleaseRec.stream(mtxRRelease)
mtxLLockedPly = Player(sico.comm.Channel(ctrl, "mtxLLocked"), 1, cycle=True)
mtxRLockedPly = Player(sico.comm.Channel(ctrl, "mtxRLocked"), 1, cycle=True)

evtRequestRec = Recorder(sico.comm.Channel(ctrl, "evtRequest"))
evtRequestRec.stream(evtRequest)
evtReadyPly = Player(sico.comm.Channel(ctrl, "evtReady"), 1, cycle=True)
evtEventPly = Player(sico.comm.Channel(ctrl, "evtEvent"), 1, cycle=True)

gteWriteRec = Recorder(sico.comm.Channel(ctrl, "gteWrite"))
gteWriteRec.stream(gteWrite)
gteInRec = Recorder(sico.comm.Channel(ctrl, "gteIn"))
gteInRec.stream(gteIn)
gteReadRec = Recorder(sico.comm.Channel(ctrl, "gteRead"))
gteReadRec.stream(gteRead)
gteOutPly = Player(sico.comm.Channel(ctrl, "gteOut"), 8, cycle=True)
gteWOpenPly = Player(sico.comm.Channel(ctrl, "gteWOpen"), 1, cycle=True)
gteROpenPly = Player(sico.comm.Channel(ctrl, "gteROpen"), 1, cycle=True)

stmInRec = Recorder(sico.comm.Channel(ctrl, "stmIn"))
stmInRec.stream(stmIn)
stmInValidRec = Recorder(sico.comm.Channel(ctrl, "stmInValid"))
stmInValidRec.stream(stmInValid)
stmOutStallRec = Recorder(sico.comm.Channel(ctrl, "stmOutStall"))
stmOutStallRec.stream(stmOutStall)
stmInStallPly = Player(sico.comm.Channel(ctrl, "stmInStall"), 1, cycle=True)
stmOutPly = Player(sico.comm.Channel(ctrl, "stmOut"), 8, cycle=True)
stmOutValidPly = Player(sico.comm.Channel(ctrl, "stmOutValid"), 1, cycle=True)

ctrl.simRun()

try:
    bufOut = SignalBuffer(bufOutPly)
    mtxLLocked = SignalBuffer(mtxLLockedPly)
    mtxRLocked = SignalBuffer(mtxRLockedPly)
    evtReady = SignalBuffer(evtReadyPly)
    evtEvent = SignalBuffer(evtEventPly)
    gteOut = SignalBuffer(gteOutPly)
    gteWOpen = SignalBuffer(gteWOpenPly)
    gteROpen = SignalBuffer(gteROpenPly)
    stmInStall = SignalBuffer(stmInStallPly)
    stmOut = SignalBuffer(stmOutPly)
    stmOutValid = SignalBuffer(stmOutValidPly)

except KeyboardInterrupt:
    pass

ctrl.simExit()

clk = Tme.fromFreq(100 * MEGA)
dump = Dumper()
dump.addSignal("buf", "bufIn", bufIn)
dump.addSignal("buf", "bufOut", bufOut)
dump.addSignal("buf", "bufOutExp", bufOutExp)
dump.addSignal("mtx", "mtxLRelease", Scale(mtxLRelease, clk))
dump.addSignal("mtx", "mtxRRelease", Scale(mtxRRelease, clk))
dump.addSignal("mtx", "mtxLLocked", Scale(mtxLLocked, clk))
dump.addSignal("mtx", "mtxRLocked", Scale(mtxRLocked, clk))
dump.addSignal("evt", "evtRequest", Scale(evtRequest, clk))
dump.addSignal("evt", "evtReady", Scale(evtReady, clk))
dump.addSignal("evt", "evtReadyExp", Scale(evtReadyExp, clk))
dump.addSignal("evt", "evtEvent", Scale(evtEvent, clk))
dump.addSignal("evt", "evtEventExp", Scale(evtEventExp, clk))
dump.addSignal("gte", "gteWrite", Scale(gteWrite, clk))
dump.addSignal("gte", "gteIn", Scale(gteIn, clk))
dump.addSignal("gte", "gteWOpen", Scale(gteWOpen, clk))
dump.addSignal("gte", "gteRead", Scale(gteRead, clk))
dump.addSignal("gte", "gteOut", Scale(gteOut, clk))
dump.addSignal("gte", "gteROpen", Scale(gteROpen, clk))
dump.addSignal("stm", "stmIn", Scale(stmIn, clk))
dump.addSignal("stm", "stmInValid", Scale(stmInValid, clk))
dump.addSignal("stm", "stmInStall", Scale(stmInStall, clk))
dump.addSignal("stm", "stmOut", Scale(stmOut, clk))
dump.addSignal("stm", "stmOutValid", Scale(stmOutValid, clk))
dump.addSignal("stm", "stmOutStall", Scale(stmOutStall, clk))
dump.writeVCD("tb.vcd")

ret = Signal.compare("buOut", bufOut, bufOutExp)
ret += Signal.compare("mtxLLocked", mtxLLocked, mtxLLockedExp)
ret += Signal.compare("mtxRLocked", mtxRLocked, mtxRLockedExp)
ret += Signal.compare("evtReady", evtReady, evtReadyExp)
ret += Signal.compare("evtEvent", evtEvent, evtEventExp)
ret += Signal.compare("stmInStall", stmInStall, stmInStallExp)
ret += Signal.compare("stmOutValid", stmOutValid, stmOutValidExp)
ret += Signal.compare("stmOut", stmOut, stmOutExp)

print("burbel burbel - burbel burbel")

sys.exit(ret)
