"""DHCP message builders shared across cocotb testbenches."""
import struct

DHCP_SERVER_PORT = 67
DHCP_CLIENT_PORT = 68
DHCP_OP_BOOTREQUEST = 1
DHCP_OP_BOOTREPLY = 2
DHCP_MSG_DISCOVER = 1
DHCP_MSG_OFFER = 2
DHCP_MSG_REQUEST = 3
DHCP_MSG_ACK = 5
DHCP_MSG_NAK = 6
DHCP_OPTIONS_O = 236
DHCP_COOKIE = bytes([99, 130, 83, 99])
DHCP_OPT_MSG_TYPE = 53
DHCP_OPT_LEASE_TIME = 51
DHCP_OPT_SERVER_ID = 54
DHCP_OPT_REQ_IP = 50
DHCP_OPT_CLIENT_ID = 61
DHCP_OPT_END = 255


def build_dhcp_fixed(op, xid, ciaddr=0, yiaddr=0, siaddr=0):
    """BOOTP fixed 236-byte header. xid/ciaddr/yiaddr/siaddr are 32-bit ints."""
    buf = bytearray(236)
    buf[0] = op & 0xFF
    buf[1] = 1   # htype Ethernet
    buf[2] = 6   # hlen
    buf[3] = 0   # hops
    struct.pack_into(">I", buf, 4, xid & 0xFFFFFFFF)
    struct.pack_into(">I", buf, 12, ciaddr & 0xFFFFFFFF)
    struct.pack_into(">I", buf, 16, yiaddr & 0xFFFFFFFF)
    struct.pack_into(">I", buf, 20, siaddr & 0xFFFFFFFF)
    return buf


def build_dhcp_options(options):
    """options: list of (tag, value_bytes). Prepends magic cookie, appends END."""
    buf = bytearray(DHCP_COOKIE)
    for tag, val in options:
        buf.append(tag & 0xFF)
        buf.append(len(val) & 0xFF)
        buf.extend(val)
    buf.append(DHCP_OPT_END)
    return buf


def build_dhcp_discover(xid):
    fixed = build_dhcp_fixed(DHCP_OP_BOOTREQUEST, xid)
    opts = build_dhcp_options([
        (DHCP_OPT_MSG_TYPE, bytes([DHCP_MSG_DISCOVER])),
        (DHCP_OPT_CLIENT_ID, bytes([1]) + bytes(6)),
    ])
    return fixed + opts


def build_dhcp_offer(xid, yiaddr, siaddr, lease_secs, srv_id=None):
    if srv_id is None:
        srv_id = siaddr
    fixed = build_dhcp_fixed(DHCP_OP_BOOTREPLY, xid, yiaddr=yiaddr, siaddr=siaddr)
    opts = build_dhcp_options([
        (DHCP_OPT_MSG_TYPE, bytes([DHCP_MSG_OFFER])),
        (DHCP_OPT_LEASE_TIME, struct.pack(">I", lease_secs)),
        (DHCP_OPT_SERVER_ID, struct.pack(">I", srv_id)),
    ])
    return fixed + opts


def build_dhcp_request(xid, yiaddr, siaddr, requested_ip=None, server_id=None):
    if requested_ip is None:
        requested_ip = yiaddr
    if server_id is None:
        server_id = siaddr
    fixed = build_dhcp_fixed(DHCP_OP_BOOTREQUEST, xid, yiaddr=yiaddr, siaddr=siaddr)
    opts = build_dhcp_options([
        (DHCP_OPT_MSG_TYPE, bytes([DHCP_MSG_REQUEST])),
        (DHCP_OPT_CLIENT_ID, bytes([1]) + bytes(6)),
        (DHCP_OPT_REQ_IP, struct.pack(">I", requested_ip)),
        (DHCP_OPT_SERVER_ID, struct.pack(">I", server_id)),
    ])
    return fixed + opts


def build_dhcp_ack(xid, yiaddr, siaddr, lease_secs, srv_id=None):
    if srv_id is None:
        srv_id = siaddr
    fixed = build_dhcp_fixed(DHCP_OP_BOOTREPLY, xid, yiaddr=yiaddr, siaddr=siaddr)
    opts = build_dhcp_options([
        (DHCP_OPT_MSG_TYPE, bytes([DHCP_MSG_ACK])),
        (DHCP_OPT_LEASE_TIME, struct.pack(">I", lease_secs)),
        (DHCP_OPT_SERVER_ID, struct.pack(">I", srv_id)),
    ])
    return fixed + opts


def build_dhcp_nak(xid):
    fixed = build_dhcp_fixed(DHCP_OP_BOOTREPLY, xid)
    opts = build_dhcp_options([(DHCP_OPT_MSG_TYPE, bytes([DHCP_MSG_NAK]))])
    return fixed + opts
