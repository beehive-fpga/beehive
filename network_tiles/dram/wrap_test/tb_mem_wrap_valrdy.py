import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.result import SimTimeoutError
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import with_timeout
from cocotb.log import SimLog
from math import ceil

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from noc_helpers import BeehiveHdrFlit, BeehiveNoCConstants
from simple_val_rdy import SimpleValRdyFrame, SimpleValRdyBus
from simple_val_rdy import SimpleValRdyBusSource, SimpleValRdyBusSink
from fake_mem import MemInputBus, MemOutputBus, FakeMem

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        self.input_bus = MemInputBus(dut,
                {"rd_en": "controller_wrap_read_en",
                 "wr_en": "controller_wrap_write_en",
                 "addr": "controller_wrap_addr",
                 "wr_data": "controller_wrap_wr_data",
                 "byte_en": "controller_wrap_byte_en",
                 "rdy": "wrap_controller_rdy"})
        self.output_bus = SimpleValRdyBus(dut,
                {"val": "wrap_controller_rd_data_val",
                 "data": "wrap_controller_rd_data",
                 "rdy": "controller_wrap_rd_data_rdy"},
                data_width = 512)
        self.output_op = SimpleValRdyBusSink(self.output_bus, dut.clk)


        self.mem_input = MemInputBus(dut,
                {"rd_en": "wrap_mem_read_en",
                 "wr_en": "wrap_mem_write_en",
                 "addr": "wrap_mem_addr",
                 "wr_data": "wrap_mem_wr_data",
                 "byte_en": "wrap_mem_byte_en",
                 "rdy": "mem_wrap_rdy"})
        self.mem_output = MemOutputBus(dut,
                {"rd_val": "mem_wrap_rd_data_val",
                 "rd_data": "mem_wrap_rd_data",
                 "rd_rdy": "wrap_mem_rd_data_rdy"})

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

@cocotb.test()
async def run_mem_wrap_test(dut):
    dut.controller_wrap_write_en.setimmediatevalue(0)
    dut.controller_wrap_addr.setimmediatevalue(0)
    dut.controller_wrap_wr_data.setimmediatevalue(0)
    dut.controller_wrap_byte_en.setimmediatevalue(0)
    dut.controller_wrap_burst_cnt.setimmediatevalue(0)

    dut.controller_wrap_read_en.setimmediatevalue(0)

    dut.controller_wrap_rd_data_rdy.setimmediatevalue(0)

    dut.mem_wrap_rdy.setimmediatevalue(0)

    dut.mem_wrap_rd_data_val.setimmediatevalue(0)
    dut.mem_wrap_rd_data.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())

    tb = TB(dut)
    await reset(dut)

    mem = FakeMem(tb, input_delay_max=10, op_delay_max=10)
    cocotb.start_soon(mem.run_mem())

    # just test a single read and write multiple times
    # the actual addresses don't matter
    # since we're not modifying those. it's about the val-ready interface and
    # the read data when playing around with those
    rand_gen = random.Random()
    rand_gen.seed(42)

    #for i in range(0, 128):
    #    cocotb.log.info(f"Doing write {i}")
    #    data = bytearray([rand_gen.randint(0, 255) for i in range(0, 64)])
    #    write_task = cocotb.start_soon(inject_write(tb, 4, data=data))
    #    await with_timeout(write_task, 100 * 4, "ns")

    #    read_task = cocotb.start_soon(inject_read(tb, 4))
    #    await with_timeout(read_task, 100 * 4, "ns")
    #    resp_task = cocotb.start_soon(tb.output_op.recv_resp())
    #    result = await with_timeout(resp_task, 100 * 4, "ns")
    #    assert result.data.buff == data

    # okay now try issuing some  writes and then a read and backpressuring
    data_1 = bytearray([rand_gen.randint(0, 255) for i in range(0, 64)])
    data_2 = bytearray([rand_gen.randint(0, 255) for i in range(0, 64)])
    write_task = cocotb.start_soon(inject_write(tb, 4, data=data_1))
    await with_timeout(write_task, 100 * 4, "ns")

    write_task = cocotb.start_soon(inject_write(tb, 5, data=data_2))
    await with_timeout(write_task, 100 * 4, "ns")

    read_task = cocotb.start_soon(inject_read(tb, 4))
    await with_timeout(read_task, 100 * 4, "ns")

    await ReadOnly()
    # check that the input isn't ready
    assert tb.input_bus.rdy.value == 0

    # wait for the read to be ready
    await RisingEdge(tb.output_bus.val)
    await ReadOnly()
    result = tb.output_bus.data.value
    assert result.buff == data_1

    await RisingEdge(dut.clk)

    # don't consume it. instead, pretend to issue another read 
    # and make sure the output doesn't change
    try:
        read_task = cocotb.start_soon(inject_read(tb, 5))
        await with_timeout(read_task, 100 * 4, "ns")
    except SimTimeoutError:
        result = tb.output_bus.data.value
        assert result.buff == data_1

    # okay now consume it
    resp_task = cocotb.start_soon(tb.output_op.recv_resp())
    result = await with_timeout(resp_task, 100 * 4, "ns")
    assert result.data.buff == data_1

    await ReadOnly()
    # check the valid cleared properly
    assert tb.output_bus.val.value == 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def inject_read(tb, addr):
    await inject_op(tb, addr)

async def inject_write(tb, addr, data):
    await inject_op(tb, addr, data=data)

async def inject_op(tb, addr, data=None):
    if data is None:
        tb.input_bus.wr_en.value = 0
        tb.input_bus.rd_en.value = 1
        tb.input_bus.wr_data.value = 0
        tb.input_bus.byte_en.value = 0
    else:
        tb.input_bus.wr_en.value = 1
        tb.input_bus.rd_en.value = 0
        tb.input_bus.wr_data.value = BinaryValue(n_bits=512, value=bytes(data))
        tb.input_bus.byte_en.value = (1 << 64) - 1

    tb.input_bus.addr.value = addr

    while True:
        await ReadOnly()
        if tb.input_bus.rdy.value == 1:
            break
        await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)

    if data is None:
        tb.input_bus.rd_en.value = 0
    else:
        tb.input_bus.wr_en.value = 0




