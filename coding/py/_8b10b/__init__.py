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

from SiCo.fn import TimeOut
from SiCo.types import Bits, Signal, Change, L9, Tme
from . import code
import logging

#makes a signal of 10 bit words from a serial (1bit) signal
class Deserialize(Signal):
    KOMMA = Bits("8'b00111110")
    KOMMA_N = Bits("8'b11000001")

    def __init__(self, sig:Signal):
        self.sig = sig
        self.buffer = []
        self.counter = 0
        self.aligned = False

    def next(self, timeout:float=None) -> Change:
        tout = TimeOut(timeout)
        while not tout():
            chg = self._parse(tout.remaining())
            if chg:
                return chg

    def width(self) -> int:
        return 20
    
    def _parse(self, timeout:float=None):
        chg = self.sig.next(timeout)
        #looking for komma
        self.buffer = [chg.value[0]] + self.buffer[0:19]
        if not self.aligned:
            curr = Bits(self.buffer[0:8])
            if curr == self.KOMMA or curr == self.KOMMA_N:
                self.aligned = True
                self.counter = 8
        else: #aligned
            self.counter += 1
            if self.counter == 20:
                self.counter = 0
                return Change(self.buffer, time=chg.time)
        return None

class Serialize(Signal):
    def __init__(self, sig:Signal):
        self.sig = sig
        self.bits = None
        self.pos = 0
        self.clock = Tme("0c")
        assert sig.width() == 20, "Serializer needs a 20bit signal"
    
    def next(self, timeout:float=1.0):
        log = logging.getLogger("8b10b")
        self.pos -= 1
        if self.pos < 0:
            self.bits = self.sig.next(timeout)
            self.pos = 19
        self.clock += 1
        return Change(self.bits[self.pos], width=1, time=self.clock)

    def width(self) -> int:
        return 1

class Decode(Signal):
    def __init__(self, sig:Signal):
        self.sig = sig
        assert sig.width() == 20, "8b10b decoder input must be 20bit"
    
    def next(self, timeout:float=None) -> Change:
        chg = self.sig.next(timeout)
        val1 = code.dec8b10b(chg[10:20].int())
        val2 = code.dec8b10b(chg[0:10].int())
        log = logging.getLogger("8b10b")
        bts1 = Bits([L9.X] * 9 if val1 is None else val1, width=9)
        bts2 = Bits([L9.X] * 9 if val2 is None else val2, width=9)
        wrd = Change(bts2 + bts1, time=chg.time)
        log.debug(f"{chg} -> {wrd}_{dkStr(bts1)},{dkStr(bts2)}")
        return wrd

    def width(self):
        return 18

class Encode(Signal):
    def __init__(self, sig:Signal):
        self.sig = sig
        self.rd = -1 #running disparity
        assert sig.width() == 18, "8b10b encoder input must be 18bit (pair)"

    def next(self, timeout:float=None) -> Change:
        log = logging.getLogger("8b10b")
        chg = self.sig.next(timeout)
        bts = Bits(chg)
        rd, val1 = code.enc8b10b(bts[9:18].int(), self.rd)
        self.rd, val2 = code.enc8b10b(bts[0:9].int(), rd)
        sym1 = Bits(val1, width=10)
        sym2 = Bits(val2, width=10)
        wrd = Change(sym2 + sym1, time=chg.time)
        log.debug(f"{dkStr(bts[9:18])},{dkStr(bts[0:9])} -> {wrd}")
        return wrd

    def width(self) -> int:
        return 20

def dataSymbol(data:int) -> Bits:
    return Bits(data, width=8) + Bits(0, width=1)

def symbolData(symbol:Bits) -> int:
    assert(symbol[8:9].int() == 0), f"this is not a data symbol:{dkStr(symbol)}"
    return symbol[0:8].int()

def D(five:int, three:int) -> Bits:
    return Bits(five, width=5) + Bits(three, width=3) + Bits(0, width=1)

def K(five:int, three:int) -> Bits:
    return Bits(five, width=5) + Bits(three, width=3) + Bits(1, width=1)

def dkStr(symbol:Bits) -> str:
    bK, bThree, bFive = symbol[8:9], symbol[5:8], symbol[0:5]
    k, three, five = bK.int(), bThree.int(), bFive.int()
    return f"{'K' if k else 'D'}({five},{three})"
