"""Step-5 CI tests: tile auto-emits a DHCP DISCOVER on reset; parser still
observes inbound replies."""
import logging
import struct
from pathlib import Path

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.log import SimLog
from cocotb.triggers import RisingEdge, with_timeout
from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
from scapy.packet import Raw

import sys
sys.path.append(str(Path(__file__).resolve().parent.parent / "common"))
from beehive_bus import BeehiveBus, BeehiveBusSink, BeehiveBusSource
from dhcp_pkts import (
    build_dhcp_ack,
    build_dhcp_offer,
    DHCP_CLIENT_PORT,
    DHCP_COOKIE,
    DHCP_MSG_DISCOVER,
    DHCP_MSG_OFFER,
    DHCP_MSG_REQUEST,
    DHCP_OP_BOOTREPLY,
    DHCP_OP_BOOTREQUEST,
    DHCP_OPT_MSG_TYPE,
    DHCP_OPT_REQ_IP,
    DHCP_OPT_SERVER_ID,
    DHCP_OPTIONS_O,
    DHCP_SERVER_PORT,
)

# dhcp_client_state_e value for BOUND (matches dhcp_tile_pkg.sv).
LEASE_STATE_BOUND = 3

# Hardcoded XID baked into dhcp_tile.sv for the one-shot DISCOVER. Lifted out
# in step 6 once the lease FSM owns XID generation.
DISCOVER_XID = 0xDEADBEEF


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


async def _wait_parser_val(dut):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.DHCP_TILE_3_0.tile.parser.parsed_val.value) == 1:
            return


async def _wait_lease_state(dut, target):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.DHCP_TILE_3_0.tile.ctrl.lease_state_dbg.value) == target:
            return


@cocotb.test()
async def post_reset_emits_discover(dut):
    """After reset deassert the tile auto-emits one well-formed DHCP DISCOVER."""
    tb = TB(dut)
    await test_prep(dut, tb)

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt, "egress is not UDP"
    assert int(pkt[UDP].sport) == DHCP_CLIENT_PORT, \
        f"sport {int(pkt[UDP].sport)} != {DHCP_CLIENT_PORT}"
    assert int(pkt[UDP].dport) == DHCP_SERVER_PORT, \
        f"dport {int(pkt[UDP].dport)} != {DHCP_SERVER_PORT}"

    payload = bytes(pkt[Raw].load)
    # tile sends DHCP_MIN_PAYLOAD_BYTES=253; padding may extend it.
    assert len(payload) >= 253, f"DHCP payload too short: {len(payload)}"

    # BOOTP fixed header
    assert payload[0] == DHCP_OP_BOOTREQUEST, \
        f"op {payload[0]} != BOOTREQUEST"
    assert payload[1] == 1, f"htype {payload[1]} != 1"
    assert payload[2] == 6, f"hlen {payload[2]} != 6"
    xid = struct.unpack(">I", payload[4:8])[0]
    assert xid == DISCOVER_XID, f"xid {xid:#x} != {DISCOVER_XID:#x}"

    # Magic cookie + option 53 = DISCOVER
    assert payload[DHCP_OPTIONS_O:DHCP_OPTIONS_O + 4] == DHCP_COOKIE, \
        f"cookie missing at offset {DHCP_OPTIONS_O}"
    assert payload[240] == DHCP_OPT_MSG_TYPE, \
        f"opt53 tag {payload[240]} != {DHCP_OPT_MSG_TYPE}"
    assert payload[241] == 1, f"opt53 len {payload[241]} != 1"
    assert payload[242] == DHCP_MSG_DISCOVER, \
        f"opt53 value {payload[242]} != DISCOVER"


@cocotb.test()
async def parser_extracts_offer_fields(dut):
    """Inject a DHCP OFFER on port 68; observe-only parser snapshots fields.
    The tile no longer echoes RX traffic; we sync on parser.parsed_val."""
    tb = TB(dut)
    await test_prep(dut, tb)

    xid = 0xCAFEF00D
    yiaddr = 0xC0A8000A   # 192.168.0.10
    siaddr = 0xC0A80001   # 192.168.0.1
    lease_secs = 3600
    payload = build_dhcp_offer(xid, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, payload))

    await with_timeout(_wait_parser_val(dut), 2_000_000_000, "ns")

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


