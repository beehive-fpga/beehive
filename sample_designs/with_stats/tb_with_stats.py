import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import with_timeout, Event, First, Join
from cocotb.result import SimTimeoutError
from cocotb.log import SimLog
from cocotb.queue import Queue
from cocotb.utils import get_sim_time
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
from tcp_driver import TCPFourTuple, TCPState
from tcp_automaton_driver import TCPAutomatonDriver, TCPAutomaton, RequestGenReturn

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/stats_read/")
from stats_checker import StatsChecker, StatsReq

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/udp_echo/")
from tb_udp_echo import create_udp_frame, check_udp_frame, pad_packet, bandwidth_log_test


class TB():
    def __init__(self, dut, buf_size, open_log_file=False):
        self.MAC_W = 512
        self.MAC_BYTES = int(self.MAC_W/8)
        self.MIN_PKT_SIZE=64
        self.MSS_SIZE=9100
        self.CLOCK_CYCLE_TIME = 4
        self.IP_TO_MAC = {
            "198.0.0.5": "b8:59:9f:b7:ba:44",
            "198.0.0.7": "00:0a:35:0d:4d:c6",
        }

        self.dut = dut
        self.clk = dut.clk
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.INFO)
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
        self.done_event = Event()

        # pass in list of tiles we want

        tiles = [StatsReq(x=0, y=0),
                StatsReq(x=1, y=0),
                StatsReq(x=0, y=1), StatsReq(x = 0, y = 2)]
                #StatsReq(x=2,y=2)]
                #StatsReq(x = 0, y =1), StatsReq(x = 0, y =2), StatsReq(x=3, y =1),
                #StatsReq(x=2, y =0), StatsReq(x=3, y = 0)]
        
        self.conn_list = [setup_stats_checker(self.done_event, tiles)]

        self.TCP_driver = TCPAutomatonDriver(dut.clk, req_gen_list=self.conn_list)
        self.logfile = None
        if open_log_file:
            self.logfile = PcapWriter("debug_pcap.pcap", linktype=DLT_EN10MB)

        self.timer_queue = Queue()

def setup_stats_checker(done_event, tiles):
    four_tuple = TCPFourTuple(
        our_ip = "198.0.0.5",
        our_port = 50000,
        their_ip = "198.0.0.7",
        their_port = 60000
        )
    log = SimLog(f"cocotb_conn_{four_tuple.our_port}")
    log.setLevel(logging.DEBUG)

    req_gen = StatsChecker(log, four_tuple.our_port, done_event, tiles)

    return (req_gen, four_tuple)


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


@cocotb.test()
async def run_tcp_open_test(dut):
    # Set some initial values
    tb = TB(dut, 64, open_log_file=True)

    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

    tb.log.info("Running load through")

    await bandwidth_log_test(tb, wait_on_reqs=False)

    # run some UDP packets through just to generate some logging data

    #test_udp_pkt = create_udp_frame(64)

    #for i in range(0, 5):
    #    pkt_bytes = test_udp_pkt.build()
    #    await tb.input_op.xmit_frame(pkt_bytes)

    #    echoed_pkt_bytes = await tb.output_op.recv_frame()

    #    check_udp_frame(echoed_pkt_bytes, pkt_bytes)

    random.seed(100)
    # just send a mix of payload sizes
    #for i in range(0, 5):
    #    payload_size = random.randint(1, 2048)
    #    pkt = create_udp_frame(payload_size)
    #    test_bytes = pkt.build()
    #    pad_packet(test_bytes)

    #    await tb.input_op.xmit_frame(test_bytes)

    #    echoed_bytes = await tb.output_op.recv_frame()

    #    check_udp_frame(echoed_bytes, test_bytes)


    # okay now attempt to read back
    #tb.log.info("Trying to read back log")
    #app_loops = tb.TCP_driver.run_req_gens()
    #send_task = cocotb.start_soon(run_send_loop(tb))
    #recv_task = cocotb.start_soon(run_recv_loop(tb))
    #timer_task = cocotb.start_soon(timer_tasks(tb))

    #tb.conn_list[0][0].got_resp.set()
    #await Combine(send_task, recv_task, timer_task, app_loops)

    await RisingEdge(dut.clk)


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


async def timer_tasks(tb):
    cocotb.log.info("Starting timer loop")
    while True:
        try:
            queue_get = cocotb.start_soon(tb.timer_queue.get())
            timer_data = await with_timeout(queue_get, tb.CLOCK_CYCLE_TIME *
                    100, timeout_unit="ns")
            timer = timer_data[0]
            time_set = timer_data[1]
#            tb.log.info(f"dequeued timer set at {time_set}")
            await timer
        except SimTimeoutError:
            if tb.done_event.is_set():
                return

async def send_one(tb, pkt_to_send):
    eth = Ether()
    eth.src = tb.IP_TO_MAC[pkt_to_send[IP].src]
    eth.dst = tb.IP_TO_MAC[pkt_to_send[IP].dst]

    pkt_to_send = eth/pkt_to_send
    pkt_bytes = bytearray(pkt_to_send.build())

    if len(pkt_to_send) < tb.MIN_PKT_SIZE:
        padding = tb.MIN_PKT_SIZE - len(pkt_to_send)
        pad_bytes = bytearray([0] * padding)
        pkt_bytes.extend(pad_bytes)

    tb.log.debug(f"Sending sequence num {hex(pkt_to_send[TCP].seq)}")

    await tb.input_op.xmit_frame(pkt_bytes)
    if tb.logfile is not None:
        tb.logfile.write(bytes_encode(pkt_bytes))
        tb.logfile.flush()


async def run_send_loop(tb, stats_queue=None):
    pkts_sent = 0
    tot_bytes = 0

    message_entries = []
    MEASURE_START_NS = 6500


    while True:
        pkt_to_send, timer = await tb.TCP_driver.get_packet_to_send()

        if pkt_to_send is not None:
            if timer is not None:
                tb.timer_queue.put_nowait((timer,
                    cocotb.utils.get_sim_time(units="ns")))
            await send_one(tb, pkt_to_send)
            pkts_sent += 1
            tb.log.info(f"Pkts sent {pkts_sent}")

        # Otherwise, wait until something happens
        else:
            # check if we're all done, so we should exit the send loop
            if tb.done_event.is_set():
                tb.log.info("Send loop exiting")
                if stats_queue is not None:
                    stats_queue.put_nowait(message_entries)
                return
            else:
                await RisingEdge(tb.clk)

async def run_recv_loop(tb, stats_queue=None):
    pkts_recv = 0
    cycles_waited = 0
    tot_bytes = 0

    message_entries = []

    while True:
        resp_coro = cocotb.start_soon(tb.output_op.recv_frame())
        pkt_recv = await First(tb.done_event.wait(), resp_coro)
        if (tb.done_event.is_set()):
            break
        tb.log.debug(f"Got buffer {pkt_recv}")
        if tb.logfile is not None:
            tb.logfile.write(bytes_encode(pkt_recv))
            tb.logfile.flush()

        tb.TCP_driver.recv_packet(pkt_recv)
        pkts_recv +=1
        tb.log.info(f"Pkts recv {pkts_recv}")

    if stats_queue is not None:
        stats_queue.put_nowait(message_entries)

