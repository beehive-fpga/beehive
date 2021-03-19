import logging

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
from tcp_logger_read import TCPLoggerReader
from tcp_automaton_driver import TCPAutomatonDriver, TCPAutomaton, RequestGenReturn
from open_loop_generator import OpenLoopGenerator, ClientDir
from simple_pcap_replay import SimplePcapReplay, SimplePcapReplayStatus

from tcp_open_bw_log_read import TCPOpenBwLogEntry, TCPOpenBwLogRead

class TB():
    def __init__(self, dut, num_conns, direction, num_reqs, buf_size,
            should_copy,
            open_log_file=False):
        self.MAC_W = 512
        self.MAC_BYTES = int(self.MAC_W/8)
        self.MIN_PKT_SIZE=64
        self.MSS_SIZE=9100
        self.CLOCK_CYCLE_TIME = 4
        self.IP_TO_MAC = {
            "198.0.0.5": "b8:59:9f:b7:ba:44",
            "198.0.0.7": "00:0a:35:0d:4d:c6",
        }

        self.num_conns = num_conns
        self.buf_size = buf_size
        self.direction = direction
        self.num_reqs = num_reqs
        self.should_copy = should_copy

        self.dut = dut
        self.clk = dut.clk
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
        self.done_event = Event()

        self.conn_list = setup_conn_list(self.CLOCK_CYCLE_TIME,
                self.done_event, self.num_conns, num_reqs,
                self.direction,
                self.buf_size, self.should_copy)

        self.TCP_driver = TCPAutomatonDriver(dut.clk, req_gen_list=self.conn_list)
        self.logfile = None
        if open_log_file:
            self.logfile = PcapWriter("debug_pcap.pcap", linktype=DLT_EN10MB)

        self.timer_queue = Queue()

def setup_conn_list(cycle_time, done_event, num_conns, num_reqs, test_dir,
        buf_size, should_copy):
    # setup setup connection
    port_num_start = 50000
    conn_list = []

    gen_buf_size = (1 << buf_size.bit_length()) - 1

    for i in range(0, num_conns + 1):
        new_four_tuple = TCPFourTuple(
                our_ip = "198.0.0.5",
                our_port = port_num_start + i,
                their_ip = "198.0.0.7",
                their_port = 65432
                )
        log = SimLog(f"cocotb_conn_{port_num_start + i}.tb")
        log.setLevel(logging.DEBUG)
        req_gen = None
        if i == 0:
            req_gen = OpenLoopGenerator(port_num_start + i, log, done_event,
                    cycle_time, 512, buf_size, test_dir, num_reqs, num_conns,
                    True, should_copy, gen_buf_size)
        else:
            req_gen = OpenLoopGenerator(port_num_start + i, log, done_event,
                    cycle_time, 512, buf_size, test_dir, num_reqs, num_conns,
                    False, should_copy, gen_buf_size)
        conn_list.append((req_gen, new_four_tuple))

    return conn_list


async def run_conn_setup(tb, four_tuple):
    # do the 3 way handshake
    syn,_ = await tb.TCP_driver.get_packet_from_conn(four_tuple)
    tb.log.info("Sending SYN")
    await send_one(tb, syn)

    while True:
        pkt_recv = await tb.output_op.recv_frame()

        (recv_tuple, new_state) = tb.TCP_driver.recv_packet(pkt_recv)

        if recv_tuple == four_tuple:
            # check that the state is correct
            assert (new_state == TCPState.SEND_ACK)
            break

    ack,_ = await tb.TCP_driver.get_packet_from_conn(four_tuple)
    tb.log.info("Sending ACK")
    await send_one(tb, ack)


