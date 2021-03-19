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
from fake_mem import MemInputBus, MemOutputBus, FakeMem, RandomDelay, ConstDelay


MSG_TYPE_LOAD_MEM = 19
MSG_TYPE_STORE_MEM = 20
MSG_TYPE_LOAD_MEM_ACK = 24
MSG_TYPE_STORE_MEM_ACK = 25

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimpleValRdyBus(dut,
                {"val":"noc0_ctovr_controller_val",
                 "data": "noc0_ctovr_controller_data",
                 "rdy": "controller_noc0_ctovr_rdy"},
                 data_width = 512)
        self.input_op = SimpleValRdyBusSource(self.input_bus, dut.clk)
        self.output_bus = SimpleValRdyBus(dut,
                {"val": "controller_noc0_vrtoc_val",
                 "data": "controller_noc0_vrtoc_data",
                 "rdy": "noc0_vrtoc_controller_rdy"},
                 data_width = 512)
        self.output_op = SimpleValRdyBusSink(self.output_bus, dut.clk)

        self.wr_output_bus = SimpleValRdyBus(dut,
                {"val": "wr_resp_noc_vrtoc_val",
                 "data": "wr_resp_noc_vrtoc_data",
                 "rdy": "noc_wr_resp_vrtoc_rdy"},
                data_width = 512)
        self.wr_output_op = SimpleValRdyBusSink(self.wr_output_bus, dut.clk)

#        self.mem_input = MemInputBus(dut,
#                {"rd_en": "controller_mem_read_en",
#                 "wr_en": "controller_mem_write_en",
#                 "addr": "controller_mem_addr",
#                 "wr_data": "controller_mem_wr_data",
#                 "byte_en": "controller_mem_byte_en",
#                 "rdy": "mem_controller_rdy"})
#        self.mem_output = MemOutputBus(dut,
#                {"rd_val": "mem_controller_rd_data_val",
#                 "rd_data": "mem_controller_rd_data",
#                 "rd_rdy": "controller_mem_rd_data_rdy"})


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
async def run_mem_controller_test(dut):
    # Set some initial values
    dut.noc0_ctovr_controller_val.setimmediatevalue(0)
    dut.noc0_ctovr_controller_data.setimmediatevalue(0)

    dut.noc0_vrtoc_controller_rdy.setimmediatevalue(0)

    #dut.mem_controller_rdy.setimmediatevalue(0)

    #dut.mem_controller_rd_data_val.setimmediatevalue(0)
    #dut.mem_controller_rd_data.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())

    tb = TB(dut)
    await reset(dut)

    #mem = FakeMem(tb, input_delay_gen=None, op_delay_gen=ConstDelay(2))
    #cocotb.start_soon(mem.run_mem())

    # do a basic set of writes then reads
    data = bytearray([ord('a')] * 64)
    write_task = cocotb.start_soon(inject_write(tb, data, 64))
    await with_timeout(write_task, 100 * 4, "ns")

    read_task = cocotb.start_soon(inject_read(tb, 64, 64))
    result = await with_timeout(read_task, 100 * 4, "ns")
    assert result == data

    # initialize the addresses we are going to use
    #data = bytearray([0] * (64 * 64))
    #write_task = cocotb.start_soon(inject_write(tb, data, 0))
    #await write_task

    # okay now do a whole bunch of stuff
    rand_gen = random.Random()
    rand_gen.seed(1)
    tb.log.info(f"Writing and then reading a range of addresses and sizes")
    #for address in range(0, 65):
    #    for size in range(1, 257):
    #        tb.log.info(f"Sending request to address {address} for size {size}")
    #        data = bytearray([rand_gen.randint(0, 255) for i in range(0, size)])
    #        write_task = cocotb.start_soon(inject_write(tb, data, address))
    #        await with_timeout(write_task, 100 * 4, "ns")

    #        read_task = cocotb.start_soon(inject_read(tb, address, size))
    #        result = await with_timeout(read_task, 100 * 4, "ns")
    #        assert result == data, f"expected: {data}, got: {result}"

    # issue a bunch of odd sized reads and then read back to make sure we
    # didn't clobber them
    address = 0
    bytes_written = bytearray()
    tb.log.info("Checking we don't clobber when writing weird things")
    for size in range(1, 65, 2):
        data = bytearray([rand_gen.randint(0, 255) for i in range(0, size)])
        tb.log.info(f"Writing buffer with size {size} to address {address}")
        write_task = cocotb.start_soon(inject_write(tb, data, address))
        await with_timeout(write_task, 100 * 4, "ns")
        bytes_written.extend(data)
        address += size

    tb.log.info(f"reading back {len(bytes_written)} bytes from 0")
    read_task = cocotb.start_soon(inject_read(tb, 0, len(bytes_written)))
    mem_resp = await with_timeout(read_task, 100 * 4, "ns")

    assert bytes_written == mem_resp

    await check_val_rdy_test(tb)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


