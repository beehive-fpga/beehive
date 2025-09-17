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

HASH_DATA_WIDTH = 96
ETH_IPv4 = 0x800
IP_TCP = 6
IP_UDP = 17
MIN_PKT_SIZE = 64
USE_ETHER = True

class HashBusFrame:
    def __init__(self, hash_data=b'', hash_val=0):
        self.hash_data = BinaryValue(n_bits = HASH_DATA_WIDTH)
        self.hash_data.buff = hash_data
        self.hash_val = hash_val

class HashBusSink(SimpleValRdyBusSink):
    def _get_return_vals(self):
        return HashBusFrame(hash_data=bytes(self._bus.hash_data.value.buff),
                            hash_val = self._bus.hash_val.value)

class TB:
    def __init__(self, dut):
        self.DATA_W = 512
        self.CLOCK_CYCLE_TIME = 4
        self.dut = dut
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
        self.hash_bus = SimpleValRdyBus(dut, {"val": "parser_dst_meta_val",
                                            "hash_data": "parser_dst_hash_data",
                                            "hash_val": "parser_dst_hash_val",
                                            "rdy": "dst_parser_meta_rdy"})
        self.hash_op = HashBusSink(self.hash_bus, self.dut.clk)

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
async def test_parser(dut):
    tb = TB(dut)

    # set initial values
    dut.src_parser_data_val.setimmediatevalue(0)
    dut.src_parser_data.setimmediatevalue(BinaryValue(value=0,
        n_bits=tb.DATA_W))
    dut.src_parser_padbytes.setimmediatevalue(0)
    dut.src_parser_last.setimmediatevalue(0)

    dut.dst_parser_meta_rdy.setimmediatevalue(0)

    dut.dst_parser_data_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

    await test_single_hdr(tb)

    await test_multiple_hdr(tb, 5)

    await payload_tests(tb)

    if (USE_ETHER):
        await bad_protocol_test(tb)

async def test_single_hdr(tb):
    cocotb.log.info("Testing a single header stack")

    test_pkt = create_udp_frame(0)
    test_pkt_bytes = bytearray(test_pkt.build())
    pad_packet(test_pkt_bytes)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_frame = await tb.hash_op.recv_resp()

    cocotb.log.info("Checking hash struct")
    check_hash(hash_frame, test_pkt)
    await send_task
    recv_buf = await recv_task

    assert recv_buf == test_pkt_bytes

async def test_multiple_hdr(tb, num_packets):
    cocotb.log.info(f"Testing {num_packets} header stacks")
    test_pkt = create_udp_frame(0)

    ip_gen = RandIP()
    port_gen = RandShort()


    for i in range(0, num_packets):
        # randomise the ports and ip addresses
        test_pkt["IP"].src = ip_gen._fix()
        test_pkt["IP"].dst = ip_gen._fix()
        test_pkt["UDP"].sport = port_gen._fix()
        test_pkt["UDP"].dport = port_gen._fix()
        test_pkt_bytes = bytearray(test_pkt.build())
        pad_packet(test_pkt_bytes)

        send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
        recv_task = cocotb.start_soon(tb.output_op.recv_frame())

        hash_frame = await tb.hash_op.recv_resp()

        check_hash(hash_frame, test_pkt)

        await send_task

        recv_buf = await recv_task

        assert recv_buf == test_pkt_bytes

async def payload_tests(tb):
    cocotb.log.info(f"Testing different frames with payload")

    for i in range(1, 129):
        test_pkt = create_udp_frame(i)

        test_pkt_bytes = bytearray(test_pkt.build())
        pad_packet(test_pkt_bytes)
        send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
        recv_task = cocotb.start_soon(tb.output_op.recv_frame())

        hash_frame = await tb.hash_op.recv_resp()

        check_hash(hash_frame, test_pkt)

        await send_task

        recv_buf = await recv_task

        assert recv_buf == test_pkt_bytes

async def bad_protocol_test(tb):
    cocotb.log.info(f"Testing ARP as a non-steerable protocol")

    test_arp = create_arp_frame()
    test_arp_bytes = bytearray(test_arp.build())
    pad_packet(test_arp_bytes)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_arp_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_frame = await tb.hash_op.recv_resp()

    check_hash(hash_frame, test_arp)

    await send_task

    recv_buf = await recv_task

    assert recv_buf == test_arp_bytes

def check_hash(hash_frame, test_pkt):
    # if it has an Ethernet header
    correct_protocols = False
    if "Ethernet" in test_pkt:
        correct_protocols = ((test_pkt["Ethernet"].type == ETH_IPv4)
                            and ((test_pkt["IP"].proto == IP_TCP)
                                or (test_pkt["IP"].proto == IP_UDP)))
    else:
        correct_protocols = ((test_pkt["IP"].proto == IP_TCP)
                            or (test_pkt["IP"].proto == IP_UDP))

    assert correct_protocols == hash_frame.hash_val

    if not correct_protocols:
        return

    hash_bytes = hash_frame.hash_data.buff

    src_ip = hash_bytes[0:4]
    dst_ip = hash_bytes[4:8]
    src_port = hash_bytes[8:10]
    dst_port = hash_bytes[10:12]

    test_pkt_src_port = 0
    test_pkt_dst_port = 0

    if "TCP" in test_pkt:
        test_pkt_src_port = test_pkt["TCP"].sport
        test_pkt_dst_port = test_pkt["TCP"].dport
    if "UDP" in test_pkt:
        test_pkt_src_port = test_pkt["UDP"].sport
        test_pkt_dst_port = test_pkt["UDP"].dport

    assert socket.inet_ntop(socket.AF_INET, src_ip) == test_pkt["IP"].src
    assert socket.inet_ntop(socket.AF_INET, dst_ip) == test_pkt["IP"].dst

    assert int.from_bytes(src_port, byteorder="big") == test_pkt_src_port
    assert int.from_bytes(dst_port, byteorder="big") == test_pkt_dst_port


def create_udp_frame(payload_len):
    test_packet = None
    if USE_ETHER:
        test_packet = Ether()/IP()/UDP()
        test_packet["Ethernet"].dst = "00:0a:35:0d:4d:c6"
        test_packet["Ethernet"].src = "00:90:fb:60:e1:e7"
    else:
        test_packet = IP()/UDP()

    test_packet["IP"].flags = "DF"
    test_packet["IP"].dst = "198.0.0.7"
    test_packet["IP"].src = "198.0.0.5"

    test_packet["UDP"].sport = 54240
    test_packet["UDP"].dport = 65432

    payload_bytes = bytearray([random.randint(65, 65+26) for i in range(0, payload_len)])
    test_packet = test_packet/Raw(payload_bytes)

    return test_packet

def pad_packet(packet_buffer):
    if len(packet_buffer) < MIN_PKT_SIZE:
        padding = MIN_PKT_SIZE - len(packet_buffer)
        pad_bytes = bytearray([0] * padding)
        packet_buffer.extend(pad_bytes)

def create_arp_frame():
    arp_dummy = Ether()/ARP()
    arp_dummy["Ethernet"].src = "e0:07:1b:6f:fc:c1"
    arp_dummy["Ethernet"].dst = "ff:ff:ff:ff:ff:ff"

    arp_dummy["ARP"].hwsrc = arp_dummy["Ethernet"].src
    arp_dummy["ARP"].hwdst = "ff:ff:ff:ff:ff:ff"
    arp_dummy["ARP"].psrc = "198.0.0.5"
    arp_dummy["ARP"].pdst =  "198.0.0.7"

    return arp_dummy

