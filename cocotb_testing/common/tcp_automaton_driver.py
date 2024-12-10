from tcp_driver import TCPDriver, TCPState, RequestGenerator, TCPFourTuple
from tcp_driver import DataBufStatus, DataBuf, RequestGenReturn, TCPSeqNum
from timer_disarm import TimerDisarm
from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw
import random
from random import Random
from collections import deque
import copy

from enum import Enum

import cocotb
from cocotb.log import SimLog
from cocotb.triggers import Combine
from echo_generator import EchoGenerator
import logging

DUP_ACK_THRESH = 3

class TCPAutomatonDriver(TCPDriver):
    def __init__(self, clk, req_gen_list):
        self.rng = random.Random(42)
        self.flow_dict = {}
        self.conn_index = 0
        self.log = SimLog("cocotb.tb")
        self.flows_done = 0
        self.finished_flows = 0

        # setup connections from the list
        self.req_gen_list = req_gen_list
        for (generator, four_tuple) in req_gen_list:
            new_tcp_state = TCPAutomaton(four_tuple, generator, clk)
            self.flow_dict[four_tuple] = new_tcp_state


    def run_req_gens(self):
        coroutines = []
        for (req_gen, four_tuple) in self.req_gen_list:
            coroutines.append(req_gen.run_app())

        self.log.debug("Starting request generators")
        return Combine(*coroutines)


    def modify_tuple(self, old_tuple, new_addr):
        # remove the automaton from the dictionary
        automaton = self.flow_dict.pop(old_tuple)

        # adjust the variables for the connection
        automaton.adjust_four_tuple_src_addr(new_addr)

        # restore it with the new tuple
        new_tuple = copy.deepcopy(old_tuple)
        new_tuple.our_ip = new_addr

        self.flow_dict[new_tuple] = automaton

    def _get_base_IP(self, four_tuple):
        ip_pkt = IP()
        ip_pkt.src = four_tuple.our_ip
        ip_pkt.dst = four_tuple.their_ip
        ip_pkt.flags = "DF"

        return ip_pkt

    async def get_packet_from_conn(self, flow_tuple):
        pkt = None
        timer = None
        conn = self.flow_dict[flow_tuple]

        pkt, timer = await conn.get_packet_to_send()

        if (pkt != None):
            ip_pkt = self._get_base_IP(flow_tuple)
            pkt = ip_pkt/pkt

        return pkt, timer

    def flow_has_unacked(self, flow_tuple):
        conn = self.flow_dict[flow_tuple]
        return len(conn.unacked_pkts) > 0

    async def get_packet_to_send(self):
        pkt = None
        timer = None
        for i in range(0, len(self.flow_dict)):
            conn_key = list(self.flow_dict)[self.conn_index]
            conn = self.flow_dict[conn_key]

            pkt, timer = await conn.get_packet_to_send()
            if (pkt != None):
                ip_pkt = self._get_base_IP(conn_key)
                pkt = ip_pkt/pkt
                self.conn_index = (self.conn_index + 1) % (len(self.flow_dict))
                break
            else:
                self.conn_index = (self.conn_index + 1) % (len(self.flow_dict))
        return pkt, timer

    def recv_packet(self, pkt_bytes):
        # assemble the packet
        pkt = Ether(pkt_bytes)
        self.log.debug(f"Recv packet {pkt.show(dump=True)}")

        lookup_tuple = TCPFourTuple(
                our_ip = pkt[IP].dst,
                our_port = pkt[TCP].dport,
                their_ip = pkt[IP].src,
                their_port = pkt[TCP].sport,
                )

        conn = None
        if lookup_tuple not in self.flow_dict:
            self.log.warning(f"Flow {lookup_tuple} not in dict. "
                            f"Dropping packet {pkt.show(dump=True)}")
            return
        else:
            conn = self.flow_dict[lookup_tuple]

        conn.process_recv_pkt(pkt[TCP])

        if conn.state == TCPState.FIN_WAIT:
            self.finished_flows += 1

        return (lookup_tuple, conn.state)

    def all_flows_closed(self):
        for conn_key, conn in self.flow_dict.items():
            self.log.debug(f"{conn.state}")
            if conn.state != TCPState.FIN_WAIT:
                return False

            if len(conn.unacked_pkts) > 0:
                return False

            if conn.send_ack:
                return False
        return True