async def run_setup(tb):
    # get connection 0
    (setup_gen, four_tuple) = tb.conn_list[0]

    # get the connection setup
    await run_conn_setup(tb, four_tuple)
    tb.log.info("First conn setup")

    pkt_to_send = None
    timer = None
    while pkt_to_send == None:
        await RisingEdge(tb.clk)
        pkt_to_send, timer = await tb.TCP_driver.get_packet_from_conn(four_tuple)


    await send_one(tb, pkt_to_send)
    while not setup_gen.setup_resp:
        pkt_recv = await tb.output_op.recv_frame()
        if tb.logfile is not None:
            tb.logfile.write(bytes_encode(pkt_recv))
            tb.logfile.flush()

        (recv_flow, new_state) = tb.TCP_driver.recv_packet(pkt_recv)

        # wait long enough that we know the receive side will have processed it
        await Timer(OpenLoopGenerator.POLL_PERIOD + 8, units="ns")

    tb.log.info("App setup done")
    # set all generators as ready to send
    tb.log.info(f"Setting up {len(tb.conn_list)-1} connections")
    for i in range(1, len(tb.conn_list)):
        (setup_gen, four_tuple) = tb.conn_list[i]
        await run_conn_setup(tb, four_tuple)

    for i in range(1, len(tb.conn_list)):
        (setup_gen, four_tuple) = tb.conn_list[i]
        setup_gen.sent_setup = True
        setup_gen.setup_resp = True

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
    test_dir = ClientDir.SEND;
    # Set some initial values
    tb = TB(dut, 1, test_dir, 20, 8192, False, open_log_file=True)
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

    tb.log.info("Running app setup")
    app_loops = tb.TCP_driver.run_req_gens()
    setup = cocotb.start_soon(run_setup(tb))
    await First(setup, app_loops)

    send_task = cocotb.start_soon(run_send_loop(tb))
    recv_task = cocotb.start_soon(run_recv_loop(tb))
    timer_task = cocotb.start_soon(timer_tasks(tb))
    done_task = cocotb.start_soon(done_monitor(tb))
#    logger_switch = cocotb.start_soon(run_logger(dut, tb, send_queue, recv_queue))

    await Combine(send_task, recv_task, timer_task, app_loops, done_task)

    log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                 our_port = 55000,
                                 their_ip = "198.0.0.7",
                                 their_port = 60000)
    log_reader = TCPOpenBwLogRead(8, 2, tb, log_four_tuple)

    # FIXME: calculate over all the connections
    log_entries = []
    (bench_req_gen, _) = tb.conn_list[1]
    if test_dir == ClientDir.SEND:
        log_entries = bench_req_gen.send_measurements
    else:
        log_entries = bench_req_gen.recv_measurements

    bws = log_reader.calculate_bws(log_entries, tb.CLOCK_CYCLE_TIME)

    cocotb.log.info(f"bws: {bws}")



    #rx_entries = await rx_log_reader.read_log()

    #tx_log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
    #                                our_port = 55000,
    #                                their_ip = "198.0.0.7",
    #                                their_port = 60001)

    #tx_log_reader = TCPLoggerReader(tx_log_four_tuple, 11, 2, tb, IP_TO_MAC,
    #        dut.clk)
    #tx_entries = await tx_log_reader.read_log()

    #entries_list = rx_entries
    #entries_list.extend(tx_entries)

    #entries_list.sort(key=lambda x: x.timestamp)

    #logger_to_pcap(entries_list)
    #tb.logfile.close()
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

async def done_monitor(tb):
    while True:
        if verify_conns_done(tb):
            tb.log.info("All apps done")
            tb.done_event.set()
            break
        else:
            await RisingEdge(tb.clk)
            await ReadOnly()


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

            # Check the sim time and log if time
            curr_time = get_sim_time(units="ns")
            if curr_time >= MEASURE_START_NS:
                tot_bytes += len(pkt_to_send.build())
                cycles = int(curr_time/tb.CLOCK_CYCLE_TIME)
                cycles_bytes = cycles.to_bytes(TCPOpenBwLogEntry.TIMESTAMP_BYTES,
                        byteorder="big")
                tot_bytes_bytes = tot_bytes.to_bytes(TCPOpenBwLogEntry.BYTES_RECV_BYTES,
                        byteorder="big")
                entry_bytearray = cycles_bytes + tot_bytes_bytes
                message_entries.append(TCPOpenBwLogEntry(entry_bytearray))

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

