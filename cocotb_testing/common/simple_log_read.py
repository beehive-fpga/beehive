import logging

import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from abc import ABC, abstractmethod

class SimpleAppLogRead():
    def __init__(self, num_entries_w, client_addr_bytes, tb, four_tuple):
        self.num_entries_w = num_entries_w
        self.num_entries = 1 << num_entries_w
        self.client_addr_bytes = client_addr_bytes
        self.tb = tb
        self.four_tuple = four_tuple
        self.our_mac = tb.IP_TO_MAC[self.four_tuple.our_ip]
        self.their_mac = tb.IP_TO_MAC[self.four_tuple.their_ip]

    async def read_log(self, LogReqClass, LogRespClass):
        self.tb.log.debug("Reading number of requests for log at port "
                f"{self.four_tuple.their_port}")
        meta_req = LogReqClass(self.num_entries_w, self.client_addr_bytes, 0,
                read_metadata=True)
        meta_req_bytes = meta_req.get_req_bytearray()
        base_pkt = self._get_base_pkt()
        pkt_with_req = base_pkt/Raw(meta_req_bytes)
        pkt_bytes = self._get_padded_pkt(pkt_with_req)

        await RisingEdge(self.tb.clk)
        await self.tb.input_op.xmit_frame(pkt_bytes)

        resp_pkt = None
        while True:
            resp = await self.tb.output_op.recv_frame()
            resp_pkt = Ether(resp)
            if resp_pkt["UDP"].dport == self.four_tuple.our_port:
                break

        await RisingEdge(self.tb.clk)
        log_resp = LogRespClass(resp_pkt["Raw"].load, self.num_entries_w,
                self.client_addr_bytes)

        num_reads = log_resp.num_written_entries

        self.tb.log.debug(f"Found {num_reads} entries")
        entries = []

        for i in range(0, num_reads):
            data_req = LogReqClass(self.num_entries_w, self.client_addr_bytes,
                    i, read_metadata=False)
            data_req_bytes = data_req.get_req_bytearray()
            base_pkt = self._get_base_pkt()
            pkt_with_req = base_pkt/Raw(data_req_bytes)
            pkt_bytes = self._get_padded_pkt(pkt_with_req)

            await self.tb.input_op.xmit_frame(pkt_bytes)

            resp_pkt = None
            while True:
                resp = await self.tb.output_op.recv_frame()
                resp_pkt = Ether(resp)
                if resp_pkt["UDP"].dport == self.four_tuple.our_port:
                    break
            payload = resp_pkt["Raw"]
            log_resp = LogRespClass(resp_pkt["Raw"].load, self.num_entries_w,
                    self.client_addr_bytes)
            entries.append(log_resp.log_entry)

            await RisingEdge(self.tb.clk)

        return entries


    def _get_padded_pkt(self, pkt):
        pkt_bytes = bytearray(pkt.build())
        if len(pkt_bytes) < 64:
            padding = 64 - len(pkt_bytes)
            pad_bytes = bytearray([0] * padding)
            pkt_bytes.extend(pad_bytes)

        return pkt_bytes


    def _get_base_pkt(self):
        eth = self._get_base_Ether()
        ip = self._get_base_IP()
        udp = self._get_base_UDP()

        return eth/ip/udp

    def _get_base_Ether(self):
        eth = Ether()
        eth.src = self.our_mac
        eth.dst = self.their_mac

        return eth

    def _get_base_IP(self):
        ip_pkt = IP()
        ip_pkt.src = self.four_tuple.our_ip
        ip_pkt.dst = self.four_tuple.their_ip
        ip_pkt.flags = "DF"

        return ip_pkt

    def _get_base_UDP(self):
        udp_pkt = UDP()
        udp_pkt.sport = self.four_tuple.our_port
        udp_pkt.dport = self.four_tuple.their_port

        return udp_pkt

class SimpleLogReq(ABC):
    def __init__(self, num_entries_w, client_addr_bytes, addr, read_metadata = False):
        self.num_entries_w = num_entries_w
        self.client_addr_bytes = client_addr_bytes
        self.addr = addr
        self.read_metadata = read_metadata

    @abstractmethod
    def get_req_bytearray(self):
        pass

class SimpleLogResp(ABC):
    def __init__(self, recv_bytearray, num_entries_w, client_addr_bytes):
        self.num_entries_w = num_entries_w
        self.recv_bytearray = recv_bytearray
        self.client_addr_bytes = client_addr_bytes

        self._parse_resp()

    @abstractmethod
    def _parse_resp(self):
        pass

