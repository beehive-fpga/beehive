"""Cocotb tests for the DHCP client tile."""
import ipaddress
import logging
import struct
from pathlib import Path

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.log import SimLog
from cocotb.triggers import ClockCycles, RisingEdge, with_timeout
from scapy.layers.inet import IP, UDP
from scapy.layers.l2 import Ether
from scapy.packet import Raw

import sys
sys.path.append(str(Path(__file__).resolve().parent.parent / "common"))
from beehive_bus import BeehiveBus, BeehiveBusSink, BeehiveBusSource
from dora_metrics import start_dora_sampler
from dhcp_pkts import (
    build_dhcp_ack,
    build_dhcp_nak,
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

# dhcp_client_state_e values (match dhcp_tile_pkg.sv).
LEASE_STATE_INIT       = 0
LEASE_STATE_SELECTING  = 1
LEASE_STATE_REQUESTING = 2
LEASE_STATE_BOUND      = 3
LEASE_STATE_RENEWING   = 4
LEASE_STATE_REBINDING  = 5

# Notify msg types (match dhcp_tile_pkg.sv).
DHCP_IP_BIND_MSG_TYPE   = 64
DHCP_IP_EXPIRE_MSG_TYPE = 65

# beehive_noc_hdr_flit bit layout for the 512-bit NoC TX flit. Packed
# struct order (declared MSB-first in beehive_noc_msg.sv):
#   dst_chip_id [14] | dst_x [8] | dst_y [8] | dst_fbits [4]
#   | msg_len [22] | msg_type [8] | src_chip_id [14] | src_x [8]
#   | src_y [8] | src_fbits [4] | metadata_flits [8] | ...
NOC_DATA_W_BITS    = 512
HDR_MSG_TYPE_MSB   = 511 - (14 + 8 + 8 + 4 + 22)  # = 455
HDR_MSG_TYPE_W     = 8
HDR_DST_X_MSB      = 511 - 14                      # = 497
HDR_DST_Y_MSB      = HDR_DST_X_MSB - 8             # = 489
XY_BITS            = 8
DATA_YIADDR_MSB    = NOC_DATA_W_BITS - 1           # = 511
DATA_YIADDR_W      = 32


def get_field(flit_int, msb, width):
    """Extract `width` bits ending at bit `msb` (inclusive) from `flit_int`."""
    lsb = msb - width + 1
    return (flit_int >> lsb) & ((1 << width) - 1)

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


def make_udp_frame(dst_port, payload_bytes, ip_dst="255.255.255.255"):
    """Default IP dst = broadcast so the dhcp_client harness's IP_RX
    destination filter (enabled via IP_DST_FILTER=1) always passes the
    frame. Override `ip_dst` to test the filter's match / drop paths."""
    pkt = Ether(dst="00:0a:35:0d:4d:c6", src="b8:59:9f:b7:ba:44") / \
        IP(src="198.0.0.5", dst=ip_dst, flags="DF") / \
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

    # udp_test_sender_tile inputs idle until a test triggers it.
    dut.test_sender_trigger.setimmediatevalue(0)
    dut.test_sender_src_ip.setimmediatevalue(0)
    dut.test_sender_dst_ip.setimmediatevalue(0)
    dut.test_sender_src_port.setimmediatevalue(0)
    dut.test_sender_dst_port.setimmediatevalue(0)
    dut.test_sender_payload_len.setimmediatevalue(0)
    dut.test_sender_payload.setimmediatevalue(BinaryValue(value=0, n_bits=512))
    dut.query_trigger.setimmediatevalue(0)
    dut.query_dst_x.setimmediatevalue(0)
    dut.query_dst_y.setimmediatevalue(0)
    dut.query_dst_fbits.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units="ns").start())
    await reset(dut)


async def fire_test_sender(dut, src_ip, dst_ip, dst_port=5555, src_port=60000,
                           payload_len=8, payload_msb=0xCAFEFACECAFEFACE):
    """Single-shot UDP burst out of udp_test_sender_tile. Payload bytes
    are placed at the MSB of the 512-bit flit (matches how to_udp
    expects byte 0 at bit 511)."""
    dut.test_sender_src_ip.value = src_ip
    dut.test_sender_dst_ip.value = dst_ip
    dut.test_sender_src_port.value = src_port
    dut.test_sender_dst_port.value = dst_port
    dut.test_sender_payload_len.value = payload_len
    # 8-byte payload at the top of the 512-bit flit.
    flit = payload_msb << (512 - 64)
    dut.test_sender_payload.value = BinaryValue(value=flit, n_bits=512)

    await RisingEdge(dut.clk)
    dut.test_sender_trigger.value = 1
    await RisingEdge(dut.clk)
    dut.test_sender_trigger.value = 0


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


@cocotb.test()
async def ignore_wrong_xid_offer(dut):
    """An OFFER whose xid does not match the in-flight DISCOVER's xid is
    silently dropped: the FSM stays in SELECTING. A subsequent matching
    OFFER then drives the normal SELECTING -> REQUESTING transition."""
    tb = TB(dut)
    await test_prep(dut, tb)

    # Catch the auto-emitted DISCOVER (xid = DISCOVER_XID).
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_DISCOVER

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # Wrong-xid OFFER -- parser observes it but FSM must ignore.
    bad_offer = build_dhcp_offer(0xBADBADBA, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, bad_offer))

    await with_timeout(_wait_parser_val(dut), 2_000_000_000, "ns")
    # Let the FSM react (or not) on the next clock edge.
    await ClockCycles(dut.clk, 2)
    state_val = int(dut.DHCP_TILE_3_0.tile.ctrl.lease_state_dbg.value)
    assert state_val == LEASE_STATE_SELECTING, \
        f"FSM moved out of SELECTING on wrong-xid OFFER (state={state_val})"

    # Correct OFFER -- normal path resumes.
    good_offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, good_offer))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"egress after good OFFER not REQUEST (opt53={payload[242]})"


