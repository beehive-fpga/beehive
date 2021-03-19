import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
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
from circ_buf_req_bus import CircBufReqFrame, CircBufReqBus, CircBufReqBusSource
from simple_padbytes_bus import SimplePadbytesFrame, SimplePadbytesBus
from simple_padbytes_bus import SimplePadbytesBusSink
from fake_mem import MemInputBus, MemOutputBus, FakeMem

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

class TB():
    def __init__(self, dut):
        self.CLOCK_CYCLE_TIME = 4
        self.MAC_WIDTH = 512
        self.BUF_PTR_WIDTH = 10

        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        self.wr_req_input = CircBufReqBus(dut,
                {"val": "src_wr_buf_req_val",
                 "flowid": "src_wr_buf_req_flowid",
                 "offset": "src_wr_buf_req_wr_ptr",
                 "size": "src_wr_buf_req_size",
                 "rdy": "wr_buf_src_req_rdy"
                })
        self.wr_req_input_op = CircBufReqBusSource(self.wr_req_input, dut.clk)

        self.wr_data_input = SimpleValRdyBus(dut,
            {"val": "src_wr_buf_req_data_val",
             "data": "src_wr_buf_req_data",
             "rdy": "wr_buf_src_req_data_rdy"
             }, data_width = self.MAC_WIDTH)
        self.wr_data_input_op = SimpleValRdyBusSource(self.wr_data_input,
                dut.clk)

        self.rd_req_input = CircBufReqBus(dut,
            {"val": "src_rd_buf_req_val",
             "flowid": "src_rd_buf_req_flowid",
             "offset": "src_rd_buf_req_offset",
             "size": "src_rd_buf_req_size",
             "rdy": "rd_buf_src_req_rdy"})

        self.rd_req_input_op = CircBufReqBusSource(self.rd_req_input, dut.clk)

        self.rd_resp_output = SimplePadbytesBus(dut,
                {"val": "rd_buf_src_data_val",
                 "data": "rd_buf_src_data",
                 "last": "rd_buf_src_data_last",
                 "padbytes": "rd_buf_src_data_padbytes",
                 "rdy": "src_rd_buf_data_rdy"},
                data_width=self.MAC_WIDTH)
        self.rd_resp_output_op = SimplePadbytesBusSink(self.rd_resp_output,
                dut.clk)

        self.mem_input = MemInputBus(dut,
                {"rd_en": "controller_mem_read_en",
                 "wr_en": "controller_mem_write_en",
                 "addr": "controller_mem_addr",
                 "wr_data": "controller_mem_wr_data",
                 "byte_en": "controller_mem_byte_en",
                 "rdy": "mem_controller_rdy"})
        self.mem_output = MemOutputBus(dut,
                {"rd_val": "mem_controller_rd_data_val",
                 "rd_data": "mem_controller_rd_data"})

@cocotb.test()
async def circ_buf_test(dut):
    # Set some initial values
    tb = TB(dut)
    dut.src_wr_buf_req_val.setimmediatevalue(0)
    dut.src_wr_buf_req_flowid.setimmediatevalue(0)
    dut.src_wr_buf_req_wr_ptr.setimmediatevalue(0)
    dut.src_wr_buf_req_size.setimmediatevalue(0)

    dut.src_wr_buf_req_data_val.setimmediatevalue(0)
    dut.src_wr_buf_req_data.setimmediatevalue(0)

    dut.src_wr_buf_done_rdy.setimmediatevalue(0)

    dut.src_rd_buf_req_val.setimmediatevalue(0)
    dut.src_rd_buf_req_flowid.setimmediatevalue(0)
    dut.src_rd_buf_req_offset.setimmediatevalue(0)
    dut.src_rd_buf_req_size.setimmediatevalue(0)

    dut.src_rd_buf_data_rdy.setimmediatevalue(0)

    dut.mem_controller_rdy.setimmediatevalue(0)

    dut.mem_controller_rd_data_val.setimmediatevalue(0)
    dut.mem_controller_rd_data.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    await reset(dut)

    mem = FakeMem(tb)
    cocotb.start_soon(mem.run_mem())

    await basic_test(tb)

#    await size_alignment_test(tb)

#    await wrapping_tests(tb, mem)

# run a basic read and write test
async def basic_test(tb):
    tb.log.info("Sanity test")
    rand_gen = random.Random(42)
    await RisingEdge(tb.dut.clk)
    data = bytearray([ord('a')] * 64)

    await inject_write(tb, data, 0, 0)

    rd_data = await inject_read(tb, len(data), 0, 0)

    assert rd_data == data, f"expected: {data}, received: {rd_data}"

    await RisingEdge(tb.dut.clk)

    tb.log.info("Non-zero address")

    data = bytearray([rand_gen.randint(0, 255) for i in range(0, 139)])

    await inject_write(tb, data, 128, 0)

    rd_data = await inject_read(tb, len(data), 128, 0)

    assert rd_data == data, f"expected: {data}, received: {rd_data}"

    tb.log.info("Write/read different flowID buffers")

    flow_0_data = bytearray([rand_gen.randint(0, 255) for i in range(0, 64)])
    flow_1_data = bytearray([rand_gen.randint(0, 255) for i in range(0, 64)])

    await inject_write(tb, flow_0_data, 64, 0)
    # read it back just to make sure
    flow_0_rd_data = await inject_read(tb, len(flow_0_data), 64, 0)

    assert flow_0_rd_data == flow_0_data

    await inject_write(tb, flow_1_data, 64, 1)
    # read it back
    flow_1_rd_data = await inject_read(tb, len(flow_1_data), 64, 1)
    assert flow_1_rd_data == flow_1_data, (f"expected: {flow_1_data} ",
        f"received: {flow_1_rd_data}")

    # read flow 0 again to make sure we didn't write over it
    flow_0_rd_data = await inject_read(tb, len(flow_0_data), 64, 0)
    assert flow_0_rd_data == flow_0_data

    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)

