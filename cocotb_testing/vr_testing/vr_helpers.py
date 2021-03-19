from collections import deque
import sys, os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")

from bitfields import AbstractStruct, bitfield
import binascii

from cocotb.binary import BinaryValue

import socket

import scapy
from scapy.layers.inet import UDP, IP
from scapy.packet import Raw

from enum import IntEnum
    
INT_W = 64
BOOL_W = 8

class LogHdrState(IntEnum):
    LOG_STATE_COMMITED = 0
    LOG_STATE_PREPARED = 1

class BeehiveVRHdr():
    Prepare = 5
    PrepareOK = 6
    Commit = 7
    StartViewChange = 10
    DoViewChange = 11
    StartView = 12
    ValidateReadReq = 13
    ValidateReadReply = 14
    SetupBeehive = 128
    SetupBeehiveResp = 129

    NONFRAG_MAGIC = 0x20050318;
    FRAG_MAGIC = 0x20101010;

    FRAG_BYTES = 4
    MSG_TYPE_BYTES = 1
    MSG_LEN_BYTES = 8
    BEEHIVE_HDR_BYTES = FRAG_BYTES + MSG_TYPE_BYTES + MSG_LEN_BYTES

    def __init__(self, is_frag=False, msg_type=Prepare, msg_len=0):
        self.is_frag = is_frag
        self.msg_type = msg_type
        self.msg_len = msg_len

        if (self.is_frag):
            self.magic = self.FRAG_MAGIC
        else:
            self.magic = self.NONFRAG_MAGIC

    def fr_bytearray(self, raw_bytes):
        curr_bytes = 0
        self.magic = int.from_bytes(raw_bytes[curr_bytes:curr_bytes +
            self.FRAG_BYTES], byteorder="little")
        curr_bytes += self.FRAG_BYTES
        self.msg_type = int.from_bytes(raw_bytes[curr_bytes:curr_bytes +
            self.MSG_TYPE_BYTES], byteorder="big")
        curr_bytes += self.MSG_TYPE_BYTES
        self.data_len = int.from_bytes(raw_bytes[curr_bytes:curr_bytes +
            self.MSG_LEN_BYTES], byteorder="big")

        if self.magic == self.FRAG_MAGIC:
            raise NotImplementedError("Fragmented packets not yet supported")
        elif self.magic == self.NONFRAG_MAGIC:
            self.is_frag = False
        else:
            raise RuntimeError("Unknown fragment magic value")

    def to_bytearray(self):
        ret_array = bytearray()
        ret_array.extend(self.magic.to_bytes(length=self.FRAG_BYTES, byteorder="little"))
        ret_array.extend(self.msg_type.to_bytes(length=self.MSG_TYPE_BYTES,
            byteorder="big"))
        ret_array.extend(self.msg_len.to_bytes(length=self.MSG_LEN_BYTES,
            byteorder="big"))

        return ret_array
    
    def __eq__(self, other):
        return (isinstance(other, BeehiveVRHdr) and (self.magic == other.magic)
                and (self.msg_type == other.msg_type) and (self.msg_len == other.msg_len))
    
    def __str__(self):
        str_rep = (f"magic: {hex(self.magic)}, msg_type: {self.msg_type}, msg_len: "
            f"{self.msg_len}")
        return str_rep

class DoViewChangeHdr(AbstractStruct):
    def __init__(self, view=0, last_norm_view=0, last_op=0, last_committed=0,
            rep_index=0, byte_count=0, init_bitstring=None):
        self.bitfields = [
            bitfield("view", INT_W, value=view),
            bitfield("last_norm_view", INT_W, value=last_norm_view),
            bitfield("last_op", INT_W, value=last_op),
            bitfield("last_committed", INT_W, value=last_committed),
            bitfield("rep_index", INT_W, value=rep_index),
            bitfield("byte_count", INT_W, value=byte_count)
        ]

        self.bitfield_indices = {
            "view": 0,
            "last_norm_view": 1,
            "last_op": 2,
            "last_committed": 3,
            "rep_index": 4,
            "byte_count": 5
        }

        super().__init__(init_bitstring=init_bitstring)


    def __str__(self):
        return f"DoViewChangeHdr:\n {super().__str__()}"    

class ValidateReadReply(AbstractStruct):
    def __init__(self, isValid=False, clientid=0, clientreqid=0, rep_index=0,
            init_bitstring=None):
        self.bitfields = [
            bitfield("isValid", BOOL_W, value=isValid),
            bitfield("clientid", INT_W, value=clientid),
            bitfield("clientreqid", INT_W, value=clientreqid),
            bitfield("rep_index", INT_W, value=rep_index)
        ]

        self.bitfield_indices = {
            "isValid": 0,
            "clientid": 1,
            "clientreqid": 2,
            "rep_index": 3
        }

        super().__init__(init_bitstring=init_bitstring)

    def __str__(self):
        return f"ValidateReadReplyHdr:\n{super().__str__()}"

