import sys
import os

import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import Event, with_timeout
from cocotb.result import SimTimeoutError
from cocotb.queue import Queue
from cocotb.utils import get_sim_time
from scapy.compat import bytes_encode

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from migration_tcp_generators import MigrationEcho, MigrationEchoDescrip
from migration_tcp_generators import RewriteUpdate, RewriteDesc

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")

from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

from tcp_driver import TCPFourTuple
from tcp_logger_read import TCPLoggerReader
from tcp_automaton_driver import TCPAutomatonDriver, EchoGenerator

async def timeseries_send_loop(tb, send_done_event, send_cycles):
    timers = []
    pkts_sent = 0

    # send a first set of requests
    tb.log.info("Send a first set of requests")
    await _timeseries_app_loop(tb, send_cycles)

    tb.log.info("Try to rewrite the table")
    # okay here comes the hard part
    # ask the thing to rewrite
    rewrite_desc = RewriteDesc(tb.echo_four_tuple.our_ip,
                               tb.echo_four_tuple.our_port,
                               tb.echo_four_tuple.their_port,
                               "198.0.0.11")
    tb.rewrite_input_queue.put_nowait(rewrite_desc)

    while True:
        pkt_to_send, timer = await tb.TCP_driver.get_packet_to_send()
        if pkt_to_send is not None:
            if timer is not None:
                timers.append(timer)
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
            # check how many timers we have set, periodically wait for them all
            if (len(timers) >= 5):
                await Combine(*timers)
                await RisingEdge(tb.clk)

        # Otherwise, wait until something happens
        else:
            # check if we're all done, so we should exit the send loop
            if tb.rewrite_generator.finished_req == 1:
                break
            else:
                await RisingEdge(tb.clk)
    # adjust locally
    tb.TCP_driver.modify_tuple(tb.echo_four_tuple, "198.0.0.11")
    tb.echo_four_tuple.our_ip = "198.0.0.11"

    tb.log.info("Sending a second set of requests")

    await _timeseries_app_loop(tb, send_cycles)
    tb.log.info("Send loop exiting")
    send_done_event.set()

async def _timeseries_app_loop(tb, send_cycles):
    cycles_elapsed = 0
    requests_sent = 0
    pkts_sent = 0
    timers = []
    init_time = get_sim_time(units='ns')
    init_finished_req = tb.echo_generator.finished_req;

    # send requests for some amount of time
    while cycles_elapsed < send_cycles:
        if tb.echo_input_queue.empty():
            tb.log.info("Enqueuing a payload")
            payload = bytearray([(i % 32) + 65 for i in range(0, 64)])
            tb.echo_input_queue.put_nowait(MigrationEchoDescrip(payload, False))
            requests_sent += 1

        pkt_to_send, timer = await tb.TCP_driver.get_packet_to_send()
        if pkt_to_send is not None:
            if timer is not None:
                timers.append(timer)
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
            # check how many timers we have set, periodically wait for them all
            if (len(timers) >= 5):
                await Combine(*timers)
                await RisingEdge(tb.clk)
            cycles_elapsed = int((get_sim_time(units='ns') - init_time)/tb.CLOCK_CYCLE_TIME)
        else:
            cycles_elapsed = int((get_sim_time(units='ns') - init_time)/tb.CLOCK_CYCLE_TIME)
            await RisingEdge(tb.clk)

    # wait to receive all the things
    while (tb.echo_generator.finished_req - init_finished_req) < requests_sent:
        await RisingEdge(tb.clk)

async def timeseries_recv_loop(tb, send_done_event):
    pkts_recv = 0
    while not send_done_event.is_set():
        try:
            # wait for 500 cycles
            recv_frame_coro = cocotb.start_soon(tb.output_op.recv_frame())
            pkt_recv = await with_timeout(recv_frame_coro,
                    2000, timeout_unit='ns')
            tb.logfile.write(bytes_encode(pkt_recv))
            tb.logfile.flush()

            tb.TCP_driver.recv_packet(pkt_recv)
            pkts_recv +=1
            tb.log.info(f"Pkts recv {pkts_recv}")
        except SimTimeoutError:
            # check if we timed out because send is finished
            if send_done_event.is_set():
                break
            # otherwise, just continue waiting
            else:
                await RisingEdge(tb.clk)

    tb.log.info("Receive loop exiting")