async def check_val_rdy_test(tb):
    tb.log.info("Checking val rdy implementation")
    noc_hdr_flit = BeehiveHdrFlit()

    data_buf = bytearray([ord('b')] * 129)
    num_data_flits = ceil(len(data_buf)/(BeehiveNoCConstants.NOC_DATA_W/8))

    # fill in the header flit
    noc_hdr_flit.set_field("dst_x", 2)
    noc_hdr_flit.set_field("dst_y", 2)
    noc_hdr_flit.set_field("dst_fbits", "1000")
    noc_hdr_flit.set_field("msg_length", num_data_flits)
    noc_hdr_flit.set_field("msg_type", MSG_TYPE_STORE_MEM)
    noc_hdr_flit.set_field("src_x", 1)
    noc_hdr_flit.set_field("src_y", 1)
    noc_hdr_flit.set_field("src_fbits", "1000")
    noc_hdr_flit.set_field("addr", 0)
    noc_hdr_flit.set_field("data_size", len(data_buf))
    noc_hdr_flit_bin = noc_hdr_flit.assemble_flit()

    req_values = SimpleValRdyFrame(data=noc_hdr_flit_bin.buff, data_width=512)
    await tb.input_op.send_req(req_values)

    await tb.input_op.send_buf(data_buf)

    # okay now check that if we issue a read, the thing isn't ready

    noc_hdr_flit = BeehiveHdrFlit()

    # fill in the header flit
    noc_hdr_flit.set_field("dst_x", 2)
    noc_hdr_flit.set_field("dst_y", 2)
    noc_hdr_flit.set_field("dst_fbits", "1000")
    noc_hdr_flit.set_field("msg_length", 0)
    noc_hdr_flit.set_field("msg_type", MSG_TYPE_LOAD_MEM)
    noc_hdr_flit.set_field("src_x", 1)
    noc_hdr_flit.set_field("src_y", 1)
    noc_hdr_flit.set_field("src_fbits", "1000")
    noc_hdr_flit.set_field("addr", 0)
    noc_hdr_flit.set_field("data_size", len(data_buf))
    noc_hdr_flit_bin = noc_hdr_flit.assemble_flit()

    req_values = SimpleValRdyFrame(data=noc_hdr_flit_bin.buff, data_width=512)

    tb.input_bus.val.value = 1
    tb.input_bus.data.value = req_values.data

    await ReadOnly()
    assert tb.input_bus.rdy.value == 0

    await RisingEdge(tb.dut.clk)
    # wait for the write response
    hdr_flit = await tb.wr_output_op.recv_resp()
    validate_wr_resp_flit(hdr_flit.data)

    # check that the read is good to go
    await ReadOnly()
    assert tb.input_bus.rdy.value == 1

    await RisingEdge(tb.dut.clk)
    tb.input_bus.val.value = 0

    # wait for the read response
    hdr_flit = await tb.output_op.recv_resp()
    validate_rd_flit(hdr_flit.data, num_data_flits)

    # now wait for the data
    data_rd = await _recv_read_data(tb, len(data_buf))
    assert data_rd == data_buf



