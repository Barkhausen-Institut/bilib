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

import atexit
import sys


class Errors:
    def __init__(self, goodMessage="TESTCASE PASSED", badMessage="TESTCASE FAILED"):
        self.good = goodMessage
        self.bad = badMessage
        self.msgs = []
        self.goodCounter = 0
        self.badCounter = 0
        self.code = 0
        atexit.register(self.report)

    def fail(self, msg=None, code=1):
        self.code |= code
        if msg is not None:
            self.msgs.append(msg)
            print(f"FAIL {msg}")
        self.badCounter += 1

    def success(self, msg=None):
        if msg is not None:
            self.msgs.append(msg)
            print(f"SUCC {msg}")
        self.goodCounter += 1

    def checkVal(self, meas, expe, desc):
        self.check(meas == expe, f"{meas} - {desc}", f"{meas} is not {expe} - {desc}")

    def checkValX(self, meas, expe, desc):
        if meas is None:
            self.check(meas == expe, f"{meas} - {desc}", f"{meas} is not {expe:#x} - {desc}")    
        self.check(meas == expe, f"{meas:#x} - {desc}", f"{meas:#x} is not {expe:#x} - {desc}")

    def check(self, condition, goodMsg, basMsg):
        if condition:
            self.success(goodMsg)
        else:
            self.fail(basMsg)

    def report(self):
        if self.goodCounter == 0:
            self.fail("no tests passed")
        print(f"---- Result:{self.code} ----")
        print(f"Tests - good:{self.goodCounter} bad:{self.badCounter}")
        if len(self.msgs):
            print(f"Messages:")
        for msg in self.msgs:
            print(msg)
        if self.code == 0:
            print(self.good)
        else:
            print(self.bad)
    
    def exit(self):
        sys.exit(self.code)