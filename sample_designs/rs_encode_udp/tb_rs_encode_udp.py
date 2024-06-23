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
from rs_encode_req_lib import RSEncodeReqLib, RSEncodeConstants
from rs_encode_udp_bw_test import rs_encode_single_tile_bw_test
import rs_encode_stats_log_read
from rs_encode_stats_log_read import RSEncStatsLogRead, RSEncStatsLogEntry

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
        self.NUM_RS_UNITS=4


@cocotb.test()
async def test_wrapper(dut):
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

    # Create the interfaces
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    await reset(dut)

    await rs_encode_bw_test(dut, tb)

async def rs_encode_bw_test(dut, tb):
    input_filename = (os.environ["BEEHIVE_PROJECT_ROOT"] +
    "/sample_designs/rs_encode_udp/test_input_32blk.txt")
    parity_filename = (os.environ["BEEHIVE_PROJECT_ROOT"] +
    "/sample_designs/rs_encode_udp/parity_output_32blk.txt")
    await rs_encode_single_tile_bw_test(tb, input_filename, parity_filename, cycles=5000)


    # read all the logs
    log_port = 60000
    for i in range(0, 4):
        log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                    our_port = 55000,
                                    their_ip = "198.0.0.7",
                                    their_port = log_port + i)
        log_reader = RSEncStatsLogRead(8, 2, tb, log_four_tuple)
        log_entries = await log_reader.read_log()
        tb.log.debug(f"Entries: {log_entries}")
        intervals = log_reader.calculate_bws(log_entries, tb.CLOCK_CYCLE_TIME)
        tb.log.debug(intervals)

        res_dir = Path(f"./logs/rs_enc_bw_test")
        res_dir.mkdir(parents=True, exist_ok=True)
        rs_encode_stats_log_read.entries_to_csv(f"logs/rs_enc_bw_test/encoder{i}_log.csv",
                log_entries)
        await RisingEdge(dut.clk)


    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)



#@cocotb.test()
async def rs_encode_multi_block_test(dut, tb):

    for i in range(0, 4):
        tb.log.info(f"sending request {i}")
        await single_file_test(tb, os.environ["BEEHIVE_PROJECT_ROOT"] +
        "/sample_designs/rs_encode_udp/test_input_32blk.txt",
        os.environ["BEEHIVE_PROJECT_ROOT"] +
        "/sample_designs/rs_encode_udp/parity_output_32blk.txt")

    await RisingEdge(tb.clk)
    await RisingEdge(tb.clk)
    await RisingEdge(tb.clk)


#@cocotb.test()
async def rs_encode_basic_test(dut):
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

    # Create the interfaces
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    await reset(dut)

    rs_enc_lib = RSEncodeReqLib(tb.MAC_BYTES, 4)

    # Create the frame
    # read in a block of data
    block_bytes = None
    second_block = None
    with open("test_input_unpadded.txt", "r") as input_file:
        block = input_file.readline()
        block_bytes = bytes.fromhex(block)
        block = input_file.readline()
        second_block = bytes.fromhex(block)

    ref_parity_bytes = None
    second_parity = None
    with open("parity_output.txt", "r") as ref_file:
        parity = ref_file.readline()
        ref_parity_bytes = bytes.fromhex(parity)
        parity = ref_file.readline()
        second_parity = bytes.fromhex(parity)

    test_input = block_bytes * tb.NUM_RS_UNITS

    test_req = rs_enc_lib.get_rs_req_buffer(tb.NUM_RS_UNITS, test_input)

    test_udp = create_udp_frame(0)
    test_udp = test_udp/Raw(test_req)

    test_packet_bytes = bytearray(test_udp.build())
    pad_packet(test_packet_bytes, tb)

    log.info("Send a basic request")
    await tb.input_op.xmit_frame(test_packet_bytes, rand_delay=True)

    resp_bytes = await tb.output_op.recv_frame()
    resp_pkt = Ether(resp_bytes)

    ref_parity_bytes = ref_parity_bytes * tb.NUM_RS_UNITS
    resp_payload = resp_pkt["Raw"].load
    resp_len_expected = ((tb.NUM_RS_UNITS * RSEncodeConstants.BLOCK_SIZE)
                        + (RSEncodeConstants.RS_T * tb.NUM_RS_UNITS))

    assert len(resp_payload) == resp_len_expected
    # chunk into data and parity
    data = resp_payload[:tb.NUM_RS_UNITS*RSEncodeConstants.BLOCK_SIZE]
    parity = resp_payload[tb.NUM_RS_UNITS*RSEncodeConstants.BLOCK_SIZE:]

    assert data == test_input, f"expected: {test_input}\nreceived: {data}"
    assert parity == ref_parity_bytes, (f"expected: "
        f"{ref_parity_bytes}\nreceived: {parity}")

    log.info("Send a second request")
    test_input = second_block * tb.NUM_RS_UNITS
    test_req = rs_enc_lib.get_rs_req_buffer(tb.NUM_RS_UNITS, test_input)

    test_udp = create_udp_frame(0)
    test_udp = test_udp/Raw(test_req)

    test_packet_bytes = bytearray(test_udp.build())
    pad_packet(test_packet_bytes, tb)
    await tb.input_op.xmit_frame(test_packet_bytes)

    resp_bytes = await tb.output_op.recv_frame()
    resp_pkt = Ether(resp_bytes)

    ref_parity_bytes = second_parity * tb.NUM_RS_UNITS
    resp_payload = resp_pkt["Raw"].load
    assert len(resp_payload) == resp_len_expected

    data = resp_payload[:tb.NUM_RS_UNITS*RSEncodeConstants.BLOCK_SIZE]
    parity = resp_payload[tb.NUM_RS_UNITS*RSEncodeConstants.BLOCK_SIZE:]

    assert data == test_input, f"expected: {test_input}\nreceived: {data}"
    assert parity == ref_parity_bytes, (f"expected: "
        f"{ref_parity_bytes}\nreceived: {parity}")



