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
from SiCo.signal import SignalBuffer, Recorder, Cut, Player
from SiCo.types import Change, Tme, Edge, Bits
from SiCo.tools import Dumper
import hash

conn = sico.comm.Connection()
ctrl = sico.comm.Control(conn)

data = (0xdeadaffedeadaffedeadaffedeadaffe00).to_bytes(17, 'big')
hashed = hash.crc(data)
exp = Bits(hashed)

inputData = SignalBuffer([
    Change(data, time=Tme(0)),
    Change("136'bd@10000")
])
inputEnable = SignalBuffer([
    Change("1'b0"),
    Change("1'b1@250"),
    Change("1'b0@251"),
    Change("1'bd@10000")
])

inDataStream = Recorder(sico.comm.Channel(ctrl, "in"))
inDataValid = Recorder(sico.comm.Channel(ctrl, "inValid"))

inDataStream.stream(inputData)
inDataValid.stream(inputEnable)

try:
    busy = SignalBuffer(Player(sico.comm.Channel(ctrl, "busy"), 1))
    out = SignalBuffer(Player(sico.comm.Channel(ctrl, "out"), 136))
    valid = SignalBuffer(Player(sico.comm.Channel(ctrl, "valid"), 1))

except KeyboardInterrupt:
    print("keyboard --")

dump = Dumper()
dump.addSignal("dut", "busy", busy)
dump.addSignal("dut", "out", out)
dump.addSignal("dut", "valid", valid)
dump.writeVCD("tb.vcd")

error = 0

edge = valid.find(Edge.pos, start=Tme(100))
print(f"found posedge @{edge}")
bits = out.get(edge)
if bits != exp:
    print(f"bits:{bits} != exp:{exp}")
    error += 1


ctrl.simExit()

print("done")

exit(error)
