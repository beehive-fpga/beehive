import random 
import sys, os
import logging

import ipaddress

import scapy
from scapy.packet import Raw
from scapy.utils import PcapReader
from scapy.layers.inet import UDP, IP

from cocotb_test.simulator import run
import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import with_timeout
from cocotb.log import SimLog
from math import ceil

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")
from noc_helpers import BeehiveHdrFlit, BeehiveNoCConstants, BeehiveUDPFlit
from simple_val_rdy import SimpleValRdyFrame, SimpleValRdyBus
from simple_val_rdy import SimpleValRdyBusSource, SimpleValRdyBusSink

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/vr_testing")
from vr_helpers import VRState, BeehiveVRHdr, run_setup, should_send_pkt, supported_msg_type
   
UDP_RX_SEGMENT = 12
UDP_TX_SEGMENT = 13
SRC_X = 1
SRC_Y = 1
DST_PORT = 51000

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimpleValRdyBus(dut,
                {"val":"noc_ctovr_app_val",
                 "data": "noc_ctovr_app_data",
                 "rdy": "app_noc_ctovr_rdy"},
                 data_width = 512)
        self.input_op = SimpleValRdyBusSource(self.input_bus, dut.clk)
        self.output_bus = SimpleValRdyBus(dut,
                {"val": "app_noc_vrtoc_val",
                 "data": "app_noc_vrtoc_data",
                 "rdy": "noc_vrtoc_app_rdy"},
                 data_width = 512)
        self.output_op = SimpleValRdyBusSink(self.output_bus, dut.clk)

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

machine_config = [
    ("127.0.0.1", 50000),
    ("127.0.0.1", 51000),
    ("127.0.0.1", 52000)
]

@cocotb.test()
async def beehive_vr_test(dut):
    # Set some initial values
    dut.noc_ctovr_app_val.setimmediatevalue(0)
    dut.noc_ctovr_app_data.setimmediatevalue(0)

    dut.noc_vrtoc_app_rdy.setimmediatevalue(0)
    
    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())

    tb = TB(dut)
    await reset(dut)

    base_pkt = IP(src="127.0.0.1", dst="127.0.0.1")/UDP(sport=50000, dport=52001)
    await run_setup(tb, base_pkt, send_pkt, recv_pkt, machine_config,
            machine_config[1])

    await run_trace(tb)


async def run_trace(tb):
    trace_file = PcapReader(os.environ["BEEHIVE_PROJECT_ROOT"] + "/apps/beehive-vr-tile/tb/view_change_trace.pcap")
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

            # do we want to send or receive this packet
            if pkt["UDP"].dport == DST_PORT:
                tb.log.info(f"Sending packet {trace_pkt_num}")
                await send_pkt(tb, pkt)
            elif pkt["UDP"].sport == DST_PORT:
                tb.log.info(f"Receiving packet {trace_pkt_num}")
                await recv_pkt(tb, pkt)
            else:
                tb.log.info(f"Not replaying packet {trace_pkt_num} due to "
                    "unknown port")
        except EOFError:
                return

def validate_recv_flits(hdr_flit, meta_flit, payload, expected_pkt):
    num_data_flits = ceil(len(expected_pkt["Raw"].load)/(BeehiveNoCConstants.NOC_DATA_W/8))
    assert hdr_flit.dst_x == SRC_X
    assert hdr_flit.dst_y == SRC_Y
    assert hdr_flit.dst_fbits.binstr == "1001"
    assert hdr_flit.msg_length == num_data_flits + 1
    assert hdr_flit.msg_type == UDP_TX_SEGMENT

    src_ip = str(ipaddress.IPv4Address(meta_flit.src_ip.integer))
    dst_ip = str(ipaddress.IPv4Address(meta_flit.dst_ip.integer))


    assert src_ip == expected_pkt["IP"].src
    assert dst_ip == expected_pkt["IP"].dst
    assert meta_flit.src_port.integer == expected_pkt["UDP"].sport
    assert meta_flit.dst_port.integer == expected_pkt["UDP"].dport
    assert meta_flit.payload_len.integer == expected_pkt["UDP"].len - 8

    assert payload == expected_pkt["Raw"].load

