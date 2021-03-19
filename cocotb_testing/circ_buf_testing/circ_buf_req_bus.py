from cocotb_bus.bus import Bus
from cocotb.binary import BinaryValue
import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from simple_val_rdy import SimpleValRdyBusSource
class CircBufReqFrame:
    def __init__(self, flowid, offset, size):
        self.flowid = flowid
        self.offset = offset
        self.size = size

    def __repr__(self):
        return f"flowid={self.flowid}, offset={self.offset}, size={self.size}"

class CircBufReqBus(Bus):
    _signalNames = ["val", "rdy", "flowid", "offset", "size"]

    def __init__(self, entity, signals):
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, "", signals, case_insensitive=False)

class CircBufReqBusSource(SimpleValRdyBusSource):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)

    def _fill_bus_data(self, req_values):
        self._bus.flowid.value = req_values.flowid
        self._bus.offset.value = req_values.offset
        self._bus.size.value = req_values.size

    async def send_buf(self, req_buf):
        raise NotImplementedError()