def create_udp_frame(payload_len):
    test_packet = Ether()/IP()/UDP()
    test_packet["Ethernet"].dst = "00:0a:35:0d:4d:c6"
    test_packet["Ethernet"].src = "00:90:fb:60:e1:e7"

    test_packet["IP"].flags = "DF"
    test_packet["IP"].dst = "198.0.0.7"
    test_packet["IP"].src = "198.0.0.5"

    test_packet["UDP"].sport = 54240
    test_packet["UDP"].dport = 65432

    if payload_len != 0:
        payload_bytes = bytearray([random.randint(65, 65+26) for i in range(0, payload_len)])
        test_packet = test_packet/Raw(payload_bytes)

    return test_packet

def pad_packet(packet_buffer, tb):
    if len(packet_buffer) < tb.MIN_PKT_SIZE:
        padding = tb.MIN_PKT_SIZE - len(packet_buffer)
        pad_bytes = bytearray([0] * padding)
        packet_buffer.extend(pad_bytes)

async def single_file_test(tb, in_file, out_file):
    rs_enc_lib = RSEncodeReqLib(tb.MAC_BYTES, 4)
    data_blocks = bytearray()
    num_blocks = 0
    with open(in_file, "r") as input_file:
        for line in input_file:
            block_bytes = bytes.fromhex(line)
            data_blocks.extend(block_bytes)
            num_blocks += 1

    ref_parity = bytearray()
    with open(out_file, "r") as ref_file:
        for line in ref_file:
            parity_bytes = bytes.fromhex(line)
            ref_parity.extend(parity_bytes)

    tb.log.info(f"Send {num_blocks} block request")

    test_req = rs_enc_lib.get_rs_req_buffer(num_blocks, data_blocks)

    test_udp = create_udp_frame(0)
    test_udp = test_udp/Raw(test_req)

    test_packet_bytes = bytearray(test_udp.build())
    pad_packet(test_packet_bytes, tb)

    await tb.input_op.xmit_frame(test_packet_bytes)
    resp_bytes = await tb.output_op.recv_frame()
    resp_pkt = Ether(resp_bytes)

    resp_payload = resp_pkt["Raw"].load
    resp_len_expected = ((num_blocks * RSEncodeConstants.BLOCK_SIZE) +
                        (RSEncodeConstants.RS_T * num_blocks))

    assert len(resp_payload) == resp_len_expected

    data = resp_payload[:num_blocks*RSEncodeConstants.BLOCK_SIZE]
    parity = resp_payload[num_blocks*RSEncodeConstants.BLOCK_SIZE:]

    assert data == data_blocks, (f"expected: {data_blocks}\nreceived: "
        f"{data}")
    assert parity == ref_parity, (f"expected: "
        f"{ref_parity}\nreceived: {parity}")

