import cocotb
from cocotb_bus.bus import Bus

from cocotb.binary import BinaryValue
from cocotb.triggers import Timer, RisingEdge, ReadOnly, ClockCycles
from abc import ABCMeta, abstractmethod

from random import Random

"""
    A convenience class for setting the data signals on a Beehive bus
"""
class BeehiveBusFrame:
    def __init__(self, data=b'', startframe=0, frame_size=0,
                    endframe=0 ,padbytes=0, data_width=256):
        if (data_width % 8) != 0:
            raise ValueError("data_width needs to be divisible by 8")

        self._data_w = data_width
        self._padbytes_w = self._data_w/8
        value = BinaryValue(n_bits=self._data_w)
        value.buff = data

        self.data = value
        self.startframe = startframe
        self.frame_size = frame_size
        self.endframe = endframe
        self.padbytes = padbytes

    def __repr__(self):
        return (
        f"{type(self).__name__}(data={self.data.buff.hex()!r}, "
        f"startframe={self.startframe!r}, "
        f"endframe={self.endframe!r}, "
        f"frame_size={self.frame_size.integer!r}, "
        f"padbytes={self.padbytes.integer!r})")


"""
    A wrapper for a bus to be used with Beehive

    entity: whatever Bus expects. Probably your dut

    signals: a dictionary mapping signalNames to signal objects. You must have
    all the signals defined in _signalNames
"""
class BeehiveBus(Bus):
    _signalNames = ["val", "data", "startframe", "frame_size", "endframe", "padbytes", "rdy"]
    def __init__(self, entity, signals):
        for name in self._signalNames:
            if not name in signals:
                raise AttributeError(f"signals doesn't contain a value for key" \
                    f"{name}")
        super().__init__(entity, "", signals, case_insensitive=False)


"""
    A class for using a BeehiveBus object

    bus: a BeehiveBus object
    clk: the clock of the domain the bus is in
"""
class BeehiveBusOperator():
    def __init__(self, bus, clk):
        self._bus = bus
        self._clk = clk
        self.data_width = self._bus.data.value.n_bits
        self.data_bytes = int(self.data_width/8)

"""
An interface (or as close as you're gonna get in Python) for modules that
other Beehive things can interact with when injecting packets into the design.

Allows us to be generic between when we're using Beehive's testing and
Corundum's testing, which uses a slightly different interface
"""
class BeehiveInputInterface:
    __metaclass__ = ABCMeta

    @abstractmethod
    async def xmit_frame(self, test_packet_bytes):
        raise NotImplementedError

"""
An interface (or as close as you're gonna get in Python) for modules that
other Beehive things can interact with when pulling packets from the design.

Allows us to be generic between when we're using Beehive's testing and
Corundum's testing, which uses a slightly different interface
"""
class BeehiveOutputInterface:
    __metaclass__ = ABCMeta

    @abstractmethod
    async def recv_frame(self):
        raise NotImplementedError


"""
    A class for sending requests on a Beehive bus.

    bus: a BeehiveBus object
    clk: the clock of the domain the bus is in
"""
class BeehiveBusSource(BeehiveBusOperator, BeehiveInputInterface):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)
        self.rand_gen = Random()
        self.rand_gen.seed(1)


    """
    Send a request on the object's bus. Takes care of the val-rdy handshake

    req_values: a BeehiveBusFrame object representing the values on the bus
    """
    async def send_req(self, req_values):
        self._bus.val.value = 1
        self._bus.data.value = req_values.data
        self._bus.startframe.value = req_values.startframe
        self._bus.frame_size.value = req_values.frame_size
        self._bus.endframe.value = req_values.endframe
        self._bus.padbytes.value = req_values.padbytes

        while True:
            await ReadOnly()
            if (self._bus.rdy.value == 1):
                break
            await RisingEdge(self._clk)
        await RisingEdge(self._clk)

        self._bus.val.value = 0

    """
    Send a frame on the object's bus. Takes care of the val-rdy handshake

    test_packet_bytes: a bytearray representing the bytes to be sent
    """
    async def xmit_frame(self, test_packet_bytes, rand_delay=False,
            stall_event=None):
        bytes_sent = 0
        while bytes_sent < len(test_packet_bytes):
            if (rand_delay):
                delay = self.rand_gen.randint(0, 4)
                await ClockCycles(self._clk, delay)

            input_frame = None
            bytes_left = len(test_packet_bytes) - bytes_sent
            if (bytes_left <= self.data_bytes):
                data = test_packet_bytes[bytes_sent:bytes_sent+bytes_left]
                input_frame = BeehiveBusFrame(data=data,
                                              startframe=(bytes_sent==0),
                                              frame_size=len(test_packet_bytes),
                                              endframe=1,
                                              padbytes=self.data_bytes -
                                              bytes_left,
                                              data_width=self.data_width)
                await self.send_req(input_frame)
                bytes_sent += bytes_left
            else:
                data = test_packet_bytes[bytes_sent:bytes_sent+self.data_bytes]
                input_frame = BeehiveBusFrame(data=data,
                                              startframe=(bytes_sent==0),
                                              frame_size=len(test_packet_bytes),
                                              endframe=0,
                                              padbytes=0,
                                              data_width=self.data_width)
                await self.send_req(input_frame)
                bytes_sent += self.data_bytes

"""
    A class for receiving responses on a Beehive bus.

    bus: a BeehiveBus object
    clk: the clock of the domain the bus is in
"""
class BeehiveBusSink(BeehiveBusOperator, BeehiveOutputInterface):
    def __init__(self, bus, clk):
        super().__init__(bus, clk)

    """
    Receive a request on the object's bus. Takes care of the val-rdy handshake

    Returns: a BeehiveBusFrame object representing the values on the bus
    """
    async def recv_resp(self, pause_len=0):
        if pause_len == 0:
            self._bus.rdy.value = 1
            await ReadOnly()

            if self._bus.val.value == 0:
                await RisingEdge(self._bus.val)

            await ReadOnly()
            return_vals = BeehiveBusFrame(data = self._bus.data.value.buff,
                                          startframe = self._bus.startframe.value,
                                          endframe = self._bus.endframe.value,
                                          frame_size = self._bus.frame_size.value,
                                          padbytes = self._bus.padbytes.value,
                                          data_width = self.data_width)
        else:
            await ReadOnly()
            if self._bus.val.value == 0:
                await RisingEdge(self._bus.val)

            await ClockCycles(self._clk, pause_len)
            self._bus.rdy.value = 1

            await ReadOnly()
            return_vals = BeehiveBusFrame(data = self._bus.data.value.buff,
                                          startframe = self._bus.startframe.value,
                                          endframe = self._bus.endframe.value,
                                          frame_size = self._bus.frame_size.value,
                                          padbytes = self._bus.padbytes.value,
                                          data_width = self.data_width)

        await RisingEdge(self._clk)
        self._bus.rdy.value = 0
        return return_vals

    """
    Receive an entire frame on the object's bus. Takes care of the val-rdy handshake

    Returns: a bytearray representing the frame
    """
    async def recv_frame(self, pause_len=0):
        recv_buf = bytearray([])
        while True:
            output_frame = await self.recv_resp(pause_len=pause_len)

            good_bytes = 0
            if (output_frame.endframe == 1):
                good_bytes = self.data_bytes - output_frame.padbytes
                recv_buf.extend(output_frame.data.buff[0:good_bytes])
                break
            else:
                good_bytes = self.data_bytes
                recv_buf.extend(output_frame.data.buff)

        return recv_buf