class RequestHdr(AbstractStruct):
    def __init__(self, client_id=0, client_req_id=0, op_bytes_len=0,
            init_bitstring=None):

        self.bitfields= [
            bitfield("clientid", INT_W, value=client_id),
            bitfield("clientreqid", INT_W, value=client_req_id),
            bitfield("op_bytes_len", INT_W, value=op_bytes_len),
        ]

        self.bitfield_indices = {
            "clientid": 0,
            "clientreqid": 1,
            "op_bytes_len": 2,
        }

        super().__init__(init_bitstring=init_bitstring)


class RecvWireLogEntryHdr(AbstractStruct):
    def __init__(self, total_size=0, view=0, op_num=0,
            log_entry_state=LogHdrState.LOG_STATE_PREPARED, hash_bytes_count=0,
            request="", init_bitstring=None):

        self.req_hdr = RequestHdr()
        self.bitfields = [
            bitfield("total_size", INT_W, value=total_size),
            bitfield("view", INT_W, value=view),
            bitfield("op_num", INT_W, value=op_num),
            bitfield("log_entry_state", INT_W, value=log_entry_state),
            bitfield("hash_bytes_count", INT_W, value=hash_bytes_count),
            bitfield("request", self.req_hdr.getWidth(),
                value=BinaryValue(value=request).integer),
        ]

        self.bitfield_indices = {
            "total_size": 0,
            "view": 1,
            "op_num": 2,
            "log_entry_state": 3,
            "hash_bytes_count": 4,
            "request": 5
        }

        super().__init__(init_bitstring=init_bitstring)

    def getInnerReqHdr(self):
        req_hdr_binstr = self.getBitfield("request").bitfield_format()
        self.req_hdr.fromBinaryString(req_hdr_binstr)
        return self.req_hdr

class PrepareOKHdr(AbstractStruct):
    def __init__(self, view=0, opnum=0, rep_index=0, last_committed=0,
            init_bitstring=None):
        self.bitfields = [
            bitfield("view", INT_W, value=view),
            bitfield("opnum", INT_W, value=opnum),
            bitfield("rep_index", INT_W, value=rep_index),
            bitfield("last_committed", INT_W, value=last_committed)
        ]

        self.bitfield_indices = {
            "view": 0,
            "opnum": 1,
            "rep_index": 2,
            "last_committed": 3
        }

        super().__init__(init_bitstring=init_bitstring)
        
class VRState(AbstractStruct):
    STATUS_W = 1
    def __init__(self, hdr_log_depth, data_log_depth, view_num=0,
            first_log_op=1, last_op=0, rep_index=0, head=0, tail=0,
            last_commit=0):

        self.data_log_depth = data_log_depth
        self.data_log_depth_w = data_log_depth.bit_length()

        self.hdr_log_depth = hdr_log_depth
        self.hdr_log_depth_w = hdr_log_depth.bit_length()
        self.bitfields = [
            bitfield("view_num", INT_W, value=view_num),
            bitfield("last_op", INT_W, value=last_op),
            bitfield("rep_index", INT_W, value=rep_index),
            bitfield("first_log_op", INT_W, value=first_log_op),
            bitfield("hdr_log_head", self.hdr_log_depth_w, value=head),
            bitfield("hdr_log_tail", self.hdr_log_depth_w, value=tail),
            bitfield("data_log_head", self.data_log_depth_w, value=head),
            bitfield("data_log_tail", self.data_log_depth_w, value=tail),
            bitfield("last_commit", INT_W, value=last_commit),
            bitfield("curr_status", self.STATUS_W, value=0)
        ]
        self.bitfield_indices = {
            "view_num": 0,
            "last_op": 1,
            "rep_index": 2,
            "first_log_op": 3,
            "hdr_log_head": 4,
            "hdr_log_tail": 5,
            "data_log_head": 6,
            "data_log_tail": 7,
            "last_commit": 8,
            "curr_status": 9,
        }
        super().__init__(init_bitstring=None)
        # Figure out how much padding we need to make a fully byte aligned
        # thing
        padding = 8 - self.getWidth() % 8
        if (padding != 8):
            self.bitfields.append(bitfield("padding", padding, value=0))
            self.bitfield_indices["padding"] = 10

    def to_bytearray(self):
        binstr = self.toBinaryString()
        hexstr_width = int(self.getWidth()/4)
        hexstr = "{0:0{width}x}".format(int(binstr,2), width=hexstr_width)
        payload_bytes = bytearray.fromhex(hexstr)
    
        return payload_bytes

def get_tuple_bytes(ip_addr, port):
    addr_bytes = bytearray(socket.inet_aton(ip_addr))
    addr_bytes.extend(port.to_bytes(2, byteorder="big"))
    return addr_bytes

