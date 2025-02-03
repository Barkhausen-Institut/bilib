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
import random
import _8b10b

#encode
encInput = []
encInputDisparity = []
encOutput = []
encOutputDisparity = []
while len(encInput) < 100:
    inKByte = random.getrandbits(9)
    inDisp = random.choice([-1, 1])
    try:
        disp, out = _8b10b.enc8b10b(inKByte, inDisp)
    except Exception:
        continue
    print(f"encode:{inKByte:x} to:{out:x}")
    encInput.append(inKByte)
    encInputDisparity.append(inDisp)
    encOutput.append(out)
    encOutputDisparity.append(disp)

def disp2bit(disp):
    return {-1: 0, 1: 1}[disp]

encIn = SignalBuffer(encInput, Tme.metronom("1n"), width=9, release=True)
encInDisp = SignalBuffer(map(disp2bit, encInputDisparity), Tme.metronom("1n"), width=1, release=True)
encOutExp = SignalBuffer(encOutput, Tme.metronom("1n"), width=10)
encOutDispExp = SignalBuffer(map(disp2bit, encOutputDisparity), Tme.metronom("1n"), width=1)

#decode
decInput = [random.getrandbits(10) for _ in range(100)]
decOutput = []
for inp in decInput:
    print(f"decode:{inp:x} b:{inp:010b}")
    try:
        kData = _8b10b.dec8b10b(inp)
    except Exception:
        kData = 0x100
    decOutput.append(kData)

decIn = SignalBuffer(decInput, Tme.metronom("1n"), width=10, release=True)
decOutExp = SignalBuffer(decOutput, Tme.metronom("1n"), width=9)

conn = sico.comm.Connection()
ctrl = sico.comm.Control(conn)

#encode
encInRec = Recorder(sico.comm.Channel(ctrl, "encIn")) 
encInRec.stream(encIn)
encInDispRec = Recorder(sico.comm.Channel(ctrl, "encInDisp")) 
encInDispRec.stream(encInDisp)
encOutPly = Player(sico.comm.Channel(ctrl, "encOut"), 10)
encOutDispPly = Player(sico.comm.Channel(ctrl, "encOutDisp"), 1)

#decode
decInRec = Recorder(sico.comm.Channel(ctrl, "decIn"))
decInRec.stream(decIn)
decOutPly = Player(sico.comm.Channel(ctrl, "decOut"), 9)

ctrl.simRun(stopAt=Tme("101n"))

try:
    encOut = SignalBuffer(encOutPly)
    encOutDisp = SignalBuffer(encOutDispPly)
    decOut = SignalBuffer(decOutPly)

except KeyboardInterrupt:
    pass

ctrl.simExit()

clk = Tme.fromFreq(100 * MEGA)
dump = Dumper()
dump.addSignal("enc", "in", encIn)
dump.addSignal("enc", "inDisp", encInDisp)
dump.addSignal("enc", "out", encOut)
dump.addSignal("enc", "outDisp", encOutDisp)
dump.addSignal("enc", "outExp", encOutExp)
dump.addSignal("enc", "outDispExp", encOutDispExp)
dump.addSignal("dec", "in", decIn)
dump.addSignal("dec", "out", decOut)
dump.addSignal("dec", "outExp", decOutExp)
dump.writeVCD("tb.vcd")

ret = Signal.compare("encOut", encOut, encOutExp)
ret += Signal.compare("encOutDisp", encOutDisp, encOutDispExp)
ret += Signal.compare("decOut", decOut, decOutExp)

print("burbel burbel - burbel burbel")

sys.exit(ret)
