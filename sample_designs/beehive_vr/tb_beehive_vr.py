import logging
import random
import collections
from collections import deque
import socket
from pathlib import Path

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, First, Event
from cocotb.triggers import ClockCycles, with_timeout
from cocotb.log import SimLog
from cocotb.utils import get_sim_time

import scapy
from scapy.utils import PcapReader
from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

import sys, os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

from tcp_driver import TCPFourTuple

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/vr_testing")
from vr_helpers import VRState, BeehiveVRHdr, run_setup
from vr_helpers import PrepareOKHdr, DoViewChangeHdr, RecvWireLogEntryHdr
from vr_helpers import RequestHdr, ValidateReadReply

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/apps/beehive-vr-tile/tb")
from beehive_vr_udp_test import run_setup, supported_msg_type

DST_PORT = 51000

machine_config = [
    ("127.0.0.1", 50000),
    ("127.0.0.1", 51000),
    ("127.0.0.1", 52000)
]

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
        self.MAC_W = 512
        self.MAC_BYTES = int(self.MAC_W/8)
        self.MIN_PKT_SIZE=64
        self.MSS_SIZE=9100
        self.CLOCK_CYCLE_TIME = 4
        log = SimLog("cocotb.tb")
        log.setLevel(logging.DEBUG)
        random.seed(42)
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
        
        self.recv_pkts = {}

@cocotb.test()
async def test_wrapper(dut):
    tb = TB(dut)
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

    await trace_test(tb)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

def checkVRMessage(tb, ref_payload, payload):
    recv_hdr = BeehiveVRHdr()
    recv_hdr.fr_bytearray(payload)

    ref_hdr = BeehiveVRHdr()
    ref_hdr.fr_bytearray(ref_payload)

    if recv_hdr != ref_hdr:
        raise RuntimeError(f"Expected hdr {ref_hdr}, got hdr {recv_hdr}")

    if recv_hdr.msg_type == BeehiveVRHdr.PrepareOK:
        ref_prep_ok_binvalue = BinaryValue(value=ref_payload[BeehiveVRHdr.BEEHIVE_HDR_BYTES:])
        ref_prep_ok = PrepareOKHdr(init_bitstring=ref_prep_ok_binvalue.binstr)

        recv_prep_ok_binvalue = BinaryValue(value=payload[BeehiveVRHdr.BEEHIVE_HDR_BYTES:])
        recv_prep_ok = PrepareOKHdr(init_bitstring=recv_prep_ok_binvalue.binstr)

        if ref_prep_ok != recv_prep_ok:
            raise RuntimeError(f"Expected {ref_prep_ok}, got {recv_prep_ok}")

    elif recv_hdr.msg_type == BeehiveVRHdr.DoViewChange:
        ref_do_view_change_binvalue = BinaryValue(value=ref_payload[BeehiveVRHdr.BEEHIVE_HDR_BYTES:])
        ref_do_view_change = DoViewChangeHdr(init_bitstring=ref_do_view_change_binvalue.binstr)

        recv_do_view_change_binvalue = BinaryValue(value=payload[BeehiveVRHdr.BEEHIVE_HDR_BYTES:])
        recv_do_view_change = DoViewChangeHdr(init_bitstring=recv_do_view_change_binvalue.binstr)

        if ref_do_view_change != recv_do_view_change:
            raise RuntimeError(f"Expected {ref_do_view_change}, got {recv_do_view_change}")

        log_entries_offset = (BeehiveVRHdr.BEEHIVE_HDR_BYTES +
                                int(ref_do_view_change.getWidth()/8))
        check_log_entries(ref_payload[log_entries_offset:],
                payload[log_entries_offset:])

    elif recv_hdr.msg_type == BeehiveVRHdr.ValidateReadReply:
        ref_val_reply_binvalue = BinaryValue(value=ref_payload[BeehiveVRHdr.BEEHIVE_HDR_BYTES:])
        ref_val_reply = ValidateReadReply(init_bitstring=ref_val_reply_binvalue.binstr)

        recv_val_reply_binvalue = BinaryValue(value=payload[BeehiveVRHdr.BEEHIVE_HDR_BYTES:])
        recv_val_reply = ValidateReadReply(init_bitstring=recv_val_reply_binvalue.binstr)

        if ref_val_reply != recv_val_reply:
            raise RuntimeError(f"Expected {ref_val_reply}, got {recv_val_reply}")

