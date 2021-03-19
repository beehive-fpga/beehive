import logging

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import with_timeout, Event, First, Join
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

from tcp_driver import TCPFourTuple, TCPState, RequestGenReturn
from tcp_logger_read import TCPLoggerReader
from tcp_automaton_driver import TCPAutomatonDriver, TCPAutomaton, EchoGenerator
from simple_pcap_replay import SimplePcapReplay, SimplePcapReplayStatus

from tcp_open_bw_log_read import TCPOpenBwLogEntry, TCPOpenBwLogRead

class TB():
    def __init__(self, dut, open_log_file=False):
        self.MAC_W = 512
        self.MAC_BYTES = int(self.MAC_W/8)
        self.MIN_PKT_SIZE=64
        self.MSS_SIZE=9100
        self.CLOCK_CYCLE_TIME = 4

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

        self.req_gen_list = setup_conn_list(1, self.MAC_W, 8192, 8192, 2,
                self.done_event, self.CLOCK_CYCLE_TIME)

        self.TCP_driver = TCPAutomatonDriver(dut.clk, self.req_gen_list)
        if open_log_file:
            self.logfile = PcapWriter("debug_pcap.pcap", linktype=DLT_EN10MB)

        self.timer_queue = Queue()

        self.IP_TO_MAC = {
            "198.0.0.5": "b8:59:9f:b7:ba:44",
            "198.0.0.7": "00:0a:35:0d:4d:c6",
        }


def setup_conn_list(num_conns, data_width, req_len, resp_len, client_len_bytes,
        done_event, cycle_time, num_reqs):
    req_gen_list = []

    port_num_start = 50000
    for i in range (0, num_conns):
        new_four_tuple = TCPFourTuple(
                our_ip = "198.0.0.5",
                our_port = port_num_start + i,
                their_ip = "198.0.0.7",
                their_port = 65432
                )
        log = SimLog(f"cocotb_conn_{port_num_start + i}.tb")
        log.setLevel(logging.DEBUG)
        req_gen = EchoGenerator(log, port_num_start + i, done_event,
                cycle_time, data_width, req_len,
                resp_len, client_len_bytes, num_reqs=num_reqs)
        req_gen_list.append((req_gen, new_four_tuple))

    return req_gen_list

async def end_monitor(tb):
    while True:
        all_done = True
        for (req_gen, four_tuple) in tb.req_gen_list:
            maybe_done = req_gen.check_if_done() == RequestGenReturn.DONE
            all_done = all_done and maybe_done
        if all_done:
            tb.log.info("All apps done")
            tb.done_event.set()
            break
        else:
            await RisingEdge(tb.clk)
            await ReadOnly()

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
async def run_tcp_echo_test(dut):
    # Set some initial values
    tb = TB(dut, open_log_file=True)
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())

    await reset(dut)

    send_queue = Queue(0)
    recv_queue = Queue(0)

    send_task = cocotb.start_soon(run_send_loop(dut, tb))
    recv_task = cocotb.start_soon(run_recv_loop(dut, tb))
    timer_task = cocotb.start_soon(timer_tasks(tb))
    app_loops = tb.TCP_driver.run_req_gens()
    done_task = cocotb.start_soon(end_monitor(tb))
#    logger_switch = cocotb.start_soon(run_logger(dut, tb, send_queue, recv_queue))

    await Combine(send_task, recv_task, timer_task, app_loops, done_task)

    (req_gen, _) = tb.req_gen_list[0]
    log_entries = req_gen.recv_measurements

    log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                 our_port = 55000,
                                 their_ip = "198.0.0.7",
                                 their_port = 60000)
    log_reader = TCPOpenBwLogRead(8, 2, tb, log_four_tuple)

    bws = log_reader.calculate_bws(log_entries, tb.CLOCK_CYCLE_TIME)

    cocotb.log.info(f"bws: {bws}")

    #rx_log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
    #                                our_port = 55000,
    #                                their_ip = "198.0.0.7",
    #                                their_port = 60000)
    #rx_log_reader = TCPLoggerReader(rx_log_four_tuple, 11, 2, tb, tb.IP_TO_MAC,
    #        dut.clk)

    #rx_entries = await rx_log_reader.read_log()

    #tx_log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
    #                                our_port = 55000,
    #                                their_ip = "198.0.0.7",
    #                                their_port = 60001)

    #tx_log_reader = TCPLoggerReader(tx_log_four_tuple, 11, 2, tb, tb.IP_TO_MAC,
    #        dut.clk)
    #tx_entries = await tx_log_reader.read_log()

    #entries_list = rx_entries
    #entries_list.extend(tx_entries)

    #entries_list.sort(key=lambda x: x.timestamp)

    #logger_to_pcap(entries_list)
    tb.logfile.close()



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
        queue_get = cocotb.start_soon(tb.timer_queue.get())
        timer_data = await First(tb.done_event.wait(), Join(queue_get))
        if tb.done_event.is_set():
            cocotb.log.info("Timer loop exiting")
            return
        timer = timer_data[0]
        time_set = timer_data[1]

