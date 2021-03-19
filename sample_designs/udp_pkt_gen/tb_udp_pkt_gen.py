import logging
import random
import collections
from pathlib import Path

import cocotb

from cocotb.queue import Queue
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, First, Event
from cocotb.triggers import ClockCycles, with_timeout
from cocotb.log import SimLog
from cocotb.utils import get_sim_time
import scapy
import socket

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

import sys, os

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

from tcp_driver import TCPFourTuple

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/udp_echo/")
from tb_udp_echo import TB, sanity_test, bandwidth_log_test, reset, pad_packet
from tb_udp_echo import create_udp_frame, recv_event_wrapper


@cocotb.test()
async def test_wrapper(dut):
    tb = TB(dut)
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    await reset(dut)

    # make sure the UDP echo still works
#    await sanity_test(tb)
    await bandwidth_log_test(tb)

    # okay now run a packet gen test
#    for i in range(6, 14):
#        packet_size = 1 << i
#        await packet_gen_test(tb, 5000, packet_size)

async def echo_loop(tb, queue, done_event, payload_size):
    num_recv = 0
    payload_reps = int(payload_size/8)

    while not done_event.is_set():
        queue_trigger = cocotb.start_soon(queue.get())
        trigger = await recv_event_wrapper(tb, done_event, queue_trigger, 100)

        if trigger == None:
           break
        else:
            # check the payload is good
            expected_payload = num_recv.to_bytes(8, byteorder="big") * payload_reps

            resp_pkt = trigger.copy()
            if (expected_payload != resp_pkt["Raw"].load):
                cocotb.log.warning(f"Expected: {expected_payload}, got: {resp_pkt['Raw'].load}")

            resp_pkt["Ethernet"].src = trigger["Ethernet"].dst
            resp_pkt["Ethernet"].dst = trigger["Ethernet"].src
            resp_pkt["IP"].src = trigger["IP"].dst
            resp_pkt["IP"].dst = trigger["IP"].src
            resp_pkt["IP"].chksum = None
            resp_pkt["UDP"].sport = trigger["UDP"].dport
            resp_pkt["UDP"].dport = trigger["UDP"].sport
            resp_pkt["UDP"].chksum = None
            resp_buf = bytearray(resp_pkt.build())
            pad_packet(tb, resp_buf)

            await tb.input_op.xmit_frame(resp_buf)
            num_recv += 1

async def recv_route(tb, pkt_queue, done):
    start_time = 0
    while True:
        pkt_buf = await tb.output_op.recv_frame()
        if start_time == 0:
            start_time = get_sim_time(units="ns")
        output_pkt = Ether(pkt_buf)
        #tb.log.info(f"Got packet {output_pkt.show2(dump=True)}")

        if output_pkt["UDP"].dport == 65000:
            pkt_queue.put_nowait(output_pkt)
        else:
            done.set()
            tb.log.info("Set done")
            end_time = get_sim_time(units="ns")
            return end_time - start_time

async def packet_gen_test(tb, runtime_cycles, packet_size):
    # craft setup packet
    setup_buf = SetupPacket.create_pkt_buf(runtime_cycles, packet_size, "198.0.0.5", 65000)
    cocotb.log.info(f"Setup buffer: {setup_buf}")

    setup_pkt = create_udp_frame(1)
    setup_pkt["UDP"].dport = 40000
    setup_pkt["Raw"].load = setup_buf
    pkt_queue = Queue()
    done = Event()

    send_buf = bytearray(setup_pkt.build())
    pad_packet(tb, send_buf)

    await tb.input_op.xmit_frame(send_buf)

    echo_task = cocotb.start_soon(echo_loop(tb, pkt_queue, done, packet_size))
    recv_task = cocotb.start_soon(recv_route(tb, pkt_queue, done))

    results = await Combine(echo_task, recv_task)

    runtime = await results.triggers[1]

    cocotb.log.info(f"Expected runtime: {runtime_cycles * 4}ns, measure runtime: {runtime}ns")

    await RisingEdge(tb.clk)
    await RisingEdge(tb.clk)
    await RisingEdge(tb.clk)

class SetupPacket():
    CYCLES_BYTES = 8
    PACKET_SIZE_BYTES = 8 

    def create_pkt_buf(runtime_cycles, buf_size, dst_ip, dst_port):
        packet_buf = bytearray([])

        packet_buf.extend(runtime_cycles.to_bytes(SetupPacket.CYCLES_BYTES, byteorder="big"))
        packet_buf.extend(buf_size.to_bytes(SetupPacket.PACKET_SIZE_BYTES,
            byteorder="big"))
        packet_buf.extend(socket.inet_aton(dst_ip))
        packet_buf.extend(dst_port.to_bytes(2, byteorder="big"))

        return packet_buf
