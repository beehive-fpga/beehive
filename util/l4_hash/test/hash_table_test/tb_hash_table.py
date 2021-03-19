import logging
import random
import socket

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.log import SimLog
from cocotb.queue import Queue

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
from simple_val_rdy import SimpleValRdyBusSink, SimpleValRdyBusSource

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/util/l4_hash/test")
from hash_helpers import reset, create_udp_frame, pad_packet
from hash_helpers import python_hash_version, extract_hash_tuple_bytearray

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/tile_generator/")
from tile_generator import BeehiveConfig
design_path = os.environ["BEEHIVE_DESIGN_ROOT"]

MIN_PKT_SIZE = 64
USE_ETHER = True
HASH_TABLE_DATA_W = 16
TABLE_ADDR_BITS = 4
TABLE_DEPTH = 1 << TABLE_ADDR_BITS

class HashTableBusRdFrame:
    def __init__(self, wr_en=0, hash_table_data=None, index =0):
        self.hash_table_data = BinaryValue(n_bits = HASH_TABLE_DATA_W)
        if hash_table_data is not None:
            self.hash_table_data = hash_table_data
        self.wr_en = wr_en
        self.index = index

class HashTableBusWrFrame:
    def __init__(self, index=0, data=None):
        self.data = BinaryValue(n_bits = HASH_TABLE_DATA_W)
        if data is not None:
            self.data = data
        self.index = index

class HashTableBusSource(SimpleValRdyBusSource):
    def _fill_bus_data(self, req_values):
        self._bus.index.value = index
        self._bus.data.value = data

class HashTableBusSink(SimpleValRdyBusSink):
    def _get_return_vals(self):
        if (self._bus.wr_en.value == 1):
            # data and index will be invalid in this case
            return HashTableBusRdFrame(hash_table_data=BinaryValue(0, n_bits=HASH_TABLE_DATA_W),
                                        wr_en=self._bus.wr_en.value,
                                        index=BinaryValue(0, n_bits=TABLE_ADDR_BITS))
        else:
            return HashTableBusRdFrame(hash_table_data=self._bus.data.value,
                                    wr_en=self._bus.wr_en.value,
                                    index=self._bus.index.value)

class HashTableData:
    def __init__(self, x, y, coord_bytes=1):
        self.x = x
        self.y = y
        self.coord_bytes = coord_bytes

    def from_bytearray(self, buffer):
        self.x = int.from_bytes(buffer[0:self.coord_bytes], byteorder="big")
        self.y = int.from_bytes(buffer[self.coord_bytes:(self.coord_bytes*2)],
                byteorder="big")

    def to_bytearray(self):
        buffer = bytearray([])
        buffer.extend(self.x.to_bytes(self.coord_bytes, byteorder="big"))
        buffer.extend(self.y.to_bytes(self.coord_bytes, byteorder="big"))
        return buffer

    def __eq__(self, other):
        return ((self.x == other.x) and (self.y == other.y))

    def __repr__(self):
        return f"x: {self.x}, y: {self.y}"

class TB:
    def __init__(self, dut):
        self.DATA_W = 512
        self.CLOCK_CYCLE_TIME = 4
        self.dut = dut
        self.clk = self.dut.clk
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.rand_gen = random.Random(5)
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

        self.table_rd_bus = SimpleValRdyBus(dut, {"val": "table_data_val",
                                                  "wr_en": "table_data_wr_en",
                                                  "index": "table_rd_index",
                                                  "data": "table_data",
                                                  "rdy": "table_data_rdy"})
        self.table_rd_op = HashTableBusSink(self.table_rd_bus, self.dut.clk)

        self.table_wr_bus = SimpleValRdyBus(dut, {"val": "src_hash_table_wr_en",
                                                  "index": "src_hash_table_wr_index",
                                                  "data": "src_hash_table_wr_data",
                                                  "rdy": "hash_table_src_rdy"})
        self.table_wr_op = HashTableBusSource(self.table_wr_bus, self.dut.clk)

        self.expected_table = []
        self.log.info(f"Using tile config at {design_path}")
        tile_config = BeehiveConfig(design_path + "/tile_config.xml")
        eth_rx_endpoints = tile_config.tree.findall("./endpoint/[port_name='eth_rx']")
        for i in range(0, TABLE_DEPTH):
            endpoint = eth_rx_endpoints[i % len(eth_rx_endpoints)]
            name = endpoint.find("endpoint_name").text
            (tile_x, tile_y) = tile_config.getEndpointCoords(name)
            self.expected_table.append(HashTableData(tile_x, tile_y, 1))

IP_TO_MAC = {
    "198.0.0.5": "b8:59:9f:b7:ba:44",
    "198.0.0.7": "00:90:fb:60:e1:e7",
    "198.0.0.9": "00:90:fb:60:e1:e7"
}

