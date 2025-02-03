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

from __future__ import annotations
from enum import Enum
import random
import re
from typing import Iterator
from bilib.fn import etype, ctype
from choc.pipe import PipeType

class TmeType(Enum):
    period = 0
    cycle = 1
    def toBytes(self) -> bytes:
        return self.value.to_bytes(1, 'big')
    
    def fromBytes(byt:bytes):
        return TmeType(int.from_bytes(byt[0:1], 'big'))

class Tme:
    REX_TIMESTR = r"^(\d+s)?(\d+m)?(\d+u)?(\d+n)?(\d+p)?(^\d+c)?$"
    E12 = 1_000_000_000_000
    period: int
    cycle: int
    def __init__(self, value:str|Tme|int=None, period:int=None, cycle:int=None, typ:TmeType=None):
        etype((value, (str,Tme,int,None)), (period, (int,None)), (cycle, (int,None)), (typ, (TmeType,None)))
        if value is not None:
            assert period is None and cycle is None, "cannot create Tme from value and period/cycle"
            if isinstance(value, str):
                assert typ is None, "cannot create Tme from string and TmeType"
                typ, val = Tme.parseStr(value)
                self.cycle = val if typ == TmeType.cycle else None
                self.period = val if typ == TmeType.period else None
            elif isinstance(value, Tme):
                assert typ is None, "cannot create Tme from Tme and TmeType"
                self.period = value.period
                self.cycle = value.cycle
            elif isinstance(value, int):
                assert typ is not None, "cannot create Tme from int without TmeType"
                self.period = value if typ == TmeType.period else None
                self.cycle = value if typ == TmeType.cycle else None
            else:
                raise Exception(f"parsing value to Tme failt {value} ({type(value)})")
        elif period is not None:
            self.period = period
            self.cycle = None
        elif cycle is not None:
            self.period = None
            self.cycle = cycle
        else:
            raise Exception("unable to create Tme from constructor params")
        assert self.period is None or self.cycle is None, "Tme cannot have both period and cycle"

    @classmethod
    def parseStr(cls, msg:str) -> tuple[TmeType,int]:
        m = re.match(cls.REX_TIMESTR, msg)
        if m is None:
            raise Exception("cannot parse time string")
        #cycle
        v = m.group(6)
        if v is not None:
            return (TmeType.cycle, int(v[:-1]))
        #period
        mask = 1000000000000
        value = None
        for v in m.groups()[:-1]:
            if v is not None:
                if value is None:
                    value = 0
                value += int(v[:-1]) * mask
            mask //= 1000
        return (TmeType.period, value)

    def __str__(self) -> str:
        active = False
        if self.cycle is not None:
            return f"{self.cycle}c"
        #period
        msg = ""
        if self.period < 0:
            msg += "-"
        if self.period is not None:
            #      s  m  u  n  p
            pico = abs(self.period)
            mask = 1000000000000
            for unit in ['s', 'm', 'u', 'n', 'p']:
                val = pico // mask
                if active:
                    msg += f"{val:03}{unit}"
                elif val != 0:
                    msg += f"{val}{unit}"
                    active = True
                pico %= mask
                mask //= 1000
        return msg

    def __repr__(self):
        return self.__str__()

    def toFreq(self) -> int:
        return self.E12 // self.period

    def toInt(self) -> int:
        if self.period is not None:
            return self.period
        if self.cycle is not None:
            return self.cycle

    @classmethod
    def fromFreq(cls, freq:int):
        return Tme(period=cls.E12 // freq)

    def comp(self, other:Tme) -> int:
        etype((other, Tme))
        if (self.period is None) != (other.period is None):
            raise Exception("cannot compare period to cycles")
        selfInt = self.toInt()
        otherInt = other.toInt()
        return -1 if selfInt < otherInt else 1 if selfInt > otherInt else 0

    def __lt__(self, other:Tme) -> bool:
        return self.comp(other) < 0 

    def __gt__(self, other:Tme) -> bool:
        return self.comp(other) > 0

    def __eq__(self, other:Tme) -> bool:
        return self.comp(other) == 0

    def __ge__(self, other:Tme) -> bool:
        return self.comp(other) >= 0

    def __le__(self, other:Tme) -> bool:
        return self.comp(other) <= 0 

    def __mul__(self, other:int|Tme|float) -> Tme:
        etype((other, (int,Tme,float)))
        if isinstance(other, (int, float)):
            return Tme(int(self.toInt() * other), typ=self.typ())
        elif isinstance(other, Tme):
            assert self.typ() != other.typ(), "can only multiply time with different types"
            return Tme(int(self) * int(other), typ=TmeType.period)
        else:
            raise Exception("Tme multiply parameter is wrong")

    def __rmul__(self, other:int) -> Tme:
        return self.__mul__(other)

    def _addsub(self, other:Tme|int, sub:bool) -> Tme:
        a = self.toInt()
        if isinstance(other, Tme):
            assert self.typ() == other.typ(), "Tme difference is only possible with the same typ"
            b = other.toInt()
        elif isinstance(other, int):
            b = other
        else:
            raise Exception("can only add int or Tme to Tme")
        v = a - b if sub else a + b
        return Tme(v, typ=self.typ())

    def __add__(self, other:Tme|int) -> Tme:
        return self._addsub(other, False)

    def __sub__(self, other:Tme|int) -> Tme:
        return self._addsub(other, True)

    def __truediv__(self, other:int|Tme) -> Tme:
        if isinstance(other, int):
            return Tme(self.toInt() // other, typ=self.typ())
        elif isinstance(other, Tme):
            assert self.typ() == TmeType.period and other.typ() == TmeType.period, "can only divide Tmes of type period"
            return Tme(self.toInt() // other.toInt(), typ=TmeType.cycle)
        else:
            raise Exception("Tme division went wrong")

    def toBytes(self) -> bytes:
        val = self.toInt()
        return val.to_bytes(8, 'big') + self.typ().toBytes()
    
    def nBytes(self) -> int:
        return 9
        
    def typ(self) -> TmeType:
        if self.cycle is None:
            return TmeType.period
        elif self.period is None:
            return TmeType.cycle
        else:
            raise Exception("cannot determine type of Tme")

    @classmethod
    def fromBytes(cls, byt:bytes):
        val = int.from_bytes(byt[0:8], 'big')
        typ = TmeType.fromBytes(byt[8:])
        return Tme(val, typ=typ)

    @classmethod
    def zero(cls, ref:TmeType|Tme=None) -> Tme:
        etype((ref, (TmeType,Tme,None)))
        if ref is None:
            typ = TmeType.period
        elif isinstance(ref, TmeType):
            typ = ref
        elif isinstance(ref, Tme):
            typ = ref.typ()
        else:
            raise Exception("cannot determine type of Tme")
        return Tme(0, typ=typ)

    @classmethod
    def metronom(cls, cycle:Tme, start:Tme=None, end:Tme=None) -> Iterator[Tme]:
        etype((cycle, Tme), (start, (Tme,None)), (end, (Tme,None)))
        if start is None:
            start = Tme.zero(cycle)
        curr = start
        while True:
            yield curr
            curr += cycle
            if end is not None and curr > end:
                break
        return

PSEC = Tme(period=1)
NSEC = Tme(period=1_000)
USEC = Tme(period=1_000_000)
MSEC = Tme(period=1_000_000_000)
SEC  = Tme(period=1_000_000_000_000)

KILO = 1000
MEGA = 1000 * KILO
GIGA = 1000 * MEGA

class Edge(Enum):
    neg = 0
    pos = 1
    any = 2

class L9(Enum):
    _0 = 0
    _1 = 1
    Z = 2
    highimpedance = 2
    X = 3
    L = 4
    weak0 = 4
    H = 5
    weak1 = 5
    Y = 6
    weakX = 6
    U = 0xa
    undefined = 0xa
    D = 0xe
    dontcare = 0xe

    def toChar(self) -> str:
        if self.name[0] == '_':
            return self.name[1:]
        else:
            return self.name

    def toVCD(self) -> str:
        return {
            L9._0: '0',
            L9._1: '1',
            L9.Z: 'Z',
            L9.X: 'X',
            L9.L: '0',
            L9.H: '1',
            L9.Y: 'X',
            L9.U: 'Z',
            L9.D: 'Z'
        }[self]

    def __int__(self):
        return self.value
    
    def toInt(self, force:bool=False) -> int:
        if self not in [self._1, self._0]:
            if force:
                return random.choice([0, 1])
            raise NotPureSignal(f"cannot convert L9:{self} to int")
        return int(self.value)

    @classmethod
    def fromChar(cls, name:str) -> L9:
        etype((name, str))
        if len(name) != 1:
            raise Exception("L9 fromChar must have string of length 1")
        for v in L9:
            if v.name == name or v.name == ("_" + name):
                return v
        raise Exception("cannot find L9 value")

class Bits:
    REX_STRPARSE = r"(\d+)'([hdob])([a-fA-F0-9xzhlyudXZHLYUD]+)"
    value: list[L9]
    def __init__(self, value:any, width:int=None):
        etype((width, (int,None)))
        if isinstance(value, Bits):
            assert width is None
            self.value = value.value
        elif isinstance(value, L9):
            assert isinstance(width, int)
            self.value = (value,) * width
        elif isinstance(value, (list, tuple)):
            assert width is None
            etype((value, (list, tuple), L9))
            self.value = tuple(value)
        elif isinstance(value, str):
            assert width is None
            self._strRead(value)
        elif isinstance(value, int):
            assert width is not None
            self._intRead(value, width)
        elif isinstance(value, bytes):
            self._binaryRead(value, width)
        else:
            raise Exception(f"cannot create Bits from given value of type:{type(value)}")

    def __hash__(self):
        return hash(self.value)

    def __len__(self) -> int:
        return len(self.value)

    def __getitem__(self, itm):
        if isinstance(itm, slice):
            return Bits(self.value[itm])
        else:
            return self.value[itm]
        
    #creates a Bits vector from binary data, creating one bit for each binary bit
    # using only the symbols 0 and 1
    # if width is given create a vector of that width, otherwise use the length of the binary data (byte precise)
    def _binaryRead(self, byt:bytes, width:int=None):
        etype((byt, bytes), width, (int,None))
        if width is None:
            width = len(byt) * 8
        lst = []
        for s in range(width):
            b = byt[(width // 8) - 1 - (s // 8)]
            lst.append(L9((b >> (s % 8)) & 1))
        self.value = tuple(lst)

    def _intRead(self, num:int, width:int):
        lst = []
        if width is None:
            raise Exception("creating bits from interger needs a width")
        for i in range(width):
            lst.append(L9((num >> i) & 1))
        self.value = tuple(lst)

    def _strRead(self, msg:str):
        m = re.match(self.REX_STRPARSE, msg)
        width = int(m.group(1))
        typ = m.group(2)
        base = {'h': 16, 'd': 10, 'o': 8, 'b': 2}[typ]
        raw = m.group(3).upper()
        #std integer convert
        try:
            num = int(raw, base)
        except ValueError:
            num = None
        if num is not None:
            lst = [L9((num >> i) & 1) for i in range(width)]
            self.value = tuple(lst)
        elif base == 2:
            last = 'X'
            lst = []
            for i in range(width):
                try:
                    last = raw[i]
                except IndexError:
                    pass
                lst.append(L9.fromChar(last))
            self.value = tuple(lst)
        else:
            raise Exception("cannot parse Bits")

    #create a Bits vector from serialization bytes (2bits per byte)
    @classmethod
    def fromBytes(self, raw:bytes) -> Bits:
        s = int.from_bytes(raw[0:2], 'big')
        lst = []
        for idx in range(s):
            byt = ((s - 1) // 2) - (idx // 2)
            b = raw[2+byt]
            lst.append(L9((b >> 4) if idx % 2 else (b & 0xf)))
        return Bits(lst)

    #serialize the Bits vector into bytes (2bits per byte)
    def toBytes(self) -> bytes:
        s = len(self.value)
        data = bytes()
        data += s.to_bytes(2, 'big')
        pack = [0] * (((s-1)//2)+1)
        for bit,val in enumerate(self.value):
            byt = ((s - 1) // 2) - (bit // 2) 
            pack[byt] |= (int(val) << 4) if bit % 2 else int(val)
        data += bytes(pack)
        #print(f"pack:{self.value} -> {data}")
        return data

    def toInt(self, force:bool=False) -> int:
        ret = 0
        for b in reversed(self.value):
            ret = (ret << 1) | b.toInt(force)
        return ret

    def toStr(self) -> str:
        msg = ""
        for b in reversed(self.value):
            msg += b.toChar()
        return msg

    def toBin(self) -> bytes:
        ret = bytes()
        curr = 0
        pos = 0
        for v in reversed(self.value):
            curr = (curr << 1) | (v & 0x1)
            pos += 1
            if pos == 8:
                ret += curr.to_bytes(1, 'big')
                pos = 0
        return ret

    def toVCD(self) -> str:
        msg = ""
        for b in reversed(self.value):
            msg += b.toVCD()
        return msg

    def __str__(self) -> str:
        return f"{len(self.value)}'b" + self.toStr()

    def __repr__(self) -> str:
        return f"Bits({self})"

    def __eq__(self, other:Bits) -> bool:
        return self.value == other.value

    def __len__(self) -> int:
        return len(self.value)

    #concat
    def __add__(self, other:Bits) -> Bits:
        etype((other, Bits))
        return Bits(self.value + other.value)

    def match(self, other:Bits) -> bool:
        etype((other, Bits))
        if len(self) != len(other):
            return False
        for l,r in zip(self.value, other.value):
            if l == r:
                continue
            if l is L9.dontcare or r is L9.dontcare:
                continue
            return False
        return True

class Change:
    value:any
    time:Tme
    sync:bool
    def __init__(self, value:any, time:Tme, sync:bool=True):
        etype((time,Tme), (sync,bool))
        self.value = value
        self.time = time
        self.sync = sync

    def __repr__(self):
        return f"Change({self.value}@{self.time}{'' if self.sync else 'a'})"

    def getTyp(self) -> PipeType:
        return PipeType(type(self.value), self.time.typ())

    def isType(self, typ:type, time:TmeType=TmeType.period) -> bool:
        etype((typ,type), (time,TmeType))
        return ctype((self.value, typ)) and self.time.typ() == time
    
    def __eq__(self, other:Change) -> bool:
        etype((other,Change))
        return self.value == other.value and self.time == other.time and self.sync == other.sync
    
    def shifted(self, time:Tme, relative:bool=True) -> Change:
        etype((time,Tme), (relative,bool))
        assert time.typ() == self.time.typ(), "cannot shift change to different time type"
        newTime = self.time + time if relative else time
        return Change(self.value, newTime, self.sync)
    
    def toBytes(self) -> bytes:
        return self.time.toBytes() \
            + int.to_bytes(self.sync, 1, 'big') \
            + self.value.toBytes()
    
    @classmethod
    def fromBytes(cls, byt:bytes, valType:type) -> Change:
        time = Tme.fromBytes(byt)
        sync = bool(byt[time.nBytes()])
        value = valType.fromBytes(byt[time.nBytes()+1:])
        return Change(value, time, sync)

#some bits are not 1 and/or 0, but contain for example X
class NotPureSignal(Exception):
    pass