class TCPAutomaton():
    def __init__(self, four_tuple, req_gen, clk):
        self.rng = Random(four_tuple.our_port)
        self.our_ack = TCPSeqNum(0)
        self.our_seq = TCPSeqNum(self.rng.randint(100, 2000040))
        self.their_ack = TCPSeqNum(self.our_seq.value)
        self.their_seq = TCPSeqNum(0)
        self.their_rx_win = 0

        self.state = TCPState.START
        self.four_tuple = four_tuple

        self.unacked_pkts = {}
        self.rt_queue = []
        self.dup_ack_count = 0
        self.req_gen = req_gen

        self.clk = clk
        self.TIMEOUT = 1000000
        self.send_ack = False

        self.log = SimLog(f"cocotb.conn_{self.four_tuple.our_port}.tb")
        self.log.setLevel(logging.DEBUG)

    def adjust_four_tuple_src_addr(self, ip_addr):
        self.four_tuple.our_ip = ip_addr

    def print_unacked(self):
        for (key, item) in self.unacked_pkts.items():
            header_only = item.pkt.copy()['TCP']
            header_only.remove_payload()
            self.log.debug(f"{header_only.show(dump=True)}")

    async def get_packet_to_send(self):
        if self.state == TCPState.START:
            self.syn = self.get_syn_packet()
            self.state = TCPState.SYN_SENT
            self.log.info(f"{self.four_tuple.our_port}: Returning SYN packet")
            return self.syn, None
        elif self.state == TCPState.SYN_SENT:
            self.log.debug(f"{self.four_tuple.our_port}: state is SYN-SENT")
            return None, None
        elif self.state == TCPState.SEND_ACK:
            self.log.info(f"{self.four_tuple.our_port}: state is SEND_ACK")
            ack = self.get_ack_packet()
            self.state = TCPState.EST
            return ack, None
        elif self.state == TCPState.EST:
            self.log.debug(f"{self.four_tuple.our_port}: State is EST"
                    f"# unacked:")
            self.print_unacked()
            # check how many packets we have outstanding
            #if len(self.unacked_pkts) > 6:
            #    self.log.debug("Too many outstanding packets")
            #    return None, None
            #else:
            payload_packet, timer_task = self.get_payload_packet()

                #if payload_packet is not None:
                #    self.log.debug("TIMING: sending payload packet at time "
                #            f"{cocotb.utils.get_sim_time(units='ns')}")
            return payload_packet, timer_task
        elif self.state == TCPState.FIN_WAIT:
            # we may need to send an ACK to fully acknowledge the received
            # packet
            if self.send_ack:
                self.send_ack = False
                return self.get_ack_packet(), None
            else:
                return None, None
        else:
            self.log.info("We're in an invalid state")
            raise RuntimeError()

    async def start_timer(self, timer):
        timed_out = await timer.arm_timer(self.TIMEOUT, self.clk)
        if (timed_out):
            seq_nums = list(self.unacked_pkts)
            seq_nums.sort()
            self.log.debug("We timed out. Retransmitting starting with pkt num "
                    f"{hex(seq_nums[0])}")

            self.rt_queue.append(seq_nums[0])

    def get_syn_packet(self):
        syn_pkt = self._get_base_TCP()
        syn_pkt.flags = "S"

        self.our_seq = self.our_seq + TCPSeqNum(1)
        return syn_pkt

    def get_ack_packet(self):
        ack_pkt = self._get_base_TCP()
        ack_pkt.flags = "A"

        return ack_pkt


    def get_payload_packet(self):
        # do we need to retransmit?
        if len(self.rt_queue) != 0:
            pkt_context = self.unacked_pkts[self.rt_queue.pop()]
            timer_task = cocotb.start_soon(self.start_timer(pkt_context.timer))
            # update our ACK
            pkt_context.pkt["TCP"].ack = self.our_ack
            return pkt_context.pkt, timer_task

        payload_size = self.req_gen.send_buf.peek_send_size()
        unacked = self.our_seq - self.their_ack
        open_window = self.their_rx_win - unacked.value

        #self.log.debug(f"open window space: {open_window}, window: "
        #        f"{self.their_rx_win}, unacked: {unacked}, next_pkt: {payload_size}")

        pkt = None
        timer_task = None
        if payload_size == None:
            # check if we need to send an updated ACK
            if self.send_ack:
                pkt = self.get_ack_packet()
        else:
            pkt = self._get_base_TCP()
            pkt.flags = "PA"

            payload = []
            # FIXME: zero window probing
            if open_window <= 0:
                self.log.debug("no window available")
                return None, None

            min_size = min(open_window, payload_size)
            (status, payload) = self.req_gen.send_buf.send_data(min_size)

            if status == DataBufStatus.SIZE_ERROR:
                raise RuntimeError("Somehow requested a packet too big")

            # update our state
            self.our_seq = self.our_seq + TCPSeqNum(len(payload))
            pkt = pkt/Raw(payload)
            timer = TimerDisarm()
            self.unacked_pkts[TCPSeqNum(pkt.seq)] = UnackedPktContext(pkt, timer)
            # start a timer whenever we transmit a new packet
            timer_task = cocotb.start_soon(self.start_timer(timer))

        self.send_ack = False
        return pkt, timer_task

    def process_recv_pkt(self, pkt_tcp):
        pkt = pkt_tcp.copy()
        if "Padding" in pkt:
            del(pkt["Padding"])
        if (self.state == TCPState.SYN_SENT):
            # is this a SYN-ACK? does it have the things we want?
            if pkt.flags == "SA":
                if TCPSeqNum(pkt.ack) == (self.their_ack + TCPSeqNum(1)):
                    self.state = TCPState.SEND_ACK
                    self.their_ack = TCPSeqNum(pkt.ack)
                    self.our_ack = TCPSeqNum(pkt.seq) + TCPSeqNum(1)
                    self.their_rx_win = pkt.window
                else:
                    self.log.info("Expected SYN-ACK")
                    self.send_buf.reset_for_retransmit()
        elif (self.state == TCPState.EST):
            #self.log.debug(f"pkt: {pkt.show(dump=True)}")
            #self.log.debug(f"pkt.payload: {pkt.payload}")
            if len(pkt.payload) == 0:
                self.log.debug("We've gotten a zero-len ACK")
            # alright...here comes the nasty crap
            # Process our send stream
            # are we out of order and need to retransmit?:
            if (TCPSeqNum(pkt.ack) == self.their_ack) and (len(self.unacked_pkts) != 0):
                self.their_rx_win = pkt.window
                self.dup_ack_count += 1
                self.log.info(f"{self.four_tuple.our_port}: We've been dup-acked for packet seq number {self.their_ack} "
                        f"ack_count: {self.dup_ack_count}")
                # okay we need to try to recover, reset where we send from
                if (self.dup_ack_count == DUP_ACK_THRESH):
                    self.log.warning(f"Retransmitting packet {self.their_ack}")
                    self.rt_queue.append(TCPSeqNum(pkt.ack))
                # we don't need to recover yet, but don't update anything
            elif TCPSeqNum(pkt.ack) > self.their_ack:
                self.their_rx_win = pkt.window
                # check that it's within the window
                if TCPSeqNum(pkt.ack) > self.our_seq:
                    self.log.warn("ACKed for data we haven't sent")

                self.dup_ack_count = 0
                # okay how much data has been acked
                trim_len = int(TCPSeqNum(pkt.ack) - self.their_ack)
                self.log.info(f"Trimming {trim_len} bytes, last_ack: "
                        f"{self.their_ack}, pkt_ack: {pkt.ack}")

                self.req_gen.send_buf.ack_data(trim_len)

                # we need to be super careful here, because we're modifying the
                # list in place. specifically, we're deleting elements, which
                # can cause bad problems if we try to iterate over the
                # dictionary directly or even the list from .items()
                # instead, take a list of all the keys (sequence numbers),
                # which copies the key values and then delete from the original
                # dictionary as appropriate

                pkt_seq_nums = list(self.unacked_pkts)
                pkt_seq_nums.sort()

                # FIXME: we need to deal with what happens if we get ACKed for
                # a partial packet
                for seq_num in pkt_seq_nums:
                    pkt_context = self.unacked_pkts[seq_num]
                    payload_len = len(pkt_context.pkt["Raw"].load)
                    self.log.debug(f"seq_num: {seq_num}, payload_len: {payload_len}"
                            f" ack_num: {pkt.ack}")
                    pkt_end = seq_num + TCPSeqNum(payload_len-1)
                    if pkt_end < TCPSeqNum(pkt.ack):
                        # disarm our timer
                        pkt_context.timer.disarm_timer()
                        self.log.debug(f"Disarming timer for pkt seq {hex(seq_num)}")
                        del(self.unacked_pkts[seq_num])
                        #self.log.debug(f"unacked pkts: {len(self.unacked_pkts)}")
                #self.log.debug(f"{self.unacked_pkts}")

                # update what has been acked for us
                self.their_ack = TCPSeqNum(pkt.ack)

            # Process our recv stream
            # are they out of order? we don't actually need to do anything if so
            # we just need to drop the packet and wait for the retransmit
            if TCPSeqNum(pkt.seq) == self.our_ack:
                # great we're in order. how much of the payload can we keep?
                if "Raw" in pkt:
                    payload = pkt.load
                    space_free = self.req_gen.recv_buf.get_space_free()
                    append_payload_size = min(len(pkt.payload), space_free)

                    self.our_ack = TCPSeqNum(pkt.seq) + TCPSeqNum(append_payload_size)
                    self.log.debug(f"Got packet num {hex(pkt.seq)}, payload_len: "
                        f"{len(payload)}")
                    #self.log.debug("TIMING: got response packet at time "
                    #        f"{cocotb.utils.get_sim_time(units='ns')}")
                    if (append_payload_size > 0):
                        self.req_gen.recv_buf.append(payload[:append_payload_size])
                    self.send_ack = True

            elif TCPSeqNum(pkt.seq) < self.our_ack:
                self.log.info(f"We received a retransmitted packet\n"
                              f"Expected {hex(self.our_ack)}, got: {hex(pkt.seq)}")
                self.send_ack = True
            else:
                self.log.info(f"We received an out of order packet\n"
                              f"Expected {hex(self.our_ack)}, got: {hex(pkt.seq)}")

            if self.req_gen.check_if_done() == RequestGenReturn.DONE:
                self.log.info("Transitioning to done")
                self.state = TCPState.FIN_WAIT


    def _get_base_TCP(self):
        pkt = TCP()
        pkt.sport = self.four_tuple.our_port
        pkt.dport = self.four_tuple.their_port
        pkt.seq = self.our_seq.value
        pkt.ack = self.our_ack.value
        pkt.window = self.req_gen.recv_buf.get_space_free()

        return pkt


class UnackedPktContext():
    def __init__(self, pkt, timer):
        self.pkt = pkt
        self.timer = timer

    def __repr__(self):
        return (f"pkt: {self.pkt.show(dump=True)}\n"
                f"timer: {self.timer}")

