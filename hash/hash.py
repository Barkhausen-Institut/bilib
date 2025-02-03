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

from crccheck.crc import Crc, Crc8Base

def crc(data:bytes, polywidth:int=8, poly:int=0x7) -> bytes:
    assert polywidth % 8 == 0
    polylength = polywidth // 8
    raw = data[:-polylength]
    crc = Crc(polywidth, poly)
    sum = crc.calc(raw).to_bytes(polylength, 'big')
    return raw + sum
