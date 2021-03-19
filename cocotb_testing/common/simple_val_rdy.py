from cocotb.utils import get_sim_time
from cocotb_bus.bus import Bus

from cocotb.binary import BinaryValue
from cocotb.triggers import Timer, RisingEdge, ReadOnly
import random

"""
    A convenience class for setting the data signals on a the val-rdy bus
"""
class SimpleValRdyFrame:
    def __init__(self, data=b'', data_width=256):
        if (data_width % 8) != 0:
            raise ValueError("data_width needs to be divisible by 8")

        self._data_w = data_width
        value = BinaryValue(n_bits=self._data_w)
        value.buff = data
        self.data = value

    def __repr__(self):
        return f"data={self.data.buff.hex()}"

"""
    A wrapper for a bus to be used with a val-rdy bus

    entity: whatever Bus expects. Probably your dut

    signals: a dictionary mapping signalNames to signal objects. You must have
    all the signals defined in _signalNames
"""

class SimpleValRdyBus(Bus):
    _signalNames = ["val", "rdy"]

    def __init__(self, entity, signals, data_width=256):
        self.data_width = data_width
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, "", signals, case_insensitive=False)

"""
    A class for using a SimpleValRdyBus object

    bus: a SimpleValRdyBus object
    clk: the clock of the domain the bus is in
"""
class SimpleValRdyBusOperator():
    def __init__(self, bus, clk):
        self._bus = bus
        self._clk = clk

class SimpleValRdyBusSource(SimpleValRdyBusOperator):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)

    def _fill_bus_data(self, req_values):
        self._bus.data.value = req_values.data

    """
    Send a request on the object's bus. Takes care of the val-rdy handshake

    req_values: a SimpleValRdyFrame object representing the values on the bus
    """
    async def send_req(self, req_values):
        self._bus.val.value = 1
        self._fill_bus_data(req_values)
        while True:
            await ReadOnly()
            time = get_sim_time(units="ns")
            if (self._bus.rdy.value == 1):
                break
            await RisingEdge(self._clk)
        await RisingEdge(self._clk)

        time = get_sim_time(units="ns")
        self._bus.val.value = 0

    async def send_buf(self, req_buf):
        bytes_sent = 0
        bus_bytes = int(self._bus.data_width/8)
        while bytes_sent < len(req_buf):
            input_frame = None
            bytes_left = len(req_buf) - bytes_sent
            if (bytes_left <= bus_bytes):
                data = req_buf[bytes_sent:bytes_sent+bytes_left]
                if (bytes_left != bus_bytes):
                    num_pad_bytes = bus_bytes - bytes_left
                    padding = bytearray([0] * num_pad_bytes)
                    data.extend(padding)

                input_frame = SimpleValRdyFrame(data=data,
                        data_width=self._bus.data_width)
                await self.send_req(input_frame)
                bytes_sent += bytes_left
            else:
                data = req_buf[bytes_sent:bytes_sent + bus_bytes]
                input_frame = SimpleValRdyFrame(data=data,
                        data_width=self._bus.data_width)

                await self.send_req(input_frame)
                bytes_sent += bus_bytes



"""
    A class for receiving responses on a val-rdy bus.

    bus: a BeehiveBus object
    clk: the clock of the domain the bus is in
"""
class SimpleValRdyBusSink(SimpleValRdyBusOperator):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)

    def _get_return_vals(self):
        return_vals = SimpleValRdyFrame(data = bytes(self._bus.data.value.buff),
                data_width = self._bus.data_width)

        return return_vals

    """
    Receive a request on the object's bus. Takes care of the val-rdy handshake,
    although still be careful about when you use this.

    Returns: a SimpleValRdyFrame object representing the values on the bus
    """
    async def recv_resp(self, max_rand_delay=0):
        delay = random.randint(0, max_rand_delay)
        if (delay != 0):
            await ReadOnly()
            if self._bus.val.value == 0:
                await RisingEdge(self._bus.val)

            await ClockCycles(self._clk, delay)

        self._bus.rdy.value = 1
        await ReadOnly()
        while self._bus.val.value == 0:
            await RisingEdge(self._clk)
            await ReadOnly()

        return_vals = self._get_return_vals()
        await RisingEdge(self._clk)
        self._bus.rdy.value = 0
        return return_vals