#        tb.log.info(f"dequeued timer set at {time_set}")
        await timer


async def run_send_loop(dut, tb):
    pkts_sent = 0
    while True:
        pkt_to_send, timer = await tb.TCP_driver.get_packet_to_send()
        if pkt_to_send is not None:
            if timer is not None:
                tb.timer_queue.put_nowait((timer,
                    cocotb.utils.get_sim_time(units="ns")))
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
            tb.logfile.write(bytes_encode(pkt_bytes))
            tb.logfile.flush()
            pkts_sent += 1
            tb.log.info(f"Pkts sent {pkts_sent}")

        # Otherwise, wait until something happens
        else:
            # check if we're all done, so we should exit the send loop
            if tb.done_event.is_set():
                cocotb.log.info("Send loop exiting")
                return
            else:
                await RisingEdge(tb.clk)

async def run_recv_loop(dut, tb):
    pkts_recv = 0
    cycles_waited = 0
    while True:
        resp_coro = cocotb.start_soon(tb.output_op.recv_frame())
        pkt_recv = await First(tb.done_event.wait(), resp_coro)

        if tb.done_event.is_set():
            break

        tb.logfile.write(bytes_encode(pkt_recv))
        tb.logfile.flush()

        tb.TCP_driver.recv_packet(pkt_recv)
        pkts_recv +=1
        tb.log.info(f"Pkts recv {pkts_recv}")


def logger_to_pcap(entries):
    server_port = 65432
    with PcapWriter("logger_pcap.pcap", linktype=DLT_EN10MB) as logger_tile_file:
        for entry in entries:
            # rebuild the pkts
            tcp_pkt = entry.tcp_hdr.copy()
            tcp_pkt.chksum = None

            # generate a fake payload
            if entry.pkt_len > 20:
                payload_len = entry.pkt_len - 20
                payload = bytearray([(i % 32) + 65 for i in range(0, payload_len)])

            # create an IP header
            ip_pkt = IP()
            if tcp_pkt.dport == server_port:
                ip_pkt.dst = "198.0.0.7"
                ip_pkt.src = "198.0.0.5"
            else:
                ip_pkt.dst = "198.0.0.5"
                ip_pkt.src = "198.0.0.7"
            ip_pkt.flags = "DF"

            # create an Ethernet header
            eth_pkt = Ether()
            eth_pkt.src = tb.IP_TO_MAC[ip_pkt.src]
            eth_pkt.dst = tb.IP_TO_MAC[ip_pkt.dst]

            # create the whole damn packet
            final_pkt = None
            final_pkt = eth_pkt/ip_pkt/tcp_pkt
            if entry.pkt_len > 20:
                final_pkt = final_pkt/Raw(payload)

            final_pkt_bytes = bytearray(final_pkt.build())

            # check that the length of the final packet matches what was logged
            check_pkt = Ether(final_pkt_bytes)
            assert check_pkt["IP"].len == (entry.pkt_len + 20)

            if len(final_pkt_bytes) < 64:
                padding = 64 - len(final_pkt_bytes)
                pad_bytes = bytearray([0] * padding)
                final_pkt_bytes.extend(pad_bytes)

            logger_tile_file.write(bytes_encode(final_pkt_bytes))

#@cocotb.test()
async def run_tcp_echo_trace(dut):
    tb = TB(dut)

    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=tb.MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, self.CLOCK_CYCLE_TIME, units='ns').start())

    replayer = SimplePcapReplay("no_req.pcap", tb, "b8:59:9f:b7:ba:44")

    await reset(dut)

    result = SimplePcapReplayStatus.OK
    while result != SimplePcapReplayStatus.DONE:
        result = await replayer.step_trace()
        await RisingEdge(dut.clk)
#        await ClockCycles(dut.clk, 64)

    tb.log.info("Finished trace")

    while True:
        pkt_extra = await tb.output_op.recv_frame()
        tb.logfile.write(bytes_encode(pkt_extra))
        tb.logfile.flush()
        pkt_extra_cast = Ether(pkt_extra)
        tb.log.info(f"Received extra packet{pkt_extra_cast.show2(dump=True)}")