@cocotb.test()
async def test_hash_table(dut):
    tb = TB(dut)

    dut.src_parser_data_val.setimmediatevalue(0)
    dut.src_parser_data.setimmediatevalue(BinaryValue(n_bits=tb.DATA_W))
    dut.src_parser_padbytes.setimmediatevalue(0)
    dut.src_parser_last.setimmediatevalue(0)

    dut.src_hash_table_wr_en.setimmediatevalue(0)
    dut.src_hash_table_wr_index.setimmediatevalue(0)
    dut.src_hash_table_wr_data.setimmediatevalue(0)
    dut.table_data_rdy.setimmediatevalue(0)
    dut.dst_parser_data_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

    await test_single_packet(tb)

    await test_multiple_packets(tb, 50)

async def test_single_packet(tb):
    cocotb.log.info("Test a single packet as a basic test")
    test_pkt = create_udp_frame(0, USE_ETHER)

    test_pkt["IP"].src = "5.66.188.170"
    test_pkt["IP"].dst = "144.246.121.48"
    test_pkt["UDP"].sport = 11988
    test_pkt["UDP"].dport = 44921

    test_pkt_bytes = bytearray(test_pkt.build())
    pad_packet(test_pkt_bytes, MIN_PKT_SIZE)

    send_task = cocotb.start_soon(tb.input_op.send_buf(test_pkt_bytes))
    recv_task = cocotb.start_soon(tb.output_op.recv_frame())

    hash_table_data = await tb.table_rd_op.recv_resp()
    while (hash_table_data.wr_en == 1):
        hash_table_data = await tb.table_rd_op.recv_resp()

    check_hash_table_data(tb, hash_table_data)

    await send_task
    recv_buf = await recv_task

async def test_multiple_packets(tb, num_packets):
    cocotb.log.info("Test multiple packets for pipelining reasons")

    send_queue = Queue(0)
    send_task = cocotb.start_soon(send_multiple_packets(tb, num_packets, send_queue,
        inner_pkt_delay=4))
    recv_task = cocotb.start_soon(recv_multiple_packets(tb, num_packets, send_queue,
        inner_pkt_delay=4))

    await Combine(send_task, recv_task)



async def send_multiple_packets(tb, num_packets, send_queue, inter_pkt_delay=0,
        inner_pkt_delay=0):
    ip_gen = random.Random(42)
    port_gen = random.Random(0)

    for i in range(0, num_packets):
        test_pkt = create_udp_frame(0, USE_ETHER)
        test_pkt["IP"].src = socket.inet_ntop(socket.AF_INET, ip_gen.randbytes(4))
        test_pkt["IP"].dst = socket.inet_ntop(socket.AF_INET, ip_gen.randbytes(4))

        test_pkt["UDP"].sport = int.from_bytes(port_gen.randbytes(2),
                byteorder="big")
        test_pkt["UDP"].dport = int.from_bytes(port_gen.randbytes(2),
                byteorder="big")

        test_pkt_bytes = bytearray(test_pkt.build())
        pad_packet(test_pkt_bytes, MIN_PKT_SIZE)
        send_queue.put_nowait(test_pkt)

        await tb.input_op.send_buf(test_pkt_bytes, inner_pkt_delay)

        # delay for a bit
        delay = tb.rand_gen.randint(0, inter_pkt_delay)
        if (delay != 0):
            await ClockCycles(tb.clk, delay)

async def recv_multiple_packets(tb, num_packets, send_queue, inter_pkt_delay=0,
        inner_pkt_delay=0):
    for i in range(0, num_packets):
        while send_queue.empty():
            await RisingEdge(tb.clk)

        test_pkt = send_queue.get_nowait()
        # await the hash value
        hash_value = await tb.table_rd_op.recv_resp()

        # check we got the right index
        expected_hash_index = python_hash_version(extract_hash_tuple_bytearray(test_pkt))
        expected_hash_index = (~(0xffffffff << 4)) & expected_hash_index
        if (expected_hash_index != hash_value.index):
            tb.log.error((f"Expected index: {expected_hash_index} "
                f"Got: {hash_value.index}"))
            tb.log.info(f"src_ip: {test_pkt['IP'].src} "
                           f"src_port: {test_pkt['UDP'].sport} "
                           f"dst_ip: {test_pkt['IP'].dst} "
                           f"dst_port: {test_pkt['UDP'].dport}")
            raise RuntimeError()

        # check we got the right table value
        check_hash_table_data(tb, hash_value)

        # alright, now await the data buf
        expected_pkt_bytes = bytearray(test_pkt.build())
        pad_packet(expected_pkt_bytes, MIN_PKT_SIZE)
        recv_pkt = await tb.output_op.recv_frame()

        assert recv_pkt == expected_pkt_bytes

        # maybe delay
        delay = tb.rand_gen.randint(0, inner_pkt_delay)
        if (delay != 0):
            await ClockCycles(tb.clk, delay)



def check_hash_table_data(tb, hash_table_data):
    expected = tb.expected_table[hash_table_data.index]

    received = HashTableData(0, 0, 1)
    received.from_bytearray(hash_table_data.hash_table_data.buff)

    assert expected == received, f"Expected: {expected}, received: {received}"



