import logging
import random
import collections
from collections import deque
from pathlib import Path

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, First, Event
from cocotb.triggers import ClockCycles, with_timeout
from cocotb.log import SimLog
from cocotb.utils import get_sim_time
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/util/l4_hash/test/")
from hash_helpers import extract_hash_tuple_bytearray, python_hash_version

from tcp_driver import TCPFourTuple
import udp_app_log_read
import eth_latency_log_read
from udp_app_log_read import UDPAppLogRead, UDPAppLogEntry
from eth_latency_log_read import EthLatencyLogRead, EthLatencyLogEntry

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
        self.dut = dut
        self.input_bus = BeehiveBus(dut, {"val": "mac_engine_rx_val",
                                     "data": "mac_engine_rx_data",
                                     "startframe": "mac_engine_rx_startframe",
                                     "frame_size": "mac_engine_rx_frame_size",
                                     "endframe": "mac_engine_rx_endframe",
                                     "padbytes": "mac_engine_rx_padbytes",
                                     "rdy": "engine_mac_rx_rdy"})
        self.input_op = BeehiveBusSource(self.input_bus, dut.clk)

        self.output_bus = BeehiveBus(dut, {"val": "engine_mac_tx_val",
                                      "startframe": "engine_mac_tx_startframe",
                                      "frame_size": "engine_mac_tx_frame_size",
                                      "data": "engine_mac_tx_data",
                                      "endframe": "engine_mac_tx_endframe",
                                      "padbytes": "engine_mac_tx_padbytes",
                                      "rdy": "mac_engine_tx_rdy"})
        self.output_op = BeehiveBusSink(self.output_bus, dut.clk)

        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.IP_TO_MAC = {
            "198.0.0.5": "b8:59:9f:b7:ba:44",
            "198.0.0.7": "00:0a:35:0d:4d:c6"
        }
        self.clk = dut.clk

        self.MAC_W = 512
        self.MAC_BYTES = int(self.MAC_W/8)
        self.MIN_PKT_SIZE=64
        self.MSS_SIZE=9100
        self.CLOCK_CYCLE_TIME = 4

@cocotb.test()
async def bus_test(dut):
    log = SimLog("cocotb.tb")
    log.setLevel(logging.DEBUG)
    random.seed(42)

    tb = TB(dut)

    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

#   await basic_test(tb)
#   await packet_size_test(tb)
    await bandwidth_log_test(tb)

async def bandwidth_log_test(tb):
    tb.pkts = {}
    done_event = Event()

    send_task = cocotb.start_soon(send_loop(tb, 20000, 64, done_event))
    recv_task = cocotb.start_soon(recv_loop(tb, done_event))

    packet_times = await send_task
    await recv_task

    log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                our_port = 55000,
                                their_ip = "198.0.0.7",
                                their_port = 60000)
    log_reader = UDPAppLogRead(8, 2, tb, log_four_tuple)

    log_entries = await log_reader.read_log()
    #tb.log.debug(log_entries)
    intervals = log_reader.calculate_bws(log_entries, tb.CLOCK_CYCLE_TIME)
    tb.log.debug(intervals)

    #tb.log.debug(packet_times)
    #ref_intervals = log_reader.calculate_bws(packet_times, tb.CLOCK_CYCLE_TIME)
    #tb.log.debug(ref_intervals)
    #tb.log.debug(f"avg: {(sum(ref_intervals)*1.0)/len(ref_intervals)}")

    log_four_tuple2 = TCPFourTuple(our_ip = "198.0.0.5",
                                our_port = 55000,
                                their_ip = "198.0.0.7",
                                their_port = 60002)
    log_reader2 = UDPAppLogRead(8, 2, tb, log_four_tuple2)
    log_entries2 = await log_reader2.read_log()
    intervals2 = log_reader.calculate_bws(log_entries2, tb.CLOCK_CYCLE_TIME)
    tb.log.debug(intervals2)

    await RisingEdge(tb.clk)
    await RisingEdge(tb.clk)
    await RisingEdge(tb.clk)


async def recv_event_wrapper(tb, event, pause_len):
    res = await tb.output_op.recv_frame(pause_len=pause_len)
    event.set(data=res)

