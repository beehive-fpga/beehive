import cocotb
from cocotb_bus.bus import Bus
from cocotb.binary import BinaryValue
import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from simple_val_rdy import SimpleValRdyBusSource, SimpleValRdyBus, SimpleValRdyBusSink

class GenericValRdyBus(SimpleValRdyBus):
    _signalNames = ["val", "rdy"]
    def __init__(self, entity, signals):
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        self.data_signal_names = []

        for signal in signals:
            if not signal in self._signalNames:
                self.data_signal_names.append(signal)

        super().__init__(entity, signals)


class GenericValRdySource(SimpleValRdyBusSource):
    def __init__(self, bus, clk):
        self._bus = bus
        self._clk = clk
        super().__init__(bus, clk)

    def _fill_bus_data(self, req_values):
        for name in self._bus.data_signal_names:
            if not name in req_values:
                raise AttributeError(f"req_values doesn't contain a value for "
                        f"key {name}")
            signal_handle = getattr(self._bus, name)
            signal_handle.value = req_values[name]

    async def send_buf(self, req_buf):
        raise NotImplementedError()

class GenericValRdySink(SimpleValRdyBusSink):
    def __init__(self, bus, clk):
        self._bus = bus
        self._clk = clk

        super().__init__(bus, clk)

    def _get_return_vals(self):
        return_vals = {}
        for name in self._bus.data_signal_names:
            signal_handle = getattr(self._bus, name)
            return_vals[name] = signal_handle.value

        return return_vals

    async def recv_frame(self, max_rand_delay=0):
        raise NotImplementedError()