@cocotb.test()
async def discover_request_ack(dut):
    """Cooperative-server DORA happy path. After reset the lease FSM walks
    INIT -> SELECTING -> REQUESTING -> BOUND while the testbench impersonates
    a DHCP server: catch DISCOVER, inject OFFER, catch REQUEST, inject ACK,
    poll lease_state_dbg until BOUND."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A   # 192.168.0.10
    siaddr = 0xC0A80001   # 192.168.0.1
    lease_secs = 3600

    # 1. Catch DISCOVER egress.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt, "first egress not UDP"
    assert int(pkt[UDP].dport) == DHCP_SERVER_PORT
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER, \
        f"first egress is not DISCOVER (opt53={payload[242]})"

    # 2. Inject OFFER (matching xid).
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    # 3. Catch REQUEST egress with the right options.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt, "second egress not UDP"
    assert int(pkt[UDP].dport) == DHCP_SERVER_PORT
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"second egress is not REQUEST (opt53={payload[242]})"

    # Option 50: requested IP = offered yiaddr.
    assert payload[252] == DHCP_OPT_REQ_IP, \
        f"opt50 tag {payload[252]} != {DHCP_OPT_REQ_IP}"
    assert payload[253] == 4, f"opt50 len {payload[253]} != 4"
    req_ip = struct.unpack(">I", payload[254:258])[0]
    assert req_ip == yiaddr, f"req_ip {req_ip:#x} != {yiaddr:#x}"

    # Option 54: server identifier = offered siaddr.
    assert payload[258] == DHCP_OPT_SERVER_ID, \
        f"opt54 tag {payload[258]} != {DHCP_OPT_SERVER_ID}"
    assert payload[259] == 4, f"opt54 len {payload[259]} != 4"
    srv_id = struct.unpack(">I", payload[260:264])[0]
    assert srv_id == siaddr, f"srv_id {srv_id:#x} != {siaddr:#x}"

    # 4. Inject ACK.
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))

    # 5. Lease FSM should land in BOUND.
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")


@cocotb.test()
async def retransmit_discover(dut):
    """No OFFER injected. The lease FSM sits in SELECTING and re-emits a
    DISCOVER once the retransmit timer (DHCP_RETRANSMIT_SEC * CLK_HZ
    cycles) expires. Harness CLK_HZ=1000 so timeout is ~5000 cycles."""
    tb = TB(dut)
    await test_prep(dut, tb)

    # First DISCOVER (right after reset).
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER, \
        f"first egress not DISCOVER (opt53={payload[242]})"
    xid_first = struct.unpack(">I", payload[4:8])[0]
    assert xid_first == DISCOVER_XID

    # Second DISCOVER after retransmit timer. CLK_HZ=1000 * 5 = 5000 cycles
    # at 4 ns/cyc = 20 us; give a generous 100 us window.
    frame = await with_timeout(tb.output_op.recv_frame(), 100_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER, \
        f"retransmit not DISCOVER (opt53={payload[242]})"
    xid_second = struct.unpack(">I", payload[4:8])[0]
    assert xid_second == DISCOVER_XID, \
        f"retransmit xid {xid_second:#x} != first xid {xid_first:#x}"


@cocotb.test()
async def retransmit_request(dut):
    """OFFER injected once, no ACK. The lease FSM sits in REQUESTING and
    re-emits a REQUEST_INIT with the same lease info on timer expiry."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # Catch DISCOVER.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_DISCOVER

    # Inject OFFER.
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    # Catch first REQUEST.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"first egress after OFFER not REQUEST (opt53={payload[242]})"
    req_ip_first = struct.unpack(">I", payload[254:258])[0]
    assert req_ip_first == yiaddr

    # No ACK -- catch retransmitted REQUEST.
    frame = await with_timeout(tb.output_op.recv_frame(), 100_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"retransmit not REQUEST (opt53={payload[242]})"
    req_ip_second = struct.unpack(">I", payload[254:258])[0]
    assert req_ip_second == yiaddr, \
        f"retransmit req_ip {req_ip_second:#x} != {yiaddr:#x}"
    srv_id_second = struct.unpack(">I", payload[260:264])[0]
    assert srv_id_second == siaddr, \
        f"retransmit srv_id {srv_id_second:#x} != {siaddr:#x}"