async def size_alignment_test(tb):
    tb.log.info("Test a range of offsets and sizes, non-wrapping")
    rand_gen = random.Random(42)
    for address in range(0, 65):
        for size in range(1, 257):
            tb.log.info(f"Sending request to address {address} for size {size}")
            data = bytearray([rand_gen.randint(0, 255) for i in range(0, size)])

            write_task = cocotb.start_soon(inject_write(tb, data, address, 0))
            await with_timeout(write_task, 100 * 4, "ns")

            read_task = cocotb.start_soon(inject_read(tb, size, address, 0))
            result = await with_timeout(read_task, 100 * 4, "ns")
            assert result == data, f"expected: {data}, got: {result}"

    await RisingEdge(tb.dut.clk)

async def wrapping_tests(tb, mem):
    tb.log.info("Test a basic wrapped request. Make sure we don't overwrite ",
                 "the next flow's buffer")
    rand_gen = random.Random(42)
    data = bytearray([ord('a')] * 64)

    data_1 = bytearray([ord('b')] * 64)

    write_task = cocotb.start_soon(inject_write(tb, data_1, 0, 1))
    await with_timeout(write_task, 100 * 4, "ns")

    end_buf_addr = (1 << tb.BUF_PTR_WIDTH) - 32
    write_task = cocotb.start_soon(inject_write(tb, data, end_buf_addr, 0))
    await with_timeout(write_task, 100 * 4, "ns")

    # figure out if we actually wrapped by reading back the initial data
    calc_addr = 1 << (tb.BUF_PTR_WIDTH)
    result = mem.read_mem(calc_addr, len(data_1))
    assert result == data_1, f"expected: {data_1}, got: {result}"

    # okay and make sure we can do a wrapped read
    read_task = cocotb.start_soon(inject_read(tb, len(data), end_buf_addr, 0))
    result = await with_timeout(read_task, 100 * 4, "ns")
    assert result == data, f"expected: {data}, got: {result}"

    tb.log.info("Test small wraps")
    for size in range(2, 64):
        end_offset = int(size/2)
        address = (1 << tb.BUF_PTR_WIDTH) - end_offset
        tb.log.info(f"Sending request to address {address} for size {size}")

        data = bytearray([rand_gen.randint(0, 255) for i in range(0, size)])

        write_task = cocotb.start_soon(inject_write(tb, data, address, 0))
        await with_timeout(write_task, 100 * 4, "ns")

        # make sure we didn't overwrite in the other buffer
        calc_addr = 1 << (tb.BUF_PTR_WIDTH)
        result = mem.read_mem(calc_addr, len(data_1))
        assert result == data_1, f"expected: {data_1}, got: {result}"

        read_task = cocotb.start_soon(inject_read(tb, size, address, 0))
        result = await with_timeout(read_task, 100 * 4, "ns")
        assert result == data, f"expected: {data}, got: {result}"

#    tb.log.info("Test more wraps")
#
#    start_addr = (1 << tb.BUF_PTR_WIDTH) - 256
#    end_addr = (1 << tb.BUF_PTR_WIDTH)
#    for address in range(start_addr, end_addr):
#        for size in range(256, 320):
#            tb.log.info(f"Sending request to address {address} for size {size}")
#
#            data = bytearray([rand_gen.randint(0, 255) for i in range(0, size)])
#
#            write_task = cocotb.start_soon(inject_write(tb, data, address, 0))
#            await with_timeout(write_task, 100 * 4, "ns")
#
#            # make sure we didn't overwrite in the other buffer
#            calc_addr = 1 << (tb.BUF_PTR_WIDTH)
#            result = mem.read_mem(calc_addr, len(data_1))
#            assert result == data_1, f"expected: {data_1}, got: {result}"
#
#            read_task = cocotb.start_soon(inject_read(tb, size, address, 0))
#            result = await with_timeout(read_task, 100 * 4, "ns")
#            if (result != data):
#                if len(result) != len(data):
#                    tb.log.debug("Lengths differ")
#                else:
#                    for i in range(0, len(data)):
#                        if (result[i] != data[i]):
#                            tb.log.debug(f"buffers differ starting at byte {i}")
#
#            assert result == data, f"expected: {data}, got: {result}"
#
#
#
#    await RisingEdge(tb.dut.clk)
#    await RisingEdge(tb.dut.clk)
#    await RisingEdge(tb.dut.clk)
#

async def inject_write(tb, data, offset, flowid):
    wr_req = CircBufReqFrame(flowid, offset, len(data))
    # send request
    await tb.wr_req_input_op.send_req(wr_req)
    # now send data
    await tb.wr_data_input_op.send_buf(data)

    # wait until the wr req finishes
    await RisingEdge(tb.dut.clk)
    tb.dut.src_wr_buf_done_rdy.value = 1
    await RisingEdge(tb.dut.wr_buf_src_req_done)
    await RisingEdge(tb.dut.clk)

async def inject_read(tb, size, offset, flowid):
    rd_req = CircBufReqFrame(flowid, offset, size)

    # send read request
    await tb.rd_req_input_op.send_req(rd_req)
    # now wait for the data
    data = await tb.rd_resp_output_op.recv_frame()

    return data


