import cocotb
from cocotb_bus.bus import Bus

from cocotb.binary import BinaryValue
from cocotb.triggers import Timer, RisingEdge, ReadOnly, ClockCycles
# This class is for a bus that uses a simple val-ready handshake with a 
# keep mask

"""
    A convenience class for setting the data signals on a the bus
"""
class SimpleKeepBusFrame:
    def __init__(self, data=b'', last=0, keep="", data_width=512):
        if (data_width % 8) != 0:
            raise ValueError("data_width needs to be divisible by 8")

        self._data_w = data_width
        self._keep_w = int(self._data_w/8)
        value = BinaryValue(n_bits=self._data_w)
        value.buff = data

        keep_mask = BinaryValue(n_bits=self._keep_w)
        keep_mask.binstr = keep

        self.data = value
        self.last = last
        self.keep = keep_mask

    def __repr__(self):
        return (
        f"{type(self).__name__}(data={self.data.buff.hex()!r}, "
        f"last={self.last!r}, "
        f"keep={self.keep_mask.binstr!r})")

"""
    A wrapper for a bus to be used with a simple val-ready keep bus

    entity: whatever Bus expects. Probably your dut

    signals: a dictionary mapping signalNames to signal objects. You must have
    all the signals defined in _signalNames
"""
class SimpleKeepBus(Bus):
    _signalNames = ["val", "data", "last", "keep", "rdy"]
    def __init__(self, entity, signals, data_width=512):
        self.data_width = data_width
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, "", signals, case_insensitive=False)

"""
    A class for using a SimpleKeepBus object

    bus: a SimpleKeepBus object
    clk: the clock of the domain the bus is in
"""
class SimpleKeepBusOperator():
    def __init__(self, bus, clk):
        self._bus = bus
        self._clk = clk
        self.data_width = self._bus.data.value.n_bits
        self.data_bytes = int(self.data_width/8)

"""
    A class for sending requests on a SimpleKeep bus.

    bus: a SimpleKeepBus object
    clk: the clock of the domain the bus is in
"""
class SimpleKeepBusSource(SimpleKeepBusOperator):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)

    """
    Send a request on the object's bus. Takes care of the val-rdy handshake

    req_values: a SimpleKeepBusFrame object representing the values on the bus
    """
    async def send_req(self, req_values):
        self._bus.val.value = 1
        self._bus.data.value = BinaryValue(value=req_values.data.binstr,
                n_bits=self._bus.data_width)
        self._bus.last.value = req_values.last
        self._bus.keep.value = req_values.keep

        while True:
            await ReadOnly()
            if (self._bus.rdy.value == 1):
                break
            await RisingEdge(self._clk)
        await RisingEdge(self._clk)

        self._bus.val.value = 0

    async def xmit_frame(self, test_packet_bytes, pause_len=0, flip_data=True):
        bytes_sent = 0
        test_packet_bytearray = bytearray(test_packet_bytes)

        while bytes_sent < len(test_packet_bytearray):
            input_frame = None
            bytes_left = len(test_packet_bytearray) - bytes_sent

            if (bytes_left <= self.data_bytes):
                data = test_packet_bytearray[bytes_sent:bytes_sent+bytes_left]
                useless_bytes = (0 if bytes_left == self.data_bytes
                                else self.data_bytes - bytes_left)
                padding_bytes = bytearray([0] * useless_bytes)
                data.extend(padding_bytes)
                data_rev = data[::-1]

                keep_mask = ("1" * bytes_left) + ("0" * useless_bytes)
                keep_mask_rev = keep_mask[::-1]

                if flip_data:
                    input_frame = SimpleKeepBusFrame(data=data_rev,
                                                 keep=keep_mask_rev,
                                                 last=1, data_width=self.data_width)
                else:
                    input_frame = SimpleKeepBusFrame(data=data,
                                                 keep=keep_mask,
                                                 last=1, data_width=self.data_width)

                await self.send_req(input_frame)
                bytes_sent += bytes_left
            else:
                data = test_packet_bytearray[bytes_sent:bytes_sent+self.data_bytes]
                data_rev = data[::-1]
                if flip_data:
                    input_frame = SimpleKeepBusFrame(data=data_rev,
                                                 keep = "1" * self.data_bytes,
                                                 last = 0, data_width=self.data_width)
                else:
                    input_frame = SimpleKeepBusFrame(data=data,
                                                 keep = "1" * self.data_bytes,
                                                 last = 0, data_width=self.data_width)

                await self.send_req(input_frame)
                if (pause_len != 0):
                   await ClockCycles(tb.dut.clk, pause_len)
                bytes_sent += self.data_bytes

"""
    A class for receiving responses on a SimpleKeep bus

    bus: a SimpleKeepBus object
    clk: the clock of the domain the bus is in
"""
class SimpleKeepBusSink(SimpleKeepBusOperator):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)

    """
    Receive a request on the object's bus. Takes care of the val-rdy handshake

    Returns: a SimpleKeepBusFrame object representing the values on the bus
    """
    async def recv_resp(self, pause_len=0):
        if pause_len == 0:
            self._bus.rdy.value = 1
            await ReadOnly()
            if self._bus.val.value == 0:
                await RisingEdge(self._bus.val)

            await ReadOnly()
            return_vals = SimpleKeepBusFrame(data = self._bus.data.value.buff,
                                         last = self._bus.last.value,
                                         keep = self._bus.keep.value.binstr,
                                         data_width = self._bus.data_width)
        else:
            await ReadOnly()
            if self._bus.val.value == 0:
                await RisingEdge(self._bus.val)

            await ClockCycles(self._clk, pause_len)
            self._bus.rdy.value = 1

            await ReadOnly()
            return_vals = SimpleKeepBusFrame(data = self._bus.data.value.buff,
                                         last = self._bus.last.value,
                                         keep = self._bus.keep.value.binstr,
                                         data_width = self._bus.data_width)

        await RisingEdge(self._clk)
        self._bus.rdy.value = 0
        return return_vals


    async def recv_frame(self, pause_len=0, flip_data=True):
        recv_buf = bytearray([])
        while True:
            output_frame = await self.recv_resp(pause_len=pause_len)

            if (output_frame.last == 1):
                num_good_bytes = output_frame.keep.binstr.count("1")
                extend_buf = []

                if flip_data:
                    frame_rev = output_frame.data.buff[::-1]
                    extend_buf = frame_rev[0:num_good_bytes]
                else:
                    extend_buf = output_frame.data.buff[0:num_good_bytes]

                recv_buf.extend(extend_buf)
                break
            else:
                extend_buf = []
                if flip_data:
                    extend_buf = output_frame.data.buff[::-1]
                else:
                    extend_buf = output_frame.data.buff

                recv_buf.extend(extend_buf)

        return recv_buf