@cocotb.test()
async def nak_restart(dut):
    """NAK in REQUESTING returns the lease FSM to INIT with a fresh xid;
    the subsequent DISCOVER must carry an xid different from the first."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # Catch first DISCOVER (xid = DISCOVER_XID).
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER
    xid_first = struct.unpack(">I", payload[4:8])[0]
    assert xid_first == DISCOVER_XID

    # Inject matching OFFER, catch REQUEST.
    offer = build_dhcp_offer(xid_first, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_REQUEST

    # Inject NAK with the same xid -- should kick the FSM back to INIT
    # and roll the xid before the next DISCOVER.
    nak = build_dhcp_nak(xid_first)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, nak))

    # Catch the post-NAK DISCOVER.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER, \
        f"post-NAK egress not DISCOVER (opt53={payload[242]})"
    xid_second = struct.unpack(">I", payload[4:8])[0]
    assert xid_second != xid_first, \
        f"xid not re-rolled after NAK ({xid_second:#x} == {xid_first:#x})"


@cocotb.test()
async def bind_pushed_to_subscribers(dut):
    """After ACK lands, the dhcp_tile pushes a DHCP_IP_BIND NoC msg
    carrying the bound yiaddr to its subscriber. Test peeks the tile's
    noc_dhcp_tx wires and decodes the header flit to verify msg_type +
    destination, then the data flit to verify yiaddr."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # 1. DISCOVER egress.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_DISCOVER

    # 2. OFFER injection.
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    # 3. REQUEST egress.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_REQUEST

    # 4. Capture every NoC TX handshake from now on; the bind notification
    #    will land here once the FSM enters BOUND.
    captured = []
    async def monitor():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_val.value) == 1 and \
               int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_rdy.value) == 1:
                captured.append(int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_data.value))
    monitor_task = cocotb.start_soon(monitor())

    # 5. ACK injection -> BOUND -> bind notification.
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))

    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")
    # Give the notify FSM a generous window to walk header + data.
    await ClockCycles(dut.clk, 50)
    monitor_task.kill()

    # 6. Find the DHCP_IP_BIND header flit; the very next captured flit
    #    must be its data flit with yiaddr at the MSB.
    bind_idx = None
    for i, flit in enumerate(captured):
        if get_field(flit, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_BIND_MSG_TYPE:
            bind_idx = i
            break
    assert bind_idx is not None, \
        f"no DHCP_IP_BIND header in captured NoC TX (got {len(captured)} flits)"

    hdr = captured[bind_idx]
    dst_x = get_field(hdr, HDR_DST_X_MSB, XY_BITS)
    dst_y = get_field(hdr, HDR_DST_Y_MSB, XY_BITS)
    # The dhcp_client harness retargets the bind subscriber to IP_TX_TILE
    # so the listener inside ip_tx_tile (DHCP_BIND_LISTEN=1) can cache
    # the bound IP. IP_TX_TILE = (1, 1) per tile_config.xml.
    assert dst_x == 1, f"bind dst_x {dst_x} != IP_TX_TILE_X (1)"
    assert dst_y == 1, f"bind dst_y {dst_y} != IP_TX_TILE_Y (1)"

    assert bind_idx + 1 < len(captured), "bind header captured but data flit missing"
    data = captured[bind_idx + 1]
    yiaddr_obs = get_field(data, DATA_YIADDR_MSB, DATA_YIADDR_W)
    assert yiaddr_obs == yiaddr, \
        f"bind yiaddr {yiaddr_obs:#x} != {yiaddr:#x}"


@cocotb.test()
async def bind_lands_in_both_subscribers(dut):
    """With NUM_SUBSCRIBERS=2 in the harness (SUB_0=IP_TX, SUB_1=IP_RX),
    each lease event fans out 2 DHCP_IP_BIND msgs back-to-back. Test
    walks the captured NoC TX after BOUND and verifies BOTH a bind
    addressed to IP_TX (1,1) AND one to IP_RX (1,0), in that order,
    each carrying the same yiaddr."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # Snapshot every NoC TX handshake.
    captured = []
    async def monitor():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_val.value) == 1 and \
               int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_rdy.value) == 1:
                captured.append(int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_data.value))
    monitor_task = cocotb.start_soon(monitor())

    # DORA -> BOUND
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # Give the second bind a window to walk.
    await ClockCycles(dut.clk, 50)
    monitor_task.kill()

    # Collect BIND headers and their destinations.
    bind_dsts = [
        (get_field(f, HDR_DST_X_MSB, XY_BITS),
         get_field(f, HDR_DST_Y_MSB, XY_BITS),
         i)
        for i, f in enumerate(captured)
        if get_field(f, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_BIND_MSG_TYPE
    ]
    assert len(bind_dsts) == 2, \
        f"expected 2 DHCP_IP_BIND msgs (1 event x 2 subs), got {len(bind_dsts)}"

    # SUB_0 = IP_TX (1,1) fires first, SUB_1 = IP_RX (1,0) second.
    assert bind_dsts[0][:2] == (1, 1), \
        f"first bind dst {bind_dsts[0][:2]} != IP_TX_TILE (1,1)"
    assert bind_dsts[1][:2] == (1, 0), \
        f"second bind dst {bind_dsts[1][:2]} != IP_RX_TILE (1,0)"

    # Both data flits should carry the same yiaddr.
    for _, _, hdr_idx in bind_dsts:
        data_idx = hdr_idx + 1
        assert data_idx < len(captured), "bind hdr captured but data missing"
        yi = get_field(captured[data_idx], DATA_YIADDR_MSB, DATA_YIADDR_W)
        assert yi == yiaddr, f"bind data yiaddr {yi:#x} != {yiaddr:#x}"


@cocotb.test()
async def renew_ack_returns_to_bound(dut):
    """T1 (lease_secs/2) fires in BOUND, the tile unicasts a REQUEST_RENEW
    (ciaddr=yiaddr, src=yiaddr, dst=siaddr, no opt 50/54). On matching
    ACK the FSM returns to BOUND and re-emits DHCP_IP_BIND for the
    renewed lease."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    # Short lease so T1 fires fast in sim: 4 s * CLK_HZ(1000) / 2 = 2000 cyc = 8 us.
    lease_secs = 4

    # Capture every NoC TX handshake so we can count bind notifications.
    captured = []
    async def monitor():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_val.value) == 1 and \
               int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_rdy.value) == 1:
                captured.append(int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_data.value))
    monitor_task = cocotb.start_soon(monitor())

    # --- DORA --------------------------------------------------------------
    # DISCOVER
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_DISCOVER

    # OFFER
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    # REQUEST_INIT (broadcast)
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    pkt = Ether(frame)
    assert bytes(pkt[Raw].load)[242] == DHCP_MSG_REQUEST

    # ACK -> BOUND
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # --- Renewal loop ------------------------------------------------------
    # T1 = lease_secs * CLK_HZ / 2 = 2000 cyc = 8 us. Allow 50 us window.
    frame = await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"post-T1 egress not REQUEST (opt53={payload[242]})"

    # ciaddr = yiaddr (RFC: REQUEST in RENEWING identifies the client via ciaddr).
    ciaddr = struct.unpack(">I", payload[12:16])[0]
    assert ciaddr == yiaddr, f"ciaddr {ciaddr:#x} != yiaddr {yiaddr:#x}"

    # No opt 50 / opt 54 (renew omits them); END follows opt 61 at offset 252.
    assert payload[252] == 0xFF, \
        f"renew payload[252] = {payload[252]:#x} != OPT_END"

    # Unicast: src IP = yiaddr, dst IP = siaddr.
    expected_src = str(ipaddress.IPv4Address(yiaddr))
    expected_dst = str(ipaddress.IPv4Address(siaddr))
    assert pkt[IP].src == expected_src, \
        f"renew IP.src {pkt[IP].src} != {expected_src}"
    assert pkt[IP].dst == expected_dst, \
        f"renew IP.dst {pkt[IP].dst} != {expected_dst}"

    # Server ACKs the renew -> FSM returns to BOUND with refreshed lease.
    ack2 = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack2))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       50_000, "ns")

    # Give the second bind notification a window to walk + parse the stream.
    await ClockCycles(dut.clk, 50)
    monitor_task.kill()

    bind_count = sum(
        1 for f in captured
        if get_field(f, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_BIND_MSG_TYPE
    )
    # NUM_SUBSCRIBERS=2 in the harness, so every lease event fans out 2 BINDs.
    # Initial DORA-ACK + renewal-ACK = 2 events = 4 BIND msgs.
    assert bind_count == 4, \
        f"expected 4 DHCP_IP_BIND notifications (2 events x 2 subs), got {bind_count}"


@cocotb.test()
async def renewing_to_rebinding_when_no_ack(dut):
    """When the unicast REQUEST_RENEW gets no ACK, T2 (lease_secs * 7/8)
    eventually fires and the tile broadcasts a REQUEST_REBIND. The renew
    payload stays identical (ciaddr=yiaddr, no opt 50/54) but dst_ip
    flips from siaddr to 255.255.255.255."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    # 8 s lease: T1 ~16 us, T2 ~28 us at CLK_HZ=1000. Retransmit (5 s
    # = 20 us from RENEWING entry) lands well past T2 so it can't beat
    # the rebind transition.
    lease_secs = 8

    # --- DORA --------------------------------------------------------------
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_DISCOVER

    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_REQUEST

    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # --- T1: unicast REQUEST_RENEW (we don't ACK) --------------------------
    frame = await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"post-T1 egress not REQUEST (opt53={payload[242]})"
    assert pkt[IP].dst == str(ipaddress.IPv4Address(siaddr)), \
        f"renew IP.dst {pkt[IP].dst} != siaddr"

    # --- T2: broadcast REQUEST_REBIND --------------------------------------
    frame = await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_REQUEST, \
        f"post-T2 egress not REQUEST (opt53={payload[242]})"

    # Same shape as RENEW: ciaddr=yiaddr, no opt 50/54.
    ciaddr = struct.unpack(">I", payload[12:16])[0]
    assert ciaddr == yiaddr, f"rebind ciaddr {ciaddr:#x} != yiaddr {yiaddr:#x}"
    assert payload[252] == 0xFF, \
        f"rebind payload[252] = {payload[252]:#x} != OPT_END"

    # Broadcast: IP.src still yiaddr (we're bound), IP.dst == 255.255.255.255.
    assert pkt[IP].src == str(ipaddress.IPv4Address(yiaddr)), \
        f"rebind IP.src {pkt[IP].src} != yiaddr"
    assert pkt[IP].dst == "255.255.255.255", \
        f"rebind IP.dst {pkt[IP].dst} != 255.255.255.255"

    # FSM should now be in REBINDING.
    state_val = int(dut.DHCP_TILE_3_0.tile.ctrl.lease_state_dbg.value)
    assert state_val == LEASE_STATE_REBINDING, \
        f"FSM not in REBINDING after T2 (state={state_val})"


@cocotb.test()
async def rebind_ack_returns_to_bound(dut):
    """ACK received in REBINDING (potentially from a different server)
    refreshes the lease and returns the FSM to BOUND with a fresh
    DHCP_IP_BIND notification."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr_first  = 0xC0A8000A   # 192.168.0.10 -- initial lease
    siaddr_first  = 0xC0A80001   # 192.168.0.1
    yiaddr_second = 0xC0A8000B   # 192.168.0.11 -- second server hands out new IP
    siaddr_second = 0xC0A80002   # 192.168.0.2
    lease_secs    = 8

    # Capture every NoC TX handshake so we can count bind notifications.
    captured = []
    async def monitor():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_val.value) == 1 and \
               int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_rdy.value) == 1:
                captured.append(int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_data.value))
    monitor_task = cocotb.start_soon(monitor())

    # --- DORA --------------------------------------------------------------
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr_first, siaddr_first, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr_first, siaddr_first, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # --- Burn through T1 (no ACK) and T2 to reach REBINDING ---------------
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # RENEW
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # REBIND
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_REBINDING),
                       50_000, "ns")

    # --- ACK from a different server, with a new yiaddr -------------------
    ack2 = build_dhcp_ack(DISCOVER_XID, yiaddr_second, siaddr_second, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack2))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       50_000, "ns")

    # Lease registers should reflect the rebind's new server / IP.
    assert int(dut.DHCP_TILE_3_0.tile.ctrl.lease_yiaddr.value) == yiaddr_second, \
        "lease_yiaddr not refreshed by REBIND ACK"
    assert int(dut.DHCP_TILE_3_0.tile.ctrl.lease_siaddr.value) == siaddr_second, \
        "lease_siaddr not refreshed by REBIND ACK"

    # Give the second bind notification a window to walk.
    await ClockCycles(dut.clk, 50)
    monitor_task.kill()

    # Two bind EVENTS (initial DORA-ACK + rebind-ACK). NUM_SUBSCRIBERS=2
    # in the harness so each event fans out 2 BIND msgs = 4 total.
    bind_headers = [
        i for i, f in enumerate(captured)
        if get_field(f, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_BIND_MSG_TYPE
    ]
    assert len(bind_headers) == 4, \
        f"expected 4 DHCP_IP_BIND notifications (2 events x 2 subs), got {len(bind_headers)}"

    # The second event starts at bind_headers[2] (after the 2 first-event
    # BINDs walked subs 0 and 1). Its data flit is the next entry.
    second_event_data_idx = bind_headers[2] + 1
    assert second_event_data_idx < len(captured), \
        "second-event bind header captured but data flit missing"
    yiaddr_obs = get_field(captured[second_event_data_idx], DATA_YIADDR_MSB, DATA_YIADDR_W)
    assert yiaddr_obs == yiaddr_second, \
        f"rebind notification yiaddr {yiaddr_obs:#x} != {yiaddr_second:#x}"


@cocotb.test()
async def rebind_expiry_goes_to_init(dut):
    """When REBINDING gets no ACK either, the full lease eventually
    expires. The tile pushes a DHCP_IP_EXPIRE notification carrying
    the expiring yiaddr, re-rolls the xid, and restarts DORA from
    INIT with a fresh DISCOVER."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    # 8 s lease: T1 ~16 us, T2 ~28 us, EXPIRY ~32 us at CLK_HZ=1000.
    lease_secs = 8

    # Capture every NoC TX flit handshake so we can find DHCP_IP_EXPIRE.
    captured = []
    async def monitor():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_val.value) == 1 and \
               int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_rdy.value) == 1:
                captured.append(int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_data.value))
    monitor_task = cocotb.start_soon(monitor())

    # --- DORA -> BOUND ----------------------------------------------------
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # --- Burn T1 (RENEW, no ACK) and T2 (REBIND, no ACK) ------------------
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # RENEW
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # REBIND
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_REBINDING),
                       50_000, "ns")

    # --- Wait for EXPIRY -> INIT ------------------------------------------
    # ST_INIT only sits for 1 cycle before ST_INIT_WAIT_TX (still maps to
    # INIT in lease_state_dbg). Poll for INIT.
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_INIT),
                       50_000, "ns")

    # --- Fresh DISCOVER must follow with a re-rolled xid ------------------
    frame = await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER, \
        f"post-expiry egress not DISCOVER (opt53={payload[242]})"
    xid_post = struct.unpack(">I", payload[4:8])[0]
    assert xid_post != DISCOVER_XID, \
        f"xid not re-rolled on expiry ({xid_post:#x} == {DISCOVER_XID:#x})"

    # Give any pending notify a window to walk + parse the stream.
    await ClockCycles(dut.clk, 50)
    monitor_task.kill()

    # One EXPIRE event x NUM_SUBSCRIBERS=2 = 2 DHCP_IP_EXPIRE notifications,
    # each carrying the expiring yiaddr.
    expire_headers = [
        i for i, f in enumerate(captured)
        if get_field(f, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_EXPIRE_MSG_TYPE
    ]
    assert len(expire_headers) == 2, \
        f"expected 2 DHCP_IP_EXPIRE notifications (1 event x 2 subs), got {len(expire_headers)}"

    # Every expire data flit (one per subscriber) carries the same yiaddr.
    for hdr_idx in expire_headers:
        data_idx = hdr_idx + 1
        assert data_idx < len(captured), \
            f"expire header at {hdr_idx} captured but data flit missing"
        yiaddr_obs = get_field(captured[data_idx], DATA_YIADDR_MSB, DATA_YIADDR_W)
        assert yiaddr_obs == yiaddr, \
            f"expire notification yiaddr {yiaddr_obs:#x} != {yiaddr:#x}"


@cocotb.test()
async def bind_lands_in_ip_tx(dut):
    """The dhcp bind subscriber is wired to IP_TX_TILE in the harness, and
    that tile is built with DHCP_BIND_LISTEN=1 so its ip_tx_dhcp_listener
    snoops DHCP_IP_BIND / DHCP_IP_EXPIRE off the NoC RX path and caches
    the bound yiaddr in `dhcp_bound_ip` + `dhcp_bound_valid`. This test
    drives a full lease cycle and peeks those regs.

    Pre-bind:  bound_valid=0,  bound_ip=0.
    Post-bind: bound_valid=1,  bound_ip=yiaddr (~one extra cycle after
               the bind data flit handshakes through the listener FSM).
    Post-expiry: bound_valid=0, bound_ip=0 (DHCP_IP_EXPIRE clears).
    """
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 8  # ~32 us total at CLK_HZ=1000

    # Sanity-check the listener powers up cleared.
    assert int(dut.IP_TX_1_1.dhcp_bound_valid.value) == 0, \
        "ip_tx listener bound_valid not 0 out of reset"

    # --- DORA -> BOUND ----------------------------------------------------
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # The bind FSM strobes notify_start the same cycle as BOUND, but the
    # 2 notify flits + 1 capture cycle still have to traverse the router
    # + listener. Poll for the cached bind to land.
    async def _wait_ip_tx_bound(target_valid):
        while True:
            await RisingEdge(dut.clk)
            if int(dut.IP_TX_1_1.dhcp_bound_valid.value) == target_valid:
                return
    await with_timeout(_wait_ip_tx_bound(1), 50_000, "ns")

    bound_ip = int(dut.IP_TX_1_1.dhcp_bound_ip.value)
    assert bound_ip == yiaddr, \
        f"ip_tx bound_ip {bound_ip:#x} != yiaddr {yiaddr:#x}"

    # --- Burn T1 + T2 + EXPIRY (no acks at all) ---------------------------
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # RENEW
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # REBIND
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_INIT),
                       50_000, "ns")

    # Expiry notification should land at the listener; bound_valid clears.
    await with_timeout(_wait_ip_tx_bound(0), 50_000, "ns")
    bound_ip_post = int(dut.IP_TX_1_1.dhcp_bound_ip.value)
    assert bound_ip_post == 0, \
        f"ip_tx bound_ip not cleared after expiry: {bound_ip_post:#x}"


@cocotb.test()
async def policy_mux_substitutes_when_bound(dut):
    """The dhcp_client harness builds IP_TX_1_1 with SRC_IP_POLICY=1, so
    its ip_tx_policy_mux should substitute src_ip with the cached DHCP
    yiaddr whenever a lease is held, and pass through the operator's
    src_ip whenever it isn't.

    Test peeks the policy_mux's combinational `substitute_now` decision
    and `substituted_src_ip` output across the full lease lifecycle.
    End-to-end IP-frame inspection is harder -- DHCP's own egress
    already supplies the correct src per RFC, so substitution is a
    no-op on those frames. A test that drives a non-DHCP UDP burst
    through ip_tx with src=0.0.0.0 requires a UDP injector (future
    work). The peek here at least proves the logic gates correctly.
    """
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 8

    # Observability hooks hoisted to tile scope -- Verilator's VPI
    # doesn't expose generate-block scopes by name.
    substitute_now_h     = dut.IP_TX_1_1.policy_substitute_now
    substituted_src_ip_h = dut.IP_TX_1_1.policy_substituted_src_ip

    # Out of reset: no lease, no substitution.
    assert int(substitute_now_h.value) == 0, \
        "policy_substitute_now should be 0 pre-bind"

    # --- DORA -> BOUND ----------------------------------------------------
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # Bind notification reaches the listener a few cycles later; poll.
    async def _wait_substitute(target):
        while True:
            await RisingEdge(dut.clk)
            if int(substitute_now_h.value) == target:
                return
    await with_timeout(_wait_substitute(1), 50_000, "ns")

    # With substitute_now=1, substituted_src_ip combinationally tracks
    # the cached DHCP IP regardless of whatever the upstream meta_flit
    # currently carries.
    sub_ip = int(substituted_src_ip_h.value)
    assert sub_ip == yiaddr, \
        f"policy_substituted_src_ip {sub_ip:#x} != yiaddr {yiaddr:#x}"

    # --- Burn through RENEW + REBIND + EXPIRY (no acks) -------------------
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # RENEW
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # REBIND
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_INIT),
                       50_000, "ns")

    # Post-expiry: substitute_now should drop back to 0. The post-expiry
    # value of substituted_src_ip mirrors whatever stale meta_flit.src_ip
    # the upstream is presenting -- the important assertion is just that
    # substitute_now cleared.
    await with_timeout(_wait_substitute(0), 50_000, "ns")


async def _wait_ip_rx_bound(dut, target):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.IP_RX_1_0.dhcp_bound_valid.value) == target:
            return


async def _count_parser_pulses(dut, window_cycles):
    """Count rising edges of parser.parsed_val over a window. Useful
    for asserting either 0 pulses (drop) or >=1 pulse (pass) within
    a window without racing against state transitions."""
    count = 0
    prev = int(dut.DHCP_TILE_3_0.tile.parser.parsed_val.value)
    for _ in range(window_cycles):
        await RisingEdge(dut.clk)
        cur = int(dut.DHCP_TILE_3_0.tile.parser.parsed_val.value)
        if cur == 1 and prev == 0:
            count += 1
        prev = cur
    return count


@cocotb.test()
async def ip_rx_caches_bound_ip(dut):
    """The dhcp_tile fans binds out to both IP_TX (sub 0) and IP_RX
    (sub 1). IP_RX_1_0 is built with DHCP_BIND_LISTEN=1, so its
    ip_rx_dhcp_listener should cache the bound yiaddr after DORA."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4

    # Pre-bind: bound_valid clear.
    assert int(dut.IP_RX_1_0.dhcp_bound_valid.value) == 0, \
        "ip_rx listener bound_valid not 0 out of reset"

    # DORA
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))

    await with_timeout(_wait_ip_rx_bound(dut, 1), 50_000, "ns")
    cached = int(dut.IP_RX_1_0.dhcp_bound_ip.value)
    assert cached == yiaddr, \
        f"ip_rx cached bound_ip {cached:#x} != yiaddr {yiaddr:#x}"


