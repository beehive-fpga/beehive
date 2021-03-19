import logging

import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from simple_log_read import SimpleAppLogRead, SimpleLogReq, SimpleLogResp

import csv

class RSEncStatsLogRead(SimpleAppLogRead):

    async def read_log(self):
        entries = await super().read_log(RSEncStatsLogReq,
                RSEncStatsLogResp)

        return entries

    def calculate_bws(self, log_entries, clock_cycle_time):
        interval_bws = []

        for i in range(1, len(log_entries)):
            bw_time_1 = log_entries[i].timestamp
            bw_time_0 = log_entries[i-1].timestamp
            time_period = bw_time_1 - bw_time_0
            time_period_ns = time_period * clock_cycle_time
            time_period_s = time_period_ns/(10**9)

            bytes_sent = log_entries[i].bytes_sent - log_entries[i-1].bytes_sent
            bits_sent = bytes_sent * 8
            interval_bws.append(bits_sent/time_period_s)

        return interval_bws

class RSEncStatsLogReq(SimpleLogReq):
    def get_req_bytearray(self):
        bitmask = (1 << self.num_entries_w) - 1
        tmp_addr = self.addr & bitmask
        if self.read_metadata:
            tmp_addr = tmp_addr | (1 << self.num_entries_w)

        addr_bytearray = bytearray(tmp_addr.to_bytes(self.client_addr_bytes,
            byteorder="big"))
        return addr_bytearray

class RSEncStatsLogResp(SimpleLogResp):
    def _parse_resp(self):
        bitmask = 1 << self.num_entries_w
        addr = int.from_bytes(self.recv_bytearray[0:self.client_addr_bytes],
                byteorder="big")
        self.read_metadata = (addr & bitmask) != 0

        if (self.read_metadata):
            num_entries_bytes = self.recv_bytearray[self.client_addr_bytes:
                    self.client_addr_bytes + self.client_addr_bytes]
            self.num_written_entries = int.from_bytes(num_entries_bytes,
                    byteorder="big")
        else:
            self.log_entry = RSEncStatsLogEntry(self.recv_bytearray[self.client_addr_bytes:])

class RSEncStatsLogEntry():
    TIMESTAMP_BYTES = 8
    BYTES_SENT_BYTES = 8
    REQS_DONE_BYTES = 8

    def __init__(self, recv_bytearray):
        timestamp_offset = 0
        self.timestamp = int.from_bytes(recv_bytearray[timestamp_offset:
            timestamp_offset + self.TIMESTAMP_BYTES],
            byteorder="big")
        bytes_sent_offset = timestamp_offset + self.TIMESTAMP_BYTES
        self.bytes_sent = int.from_bytes(recv_bytearray[bytes_sent_offset:
            bytes_sent_offset + self.BYTES_SENT_BYTES], byteorder="big")
        reqs_done_offset = bytes_sent_offset + self.BYTES_SENT_BYTES
        self.reqs_done = int.from_bytes(recv_bytearray[reqs_done_offset:
            reqs_done_offset + self.REQS_DONE_BYTES], byteorder="big")

    def __repr__(self):
        return (f"time: {self.timestamp},\n"
                f"bytes_sent: {self.bytes_sent},\n"
                f"reqs_done: {self.reqs_done},\n")


def entries_to_csv(filename, entries):
    field_names = ["timestamp", "bytes_sent", "reqs_done"]
    with open(filename, "w", newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=field_names)

        writer.writeheader()

        for entry in entries:
            writer.writerow({"timestamp": entry.timestamp,
                            "bytes_sent": entry.bytes_sent,
                            "reqs_done": entry.reqs_done})

