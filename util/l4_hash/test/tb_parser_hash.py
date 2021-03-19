import logging
import random
import socket

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.log import SimLog

import scapy
from scapy.volatile import RandIP, RandShort

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from simple_padbytes_bus import SimplePadbytesFrame
from simple_padbytes_bus import SimplePadbytesBus
from simple_padbytes_bus import SimplePadbytesBusSource
from simple_padbytes_bus import SimplePadbytesBusSink

from simple_val_rdy import SimpleValRdyFrame, SimpleValRdyBus
from simple_val_rdy import SimpleValRdyBusSink

from hash_helpers import reset, create_udp_frame, pad_packet, python_hash_version
from hash_helpers import extract_hash_tuple_bytearray

MIN_PKT_SIZE = 64
USE_ETHER = True

class TB:
    def __init__(self, dut):
        self.DATA_W = 512
        self.CLOCK_CYCLE_TIME = 4
        self.dut = dut
        self.clk = self.dut.clk
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimplePadbytesBus(dut, {"val": "src_parser_data_val",
                                                "data": "src_parser_data",
                                                "padbytes": "src_parser_padbytes",
                                                "last": "src_parser_last",
                                                "rdy": "parser_src_data_rdy"},
                                                data_width = self.DATA_W)
        self.input_op = SimplePadbytesBusSource(self.input_bus, self.dut.clk)

        self.output_bus = SimplePadbytesBus(dut, {"val": "parser_dst_data_val",
                                                "data": "parser_dst_data",
                                                "padbytes": "parser_dst_padbytes",
                                                "last": "parser_dst_last",
                                                "rdy": "dst_parser_data_rdy"},
                                                data_width = self.DATA_W)
        self.output_op = SimplePadbytesBusSink(self.output_bus, self.dut.clk)

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

IP_TO_MAC = {
    "198.0.0.5": "b8:59:9f:b7:ba:44",
    "198.0.0.7": "00:90:fb:60:e1:e7",
    "198.0.0.9": "00:90:fb:60:e1:e7"
}

@cocotb.test()
async def test_parser_hash(dut):
    tb = TB(dut)
    dut.src_parser_data_val.setimmediatevalue(0)
    dut.src_parser_data.setimmediatevalue(0)
    dut.src_parser_padbytes.setimmediatevalue(0)
    dut.src_parser_last.setimmediatevalue(0)

    dut.dst_hash_stall.setimmediatevalue(0)
    dut.dst_parser_data_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

    await test_single_packet(tb)

    await test_copy_packet(tb)

    await test_multiple_packets(tb)


async def test_single_packet(tb):
    cocotb.log.info("Test a single packet as a basic test")
    test_pkt = create_udp_frame(0, USE_ETHER)
    test_pkt_bytes = bytearray(test_pkt.build())
    pad_packet(test_pkt_bytes, MIN_PKT_SIZE)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_value = await receive_hash(tb)

    cocotb.log.info(f"received hash {hash_value.buff}")

    hash_tuple = extract_hash_tuple_bytearray(test_pkt)
    expected_cpu_hash = python_hash_version(hash_tuple)
    cocotb.log.info(f"expected cpu hash {expected_cpu_hash.to_bytes(4,byteorder='big')}")

    assert hash_value.buff == expected_cpu_hash.to_bytes(4, byteorder="big")

    await send_task
    recv_buf = await recv_task

    assert recv_buf == test_pkt_bytes

async def test_copy_packet(tb):
    cocotb.log.info("Test multiple copies of the same packet")
    test_pkt = create_udp_frame(0, USE_ETHER)
    test_pkt_bytes = bytearray(test_pkt.build())
    pad_packet(test_pkt_bytes, MIN_PKT_SIZE)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_value_1 = await receive_hash(tb)

    await send_task
    recv_buf = await recv_task

    assert recv_buf == test_pkt_bytes

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_value_2 = await receive_hash(tb)

    assert hash_value_1 == hash_value_2

    await send_task
    recv_buf = await recv_task

    assert recv_buf == test_pkt_bytes

async def test_multiple_packets(tb):
    cocotb.log.info("Test different packets")
    test_pkt = create_udp_frame(0, USE_ETHER)

    ip_gen = RandIP()
    port_gen = RandShort()

    test_pkt["IP"].src = ip_gen._fix()
    test_pkt["IP"].dst = ip_gen._fix()
    test_pkt["UDP"].sport = port_gen._fix()
    test_pkt["UDP"].dport = port_gen._fix()

    test_pkt_bytes = bytearray(test_pkt.build())
    pad_packet(test_pkt_bytes, MIN_PKT_SIZE)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_value_1 = await receive_hash(tb)
    cpu_hash = python_hash_version(extract_hash_tuple_bytearray(test_pkt))

    assert cpu_hash.to_bytes(4, byteorder="big") == hash_value_1.buff

    await send_task
    recv_buf = await recv_task

    assert recv_buf == test_pkt_bytes

    test_pkt["IP"].src = ip_gen._fix()
    test_pkt["IP"].dst = ip_gen._fix()
    test_pkt["UDP"].sport = port_gen._fix()
    test_pkt["UDP"].dport = port_gen._fix()

    test_pkt_bytes = bytearray(test_pkt.build())
    pad_packet(test_pkt_bytes, MIN_PKT_SIZE)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_value_2 = await receive_hash(tb)
    cpu_hash = python_hash_version(extract_hash_tuple_bytearray(test_pkt))
    assert cpu_hash.to_bytes(4, byteorder="big") == hash_value_2.buff

    cocotb.log.info(f"Received hashes {hash_value_1.buff} and {hash_value_2.buff}")

    # these hashes could collide I suppose
    assert hash_value_1 != hash_value_2

    await send_task
    recv_buf = await recv_task

    assert recv_buf == test_pkt_bytes



async def receive_hash(tb):
    tb.dut.dst_hash_stall.value = 0
    await ReadOnly()
    while (tb.dut.hash_dst_hash_val.value != 1):
        await RisingEdge(tb.clk)
        await ReadOnly()

    return_hash = tb.dut.hash_dst_hash_value.value
    await RisingEdge(tb.clk)
    tb.dut.dst_hash_stall.value = 1

    return return_hash

