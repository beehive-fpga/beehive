import logging
import random
import collections
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

from tcp_driver import TCPFourTuple
import udp_app_log_read
import eth_latency_log_read
from udp_app_log_read import UDPAppLogRead, UDPAppLogEntry
from eth_latency_log_read import EthLatencyLogRead, EthLatencyLogEntry

MAC_W = 512
MAC_BYTES = int(MAC_W/8)
MIN_PKT_SIZE=64
MSS_SIZE=9100
CLOCK_CYCLE_TIME = 4

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

async def recv_event_wrapper(tb, event, delay):
    res = await tb.output_op.recv_frame()
    event.set(data=res)


async def recv_loop(tb, done_event):
    requests_recv = 0
    res = 0
    random_generator = random.Random(10)

#    await ClockCycles(tb.dut.clk, 5000)

    while not done_event.is_set():
        tb.log.info(f"Waiting for request {requests_recv}")
        delay = random_generator.randint(0, 10)

        recv_event = Event()
        recv_frame_task = cocotb.start_soon(recv_event_wrapper(tb, recv_event,
            delay))
        res = await recv_frame_task

        # did we get data?
        pkt = tb.pkts.popleft()
        recv_pkt = pkt.copy()
        max_udp_pkt_bytes = bytearray(recv_pkt.build())
        pad_packet(max_udp_pkt_bytes)
        check_udp_frame(recv_event.data, max_udp_pkt_bytes)
        requests_recv += 1

    res = done_event.data

    tb.log.info(f"Requests sent {res}")
    while requests_recv <= res:
        tb.log.info(f"Waiting for remaining request {requests_recv}")
        delay = random_generator.randint(0, 10)
        pkt_buf = await tb.output_op.recv_frame(pause_len=delay)
        recv_pkt = tb.pkts.popleft()
        max_udp_pkt_bytes = bytearray(recv_pkt.build())
        pad_packet(max_udp_pkt_bytes)
        check_udp_frame(pkt_buf, max_udp_pkt_bytes)
        requests_recv += 1

async def send_loop(tb, run_cycles, req_size, done_event):
    packet_times = []
    tot_bytes = 0

    init_time = get_sim_time(units='ns')
    cycles_elapsed = 0
    requests_sent = 0
    max_udp_pkt = create_udp_frame(req_size)

    while cycles_elapsed < run_cycles:
        tb.log.info(f"Sending request {requests_sent}")
        max_udp_pkt_bytes = bytearray(max_udp_pkt.build())
        pad_packet(max_udp_pkt_bytes)
        tb.pkts.append(max_udp_pkt)
        await tb.input_op.xmit_frame(max_udp_pkt_bytes, rand_delay=False)

        start_time_ns = get_sim_time(units='ns')
        tot_bytes += req_size

        cycles = int((start_time_ns)/CLOCK_CYCLE_TIME)
        cycles_bytes = cycles.to_bytes(UDPAppLogEntry.TIMESTAMP_BYTES, byteorder="big")
        tot_bytes_bytes = tot_bytes.to_bytes(UDPAppLogEntry.BYTES_RECV_BYTES,
                        byteorder="big")
        entry_bytearray = cycles_bytes + tot_bytes_bytes
        packet_times.append(UDPAppLogEntry(entry_bytearray))

        cycles_elapsed = int((get_sim_time(units='ns') - init_time)/CLOCK_CYCLE_TIME)
        requests_sent += 1

    tb.log.info(f"Send {requests_sent}")
    done_event.set(data=requests_sent-1)

    return packet_times


#@cocotb.test()
async def latency_log_test(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, CLOCK_CYCLE_TIME, units='ns').start())
    tb = TB(dut)
    await reset(dut)

    latencies = []
    test_udp = create_udp_frame(2)
    test_udp_bytes = bytearray(test_udp.build())
    pad_packet(test_udp_bytes)
    for i in range(0, 10):
        await RisingEdge(dut.clk)
        start_time = get_sim_time(units="ns")
        await tb.input_op.xmit_frame(test_udp_bytes, rand_delay=False)
        recv_pkt = await tb.output_op.recv_frame()
        end_time = get_sim_time(units="ns")
        latencies.append(end_time-start_time)

    log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                our_port = 55000,
                                their_ip = "198.0.0.7",
                                their_port = 60001)
    log_reader = EthLatencyLogRead(10, 2, tb, log_four_tuple)

    log_entries = await log_reader.read_log()
    print(log_entries)
    tb.log.debug(log_entries)
    tb.log.debug(latencies)

    res_dir = Path(f"./logs/latency_test")
    res_dir.mkdir(parents=True, exist_ok=True)
    eth_latency_log_read.entries_to_csv(f"logs/latency_test/latency_log.csv", log_entries)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

