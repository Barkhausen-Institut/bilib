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

def prng(bits:int=16, len:int=None):
    v = 0x14d5ba65
    l = 0 
    while True:
        v = ((v << 1) & 0x1ffffffff) | ((v >> 32) ^ ((v >> 13) & 0x1))
        yield v & (0xffffffff >> (32 - bits))
        l += 1
        if len is not None and l >= len:
            break
    return