def check_log_entries(ref_payload, recv_payload):
    curr_payload_ptr = 0
    ref_hdr = RecvWireLogEntryHdr()
    recv_hdr = RecvWireLogEntryHdr()
    log_entry_num = 0

    log_entry_hdr_bytes = int(ref_hdr.getWidth()/8)
    while ((curr_payload_ptr < len(ref_payload)) 
            and (curr_payload_ptr < len(recv_payload))):
        ref_hdr_bytes = BinaryValue(value=ref_payload[curr_payload_ptr:
                    curr_payload_ptr + log_entry_hdr_bytes])
        recv_hdr_bytes = BinaryValue(value=recv_payload[curr_payload_ptr:
            curr_payload_ptr + log_entry_hdr_bytes])
        ref_hdr.fromBinaryString(ref_hdr_bytes.binstr)
        recv_hdr.fromBinaryString(recv_hdr_bytes.binstr)
        if (ref_hdr != recv_hdr):
            raise RuntimeError(f"Expected hdr {ref_hdr}, got {recv_hdr} on "
                                f"entry {log_entry_num}")

        req_hdr = ref_hdr.getInnerReqHdr()
        op_len = req_hdr.getField("op_bytes_len")


        op_offset = curr_payload_ptr + log_entry_hdr_bytes
        ref_op = ref_payload[op_offset:op_offset+op_len]
        recv_op = recv_payload[op_offset:op_offset+op_len]

        if ref_op != recv_op:
            raise RuntimeError(f"Expected op {ref_op}, got {recv_op}")

        curr_payload_ptr += log_entry_hdr_bytes + op_len
        log_entry_num += 1


async def recv_wrapper(tb):
    pkt_bytes = await tb.output_op.recv_frame()
    pkt = Ether(pkt_bytes)

    # zero out the ID manually
    pkt["IP"].id = 0
    # rechecksum the ref packet

    if "Padding" in pkt:
        del(pkt["Padding"])

    
    #assert len(pkt["Raw"]) == len(ref_pkt["Raw"]), "payloads are diff lens"
    if (pkt["UDP"].sport == DST_PORT):
        # check that the deque contains something
        ref_pkts = tb.recv_pkts[pkt["UDP"].sport]
        ref_pkt = None
        if len(ref_pkts) == 0:
            raise RuntimeError("Received unexpected packet")
        else:
            ref_pkt = ref_pkts.popleft()

        payload = pkt["Raw"].load
        ref_payload = ref_pkt["Raw"].load

        checkVRMessage(tb, ref_payload, payload)

        assert pkt["Raw"] == ref_pkt["Raw"]

        assert pkt == ref_pkt, f"pkt is {pkt.show(dump=True)}, ref is {ref_pkt.show(dump=True)}"
    return pkt

async def send_wrapper(tb, pkt):
    #tb.log.info(f"sending packet {pkt.show2(dump=True)}")
    await tb.input_op.xmit_frame(pkt.build())

async def trace_test(tb):
    # put in some junk MAC addresses. 
    base_pkt = Ether(src="00:00:00:00:00:00", dst="00:00:00:00:00:00",
            type=0x0800)/IP(src="127.0.0.1", dst="127.0.0.1", flags="DF",
                    id=0)/UDP(sport=50000, dport=51000)
    await run_setup(tb, base_pkt, send_wrapper,
            recv_wrapper, machine_config, machine_config[1])

    trace_file = PcapReader(os.environ["BEEHIVE_PROJECT_ROOT"] +
            "/apps/beehive-vr-tile/tb/read_validate_trace.pcap")
    trace_pkt_num = 0
    while True:
        try:
            pkt = trace_file.read_packet()
            trace_pkt_num += 1

            payload = pkt["Raw"].load
            beehive_hdr = BeehiveVRHdr()
            beehive_hdr.fr_bytearray(payload)
            tb.log.debug(f"Header is {beehive_hdr}")
            if not supported_msg_type(beehive_hdr):
                tb.log.info(f"Not replaying packet {trace_pkt_num} due to "
                    "bad message type")
                continue

            pkt["UDP"].chksum = None
            pkt["IP"].id = 0
            pkt["IP"].chksum = None
            pkt = Ether(pkt.build())

            # do we want to send or receive this packet
            if pkt["UDP"].dport == DST_PORT:
                tb.log.info(f"Sending packet {trace_pkt_num}")
                # force rechecksum of the UDP layer since it didn't do it
                await send_wrapper(tb, pkt)
            elif pkt["UDP"].sport == DST_PORT:
                tb.log.info(f"Receiving packet {trace_pkt_num}")
                if not pkt["UDP"].sport in tb.recv_pkts:
                    tb.recv_pkts[pkt["UDP"].sport] = deque()
    
                tb.recv_pkts[pkt["UDP"].sport].append(pkt)
                await recv_wrapper(tb)
            else:
                tb.log.info(f"Not replaying packet {trace_pkt_num} due to "
                    "unknown port")
        except EOFError:
                return