#@cocotb.test()
async def bandwidth_log_test(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, CLOCK_CYCLE_TIME, units='ns').start())
    tb = TB(dut)
    await reset(dut)

    tb.pkts = collections.deque()
    done_event = Event()
    send_task = cocotb.start_soon(send_loop(tb, 1000, 64, done_event))
    recv_task = cocotb.start_soon(recv_loop(tb, done_event))

    packet_times = await send_task
    await recv_task

    log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                our_port = 55000,
                                their_ip = "198.0.0.7",
                                their_port = 60000)
    log_reader = UDPAppLogRead(8, 2, tb, log_four_tuple)

    log_entries = await log_reader.read_log()
    tb.log.debug(log_entries)
    intervals = log_reader.calculate_bws(log_entries, CLOCK_CYCLE_TIME)
    tb.log.debug(intervals)

    ref_intervals = log_reader.calculate_bws(packet_times, CLOCK_CYCLE_TIME)
    tb.log.debug(ref_intervals)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

@cocotb.test()
async def bus_test(dut):
    log = SimLog("cocotb.tb")
    log.setLevel(logging.DEBUG)
    random.seed(42)
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    # Create the interfaces
    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())
    tb = TB(dut)

    await reset(dut)

    test_udp = create_udp_frame(14)
    test_packet_bytes = bytearray(test_udp.build())

    log.info(f"length: {len(test_packet_bytes)}")
    pad_packet(test_packet_bytes)

    log.info("Send a basic packet")
    await tb.input_op.xmit_frame(test_packet_bytes, rand_delay=True)

    echoed_pkt_bytes = await tb.output_op.recv_frame()

    check_udp_frame(echoed_pkt_bytes, test_packet_bytes)

    await RisingEdge(dut.clk)

    # Try a frame being sent to the wrong port
    log.info("Send a packet to the wrong port")
    test_wrong_port = test_udp.copy()
    test_wrong_port["UDP"].dport = 40000
    test_wrong_port_bytes = bytearray(test_wrong_port.build())
    pad_packet(test_wrong_port_bytes)

    await tb.input_op.xmit_frame(test_wrong_port.build(), rand_delay=True)

    # Immediately send a packet to the right port and make sure the echo
    # we get back is for that packet
    log.info("Make sure that we can still echo")
    test_right_port = test_udp.copy()
    new_payload = bytearray([i + 45 for i in range(0, 64)])
    test_right_port["Raw"].load = new_payload

    test_right_port_bytes = bytearray(test_right_port.build())
    pad_packet(test_right_port_bytes)

    await tb.input_op.xmit_frame(test_right_port_bytes, rand_delay=True)

    echoed_right_pkt_bytes = await tb.output_op.recv_frame()
    check_udp_frame(echoed_right_pkt_bytes, test_right_port.build())

    await RisingEdge(dut.clk)

    # Try a frame that isn't UDP
    log.info("Send a packet that isn't UDP")
    tcp_dummy = create_tcp_frame()
    tcp_dummy_bytes = bytearray(tcp_dummy.build())
    pad_packet(tcp_dummy_bytes)

    await tb.input_op.xmit_frame(tcp_dummy_bytes, rand_delay=True)

    # Immediately send an actual UDP packet and make sure the echo
    # we get back is for that packet
    # Check that we can still echo
    log.info("Echo again")
    test_right_protocol = test_udp.copy()
    new_payload = bytearray([ord('b')]*71)
    test_right_protocol["Raw"].load = new_payload

    test_right_protocol_bytes = bytearray(test_right_protocol.build())
    pad_packet(test_right_protocol_bytes)

    await tb.input_op.xmit_frame(test_right_protocol_bytes, rand_delay=True)

    echoed_right_protocol_bytes = await tb.output_op.recv_frame()
    check_udp_frame(echoed_right_protocol_bytes, test_right_protocol.build())

    await RisingEdge(dut.clk)

    # Try a frame that isn't IP
    log.info("Send a packet that isn't IP")
    arp_dummy = create_arp_frame()
    arp_dummy_bytes = bytearray(arp_dummy.build())
    pad_packet(arp_dummy_bytes)

    await tb.input_op.xmit_frame(arp_dummy_bytes, rand_delay=True)

    log.info("Echo normal again")
    test_right_packet = test_udp.copy()
    new_payload = bytearray("deadbeef", "utf8") * 10
    test_right_packet["Raw"].load = new_payload
    test_right_packet_bytes = bytearray(test_right_packet.build())
    pad_packet(test_right_packet_bytes)

    await tb.input_op.xmit_frame(test_right_packet_bytes, rand_delay=True)
    echoed_right_pkt_bytes = await tb.output_op.recv_frame()
    check_udp_frame(echoed_right_pkt_bytes, test_right_packet.build())

    await RisingEdge(dut.clk)

    log.info("Send a range of packet sizes")
    for i in range(1, 128):
        log.info(f"Trying packet size {i}")
        test_udp = create_udp_frame(i)
        test_packet_bytes = bytearray(test_udp.build())
        pad_packet(test_packet_bytes)

        await tb.input_op.xmit_frame(test_packet_bytes, rand_delay=True)

        echoed_pkt_bytes = await tb.output_op.recv_frame()

        check_udp_frame(echoed_pkt_bytes, test_packet_bytes)

        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)

    log.info("Send a max-sized packet")
    max_payload = MSS_SIZE - 14 - 20 - 8
    max_udp_pkt = create_udp_frame(max_payload)
    max_udp_pkt_bytes = bytearray(max_udp_pkt.build())
    pad_packet(max_udp_pkt_bytes)

    await tb.input_op.xmit_frame(max_udp_pkt_bytes, rand_delay=False)
    echoed_bytes = await tb.output_op.recv_frame()
    check_udp_frame(echoed_bytes, max_udp_pkt_bytes)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)


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

    assert output_pkt["Ethernet"].dst == "00:90:fb:60:e1:e7"
    assert output_pkt["Ethernet"].src == test_udp["Ethernet"].dst

    assert output_pkt["IP"].dst == test_udp["IP"].src
    assert output_pkt["IP"].src == test_udp["IP"].dst

    assert output_pkt["UDP"].sport == test_udp["UDP"].dport
    assert output_pkt["UDP"].dport == test_udp["UDP"].sport

    assert output_pkt["UDP"].payload == test_udp["UDP"].payload

