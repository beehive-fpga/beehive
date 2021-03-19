import logging

import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from scapy.utils import PcapWriter
from scapy.data import DLT_EN10MB
from scapy.compat import bytes_encode
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw
class TCPLoggerReader():
    def __init__(self, four_tuple, num_entries_w, client_addr_bytes, tb,
            ip_to_mac, clk):
        self.four_tuple = four_tuple
        self.num_entries_w = num_entries_w
        self.num_entries = 1 << num_entries_w
        self.client_addr_bytes = client_addr_bytes
        self.tb = tb
        self.clk = clk
        self.our_mac = ip_to_mac[self.four_tuple.our_ip]
        self.their_mac = ip_to_mac[self.four_tuple.their_ip]

    async def read_log(self):
        self.tb.log.debug("Reading number of requests for log at port "
                f"{self.four_tuple.their_port}")
        # get how many entries are in there
        meta_req = TCPLoggerReq(self.num_entries_w, self.client_addr_bytes, 0,
                read_metadata=True)
        meta_req_bytes = meta_req.get_req_bytearray()
        base_pkt = self._get_base_pkt()
        pkt_with_req = base_pkt/Raw(meta_req_bytes)
        pkt_bytes = self._get_padded_pkt(pkt_with_req)

        await self.tb.input_op.xmit_frame(pkt_bytes)
        self.tb.logfile.write(bytes_encode(pkt_bytes))

        resp_pkt = None
        while True:
            resp = await self.tb.output_op.recv_frame()
            self.tb.logfile.write(bytes_encode(resp))
            resp_pkt = Ether(resp)
            if "UDP" in resp_pkt:
                break
        await RisingEdge(self.clk)
        log_resp = TCPLoggerResp(resp_pkt["Raw"].load, self.client_addr_bytes,
                read_metadata=True)

        # check how many entries there are
        num_reads = log_resp.num_written_entries
        self.tb.log.debug(f"Found {num_reads} entries")
        entries = []
        for i in range(0, num_reads):
            data_req = TCPLoggerReq(self.num_entries_w, self.client_addr_bytes,
                    i, read_metadata=False)
            data_req_bytes = data_req.get_req_bytearray()
            base_pkt = self._get_base_pkt()
            pkt_with_req = base_pkt/Raw(data_req_bytes)
            pkt_bytes = self._get_padded_pkt(pkt_with_req)

            await self.tb.input_op.xmit_frame(pkt_bytes)
            self.tb.logfile.write(bytes_encode(pkt_bytes))

            resp_pkt = None
            while True:
                resp = await self.tb.output_op.recv_frame()
                self.tb.logfile.write(bytes_encode(resp))
                resp_pkt = Ether(resp)
                if "UDP" in resp_pkt:
                    break
            log_resp = TCPLoggerResp(resp_pkt["Raw"].load,
                    self.client_addr_bytes, read_metadata=False)

            entries.append(log_resp.log_entry)
            await RisingEdge(self.clk)

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



class TCPLoggerReq():
    def __init__(self, num_entries_w, client_addr_bytes, addr, read_metadata=False):
        self.client_addr_bytes = client_addr_bytes
        self.num_entries_w = num_entries_w
        self.addr = addr
        self.read_metadata = read_metadata

    def get_req_bytearray(self):
        bitmask = (1 << self.num_entries_w) - 1
        tmp_addr = self.addr & bitmask
        if self.read_metadata:
            tmp_addr = tmp_addr | (1 << self.num_entries_w)

        addr_bytearray = bytearray(tmp_addr.to_bytes(self.client_addr_bytes,
            byteorder="big"))
        return addr_bytearray

class TCPLoggerResp():
    def __init__(self, recv_bytearray, client_addr_bytes, read_metadata=False):
        self.recv_bytearray = recv_bytearray
        self.client_addr_bytes = client_addr_bytes
        self.read_metadata = read_metadata

        self._parse_resp()

    def _parse_resp(self):
        if (self.read_metadata):
            recv_entries = self.recv_bytearray[self.client_addr_bytes:
                    self.client_addr_bytes + self.client_addr_bytes]
            self.num_written_entries = int.from_bytes(recv_entries,
                    byteorder="big")
        else:
            self.log_entry = TCPLoggerEntry(self.recv_bytearray[self.client_addr_bytes:])


class TCPLoggerEntry():
    TIMESTAMP_BYTES = 8
    TOT_LEN_BYTES = 2
    TCP_HDR_BYTES = 20

    def __init__(self, recv_bytearray):
        self.timestamp = int.from_bytes(recv_bytearray[0:self.TIMESTAMP_BYTES],
                byteorder="big")
        self.pkt_len = int.from_bytes(recv_bytearray[self.TIMESTAMP_BYTES:
            self.TIMESTAMP_BYTES + self.TOT_LEN_BYTES], byteorder="big")
        self.tcp_hdr = TCP(recv_bytearray[self.TIMESTAMP_BYTES + self.TOT_LEN_BYTES:])