async def recv_pkt(tb, pkt):
    noc_bytes = int(BeehiveNoCConstants.NOC_DATA_W/8)
    test_buf = bytearray()

    hdr_flit_data = await tb.output_op.recv_resp()
    hdr_flit = BeehiveHdrFlit()
    hdr_flit.flit_from_bitstring(hdr_flit_data.data.binstr)
    udp_flit_data = await tb.output_op.recv_resp()
    udp_flit = BeehiveUDPFlit()
    udp_flit.flit_from_bitstring(udp_flit_data.data.binstr)

    num_payload_bytes = udp_flit.payload_len.integer
    num_payload_flits = hdr_flit.msg_length.integer - 1
    expected_data_flits = ceil(num_payload_bytes/(BeehiveNoCConstants.NOC_DATA_W/8))
    assert num_payload_flits == expected_data_flits
    
    for i in range(0, num_payload_flits):
        noc_data = await tb.output_op.recv_resp()
        if num_payload_bytes <= noc_bytes:
            test_buf.extend(noc_data.data.buff[0:num_payload_bytes])
        else:
            test_buf.extend(noc_data.data.buff[0:noc_bytes])

    validate_recv_flits(hdr_flit, udp_flit, test_buf, pkt)

async def send_pkt(tb, pkt):
    noc_hdr_flit = BeehiveHdrFlit()
    data_buf = bytearray(pkt["Raw"].load)

    num_data_flits = ceil(len(data_buf)/(BeehiveNoCConstants.NOC_DATA_W/8))
    
    # fill in the header flit
    noc_hdr_flit.set_field("dst_x", 2)
    noc_hdr_flit.set_field("dst_y", 2)
    noc_hdr_flit.set_field("dst_fbits", "1000")
    noc_hdr_flit.set_field("msg_length", num_data_flits + 1)
    noc_hdr_flit.set_field("msg_type", UDP_RX_SEGMENT)
    noc_hdr_flit.set_field("src_x", SRC_X)
    noc_hdr_flit.set_field("src_y", SRC_Y)
    noc_hdr_flit.set_field("src_fbits", "1000")
    noc_hdr_flit.set_field("metadata_flits", 1)
    noc_hdr_flit_bin = noc_hdr_flit.assemble_flit()

    udp_meta_flit = BeehiveUDPFlit()
    udp_meta_flit.set_field("src_ip", pkt["IP"].src)
    udp_meta_flit.set_field("dst_ip", pkt["IP"].dst)
    udp_meta_flit.set_field("src_port", pkt["UDP"].sport)
    udp_meta_flit.set_field("dst_port", pkt["UDP"].dport)
    udp_meta_flit.set_field("payload_len", pkt["UDP"].len)
    udp_meta_flit_bin = udp_meta_flit.assemble_flit()
    
    req_values = SimpleValRdyFrame(data=noc_hdr_flit_bin.buff, data_width=512)
    await tb.input_op.send_req(req_values)
    req_values = SimpleValRdyFrame(data=udp_meta_flit_bin.buff, data_width=512)
    await tb.input_op.send_req(req_values)
    await tb.input_op.send_buf(data_buf)


def test_beehive_vr_udp():
    base_run_args = {}
    base_run_args["toplevel"] = "vr_app_wrap"
    base_run_args["module"] = "beehive_vr_udp_test"

    base_run_args["verilog_sources"] = [
                os.path.join("..", "vr_app_wrap.sv"),
            ]


    base_run_args["sim_args"] = ["-voptargs=+acc"]
    compile_arg_string = f"{os.path.join(os.getcwd(), 'vr_app_test.flist')}"
    base_run_args["compile_args"] = ["-f", f"{compile_arg_string}"]
    base_run_args["force_compile"] = True
    
    base_run_args["parameters"] = {
        "SRC_X": 2,
        "SRC_Y": 2,
        "SRC_FBITS": 8,
    }
    base_run_args["waves"] = 1
    base_run_args["gui"] = 1
    
    run(**base_run_args)