#@cocotb.test()
async def run_window_full_test(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=256))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())

    tb = TB(dut)

    await reset(dut)
    tb.log.info("Finished reset")

    new_four_tuple = TCPFourTuple(
            our_ip = "198.0.0.5",
            our_port = 50005,
            their_ip = "198.0.0.7",
            their_port = 65432
            )
    log = SimLog(f"cocotb_conn_50005.tb")
    log.setLevel(logging.DEBUG)
    req_gen = EchoGenerator(log, 50005, tb.MAC_W, 1024, 64, 2)
    new_tcp_state = TCPAutomaton(new_four_tuple, req_gen, dut.clk)
    # do the 3 way handshake
    syn,_ = await new_tcp_state.get_packet_to_send()
    syn = get_base_IP(new_four_tuple)/syn
    eth = Ether()
    eth.src = tb.IP_TO_MAC[syn[IP].src]
    eth.dst = tb.IP_TO_MAC[syn[IP].dst]

    pkt_to_send = eth/syn
    pkt_bytes = bytearray(pkt_to_send.build())

    if len(pkt_to_send) < 64:
        padding = 64 - len(pkt_to_send)
        pad_bytes = bytearray([0] * padding)
        pkt_bytes.extend(pad_bytes)

    tb.log.info("Sending SYN")
    await tb.input_op.xmit_frame(pkt_bytes)

    pkt_recv = await tb.output_op.recv_frame()
    pkt_cast = Ether(pkt_recv)

    new_tcp_state.process_recv_pkt(pkt_cast[TCP])
    # check that the state is correct
    assert (new_tcp_state.state == TCPState.SEND_ACK)

    ack,_ = await new_tcp_state.get_packet_to_send()
    ack = get_base_IP(new_four_tuple)/ack
    eth = Ether()
    eth.src = tb.IP_TO_MAC[ack[IP].src]
    eth.dst = tb.IP_TO_MAC[ack[IP].dst]

    pkt_to_send = eth/ack
    pkt_bytes = bytearray(pkt_to_send.build())

    if len(pkt_to_send) < 64:
        padding = 64 - len(pkt_to_send)
        pad_bytes = bytearray([0] * padding)
        pkt_bytes.extend(pad_bytes)

    tb.log.info("Sending ACK")
    await RisingEdge(dut.clk)
    await tb.input_op.xmit_frame(pkt_bytes)

    # send a request
    req,_ = await new_tcp_state.get_packet_to_send()
    req = get_base_IP(new_four_tuple)/req
    eth = Ether()
    eth.src = tb.IP_TO_MAC[req[IP].src]
    eth.dst = tb.IP_TO_MAC[req[IP].dst]

    pkt_to_send = eth/req
    pkt_bytes = bytearray(pkt_to_send.build())

    if len(pkt_to_send) < 64:
        padding = 64 - len(pkt_to_send)
        pad_bytes = bytearray([0] * padding)
        pkt_bytes.extend(pad_bytes)

    tb.log.info(f"Sending request with seq num {hex(req['TCP'].seq)}")
    await tb.input_op.xmit_frame(pkt_bytes)
    curr_seq = new_tcp_state.our_seq
    tb.log.info(f"Sequence number is {hex(curr_seq)}")

    while True:
        pkt_recv = await with_timeout(cocotb.start_soon(tb.output_op.recv_frame()),
            1023 * tb.CLOCK_CYCLE_TIME, "ns")
        tb.log.info("Received ACK")
        pkt_cast = Ether(pkt_recv)
        new_tcp_state.process_recv_pkt(pkt_cast[TCP])
        if (req_gen.finished_req == 1):
            break

    tb.log.info("Fill up the window")
    # send 4 requests. check that we don't get ACKed for the 4th
    for i in range(0,4):
        req,_ = await new_tcp_state.get_packet_to_send()
        req = get_base_IP(new_four_tuple)/req
        eth = Ether()
        eth.src = tb.IP_TO_MAC[req[IP].src]
        eth.dst = tb.IP_TO_MAC[req[IP].dst]

        pkt_to_send = eth/req
        pkt_bytes = bytearray(pkt_to_send.build())

        if len(pkt_to_send) < 64:
            padding = 64 - len(pkt_to_send)
            pad_bytes = bytearray([0] * padding)
            pkt_bytes.extend(pad_bytes)

        tb.log.info(f"Sending request with seq num {hex(req['TCP'].seq)}")
        await tb.input_op.xmit_frame(pkt_bytes)
        curr_seq = new_tcp_state.our_seq
        tb.log.info(f"Sequence number is {hex(curr_seq)}")

    # Check our current sequence number
    curr_seq = new_tcp_state.our_seq
    tb.log.info(f"Sequence number is {hex(curr_seq)}")

    while True:
        try:
            pkt_recv = await with_timeout(cocotb.start_soon(tb.output_op.recv_frame()),
                1023 * tb.CLOCK_CYCLE_TIME, "ns")
        except cocotb.result.SimTimeoutError:
            break
        else:
            tb.log.info("Received ACK")
            pkt_cast = Ether(pkt_recv)
            assert(pkt_cast[TCP].ack != curr_seq)
            new_tcp_state.process_recv_pkt(pkt_cast[TCP])

def get_base_IP(four_tuple):
    ip_pkt = IP()
    ip_pkt.src = four_tuple.our_ip
    ip_pkt.dst = four_tuple.their_ip
    ip_pkt.flags = "DF"

    return ip_pkt