def create_arp_frame():
    arp_dummy = Ether()/ARP()
    arp_dummy["Ethernet"].src = "e0:07:1b:6f:fc:c1"
    arp_dummy["Ethernet"].dst = "ff:ff:ff:ff:ff:ff"

    arp_dummy["ARP"].hwsrc = arp_dummy["Ethernet"].src
    arp_dummy["ARP"].hwdst = "ff:ff:ff:ff:ff:ff"
    arp_dummy["ARP"].psrc = "198.0.0.5"
    arp_dummy["ARP"].pdst =  "198.0.0.7"

    return arp_dummy

def create_tcp_frame():
    tcp_dummy = Ether()/IP()/TCP()
    tcp_dummy["Ethernet"].dst = "24:be:05:bf:5b:91"
    tcp_dummy["Ethernet"].src = "e0:07:1b:6f:fc:c1"

    tcp_dummy["IP"].flags = "DF"
    tcp_dummy["IP"].dst = "198.0.0.7"
    tcp_dummy["IP"].src = "198.0.0.5"

    tcp_dummy["TCP"].sport = 54240
    tcp_dummy["TCP"].dport = 65432
    tcp_dummy["TCP"].flags = "SA"

    return tcp_dummy

def create_udp_frame(payload_len):
    test_packet = Ether()/IP()/UDP()
    test_packet["Ethernet"].dst = "00:0a:35:0d:4d:c6"
    test_packet["Ethernet"].src = "00:90:fb:60:e1:e7"

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
