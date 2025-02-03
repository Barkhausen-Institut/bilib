////    ////////////    Copyright (C) 2025 Mattis Hasler, Barkhausen Institut
////    ////////////    
////                    This source describes Open Hardware and is licensed under the
////                    CERN-OHL-W v2 (https://cern.ch/cern-ohl)
////////////    ////    
////////////    ////    
////    ////    ////    
////    ////    ////    
////////////            Authors:
////////////            Mattis Hasler (mattis.hasler@barkhauseninstitut.org)

`default_nettype none
package _8b10b;

localparam  PAIR10_WIDTH = 20;
localparam  SYMBOL10_WIDTH = 10;
localparam  PAIR_WIDTH = 18;
localparam  SYMBOL_WIDTH = 9;

typedef logic[9:0]  symbol10;   //8b10b encoded symbol - msb to be transmitted first
typedef logic[8:0]  symbol;     //{K, byte}
typedef logic[17:0] pair;       //two symbols - first symbol in high bits
typedef logic[19:0] pair10;     //two encoded symbols - first symbols in high bits

function automatic logic[7:0] SymbolData(symbol sym);
    SymbolData = sym[7:0];
endfunction

function automatic logic[15:0] PairData(pair p);
    PairData = {
        SymbolData(PairSymbol0(p)),
        SymbolData(PairSymbol1(p))
    };
endfunction

function automatic logic SymbolIsK(symbol sym);
    SymbolIsK = sym[8];
endfunction

function automatic pair PairFromData(logic [15:0] word);
    PairFromData = Pair(SymbolD(word[15:8]), SymbolD(word[7:0])); //more significant byte first
endfunction

function automatic symbol SymbolD(logic [7:0] byt);
    SymbolD = {1'b0, byt};
endfunction

function automatic symbol SymbolK(logic [7:0] byt);
    SymbolK = {1'b1, byt};
endfunction

function automatic symbol Symbol(logic [7:0] byt, logic isK);
    Symbol = {isK, byt};
endfunction

function automatic pair Pair(symbol first, symbol second);
    Pair = {first, second};
endfunction

function automatic symbol PairSymbol0(pair p);
    PairSymbol0 = p[17:9];
endfunction

function automatic symbol PairSymbol1(pair p);
    PairSymbol1 = p[8:0];
endfunction

function automatic pair10 Pair10(symbol10 first, symbol10 second);
    Pair10 = {first, second};
endfunction

function automatic symbol10 Pair10Symbol0(pair10 p);
    Pair10Symbol0 = p[19:10];
endfunction

function automatic symbol10 Pair10Symbol1(pair10 p);
    Pair10Symbol1 = p[9:0];
endfunction

function automatic symbol K(logic[4:0] five, logic[2:0] three);
    K = {1'b1, three[2:0], five[4:0]};
endfunction

function automatic symbol D(logic[4:0] five, logic[2:0] three);
    D = {1'b0, three[2:0], five[4:0]};
endfunction

endpackage