@cocotb.test()
async def filter_passes_matching_dst(dut):
    """Post-bind, inject a UDP frame whose IP.dst matches the bound
    yiaddr. IP_RX filter must pass it through; the dhcp_tile parser
    should snapshot the payload."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4

    # DORA -> BOUND
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_ip_rx_bound(dut, 1), 50_000, "ns")

    # Inject a DHCP-shaped probe with ip_dst = yiaddr (matches).
    probe = build_dhcp_offer(0xCAFEBABE, yiaddr, siaddr, lease_secs)
    yiaddr_str = str(ipaddress.IPv4Address(yiaddr))
    await tb.input_op.xmit_frame(
        make_udp_frame(DHCP_CLIENT_PORT, probe, ip_dst=yiaddr_str)
    )

    # Filter should pass; parser should see at least one pulse.
    pulses = await _count_parser_pulses(dut, 1000)
    assert pulses >= 1, \
        f"matching-dst probe never reached parser (pulses={pulses})"


@cocotb.test()
async def filter_passes_broadcast(dut):
    """Broadcast IP.dst (255.255.255.255) must always pass the filter
    even when bound, because DHCP replies arrive that way."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4

    # DORA -> BOUND. The DORA itself uses broadcast, so reaching BOUND
    # also implicitly proves broadcast passes pre-bind.
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_ip_rx_bound(dut, 1), 50_000, "ns")

    # Inject a probe with broadcast ip_dst (default for make_udp_frame).
    probe = build_dhcp_offer(0xCAFEBABE, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(
        make_udp_frame(DHCP_CLIENT_PORT, probe, ip_dst="255.255.255.255")
    )

    pulses = await _count_parser_pulses(dut, 1000)
    assert pulses >= 1, \
        f"broadcast probe never reached parser (pulses={pulses})"


@cocotb.test()
async def filter_drops_mismatched_dst(dut):
    """Post-bind, inject a UDP frame whose IP.dst is neither the bound
    yiaddr nor the IPv4 broadcast. IP_RX filter must drop it -- the
    dhcp_tile parser must NOT see it within a generous window."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4

    # DORA -> BOUND
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_ip_rx_bound(dut, 1), 50_000, "ns")

    # Wait for any in-flight parser activity from the DORA to settle.
    await ClockCycles(dut.clk, 50)

    # Inject a probe with ip_dst that matches neither yiaddr nor broadcast.
    probe = build_dhcp_offer(0xCAFEBABE, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(
        make_udp_frame(DHCP_CLIENT_PORT, probe, ip_dst="10.20.30.40")
    )

    # Filter should drop. Parser must see zero new pulses.
    pulses = await _count_parser_pulses(dut, 1500)
    assert pulses == 0, \
        f"mismatched-dst probe reached parser ({pulses} pulses) -- filter not dropping"


# --- udp_test_sender end-to-end substitution tests ------------------------
# These drive a non-DHCP UDP burst through ip_tx_tile's policy_mux and
# inspect the actual MAC egress frame's IP.src. With SRC_IP_POLICY=1:
#   * unbound -> IP.src equals whatever the operator (test sender) supplied
#   * bound   -> IP.src is substituted with the DHCP yiaddr

EXTERNAL_DST_IP_INT = 0x0A141E0A   # 10.20.30.10 (caller-supplied test dst)


async def _wait_ip_tx_bound(dut, target):
    while True:
        await RisingEdge(dut.clk)
        if int(dut.IP_TX_1_1.dhcp_bound_valid.value) == target:
            return


@cocotb.test()
async def udp_send_pre_bind_uses_operator_src(dut):
    """Pre-bind, POLICY=1 substitution is gated by dhcp_bound_valid=0,
    so the operator's src_ip flows through. Test sender supplies
    src=0.0.0.0; expect the MAC egress to carry IP.src=0.0.0.0."""
    tb = TB(dut)
    await test_prep(dut, tb)

    # Drain the auto-emitted DISCOVER first so we capture our own frame next.
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")

    # FSM is in SELECTING, IP_TX dhcp_bound_valid still 0.
    assert int(dut.IP_TX_1_1.dhcp_bound_valid.value) == 0

    # Make the test dst broadcast so the harness's IP_DST_FILTER on IP_RX
    # doesn't drop the egress on its way back through any loopback path.
    await fire_test_sender(
        dut,
        src_ip=0,
        dst_ip=EXTERNAL_DST_IP_INT,
        dst_port=5555,
    )

    frame = await with_timeout(tb.output_op.recv_frame(), 200_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt, "test-sender egress not UDP"
    assert pkt[IP].src == "0.0.0.0", \
        f"pre-bind IP.src {pkt[IP].src} != 0.0.0.0 (substitution fired without a lease)"
    assert pkt[IP].dst == str(ipaddress.IPv4Address(EXTERNAL_DST_IP_INT))
    assert int(pkt[UDP].dport) == 5555


@cocotb.test()
async def udp_send_post_bind_substitutes_visible(dut):
    """Post-bind, POLICY=1 substitution kicks in: test sender supplies
    src=0.0.0.0 but the MAC egress carries IP.src=yiaddr. This is the
    visible end-to-end substitution test."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4

    # DORA -> BOUND
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_ip_tx_bound(dut, 1), 50_000, "ns")

    # Fire the test sender with src=0.0.0.0 -- substitution should swap
    # it to yiaddr on egress.
    await fire_test_sender(
        dut,
        src_ip=0,
        dst_ip=EXTERNAL_DST_IP_INT,
        dst_port=5555,
    )

    frame = await with_timeout(tb.output_op.recv_frame(), 200_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt, "test-sender egress not UDP"
    assert pkt[IP].src == str(ipaddress.IPv4Address(yiaddr)), \
        f"post-bind IP.src {pkt[IP].src} != yiaddr -- substitution didn't fire"
    assert pkt[IP].dst == str(ipaddress.IPv4Address(EXTERNAL_DST_IP_INT))
    assert int(pkt[UDP].dport) == 5555


@cocotb.test()
async def udp_send_after_rebind_substitutes_new_ip(dut):
    """Run DORA, then REBIND with a *different* server that hands out a
    new yiaddr. Fire the test sender; the substitution should use the
    refreshed yiaddr, not the original one."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr_first  = 0xC0A8000A
    siaddr_first  = 0xC0A80001
    yiaddr_second = 0xC0A8000B
    siaddr_second = 0xC0A80002
    lease_secs = 8

    # DORA with first server.
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr_first, siaddr_first, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr_first, siaddr_first, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # Burn T1 (no ACK) + T2 (no ACK) to reach REBINDING.
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # RENEW
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")  # REBIND
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_REBINDING),
                       50_000, "ns")

    # Different server answers the rebind with a NEW yiaddr.
    ack2 = build_dhcp_ack(DISCOVER_XID, yiaddr_second, siaddr_second, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack2))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND), 50_000, "ns")

    # IP_TX listener should have cached the new yiaddr.
    async def _wait_ip_tx_bound_ip(target):
        while True:
            await RisingEdge(dut.clk)
            if int(dut.IP_TX_1_1.dhcp_bound_ip.value) == target:
                return
    await with_timeout(_wait_ip_tx_bound_ip(yiaddr_second), 50_000, "ns")

    # Fire test sender with src=0; substitution uses the NEW yiaddr.
    await fire_test_sender(
        dut,
        src_ip=0,
        dst_ip=EXTERNAL_DST_IP_INT,
        dst_port=5555,
    )

    frame = await with_timeout(tb.output_op.recv_frame(), 200_000, "ns")
    pkt = Ether(frame)
    assert UDP in pkt
    assert pkt[IP].src == str(ipaddress.IPv4Address(yiaddr_second)), \
        f"post-rebind IP.src {pkt[IP].src} != new yiaddr"


@cocotb.test()
async def query_response_returns_bind(dut):
    """DHCP_IP_QUERY emitted from udp_test_sender (coord 3,1) to
    dhcp_tile (coord 3,0) must elicit a single-subscriber DHCP_IP_BIND
    response back at (3,1) carrying the current yiaddr."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4

    # Monitor noc_dhcp_tx from t=0 so we can count broadcast binds vs
    # the response bind.
    captured = []
    async def monitor():
        while True:
            await RisingEdge(dut.clk)
            if int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_val.value) == 1 and \
               int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_rdy.value) == 1:
                captured.append(int(dut.DHCP_TILE_3_0.tile.noc_dhcp_tx_data.value))
    monitor_task = cocotb.start_soon(monitor())

    # --- DORA -> BOUND ----------------------------------------------------
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    # Let the initial multi-subscriber bind (2 binds: IP_TX + IP_RX) finish.
    await ClockCycles(dut.clk, 50)

    initial_binds = sum(
        1 for f in captured
        if get_field(f, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_BIND_MSG_TYPE
    )
    assert initial_binds == 2, \
        f"expected 2 broadcast binds from DORA, got {initial_binds}"

    # --- Fire DHCP_IP_QUERY from (3,1) to dhcp_tile at (3,0) --------------
    # PKT_IF_FBITS = {1'b1, 3'b000} = 8 (matches noc_defs FINAL_BITS=4).
    PKT_IF_FBITS_VAL = 8
    dut.query_dst_x.value = 3   # DHCP_TILE_X
    dut.query_dst_y.value = 0   # DHCP_TILE_Y
    dut.query_dst_fbits.value = PKT_IF_FBITS_VAL

    await RisingEdge(dut.clk)
    dut.query_trigger.value = 1
    await RisingEdge(dut.clk)
    dut.query_trigger.value = 0

    # Round trip: udp_test_sender -> NoC -> dhcp_query_rx -> ctrl ->
    # notify_tx -> noc_dhcp_tx. Generous window for the routing.
    await ClockCycles(dut.clk, 200)
    monitor_task.kill()

    # --- Verify the response ----------------------------------------------
    bind_headers = [
        i for i, f in enumerate(captured)
        if get_field(f, HDR_MSG_TYPE_MSB, HDR_MSG_TYPE_W) == DHCP_IP_BIND_MSG_TYPE
    ]
    assert len(bind_headers) == 3, \
        f"expected 3 BIND headers (2 broadcast + 1 query response), got {len(bind_headers)}"

    # Third bind is the query response; check dst coords.
    resp_hdr = captured[bind_headers[2]]
    dst_x = get_field(resp_hdr, HDR_DST_X_MSB, XY_BITS)
    dst_y = get_field(resp_hdr, HDR_DST_Y_MSB, XY_BITS)
    assert dst_x == 3, f"query response dst_x {dst_x} != UDP_TEST_SENDER_X (3)"
    assert dst_y == 1, f"query response dst_y {dst_y} != UDP_TEST_SENDER_Y (1)"

    # Data flit after the response header must carry the current yiaddr.
    assert bind_headers[2] + 1 < len(captured), \
        "response header captured but data flit missing"
    resp_data = captured[bind_headers[2] + 1]
    yiaddr_obs = get_field(resp_data, DATA_YIADDR_MSB, DATA_YIADDR_W)
    assert yiaddr_obs == yiaddr, \
        f"query response yiaddr {yiaddr_obs:#x} != {yiaddr:#x}"


@cocotb.test()
async def dora_baseline_metrics(dut):
    """Measure cycle/byte budgets for the canonical DORA happy path so the
    datasheet has concrete numbers. Asserts only loose sanity bounds; the
    real values come out of the cocotb log via DoraMetrics.log_summary."""
    tb = TB(dut)
    await test_prep(dut, tb)

    sampler = start_dora_sampler(dut)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # DISCOVER -> OFFER -> REQUEST -> ACK -> BOUND.
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")

    sampler.stop()
    # One more edge so the sampler exits cleanly.
    await RisingEdge(dut.clk)
    metrics = sampler.metrics
    metrics.log_summary(tb.log)

    # Sanity bounds. The actual measurements are far smaller than these
    # ceilings -- if you bust them the FSM is stuck somewhere.
    assert metrics.cycles_total < 200_000, \
        f"DORA wall-clock blew the loose ceiling: {metrics.cycles_total}"
    assert metrics.tx_frames >= 2, \
        f"expected >=2 TX frames (DISCOVER + REQUEST), got {metrics.tx_frames}"
    assert metrics.rx_frames >= 2, \
        f"expected >=2 RX frames (OFFER + ACK), got {metrics.rx_frames}"
    # CPU-side cycles for DORA on Beehive is structurally zero because
    # the dhcp_tile runs autonomously; this is the datapoint that pairs
    # with a software baseline.
    assert metrics.cpu_cycles == 0


async def _run_dora_unsampled(dut, tb, yiaddr, siaddr, lease_secs):
    """Walk DORA to BOUND without any sampler attached. Used as preamble
    for the renewal/rebind/expiry measurement tests so the reported
    metrics cover only the phase under test."""
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await with_timeout(_wait_lease_state(dut, LEASE_STATE_BOUND),
                       2_000_000_000, "ns")


@cocotb.test()
async def renew_phase_metrics(dut):
    """Cycle/byte budget for the renewal half-trip (T1 expiry in BOUND ->
    unicast REQUEST_RENEW -> ACK -> BOUND). Sampler starts after the
    initial DORA so its numbers reflect only the renewal phase."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 4   # T1 ~2000 cyc

    await _run_dora_unsampled(dut, tb, yiaddr, siaddr, lease_secs)

    sampler = start_dora_sampler(dut)

    # T1 fires -> tile emits REQUEST_RENEW.
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    # Re-entry into BOUND completes the renewal.
    await _wait_lease_state(dut, LEASE_STATE_BOUND)

    sampler.stop()
    await RisingEdge(dut.clk)
    sampler.metrics.log_summary(tb.log, label="RENEW")

    assert sampler.metrics.tx_frames >= 1, \
        f"expected >=1 TX frame (REQUEST_RENEW), got {sampler.metrics.tx_frames}"
    assert sampler.metrics.rx_frames >= 1, \
        f"expected >=1 RX frame (ACK), got {sampler.metrics.rx_frames}"
    assert sampler.metrics.cpu_cycles == 0


@cocotb.test()
async def rebind_phase_metrics(dut):
    """Cycle/byte budget for the rebind path: BOUND -> T1 RENEW (no ACK) ->
    T2 broadcast REBIND -> ACK -> BOUND. Sampler captures everything
    from BOUND entry through the rebind completion."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 8   # T1 ~4000, T2 ~7000 cyc

    await _run_dora_unsampled(dut, tb, yiaddr, siaddr, lease_secs)

    sampler = start_dora_sampler(dut)

    # T1 RENEW egress, no ACK.
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    # T2 REBIND egress.
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    # ACK the rebind.
    ack = build_dhcp_ack(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await _wait_lease_state(dut, LEASE_STATE_BOUND)

    sampler.stop()
    await RisingEdge(dut.clk)
    sampler.metrics.log_summary(tb.log, label="REBIND")

    assert sampler.metrics.tx_frames >= 2, \
        f"expected >=2 TX frames (RENEW + REBIND), got {sampler.metrics.tx_frames}"
    assert sampler.metrics.rx_frames >= 1, \
        f"expected >=1 RX frame (rebind ACK), got {sampler.metrics.rx_frames}"
    assert sampler.metrics.cpu_cycles == 0


@cocotb.test()
async def expiry_redora_metrics(dut):
    """Worst-case path metric: BOUND -> RENEW (no ACK) -> REBIND (no ACK)
    -> EXPIRY -> INIT -> fresh DORA -> BOUND. Sampler scopes from the
    first BOUND through the post-expiry second BOUND."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 8

    await _run_dora_unsampled(dut, tb, yiaddr, siaddr, lease_secs)

    sampler = start_dora_sampler(dut)

    # Burn through RENEW + REBIND egresses (no ACKs).
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    # EXPIRY drops us to INIT, fresh DISCOVER follows.
    await _wait_lease_state(dut, LEASE_STATE_INIT)
    frame = await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    pkt = Ether(frame)
    payload = bytes(pkt[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER
    xid_new = struct.unpack(">I", payload[4:8])[0]

    # Cooperative server returns the same yiaddr; finish the re-DORA.
    offer = build_dhcp_offer(xid_new, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    await with_timeout(tb.output_op.recv_frame(), 50_000, "ns")
    ack = build_dhcp_ack(xid_new, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, ack))
    await _wait_lease_state(dut, LEASE_STATE_BOUND)

    sampler.stop()
    await RisingEdge(dut.clk)
    sampler.metrics.log_summary(tb.log, label="EXPIRY+REDORA")

    # Egresses: RENEW + REBIND + post-expiry DISCOVER + REQUEST = 4.
    assert sampler.metrics.tx_frames >= 4, \
        f"expected >=4 TX frames, got {sampler.metrics.tx_frames}"
    # Ingresses: OFFER + ACK from the re-DORA = 2.
    assert sampler.metrics.rx_frames >= 2, \
        f"expected >=2 RX frames, got {sampler.metrics.rx_frames}"
    assert sampler.metrics.cpu_cycles == 0


@cocotb.test()
async def nak_restart_metrics(dut):
    """NAK error path: REQUESTING -> NAK -> INIT -> fresh DISCOVER.
    Sampler scopes from NAK injection through the post-NAK DISCOVER
    egress, so the reported numbers reflect just the restart cost."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # Get to REQUESTING the same way as the original nak_restart test.
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    payload = bytes(Ether(frame)[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER
    xid_first = struct.unpack(">I", payload[4:8])[0]

    offer = build_dhcp_offer(xid_first, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_REQUEST

    # Sampler starts here so we measure only the NAK -> restart cost.
    sampler = start_dora_sampler(dut)

    nak = build_dhcp_nak(xid_first)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, nak))

    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    payload = bytes(Ether(frame)[Raw].load)
    assert payload[242] == DHCP_MSG_DISCOVER
    xid_second = struct.unpack(">I", payload[4:8])[0]
    assert xid_second != xid_first

    sampler.stop()
    await RisingEdge(dut.clk)
    sampler.metrics.log_summary(tb.log, label="NAK_RESTART")

    # NAK ingress + DISCOVER egress = 2 frames each direction min.
    assert sampler.metrics.tx_frames >= 1, \
        f"expected >=1 TX frame (post-NAK DISCOVER), got {sampler.metrics.tx_frames}"
    assert sampler.metrics.rx_frames >= 1, \
        f"expected >=1 RX frame (NAK), got {sampler.metrics.rx_frames}"
    assert sampler.metrics.cpu_cycles == 0


@cocotb.test()
async def retransmit_discover_metrics(dut):
    """DISCOVER retransmit budget: SELECTING with no OFFER -> 5s timer ->
    re-emit DISCOVER. Sampler runs from reset to the second DISCOVER
    egress so the total covers timer + emit cost."""
    tb = TB(dut)
    await test_prep(dut, tb)

    sampler = start_dora_sampler(dut)

    # First DISCOVER (post-reset).
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_DISCOVER

    # Retransmit after DHCP_RETRANSMIT_SEC * CLK_HZ = 5000 cycles.
    frame = await with_timeout(tb.output_op.recv_frame(), 100_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_DISCOVER

    sampler.stop()
    await RisingEdge(dut.clk)
    sampler.metrics.log_summary(tb.log, label="RETRANSMIT_DISCOVER")

    assert sampler.metrics.tx_frames >= 2, \
        f"expected >=2 TX frames (both DISCOVERs), got {sampler.metrics.tx_frames}"
    assert sampler.metrics.cpu_cycles == 0


@cocotb.test()
async def retransmit_request_metrics(dut):
    """REQUEST retransmit budget: REQUESTING with no ACK -> 5s timer ->
    re-emit REQUEST. Sampler scopes from the first REQUEST egress
    through the retransmit, isolating the wait + re-emit cost."""
    tb = TB(dut)
    await test_prep(dut, tb)

    yiaddr = 0xC0A8000A
    siaddr = 0xC0A80001
    lease_secs = 3600

    # DISCOVER -> OFFER -> first REQUEST (unsampled preamble).
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_DISCOVER
    offer = build_dhcp_offer(DISCOVER_XID, yiaddr, siaddr, lease_secs)
    await tb.input_op.xmit_frame(make_udp_frame(DHCP_CLIENT_PORT, offer))
    frame = await with_timeout(tb.output_op.recv_frame(), 2_000_000_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_REQUEST

    # Sampler covers only the retransmit wait + re-emit.
    sampler = start_dora_sampler(dut)

    frame = await with_timeout(tb.output_op.recv_frame(), 100_000, "ns")
    assert bytes(Ether(frame)[Raw].load)[242] == DHCP_MSG_REQUEST

    sampler.stop()
    await RisingEdge(dut.clk)
    sampler.metrics.log_summary(tb.log, label="RETRANSMIT_REQUEST")

    assert sampler.metrics.tx_frames >= 1, \
        f"expected >=1 TX frame (retransmitted REQUEST), got {sampler.metrics.tx_frames}"
    assert sampler.metrics.cpu_cycles == 0
