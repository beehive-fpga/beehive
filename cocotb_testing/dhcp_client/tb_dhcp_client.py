"""Step-1 CI tests for minimal DHCP port-68 UDP bridge."""
import logging
from pathlib import Path

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.log import SimLog
from cocotb.result import SimTimeoutError
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
from scapy.packet import Raw

import sys
sys.path.append(str(Path(__file__).resolve().parent.parent / "common"))
from beehive_bus import BeehiveBus, BeehiveBusSink, BeehiveBusSource
from dhcp_pkts import (
    build_dhcp_offer,
    DHCP_MSG_OFFER,
    DHCP_OP_BOOTREPLY,
    DHCP_SERVER_PORT,
)

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


@cocotb.test()
async def forwards_multiflit_port_68_udp(dut):
    """Port-68 frame whose UDP payload spans several 64-byte flits."""
    tb = TB(dut)
    await test_prep(dut, tb)

    payload = bytes([i & 0xFF for i in range(256)])
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt
    assert int(pkt[UDP].dport) == DHCP_CLIENT_PORT
    assert bytes(pkt[Raw].load)[:len(payload)] == payload


@cocotb.test()
async def forwards_two_consecutive_frames(dut):
    """FSM must return to WAIT_META cleanly between two back-to-back port-68 frames."""
    tb = TB(dut)
    await test_prep(dut, tb)

    payloads = [bytes([0x11] * 40), bytes([0x22] * 40)]
    for p in payloads:
        await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, p))

    for expected in payloads:
        frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
        pkt = Ether(frame)
        assert UDP in pkt
        assert int(pkt[UDP].dport) == DHCP_CLIENT_PORT
        assert bytes(pkt[Raw].load)[:len(expected)] == expected


@cocotb.test()
async def drops_port_67_udp(dut):
    """DHCP server port must be dropped (client tile only accepts port 68)."""
    tb = TB(dut)
    await test_prep(dut, tb)

    await tb.input_op.xmit_frame(make_udp_frame(67, bytes([0xCC] * 32)))

    try:
        await with_timeout(tb.output_op.recv_frame(), 200_000, "ns")
    except SimTimeoutError:
        return
    raise AssertionError("Unexpected egress frame for port-67 traffic")


@cocotb.test()
async def forwards_under_tx_backpressure(dut):
    """Hold egress rdy low so backpressure propagates back through the pipeline;
    then release rdy and verify the frame still arrives intact."""
    tb = TB(dut)
    await test_prep(dut, tb)

    # Stall the egress before the frame is injected so the MAC-TX side
    # back-pressures the whole tx pipeline (ip_tx/udp_tx/dhcp_tile/...).
    dut.mac_engine_tx_rdy.value = 0

    payload = bytes([i & 0xFF for i in range(64)])
    xmit_task = cocotb.start_soon(
        tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload))
    )

    # Hold backpressure for a meaningful window, then let recv_frame raise rdy.
    await ClockCycles(dut.clk, 50)

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    await xmit_task

    pkt = Ether(frame)
    assert UDP in pkt
    assert int(pkt[UDP].dport) == DHCP_CLIENT_PORT
    assert bytes(pkt[Raw].load)[:len(payload)] == payload


@cocotb.test()
async def reset_mid_forward(dut):
    """Pulse reset mid-frame, then verify a fresh frame is forwarded normally."""
    tb = TB(dut)
    await test_prep(dut, tb)

    # Start a long frame, then reset before it can finish.
    payload_a = bytes([0xAB] * 256)
    xmit_task = cocotb.start_soon(
        tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload_a))
    )

    await ClockCycles(dut.clk, 3)
    xmit_task.kill()

    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))

    dut.rst.value = 1
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0
    await ClockCycles(dut.clk, 4)

    payload_b = bytes([0x5A] * 40)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload_b))
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt
    assert int(pkt[UDP].dport) == DHCP_CLIENT_PORT
    assert bytes(pkt[Raw].load)[:len(payload_b)] == payload_b


@cocotb.test()
async def parser_extracts_offer_fields(dut):
    """Send a constructed DHCP OFFER on port 68; verify the observe-only
    parser registers the expected fields (peeked via deep hierarchy)."""
    tb = TB(dut)
    await test_prep(dut, tb)

    xid = 0xDEADBEEF
    yiaddr = 0xC0A8000A   # 192.168.0.10
    siaddr = 0xC0A80001   # 192.168.0.1
    lease_secs = 3600
    payload = build_dhcp_offer(xid, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt
    assert int(pkt[UDP].dport) == DHCP_CLIENT_PORT

    # Give the parser one extra cycle past the last data flit to register.
    await ClockCycles(dut.clk, 4)

    parser = dut.DHCP_TILE_3_0.tile.parser
    assert int(parser.parsed_op.value) == DHCP_OP_BOOTREPLY, \
        f"op {int(parser.parsed_op.value):#x} != BOOTREPLY"
    assert int(parser.parsed_xid.value) == xid, \
        f"xid {int(parser.parsed_xid.value):#x} != {xid:#x}"
    assert int(parser.parsed_yiaddr.value) == yiaddr, \
        f"yiaddr {int(parser.parsed_yiaddr.value):#x} != {yiaddr:#x}"
    assert int(parser.parsed_siaddr.value) == siaddr, \
        f"siaddr {int(parser.parsed_siaddr.value):#x} != {siaddr:#x}"
    assert int(parser.parsed_cookie_valid.value) == 1, "cookie_valid != 1"
    assert int(parser.parsed_msg_type_53.value) == DHCP_MSG_OFFER, \
        f"msg_type_53 {int(parser.parsed_msg_type_53.value)} != OFFER"
    assert int(parser.parsed_lease_secs.value) == lease_secs, \
        f"lease_secs {int(parser.parsed_lease_secs.value)} != {lease_secs}"
    assert int(parser.parsed_srv_id.value) == siaddr, \
        f"srv_id {int(parser.parsed_srv_id.value):#x} != {siaddr:#x}"
