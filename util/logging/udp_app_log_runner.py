import socket
import logging
import csv

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from tcp_driver import TCPFourTuple

from udp_app_log_read import UDPAppLogReq, UDPAppLogResp, UDPAppLogEntry

from network_log_reader import NetworkLogReader

UDP_IP = "198.0.0.9"
UDP_APP_LOG_PORT = 60002

IF_IP = "198.0.0.1"
IF_PORT = 51000

def entries_to_csv(filename, entries):
    field_names = ["timestamp", "bytes"]
    with open(filename, "w", newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=field_names)

        writer.writeheader()

        for entry in entries:
            writer.writerow({"timestamp": entry.timestamp,
                            "bytes": entry.bytes_recv})


def read_udp_app_log(out_filename, log_port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((IF_IP, IF_PORT))

    reader = NetworkLogReader(8, 2, (UDP_IP, log_port), sock, 16 + 2)
    entries = reader.read_log(UDPAppLogReq, UDPAppLogResp)

    entries.sort(key=lambda x: x.timestamp)

    entries_to_csv(out_filename, entries)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: udp_app_log_runner.py <output_file> <log_port>")
        exit(1)

    read_udp_app_log(sys.argv[1], int(sys.argv[2]))

