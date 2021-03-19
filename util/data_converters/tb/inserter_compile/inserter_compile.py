import random 
import sys, os
import logging
from cocotb_test.simulator import run

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
        self.input_bus = SimplePadbytesBus(dut, {"val": "src_insert_data_val",
                                        "data": "src_insert_data",
                                        "padbytes": "src_insert_data_padbytes",
                                        "last": "src_insert_data_last",
                                        "rdy": "insert_src_data_rdy"},
                                        data_width = 512)
        self.input_op = SimplePadbytesBusSource(self.input_bus, dut.clk)

        self.output_bus = SimplePadbytesBus(dut, {"val": "insert_dst_data_val",
                                      "data": "insert_dst_data",
                                      "padbytes": "insert_dst_data_padbytes",
                                      "last": "insert_dst_data_last",
                                      "rdy": "dst_insert_data_rdy"}, 
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

async def recv_task(tb, event):
    output_data = await tb.output_op.recv_frame()
    event.set(data=output_data)

@cocotb.test()
# pytest tries to run anything starting with test...can also use
# @pytest.mark.skip
async def inserter_test(dut):
    tb = TB(dut)
    
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    
    dut.insert_data.setimmediatevalue(0)
    dut.src_insert_data_val.setimmediatevalue(0)
    dut.src_insert_data.setimmediatevalue(BinaryValue(value=0,
        n_bits=dut.src_insert_data.value.n_bits))
    dut.src_insert_data_padbytes .setimmediatevalue(0)
    dut.src_insert_data_last.setimmediatevalue(0)

    dut.dst_insert_data_rdy.setimmediatevalue(0)

    await reset(dut)

    data_generator = random.Random(0)
    insert_data_w = dut.insert_data.value.n_bits
    insert_data_bytes = int(insert_data_w/8)


    for i in range(1, 256):
        cocotb.log.info(f"Testing buffer of size {i}")
        insert_data = data_generator.randbytes(insert_data_bytes)
        data_buf = data_generator.randbytes(i)

        dut.insert_data.value = BinaryValue(value=insert_data,
                n_bits=insert_data_w)

        ref_data = insert_data + data_buf
        data_event = Event()

        xmit_coro = cocotb.start_soon(tb.input_op.send_buf(data_buf))
        recv_coro = cocotb.start_soon(recv_task(tb, data_event))

        await Combine(recv_coro, xmit_coro)

        assert data_event.data == ref_data
