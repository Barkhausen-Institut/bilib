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

class TestMemory(unittest.TestCase):
    def setUp(self):
        logging.basicConfig(level=logging.DEBUG)
    
    def test_access(self):
        with UnitTestRunner() as utr:
            ret = utr.main(["memory.test.testAccess"])
            self.assertEqual(ret, 0)

    def test_memory(self):
        with UnitTestRunner() as utr:
            ret = utr.main(["memory.test.testMemory"])
            self.assertEqual(ret, 0)