def get_setup_payload(hdr_log_depth=0, data_log_depth=0, rep_index=0, first_log_op=0, machine_config=[], rep_tuple=()):

    new_state = VRState(hdr_log_depth=hdr_log_depth, data_log_depth=data_log_depth, rep_index=rep_index,
            first_log_op=first_log_op)
    vr_payload = new_state.to_bytearray()
    beehive_hdr = BeehiveVRHdr(msg_type=BeehiveVRHdr.SetupBeehive,
            msg_len=len(vr_payload))
    beehive_hdr_bytes = beehive_hdr.to_bytearray()
    payload = beehive_hdr_bytes + vr_payload

    # pad to 64 bytes when the beehive hdr is removed
    padding = 64 + len(beehive_hdr_bytes) - len(payload)
    payload = payload + bytearray([0] * padding)

    config_payload = bytearray([])
    num_nodes = len(machine_config)
    config_payload.extend(num_nodes.to_bytes(4, byteorder="big"))
    (rep_ip, rep_port) = rep_tuple
    config_payload.extend(get_tuple_bytes(rep_ip, rep_port))
    
    for (machine_ip, machine_port) in machine_config:
        config_payload.extend(get_tuple_bytes(machine_ip, machine_port))

    payload = payload + config_payload

    return payload

async def run_setup(tb, base_udp_pkt, send_coro, recv_coro, machine_config,
        rep_tuple):
    # transmit a setup packet
    pkt = base_udp_pkt.copy()
    # get base layer
    base_type = pkt.layers()[0]

    payload = get_setup_payload(hdr_log_depth=2048, data_log_depth=2048,
        rep_index=1, first_log_op=1, machine_config=machine_config,
        rep_tuple=rep_tuple)

    pkt = pkt/Raw(payload)
    # hack to get the fields filled in
    test_bytes = bytearray(pkt.build())
    final_pkt = base_type(test_bytes)
    print(f"sending setup packet {final_pkt.show(dump=True)}")

    await send_coro(tb, final_pkt)
    print("sent setup packet")
    # wait for setup response
    # craft ref packet
    ref_pkt = base_udp_pkt.copy()
    if "Ether" in ref_pkt:
        ref_pkt["Ether"].src = base_udp_pkt["Ether"].dst
        ref_pkt["Ether"].dst = base_udp_pkt["Ether"].src
    if "IP" in ref_pkt:
        ref_pkt["IP"].src = base_udp_pkt["IP"].dst
        ref_pkt["IP"].dst = base_udp_pkt["IP"].src
    if "UDP" in ref_pkt:
        ref_pkt["UDP"].sport = base_udp_pkt["UDP"].dport
        ref_pkt["UDP"].dport = base_udp_pkt["UDP"].sport

    payload = BeehiveVRHdr(msg_type=BeehiveVRHdr.SetupBeehiveResp).to_bytearray()
    ref_pkt = ref_pkt/Raw(payload)
    ref_pkt = base_type(bytearray(ref_pkt.build()))

    if not ref_pkt["UDP"].sport in tb.recv_pkts:
        tb.recv_pkts[ref_pkt["UDP"].sport] = deque()

    tb.recv_pkts[ref_pkt["UDP"].sport].append(ref_pkt)

    await recv_coro(tb)

def should_send_pkt(pkt, dst_port):
    # check it's to the right destination
    if pkt["UDP"].dport != dst_port:
        return False
    # check it's a message type we want to be sending
    payload = pkt["Raw"].load
    beehive_hdr = BeehiveVRHdr()
    beehive_hdr.fr_bytearray(payload)
    if ((beehive_hdr.msg_type != BeehiveVRHdr.Prepare) or 
        (beehive_hdr.msg_type != BeehiveVRHdr.Commit)):
        return False

def supported_msg_type(beehive_hdr):
    return ((beehive_hdr.msg_type == BeehiveVRHdr.Prepare) or
            (beehive_hdr.msg_type == BeehiveVRHdr.PrepareOK) or
            (beehive_hdr.msg_type == BeehiveVRHdr.Commit) or
            (beehive_hdr.msg_type == BeehiveVRHdr.StartViewChange) or
            (beehive_hdr.msg_type == BeehiveVRHdr.DoViewChange) or
            (beehive_hdr.msg_type == BeehiveVRHdr.StartView) or
            (beehive_hdr.msg_type == BeehiveVRHdr.ValidateReadReq) or
            (beehive_hdr.msg_type == BeehiveVRHdr.ValidateReadReply))

def pad_packet(tb, packet_buffer):
    if len(packet_buffer) < tb.MIN_PKT_SIZE:
        padding = tb.MIN_PKT_SIZE - len(packet_buffer)
        pad_bytes = bytearray([0] * padding)
        packet_buffer.extend(pad_bytes)
