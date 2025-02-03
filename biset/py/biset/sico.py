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

from bilib.fn import etype
from biset import BiSetRequest
from biset.access import BiSetBitsTrafo
from choc.items import ClockedSignal, SignalInterface
from choc.pipe import InPort, Item
from sico.comm import Channel, Control


# -> BiSetRequest
class BiSetSiCoDriver(Item):
    def __init__(self, ctrl:Control, channel:str="biset", name:str="BiSetDriver"):
        etype((ctrl, Control), (channel, str), (name, str))
        super().__init__(name)
        chan = Channel(ctrl, channel)
        trafo = BiSetBitsTrafo(f"{name}Trafo")
        trafo << InPort(self.itemAddReceiver("req", BiSetRequest), f"{name}In")
        chan << ClockedSignal(f"{name}Sig") << trafo
        chan >> SignalInterface(f"{name}Desig") >> trafo
