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
import re

#checks if the type of a variable is correct
# takes tuples of (varibale, types, [[keyTypes], valTypes])
# types can be a tuple of types that are allowed and also None
# if a variable is list, tuple or set the values are checked against the valTypes
# same with dicts and keyTypes and valTypes
def etype(*args) -> bool:
    for tup in args:
        #break up tuple
        if len(tup) == 2:
            var,varTup = tup
            keyTup, valTup = None, None
        elif len(tup) == 3:
            var,varTup,valTup = tup
            keyTup = None
        elif len(tup) == 4:
            var,varTup,keyTup,valTup = tup
        else:
            raise ValueError(f"wrong number of arguments:{len(tup)}")
        ##### make sets
        def makeSet(tup):
            if tup is None:
                return None, False
            if not isinstance(tup, tuple):
                return (tuple(), True) if tup is None else ((tup,), False)
            return tuple(filter(lambda x: x is not None, tup)), None in tup
        varTypes, varNone = makeSet(varTup)
        keyTypes, keyNone = makeSet(keyTup)
        valTypes, valNone = makeSet(valTup)
        #check
        def check(var, types, none):
            if none and var is None:
                return
            if types is None or isinstance(var, types):
                return 
            raise TypeError(f"wrong type:{type(var)} != {types}")
        check(var, varTypes, varNone)
        #check iteratables
        if isinstance(var, (list, tuple, set)) and valTypes is not None:
            for val in var:
                check(val, valTypes, valNone)
        if isinstance(var, dict):
            for key,val in var.items():
                check(key, keyTypes, keyNone)
                check(val, valTypes, valNone)
    return True

def ctype(*args):
    try:
        return etype(*args)
    except TypeError:
        return False

class Interval():
    def __init__(self, b1:int=0, b2:int=None, size:int=1):
        if b2 is None:
            self.low = b1
            self.hi = b1 + size - 1
        else:
            self.low = min(b1, b2)
            self.hi = max(b1, b2)
    
    def __len__(self):
        return self.hi - self.low + 1
    
    def __str__(self) -> str:
        return f"Iv({self.low},{self.hi})"
    
    def hex(self) -> str:
        return f"Iv({self.low:#x},{self.hi:#x})"
    
    def overlap(self, other:Interval) -> Interval:
        low = max(self.low, other.low)
        hi = min(self.hi, other.hi)
        if low >= hi:
            return None
        return Interval(low, hi)
    
    def contains(self, val:int) -> bool:
        return val >= self.low and val <= self.hi

def mkmask(itvl:Interval):
    ret = 0
    for _ in range(len(itvl)):
        ret = (ret << 1) | 1
    return ret << itvl.low

def mkList(val):
    return val if isinstance(val, (list, tuple)) else [val]

def bitsel(var:int, itvl:Interval):
    return (var & mkmask(itvl)) >> itvl.low

#remove bits from var
def bitmask(var:int, mask:int):
    return var ^ (var & mask)

class Packer:
    def __init__(self, data:int=0):
        self.val = data
        self.pos = 0
    def add(self, data:int, size:int):
        self.val |= (data & mkmask(Interval(size=size))) << self.pos
        self.pos += size
    def get(self, size):
        ret = (self.val >> self.pos) & mkmask(Interval(size=size))
        self.pos += size
        return ret

uniqueNameStore = {}
def uniqueName(base:str) -> str:
    etype((base, str))
    if re.match(r'^.*[^\d]\d+$', base):
        base += "_"
    if base not in uniqueNameStore:
        uniqueNameStore[base] = 0
    n = uniqueNameStore[base] + 1
    uniqueNameStore[base] = n
    return base if n == 1 else f"{base}{n}"

