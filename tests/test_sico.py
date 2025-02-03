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

import unittest
from roadrunner.run import UnitTestRunner

import logging

class TestSico(unittest.TestCase):
    def setUp(self):
        logging.basicConfig(level=logging.DEBUG)
    
    def test_channel(self):
        with UnitTestRunner() as utr:
            ret = utr.main(["sico.test.chan"])
            self.assertEqual(ret, 0)

    def test_hold(self):
        with UnitTestRunner() as utr:
            ret = utr.main(["sico.test.hold"])
            self.assertEqual(ret, 0)

    def test_finish(self):
        with UnitTestRunner() as utr:
            ret = utr.main(["sico.test.finish"])
            self.assertEqual(ret, 0)

    def test_wrongValue(self):
        with UnitTestRunner() as utr:
            ret = utr.main(["sico.test.wrongValue"])
            self.assertEqual(ret, 0)
            fh = open(utr.tmp / "rrun/sico.test.wrongValue/0sim/vvp.stdout")
            msg = "SiCo @               \x1b[31mERROR\x1b[0m loop:  player received new change of wrong time type:cycled\n"
            self.assertRegexpMatches
            self.assertIn(msg, fh.readlines())


