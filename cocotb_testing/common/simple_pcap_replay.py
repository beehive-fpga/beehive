from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from enum import Enum

import cocotb
from cocotb.log import SimLog
import logging

from scapy.utils import PcapReader
class SimplePcapReplay():
    def __init__(self, pcap_file, tb, client_mac):
        self.trace_file = PcapReader(pcap_file)
        self.client_mac = client_mac
        self.tb = tb
        self.check_fields = ["sport", "dport", "seq", "ack", "flags"]
        self.trace_pkt_num = 0

    async def step_trace(self):
        try:
            pkt = self.trace_file.read_packet()
            self.trace_pkt_num += 1
            while "TCP" not in pkt:
                self.tb.log.debug(f"Not replaying packet {self.trace_pkt_num}")
                pkt = self.trace_file.read_packet()
                self.trace_pkt_num += 1
        except EOFError:
            return SimplePcapReplayStatus.DONE

        if pkt["Ethernet"].src == self.client_mac:
            self.tb.log.info(f"Sending packet {self.trace_pkt_num}")
            # force calcuation of the checksum when the packet gets built
            pkt["TCP"].chksum = None
            await self._send_pkt(pkt)
            return SimplePcapReplayStatus.OK
        else:
            self.tb.log.info(f"Waiting to receive packet {self.trace_pkt_num}")
            await self._recv_pkt(pkt)
            return SimplePcapReplayStatus.OK

    async def _send_pkt(self, send_pkt):
        await self.tb.input_op.xmit_frame(send_pkt.build())

    async def _recv_pkt(self, ref_pkt):
        recv_pkt = await self.tb.output_op.recv_frame()
        recv_pkt_cast = Ether(recv_pkt)
        return self._check_TCP_pkt(recv_pkt_cast, ref_pkt)

    def _check_TCP_pkt(self, recv_pkt, ref_pkt):
        tcp_recv_pkt = recv_pkt["TCP"]
        tcp_ref_pkt = ref_pkt["TCP"]

        for field in self.check_fields:
            ref_attr = getattr(tcp_ref_pkt, field)
            recv_attr = getattr(tcp_recv_pkt, field)

            if ref_attr != recv_attr:
                raise RuntimeError((f"Field {field} doesn't match\n",
                                    f"Ref field: {ref_attr}\n",
                                    f"Recv field: {recv_attr}\n"))

class SimplePcapReplayStatus(Enum):
    OK = 0
    BAD_RESP = 1
    DONE = 2
