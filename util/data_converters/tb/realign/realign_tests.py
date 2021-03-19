import random 
import sys, os
import logging

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import with_timeout, Event, First, Join
from cocotb.log import SimLog

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")
from simple_padbytes_bus import SimplePadbytesFrame
from simple_padbytes_bus import SimplePadbytesBus
from simple_padbytes_bus import SimplePadbytesBusSource
from simple_padbytes_bus import SimplePadbytesBusSink

class TB():
    def __init__(self, dut):
        self.CLOCK_CYCLE_TIME = 4
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimplePadbytesBus(dut, {"val": "src_realign_data_val",
                                        "data": "src_realign_data",
                                        "padbytes": "src_realign_data_padbytes",
                                        "last": "src_realign_data_last",
                                        "rdy": "realign_src_data_rdy"},
                                        data_width = 512)
        self.input_op = SimplePadbytesBusSource(self.input_bus, dut.clk)

        self.output_bus = SimplePadbytesBus(dut, {"val": "realign_dst_data_val",
                                      "data": "realign_dst_data",
                                      "padbytes": "realign_dst_data_padbytes",
                                      "last": "realign_dst_data_last",
                                      "rdy": "dst_realign_data_rdy"}, 
                                      data_width = 512)
        self.output_op = SimplePadbytesBusSink(self.output_bus, dut.clk)

async def reset(dut):
    dut.rst.setimmediatevalue(0)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

async def recv_task(tb, event, max_rand_delay=0):
    output_data = await tb.output_op.recv_frame(max_rand_delay=max_rand_delay)
    event.set(data=output_data)

async def run_data_buf_size_test(tb, realign_bytes, max_rand_delay_in=0, max_rand_delay_out=0):
    data_generator = random.Random(0)

    # we need one more byte than there is to realign
    for i in range(realign_bytes + 1, realign_bytes + 256):
        cocotb.log.info(f"Testing buffer of size {i}")
        data_buf = data_generator.randbytes(i)

        ref_data = data_buf[realign_bytes:]
        data_event = Event()

        xmit_coro = cocotb.start_soon(tb.input_op.send_buf(data_buf,
            max_rand_delay=max_rand_delay_in))
        recv_coro = cocotb.start_soon(recv_task(tb, data_event,
            max_rand_delay=max_rand_delay_out))

        await Combine(recv_coro, xmit_coro)

        assert data_event.data == ref_data

