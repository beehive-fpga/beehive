"""Step-1 CI tests for minimal DHCP port-68 UDP bridge."""
import logging
from pathlib import Path

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.log import SimLog
from cocotb.result import SimTimeoutError
from cocotb.triggers import RisingEdge, with_timeout
from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
from scapy.packet import Raw

import sys
sys.path.append(str(Path(__file__).resolve().parent.parent / "common"))
from beehive_bus import BeehiveBus, BeehiveBusSink, BeehiveBusSource

DHCP_CLIENT_PORT = 68
OTHER_PORT = 65432


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


def pad_packet(packet_buffer, min_size=64):
    if len(packet_buffer) < min_size:
        packet_buffer.extend(bytearray(min_size - len(packet_buffer)))


def make_udp_frame(dst_port, payload_bytes):
    pkt = Ether(dst="00:0a:35:0d:4d:c6", src="b8:59:9f:b7:ba:44") / \
        IP(src="198.0.0.5", dst="198.0.0.7", flags="DF") / \
        UDP(sport=60000, dport=dst_port) / Raw(load=payload_bytes)
    data = bytearray(pkt.build())
    pad_packet(data)
    return data


class TB:
    def __init__(self, dut):
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.dut = dut
        self.MAC_W = 512
        self.CLOCK_CYCLE_TIME = 4

        self.input_bus = BeehiveBus(dut, {
            "val": "mac_engine_rx_val",
            "data": "mac_engine_rx_data",
            "startframe": "mac_engine_rx_startframe",
            "frame_size": "mac_engine_rx_frame_size",
            "endframe": "mac_engine_rx_endframe",
            "padbytes": "mac_engine_rx_padbytes",
            "rdy": "engine_mac_rx_rdy",
        })
        self.output_bus = BeehiveBus(dut, {
            "val": "engine_mac_tx_val",
            "data": "engine_mac_tx_data",
            "startframe": "engine_mac_tx_startframe",
            "frame_size": "engine_mac_tx_frame_size",
            "endframe": "engine_mac_tx_endframe",
            "padbytes": "engine_mac_tx_padbytes",
            "rdy": "mac_engine_tx_rdy",
        })
        self.input_op = BeehiveBusSource(self.input_bus, dut.clk)
        self.output_op = BeehiveBusSink(self.output_bus, dut.clk)


async def test_prep(dut, tb):
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)
    dut.mac_engine_tx_rdy.setimmediatevalue(1)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units="ns").start())
    await reset(dut)


@cocotb.test()
async def forwards_port_68_udp(dut):
    tb = TB(dut)
    await test_prep(dut, tb)

    payload = bytes([0x11, 0x22, 0x33, 0x44] * 16)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt
    assert int(pkt[UDP].dport) == DHCP_CLIENT_PORT
    assert bytes(pkt[Raw].load)[:len(payload)] == payload


@cocotb.test()
async def drops_non_port_68_udp(dut):
    tb = TB(dut)
    await test_prep(dut, tb)

    await tb.input_op.xmit_frame(make_udp_frame(OTHER_PORT, bytes([0xAA] * 32)))

    try:
        await with_timeout(tb.output_op.recv_frame(), 200_000, "ns")
    except SimTimeoutError:
        return
    raise AssertionError("Unexpected egress frame for non-port-68 traffic")
