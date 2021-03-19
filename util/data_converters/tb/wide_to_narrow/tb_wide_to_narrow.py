import logging

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, ClockCycles
from cocotb.triggers import with_timeout
from cocotb.log import SimLog
import scapy

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")
from simple_keep_bus import SimpleKeepBusFrame
from simple_keep_bus import SimpleKeepBus
from simple_keep_bus import SimpleKeepBusSource
from simple_keep_bus import SimpleKeepBusSink

DATA_W = 512
KEEP_W = int(DATA_W/8)
DATA_BYTES = int(DATA_W/8)

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

def ceiling_div(n ,d):
    # Ceiling division...works because of integers
    return (n + d - 1) // d

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimpleKeepBus(dut, {"val": "src_w_to_n_val",
                                        "data": "src_w_to_n_data",
                                        "keep": "src_w_to_n_keep",
                                        "last": "src_w_to_n_last",
                                        "rdy": "w_to_n_src_rdy"},
                                        data_width=512)
        self.input_op = SimpleKeepBusSource(self.input_bus, dut.clk)

        self.output_bus = SimpleKeepBus(dut, {"val": "w_to_n_dst_val",
                                      "data": "w_to_n_dst_data",
                                      "keep": "w_to_n_dst_keep",
                                      "last": "w_to_n_dst_last",
                                      "rdy": "dst_w_to_n_rdy"}, data_width=256)
        self.output_op = SimpleKeepBusSink(self.output_bus, dut.clk)

@cocotb.test()
async def wide_to_narrow_test(dut):
    tb = TB(dut)

    # Set some initial values
    dut.src_w_to_n_val.setimmediatevalue(0)
    dut.src_w_to_n_data.setimmediatevalue(BinaryValue(value=0, n_bits=DATA_W))
    dut.src_w_to_n_keep.setimmediatevalue(BinaryValue(value=0, n_bits=KEEP_W))
    dut.src_w_to_n_last.setimmediatevalue(0)

    dut.dst_w_to_n_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())
    await reset(dut)

    tb.log.info("Try to send things of different sizes")
    for msg_size in range(64, 129):
        tb.log.info(f"Message of size {msg_size}")
        num_chunks = ceiling_div(msg_size, DATA_BYTES)

        msg_buffer = []
        for i in range(0, num_chunks):
            msg_buffer.extend(bytearray([44 + i] * DATA_BYTES))

        msg_buffer = bytearray(msg_buffer[0:msg_size])


        await cocotb.start(xmit_frame(tb, msg_buffer))

        task = cocotb.start_soon(recv_frame(tb))
        pkt_buf = await with_timeout(task, 10*10000, "ns")

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)
        assert pkt_buf == msg_buffer

    tb.log.info("Try some stalls")
    msg_size = 417
    for stall_input in range(0, 4):
        for stall_output in range(0, 4):
            tb.log.info((f"Stalling input for {stall_input} cycles. "
                         f"Stalling output for {stall_output} cycles."))
            num_chunks = ceiling_div(msg_size, DATA_BYTES)

            msg_buffer = []
            for i in range(0, num_chunks):
                msg_buffer.extend(bytearray([44 + i] * DATA_BYTES))

            msg_buffer = bytearray(msg_buffer[0:msg_size])


            await cocotb.start(xmit_frame(tb, msg_buffer, pause_len=stall_input))

            task = cocotb.start_soon(recv_frame(tb, pause_len=stall_output))
            pkt_buf = await with_timeout(task, 10*10000, "ns")

            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            assert pkt_buf == msg_buffer



    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

async def xmit_frame(tb, test_packet_bytes, pause_len=0):
    bytes_sent = 0
    while bytes_sent < len(test_packet_bytes):
        input_frame = None
        bytes_left = len(test_packet_bytes) - bytes_sent
        if (bytes_left <= DATA_BYTES):
            data = test_packet_bytes[bytes_sent:bytes_sent+bytes_left]
            useless_bytes = 0 if bytes_left == DATA_BYTES else DATA_BYTES - bytes_left
            padding_bytes = bytearray([0] * useless_bytes)
            data.extend(padding_bytes)

            keep_mask = ("1" * bytes_left) + ("0" * useless_bytes)

            input_frame = SimpleKeepBusFrame(data=data,
                                             keep=keep_mask,
                                             last=1)
            await tb.input_op.send_req(input_frame)
            bytes_sent += bytes_left
        else:
            data = test_packet_bytes[bytes_sent:bytes_sent+DATA_BYTES]
            input_frame = SimpleKeepBusFrame(data=data,
                                             keep = "1" * DATA_BYTES,
                                             last = 0)
            await tb.input_op.send_req(input_frame)
            if (pause_len != 0):
               await ClockCycles(tb.dut.clk, pause_len)
            bytes_sent += DATA_BYTES

async def recv_frame(tb, pause_len=0):
    recv_buf = bytearray([])
    while True:
        output_frame = await tb.output_op.recv_resp()

        if (output_frame.last == 1):
            num_good_bytes = output_frame.keep.binstr.count("1")
            recv_buf.extend(output_frame.data.buff[0:num_good_bytes])
            break
        else:
            recv_buf.extend(output_frame.data.buff)

        if (pause_len != 0):
            await ClockCycles(tb.dut.clk, pause_len)

    return recv_buf

