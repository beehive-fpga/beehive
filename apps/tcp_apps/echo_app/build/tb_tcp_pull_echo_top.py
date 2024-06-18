import logging

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.log import SimLog
from cocotb.queue import Queue
from scapy.utils import PcapWriter
from scapy.data import DLT_EN10MB
from scapy.compat import bytes_encode
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

from tcp_automaton_driver import TCPAutomatonDriver, EchoGenerator
from simple_pcap_replay import SimplePcapReplay, SimplePcapReplayStatus

class TB():
    def __init__(self, dut, open_log_file=False):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
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

        self.TCP_driver = TCPAutomatonDriver(2, EchoGenerator, dut.clk)
        if open_log_file:
            self.logfile = PcapWriter("debug_pcap.pcap", linktype=DLT_EN10MB)



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


IP_TO_MAC = {
    "198.19.100.18": "00:0a:35:0d:4d:28",
    "198.19.100.17": "b8:59:9f:b7:ba:44"
}


@cocotb.test()
async def run_tcp_echo_test(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=256))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())

    tb = TB(dut, open_log_file=True)
    await reset(dut)

    send_queue = Queue(0)
    recv_queue = Queue(0)

    send_task = cocotb.start_soon(run_send_loop(dut, tb, send_queue))
    recv_task = cocotb.start_soon(run_recv_loop(dut, tb, recv_queue))
#    logger_switch = cocotb.start_soon(run_logger(dut, tb, send_queue, recv_queue))

    await Combine(send_task, recv_task)
    tb.logfile.close()

async def timer_wait_wrapper(timer):
    await timer

async def run_logger(dut, tb, send_queue, recv_queue):
    with PcapWriter("debug_pcap.pcap", linktype=DLT_EN10MB) as log_file:
        while True:
            # try to get packet to sent if there is one waiting
            if not send_queue.empty():
                pkt_sent = send_queue.get_nowait()
                raw = bytes_encode(pkt_sent)
                log_file.write(raw)

            # try to get a packet that was received if one was received
            if not recv_queue.empty():
                pkt_recv = recv_queue.get_nowait()
                raw = bytes_encode(pkt_recv)
                log_file.write(raw)

            await RisingEdge(dut.clk)

            await RisingEdge(dut.clk)

async def run_send_loop(dut, tb, send_queue):
    pkts_sent = 0
    timers = []
    while True:
        pkt_to_send, timer = tb.TCP_driver.get_packet_to_send()
        if pkt_to_send is not None:
            if timer is not None:
                timers.append(timer)
            eth = Ether()
            eth.src = IP_TO_MAC[pkt_to_send[IP].src]
            eth.dst = IP_TO_MAC[pkt_to_send[IP].dst]

            pkt_to_send = eth/pkt_to_send
            pkt_bytes = bytearray(pkt_to_send.build())

            if len(pkt_to_send) < 64:
                padding = 64 - len(pkt_to_send)
                pad_bytes = bytearray([0] * padding)
                pkt_bytes.extend(pad_bytes)

            tb.log.debug(f"Sending sequence num {hex(pkt_to_send[TCP].seq)}")

            await tb.input_op.xmit_frame(pkt_bytes)
            tb.logfile.write(bytes_encode(pkt_bytes))
            tb.logfile.flush()
            pkts_sent += 1
            tb.log.info(f"Pkts sent {pkts_sent}")
            #if (pkts_sent >= 3):
            #    await ClockCycles(dut.clk, 2048)
            # check how many timers we have set, periodically wait for them all
            if (len(timers) >= 5):
                await Combine(*timers)
                await RisingEdge(dut.clk)

        # Otherwise, wait until something happens
        else:
            # check if we're all done, so we should exit the send loop
            if tb.TCP_driver.all_flows_done():
                return
            else:
                await RisingEdge(dut.clk)

async def run_recv_loop(dut, tb, recv_queue):
    pkts_recv = 0
    while True:
        pkt_recv = await tb.output_op.recv_frame()
        tb.logfile.write(bytes_encode(pkt_recv))
        tb.logfile.flush()

        tb.TCP_driver.recv_packet(pkt_recv)
        pkts_recv +=1
        tb.log.info(f"Pkts recv {pkts_recv}")

        # check if we're all done, so we should exit the recv loop
        if tb.TCP_driver.all_flows_closed():
            return

#@cocotb.test()
async def run_tcp_echo_trace(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=256))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())

    tb = TB(dut)
    replayer = SimplePcapReplay("conn2_tcp.pcap", tb, "b8:59:9f:b7:ba:44")

    await reset(dut)

    result = SimplePcapReplayStatus.OK
    while result != SimplePcapReplayStatus.DONE:
        result = await replayer.step_trace()
        await RisingEdge(dut.clk)
#        await ClockCycles(dut.clk, 64)

    tb.log.info("Finished trace")

    while True:
        pkt_extra = await tb.output_op.recv_frame()
        pkt_extra_cast = Ether(pkt_extra)
        tb.log.info(f"Received extra packet{pkt_extra_cast.show2(dump=True)}")

