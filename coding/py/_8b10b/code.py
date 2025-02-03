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

#D.X: EDCBA -> abcdei
Dfivesix = {
    0b00000:    (0b100111, 0b011000),
    0b00001:    (0b011101, 0b100010),
    0b00010:    (0b101101, 0b010010),
    0b00011:    0b110001,
    0b00100:    (0b110101, 0b001010),
    0b00101:    0b101001,
    0b00110:    0b011001,
    0b00111:    (0b111000, 0b000111),
    0b01000:    (0b111001, 0b000110),
    0b01001:    0b100101,
    0b01010:    0b010101,
    0b01011:    0b110100,
    0b01100:    0b001101,
    0b01101:    0b101100,
    0b01110:    0b011100,
    0b01111:    (0b010111, 0b101000),
    0b10000:    (0b011011, 0b100100),
    0b10001:    0b100011, 
    0b10010:    0b010011, 
    0b10011:    0b110010, 
    0b10100:    0b001011, 
    0b10101:    0b101010, 
    0b10110:    0b011010, 
    0b10111:    (0b111010, 0b000101),
    0b11000:    (0b110011, 0b001100),
    0b11001:    0b100110, 
    0b11010:    0b010110, 
    0b11011:    (0b110110, 0b001001),
    0b11100:    0b001110, 
    0b11101:    (0b101110, 0b010001),
    0b11110:    (0b011110, 0b100001),
    0b11111:    (0b101011, 0b010100)
}

#K.X: EDCBA -> abcdei
Kfivesix = {
    0b10111:    (0b111010, 0b000101),
    0b11011:    (0b110110, 0b001001),
    0b11100:    (0b001111, 0b110000),
    0b11101:    (0b101110, 0b010001),
    0b11110:    (0b011110, 0b100001)
}

#D.?.X: HGF -> fghj
Dthreefour = {
    0b000:  (0b1011, 0b0100),
    0b001:  0b1001,    
    0b010:  0b0101,    
    0b011:  (0b1100, 0b0011),
    0b100:  (0b1101, 0b0010),
    0b101:  0b1010,    
    0b110:  0b0110,    
    0b111:  (0b1110, 0b0001),
    0xf:    (0b0111, 0b1000) #D.x.A7
}

#K.?.X: HGF -> fghj
Kthreefour = {
    0b000:  (0b1011, 0b0100),
    0b001:  (0b0110, 0b1001),
    0b010:  (0b1010, 0b0101),
    0b011:  (0b1100, 0b0011),
    0b100:  (0b1101, 0b0010),
    0b101:  (0b0101, 0b1010),
    0b110:  (0b1001, 0b0110),
    0b111:  (0b0111, 0b1000)
}

DxA7 = [
    (-1,17),
    (-1,18),
    (-1,20),
    ( 1,11),
    ( 1,13),
    ( 1,14)
]

Ks = [0x1c, 0x3c, 0x5c, 0x7c, 0x9c, 0xbc, 0xdc, 0xfc, 0xf7, 0xfb, 0xfd, 0xfe]

def disparity(num:int, len:int):
    count = 0
    sr = num
    while sr != 0:
        if sr & 1:
            count += 1
        sr //= 2
    d = count - (len - count)
    assert(d in [-2, 0, 2])
    return d

#KHGFEDCBA -> abcdeifghj
def enc8b10b(raw:int, RD:int) -> tuple[int, int]:
    assert(raw >= 0 and raw <= 0x1ff)
    assert(RD in [-1, 1])
    isK = (raw >> 8) & 1
    if isK and (raw & 0xff) not in Ks:
        raise Exception(f"bad K word:{raw & 0xff:#x}")
    five = (raw) & 0x1f
    three = (raw >> 5) & 0x7
    fivesix = Kfivesix if isK else Dfivesix
    threefour = Kthreefour if isK else Dthreefour
    try:
        sixs = fivesix[five]
        if not isK and three == 0b111 and (RD, five) in DxA7:
            three = 0xf #hack to reach D.x.A7
        fours = threefour[three]
    except KeyError:
        raise Exception("bad word")
    six = sixs[1 if RD == 1 else 0] if isinstance(sixs, tuple) else sixs
    ND0 = RD + disparity(six, 6)
    four = fours[1 if ND0 == 1 else 0] if isinstance(fours, tuple) else fours
    ten = (six << 4) | four
    ND1 = ND0 + disparity(four, 4)
    return ND1, ten

#abcdeifghj -> KHGFEDCBA
def dec8b10b(enc:int) -> int:
    for RD in [-1, 1]:
        for raw in range(0x1ff):
            try:
                tst = enc8b10b(raw, RD)
                if tst[1] == enc:
                    return raw
            except Exception:
                pass
    return None

