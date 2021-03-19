import cocotb
from cocotb_bus.bus import Bus
from cocotb.binary import BinaryValue
from cocotb.log import SimLog
import random
import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from cocotb.triggers import ClockCycles

from simple_val_rdy import SimpleValRdyBus, SimpleValRdyBusSource
from simple_val_rdy import SimpleValRdyBusSink
class SimplePadbytesFrame:
    def __init__(self, data=b'', last=0 ,padbytes=0, data_width=256,
            timestamp=None):
        if (data_width % 8) != 0:
            raise ValueError("data_width needs to be divisible by 8")

        self._data_w = data_width
        self._padbytes_w = self._data_w/8
        value = BinaryValue(n_bits=self._data_w)
        value.buff = data

        self.data = value
        self.last = last
        self.padbytes = padbytes
        self.timestamp = timestamp

    def __repr__(self):
        return (
        f"{type(self).__name__}(data={self.data.buff.hex()!r}, "
        f"last={self.last!r}, "
        f"padbytes={self.padbytes.integer!r})")

class SimplePadbytesBus(SimpleValRdyBus):
    _signalNames  = ["val", "data", "last", "padbytes", "rdy"]
    def __init__(self, entity, signals, data_width=256):
        self.data_width = data_width
        self.data_bytes = int(self.data_width/8)
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, signals, data_width)


class SimplePadbytesBusSource(SimpleValRdyBusSource):
    def __init__(self, bus, clk):
        self._bus = bus
        self._clk = clk
        self.data_width = self._bus.data.value.n_bits
        self.data_bytes = int(self.data_width/8)
        self.rand_gen = random.Random(3)
        super().__init__(bus, clk)

    def _fill_bus_data(self, req_values):
        self._bus.data.value = req_values.data
        self._bus.last.value = req_values.last
        self._bus.padbytes.value = req_values.padbytes

        if req_values.timestamp is not None:
            self._bus.timestamp.value = req_values.timestamp

    async def send_buf(self, buffer, timestamp=None, max_rand_delay=0):
        bytes_sent = 0
        while bytes_sent < len(buffer):
            input_frame = None
            bytes_left = len(buffer) - bytes_sent
            if (bytes_left <= self.data_bytes):
                data = buffer[bytes_sent:bytes_sent+bytes_left]
                input_frame = SimplePadbytesFrame(data=data,
                                              last=1,
                                              padbytes=self.data_bytes - bytes_left,
                                              timestamp=timestamp,
                                              data_width=self.data_width)
                await self.send_req(input_frame)
                bytes_sent += bytes_left
            else:
                data = buffer[bytes_sent:bytes_sent+self.data_bytes]
                input_frame = SimplePadbytesFrame(data=data,
                                              last=0,
                                              padbytes=0,
                                              timestamp=timestamp,
                                              data_width=self.data_width)
                await self.send_req(input_frame)
                bytes_sent += self.data_bytes

            # maybe add a random delay between frames
            delay = self.rand_gen.randint(0, max_rand_delay)
            if (delay != 0):
                await ClockCycles(self._clk, delay)

class SimplePadbytesBusSink(SimpleValRdyBusSink):
    def __init__(self, bus, clk):
        self._clk = clk
        self.rand_gen = random.Random(2)
        super().__init__(bus, clk)

    def _get_return_vals(self):
        timestamp = None
        if (hasattr(self._bus, "timestamp")):
            timestamp = self._bus.timestamp.value
        return_vals = SimplePadbytesFrame(data=bytes(self._bus.data.value.buff),
                                        last = self._bus.last.value,
                                        padbytes = self._bus.padbytes.value,
                                        timestamp = timestamp,
                                        data_width=self._bus.data_width)
        return return_vals

    async def recv_frame(self, max_rand_delay=0):
        recv_buf = bytearray([])
        while True:
            output_frame = await self.recv_resp()
#            cocotb.log.info("Receiving frame")
            good_bytes = 0
            if (output_frame.last == 1):
#                cocotb.log.info("Receiving last line")
                good_bytes = self._bus.data_bytes - output_frame.padbytes
                recv_buf.extend(output_frame.data.buff[0:good_bytes])
                break
            else:
                good_bytes = self._bus.data_bytes
                recv_buf.extend(output_frame.data.buff)

            # maybe add a random delay between frames
            delay = self.rand_gen.randint(0, max_rand_delay)
            if (delay != 0):
                await ClockCycles(self._clk, delay)
        return recv_buf