async def recv_loop(tb, done_event):
    requests_recv = 0
    res = 0

    await ClockCycles(tb.dut.clk, 10000)

    while not done_event.is_set():
        tb.log.info(f"Waiting for request {requests_recv}")

        recv_event = Event()
        recv_frame_task = cocotb.start_soon(recv_event_wrapper(tb, recv_event, 0))

        res = await recv_frame_task

        tb.log.info("Got pkt")

        recv_pkt = Ether(recv_event.data)
        hash_tuple = TCPFourTuple(our_ip=recv_pkt["IP"].dst,
                                our_port=recv_pkt["UDP"].dport,
                                their_ip=recv_pkt["IP"].src,
                                their_port=recv_pkt["UDP"].sport)

        sent_pkt = tb.pkts[hash_tuple].popleft()

        test_packet_bytes = bytearray(sent_pkt.build())
        pad_packet(tb, test_packet_bytes)
        check_udp_frame(recv_event.data, test_packet_bytes)

        requests_recv += 1

    res = done_event.data

    tb.log.info(f"Requests sent {res}")
    while requests_recv <= res:
        tb.log.info(f"Waiting for remaining request {requests_recv}")
        pkt_buf = await tb.output_op.recv_frame(pause_len=0)
        recv_pkt = Ether(pkt_buf)
        hash_tuple = TCPFourTuple(our_ip=recv_pkt["IP"].dst,
                                our_port=recv_pkt["UDP"].dport,
                                their_ip=recv_pkt["IP"].src,
                                their_port=recv_pkt["UDP"].sport)

        sent_pkt = tb.pkts[hash_tuple].popleft()
        test_packet_bytes = bytearray(sent_pkt.build())
        pad_packet(tb, test_packet_bytes)
        check_udp_frame(pkt_buf, test_packet_bytes)
        requests_recv += 1

async def send_loop(tb, run_cycles, req_size, done_event):
    packet_times = []
    tot_bytes = 0

    init_time = get_sim_time(units='ns')
    cycles_elapsed = 0
    requests_sent = 0

    ip_gen = random.Random(3)
    port_gen = random.Random(2)

    while cycles_elapsed < run_cycles:
        tb.log.info(f"Sending request {requests_sent}")
        send_pkt = create_udp_frame(req_size)

        if (requests_sent % 2) == 0:
            # send to the other chain
            send_pkt["UDP"].sport = 60001

        test_pkt_bytes = bytearray(send_pkt.build())
        pad_packet(tb, test_pkt_bytes)
        hash_tuple = TCPFourTuple(our_ip=send_pkt["IP"].src,
                                our_port=send_pkt["UDP"].sport,
                                their_ip=send_pkt["IP"].dst,
                                their_port=send_pkt["UDP"].dport)
#        print(hash_tuple)
        if hash_tuple not in tb.pkts:
            tb.pkts[hash_tuple] = deque()
        tb.pkts[hash_tuple].append(send_pkt)

        await tb.input_op.xmit_frame(test_pkt_bytes)

        start_time_ns = get_sim_time(units='ns')
        tot_bytes += req_size

        cycles = int((start_time_ns)/tb.CLOCK_CYCLE_TIME)
        cycles_bytes = cycles.to_bytes(UDPAppLogEntry.TIMESTAMP_BYTES,
                byteorder="big")
        tot_bytes_bytes = tot_bytes.to_bytes(UDPAppLogEntry.BYTES_RECV_BYTES,
                byteorder="big")

        entry_bytearray = cycles_bytes + tot_bytes_bytes
        packet_times.append(UDPAppLogEntry(entry_bytearray))
        cycles_elapsed = int((get_sim_time(units='ns') - init_time)/tb.CLOCK_CYCLE_TIME)
        requests_sent += 1

    tb.log.info(f"Send {requests_sent}")
    done_event.set(data=requests_sent-1)
    return packet_times