async def inject_write(tb, data_buf, addr):
    noc_hdr_flit = BeehiveHdrFlit()

    num_data_flits = ceil(len(data_buf)/(BeehiveNoCConstants.NOC_DATA_W/8))

    # fill in the header flit
    noc_hdr_flit.set_field("dst_x", 2)
    noc_hdr_flit.set_field("dst_y", 2)
    noc_hdr_flit.set_field("dst_fbits", "1000")
    noc_hdr_flit.set_field("msg_length", num_data_flits)
    noc_hdr_flit.set_field("msg_type", MSG_TYPE_STORE_MEM)
    noc_hdr_flit.set_field("src_x", 1)
    noc_hdr_flit.set_field("src_y", 1)
    noc_hdr_flit.set_field("src_fbits", "1000")
    noc_hdr_flit.set_field("addr", addr)
    noc_hdr_flit.set_field("data_size", len(data_buf))
    noc_hdr_flit_bin = noc_hdr_flit.assemble_flit()

    req_values = SimpleValRdyFrame(data=noc_hdr_flit_bin.buff, data_width=512)
    await tb.input_op.send_req(req_values)
    await tb.input_op.send_buf(data_buf)

    mem_resp = await tb.wr_output_op.recv_resp()

    validate_wr_resp_flit(mem_resp.data)

def validate_wr_resp_flit(flit):
    hdr_flit = BeehiveHdrFlit()
    hdr_flit.flit_from_bitstring(flit.binstr)

    assert hdr_flit.dst_x == 1
    assert hdr_flit.dst_y == 1
    assert hdr_flit.dst_fbits.binstr == "1000"
    assert hdr_flit.msg_length == 0
    assert hdr_flit.msg_type == MSG_TYPE_STORE_MEM_ACK


async def inject_read(tb, addr, rd_len):
    noc_hdr_flit = BeehiveHdrFlit()

    # fill in the header flit
    noc_hdr_flit.set_field("dst_x", 2)
    noc_hdr_flit.set_field("dst_y", 2)
    noc_hdr_flit.set_field("dst_fbits", "1000")
    noc_hdr_flit.set_field("msg_length", 0)
    noc_hdr_flit.set_field("msg_type", MSG_TYPE_LOAD_MEM)
    noc_hdr_flit.set_field("src_x", 1)
    noc_hdr_flit.set_field("src_y", 1)
    noc_hdr_flit.set_field("src_fbits", "1000")
    noc_hdr_flit.set_field("addr", addr)
    noc_hdr_flit.set_field("data_size", rd_len)
    noc_hdr_flit_bin = noc_hdr_flit.assemble_flit()

    req_values = SimpleValRdyFrame(data=noc_hdr_flit_bin.buff, data_width=512)
    await tb.input_op.send_req(req_values)

    num_data_flits = ceil(rd_len/(BeehiveNoCConstants.NOC_DATA_W/8))

    hdr_flit = await tb.output_op.recv_resp()
    validate_rd_flit(hdr_flit.data, num_data_flits)

    data_rd = await _recv_read_data(tb, rd_len)
    return data_rd


async def _recv_read_data(tb, rd_len):
    noc_bytes = int(BeehiveNoCConstants.NOC_DATA_W/8)
    test_buf = bytearray()
    bytes_recv = 0
    while bytes_recv < rd_len:
        bytes_left = rd_len - bytes_recv
        noc_data = await tb.output_op.recv_resp()

        if bytes_left <= noc_bytes:
            test_buf.extend(noc_data.data.buff[0:bytes_left])
            bytes_recv += bytes_left
        else:
            test_buf.extend(noc_data.data.buff[0:noc_bytes])
            bytes_recv += noc_bytes

    return test_buf

def validate_rd_flit(flit, msg_len):
    hdr_flit = BeehiveHdrFlit()
    hdr_flit.flit_from_bitstring(flit.binstr)

    assert hdr_flit.dst_x == 1
    assert hdr_flit.dst_y == 1
    assert hdr_flit.dst_fbits.binstr == "1000"
    assert hdr_flit.msg_length == msg_len
    assert hdr_flit.msg_type == MSG_TYPE_LOAD_MEM_ACK