def verify_conns_done(tb):
    for i in range(1, len(tb.conn_list)):
        (setup_gen, four_tuple) = tb.conn_list[i]
        if setup_gen.check_if_done() != RequestGenReturn.DONE:
            return False
        # check if there are any packets that still need to be ACKed
        if tb.TCP_driver.flow_has_unacked(four_tuple):
            return False

    return True



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

        # record stats
        curr_time = get_sim_time(units='ns')
        tot_bytes += tb.buf_size
        cycles = int(curr_time/tb.CLOCK_CYCLE_TIME)
        cycles_bytes = cycles.to_bytes(TCPOpenBwLogEntry.TIMESTAMP_BYTES, byteorder="big")
        tot_bytes_bytes = tot_bytes.to_bytes(TCPOpenBwLogEntry.BYTES_RECV_BYTES,
                        byteorder="big")
        entry_bytearray = cycles_bytes + tot_bytes_bytes
        message_entries.append(TCPOpenBwLogEntry(entry_bytearray))

    if stats_queue is not None:
        stats_queue.put_nowait(message_entries)

#@cocotb.test()
async def run_open_benchmark(dut):
    test_dir = ClientDir.RECV

    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())

    benchmark_runs = [(64, 200), (128, 200), (256, 200), (512, 200), (1024,
       200), (2048, 200), (3072, 200), (4096, 200), (6144, 200), (8192, 200)]

    benchmark_bws = []

    for packet_size, num_reqs in benchmark_runs:
        tb = TB(dut, 1, test_dir, num_reqs, packet_size, True,
                open_log_file=False)
        dut.mac_engine_rx_val.setimmediatevalue(0)
        dut.mac_engine_rx_startframe.setimmediatevalue(0)
        dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0,
            n_bits=tb.MAC_W))
        dut.mac_engine_rx_endframe.setimmediatevalue(0)
        dut.mac_engine_rx_padbytes.setimmediatevalue(0)
        dut.mac_engine_rx_frame_size.setimmediatevalue(0)

        dut.mac_engine_tx_rdy.setimmediatevalue(0)

        await reset(dut)

        tb.log.info("Running app setup")
        app_loops = tb.TCP_driver.run_req_gens()
        setup = cocotb.start_soon(run_setup(tb))
        await First(setup, app_loops)

        send_task = cocotb.start_soon(run_send_loop(tb))
        recv_task = cocotb.start_soon(run_recv_loop(tb))
        timer_task = cocotb.start_soon(timer_tasks(tb))
        done_task = cocotb.start_soon(done_monitor(tb))

        await Combine(send_task, recv_task, timer_task, app_loops, done_task)

        await RisingEdge(dut.clk)
        log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                     our_port = 55000,
                                     their_ip = "198.0.0.7",
                                     their_port = 60000)
        log_reader = TCPOpenBwLogRead(8, 2, tb, log_four_tuple)

        # FIXME: calculate over all the connections
        log_entries = []
        (bench_req_gen, _) = tb.conn_list[1]
        if test_dir == ClientDir.SEND:
            log_entries = bench_req_gen.send_measurements
        else:
            log_entries = bench_req_gen.recv_measurements

        cocotb.log.info(f"log_entries: {log_entries}")

        bws = log_reader.calculate_bws(log_entries, tb.CLOCK_CYCLE_TIME)
        cocotb.log.info(f"bws: {bws}")
        avg_bw = sum(bws)/len(bws)
        benchmark_bws.append((packet_size, avg_bw))

    cocotb.log.info(f"{benchmark_bws}")