async def basic_test(tb):
    tb.log.info("Send a basic packet")
    test_udp = create_udp_frame(1)
    test_packet_bytes = bytearray(test_udp.build())
    pad_packet(tb, test_packet_bytes)

    await tb.input_op.xmit_frame(test_packet_bytes, rand_delay=False)

    echoed_pkt_bytes = await tb.output_op.recv_frame()

    check_udp_frame(echoed_pkt_bytes, test_packet_bytes)

    tb.log.info("Send a packet that (hopefully) hashes to a different flow")

    second_frame = test_udp.copy()
    second_frame["IP"].sport = 60001
    second_frame_bytes = bytearray(second_frame.build())
    pad_packet(tb, second_frame_bytes)

    await tb.input_op.xmit_frame(second_frame_bytes, rand_delay=False)

    echoed_bytes = await tb.output_op.recv_frame()

    check_udp_frame(echoed_bytes, second_frame_bytes)

async def packet_size_test(tb):
    tb.log.info("Send a range of sizes with different addresses and ports");
    ip_gen = random.Random(3)
    port_gen = random.Random(2)

    for i in range(1, 129):
        tb.log.info(f"Sending packet of size {i}")
        test_pkt = create_udp_frame(i)

        test_pkt["IP"].src = socket.inet_ntop(socket.AF_INET, ip_gen.randbytes(4))
        test_pkt["IP"].dst = socket.inet_ntop(socket.AF_INET, ip_gen.randbytes(4))

        test_pkt["UDP"].sport = int.from_bytes(port_gen.randbytes(2),
                byteorder="big")
        # don't change the destination port; we need it to get the echo

        test_pkt_bytes = bytearray(test_pkt.build())
        pad_packet(tb, test_pkt_bytes)

        await tb.input_op.xmit_frame(test_pkt_bytes, rand_delay=True)

        echoed_bytes = await tb.output_op.recv_frame()

        # patch up the Ethernet address: because we randomized the IP, we're
        # not going to have proper Ethernet address lookup
        echoed_pkt = Ether(echoed_bytes)
        echoed_pkt["Ethernet"].src = test_pkt["Ethernet"].dst
        echoed_bytes = echoed_pkt.build()

        check_udp_frame(echoed_bytes, test_pkt_bytes)

def check_udp_frame(output_pkt_bytes, test_udp_bytes):
    output_pkt = Ether(output_pkt_bytes)
    test_udp = Ether(test_udp_bytes)
    if "Padding" in output_pkt:
        del(output_pkt["Padding"])
    if "Padding" in test_udp:
        del(test_udp["Padding"])

    out_bytes = output_pkt.build()
    test_bytes = test_udp.build()

    assert len(out_bytes) == len(test_bytes)

    assert output_pkt["Ethernet"].dst == test_udp["Ethernet"].src
    assert output_pkt["Ethernet"].src == test_udp["Ethernet"].dst

    assert output_pkt["IP"].dst == test_udp["IP"].src, (f"Expected: "
            f"{test_udp['IP'].src}, Received: {output_pkt['IP'].dst}")
    assert output_pkt["IP"].src == test_udp["IP"].dst

    assert output_pkt["UDP"].sport == test_udp["UDP"].dport
    assert output_pkt["UDP"].dport == test_udp["UDP"].sport

    assert output_pkt["UDP"].payload == test_udp["UDP"].payload

def create_udp_frame(payload_len):
    test_packet = Ether()/IP()/UDP()
    test_packet["Ethernet"].dst = "00:0a:35:0d:4d:c6"
    test_packet["Ethernet"].src = "b8:59:9f:b7:ba:44"

    test_packet["IP"].flags = "DF"
    test_packet["IP"].dst = "198.0.0.7"
    test_packet["IP"].src = "198.0.0.5"

    test_packet["UDP"].sport = 54240
    test_packet["UDP"].dport = 65432

    payload_bytes = bytearray([random.randint(65, 65+26) for i in range(0, payload_len)])
    test_packet = test_packet/Raw(payload_bytes)

    return test_packet

def pad_packet(tb, packet_buffer):
    if len(packet_buffer) < tb.MIN_PKT_SIZE:
        padding = tb.MIN_PKT_SIZE - len(packet_buffer)
        pad_bytes = bytearray([0] * padding)
        packet_buffer.extend(pad_bytes)
