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

import time
import unittest
from choc.items import BitsToInt, Clock, Input, IntToBits, Output, Printer, Range, Signal

import logging

from choc.types import Bits, Change, Tme, TmeType

class TestChoc(unittest.TestCase):
    def setUp(self):
        logging.basicConfig(level=logging.DEBUG)

    def test_choc(self):
        syn = Input("in")
        bnd = Output("out")
        syn >> bnd
        syn.feeds(range(100))
        lst = [bnd.consume() for _ in range(100)]
        self.assertListEqual(lst, list(range(100)))

    def test_int2bits(self):
        syn = Input("in")
        bnd = Output("out")
        syn >> IntToBits(16) >> BitsToInt() >> bnd
        syn.feeds(range(100))
        lst = [bnd.consume() for _ in range(100)]
        self.assertListEqual(lst, list(range(100)))

    def test_signal(self):
        out = Output("out")
        (Clock(Tme("5c")) | Range(10)) >> Signal() >> out
        for i in range(10):
            val = out.consume()
            self.assertEqual(val, Change(i, Tme(f"{i*5}c")))


class TestTme(unittest.TestCase):
    def setUp(self):
        logging.basicConfig(level=logging.DEBUG)

    def test_TmeType(self):
        self.assertEqual(TmeType.period.toBytes(), b'\x00')
        self.assertEqual(TmeType.cycle.toBytes(), b'\x01')
        self.assertEqual(TmeType.period, TmeType.fromBytes(b'\x00'))
        self.assertEqual(TmeType.cycle, TmeType.fromBytes(b'\x01'))
        self.assertEqual(TmeType.period, TmeType.fromBytes(b'\x00\x01'))
        self.assertEqual(TmeType.cycle, TmeType.fromBytes(b'\x01\x00'))

    def test_bytes(self):
        self.assertEqual(Tme("123c").toBytes(), b'\x00\x00\x00\x00\x00\x00\x00\x7b\x01')
        self.assertEqual(Tme("123c"), Tme.fromBytes(b'\x00\x00\x00\x00\x00\x00\x00\x7b\x01'))
        self.assertEqual(Tme("123n").toBytes(), b'\x00\x00\x00\x00\x00\x01\xe0x\x00')
        self.assertEqual(Tme("123n"), Tme.fromBytes(b'\x00\x00\x00\x00\x00\x01\xe0x\x00'))

