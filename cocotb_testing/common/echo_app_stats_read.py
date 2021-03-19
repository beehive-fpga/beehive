import logging
import csv

import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from simple_log_read import SimpleAppLogRead, SimpleLogReq, SimpleLogResp

class EchoAppStatsRead(SimpleAppLogRead):
    async def read_log(self):
        entries = await super().read_log(EchoAppStatsReq, EchoAppStatsResp)

        return entries

class EchoAppStatsReq(SimpleLogReq):
    def get_req_bytearray(self):
        bitmask = (1 << self.num_entries_w) - 1
        tmp_addr = self.addr & bitmask

        if self.read_metadata:
            tmp_addr = tmp_addr | (1 << self.num_entries_w)

        addr_bytearray = bytearray(tmp_addr.to_bytes(self.client_addr_bytes,
            byteorder="big"))
        return addr_bytearray

class EchoAppStatsResp(SimpleLogResp):
    def _parse_resp(self):
        bitmask = 1 << self.num_entries_w

        addr = int.from_bytes(self.recv_bytearray[0:self.client_addr_bytes],
                byteorder="big")
        self.read_metadata = (addr & bitmask) != 0

        if (self.read_metadata):
            num_entries_bytes = self.recv_bytearray[self.client_addr_bytes:
                    self.client_addr_bytes+self.client_addr_bytes]
            self.num_written_entries = int.from_bytes(num_entries_bytes,
                    byteorder="big")
        else:
            self.log_entry = EchoAppStatsEntry(self.recv_bytearray[self.client_addr_bytes:])

class EchoAppStatsEntry():
    TIMESTAMP_BYTES = 8
    REQS_DONE_BYTES = 8

    def __init__(self, recv_bytearray):
        self.timestamp = int.from_bytes(recv_bytearray[0:self.TIMESTAMP_BYTES],
                byteorder="big")
        self.reqs_done = int.from_bytes(recv_bytearray[self.TIMESTAMP_BYTES:
            self.TIMESTAMP_BYTES + self.REQS_DONE_BYTES], byteorder="big")

    def __repr__(self):
        return (f"time: {self.timestamp}, reqs_done: {self.reqs_done}")

def entries_to_csv(filename, entries):
    field_names = ["timestamp", "reqs_done"]
    with open(filename, "w", newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=field_names)

        writer.writeheader()

        for entry in entries:
            writer.writerow({"timestamp": entry.timestamp,
                            "reqs_done": entry.reqs_done})
