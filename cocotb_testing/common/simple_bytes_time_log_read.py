import logging
import cocotb
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from simple_log_read import SimpleAppLogRead, SimpleLogReq, SimpleLogResp

import csv

class SimpleBytesTimeLogRead(SimpleAppLogRead):
    def calculate_bws(self, log_entries, clock_cycle_time):
        interval_bws = []
        for i in range(1, len(log_entries)):
            bw_time_1 = log_entries[i].timestamp
            bw_time_0 = log_entries[i-1].timestamp
            time_period = bw_time_1 - bw_time_0
            time_period_ns = time_period * clock_cycle_time
            time_period_s = time_period_ns/(10**9)

            bytes_sent = log_entries[i].bytes_recv - log_entries[i-1].bytes_recv
            bits_sent = bytes_sent * 8
            interval_bws.append(bits_sent/time_period_s)

        return interval_bws

    def entries_to_csv(self, filename, entries):
        field_names = ["timestamp", "bytes"]
        with open(filename, "w", newline='') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=field_names)

            writer.writeheader()

            for entry in entries:
                writer.writerow({"timestamp": entry.timestamp,
                                "bytes": entry.bytes_recv})


class SimpleBytesTimeLogReq(SimpleLogReq):
    def get_req_bytearray(self):
        bitmask = (1 << self.num_entries_w) - 1
        tmp_addr = self.addr & bitmask
        if self.read_metadata:
            tmp_addr = tmp_addr | (1 << self.num_entries_w)

        addr_bytearray = bytearray(tmp_addr.to_bytes(self.client_addr_bytes,
            byteorder="big"))
        return addr_bytearray

class SimpleBytesTimeLogResp(SimpleLogResp):
    def __init__(self, recv_bytearray, num_entries_w, client_addr_bytes, log_entry_type):
        self.LogEntryType = log_entry_type
        super().__init__(recv_bytearray, num_entries_w, client_addr_bytes)

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
            self.log_entry = self.LogEntryType(self.recv_bytearray[self.client_addr_bytes:])

class SimpleBytesTimeLogEntry():
    def __init__(self, recv_bytearray, timestamp_bytes, bytes_recv_bytes):
        self.timestamp_bytes = timestamp_bytes
        self.bytes_recv_bytes = bytes_recv_bytes

        self.timestamp = int.from_bytes(recv_bytearray[0:self.timestamp_bytes],
            byteorder="big")
        self.bytes_recv = int.from_bytes(recv_bytearray[self.timestamp_bytes:
            self.timestamp_bytes + self.bytes_recv_bytes], byteorder="big")

    def __repr__(self):
        return (f"time: {self.timestamp}, bytes {self.bytes_recv}")

