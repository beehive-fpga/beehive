import socket
import csv

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")

from rs_encode_stats_log_read import RSEncStatsLogReq, RSEncStatsLogResp

from network_log_reader import NetworkLogReader

UDP_IP = "198.0.0.9"

IF_IP = "198.0.0.11"
IF_PORT = 51000
def entries_to_csv(filename, entries):
    field_names = ["timestamp", "bytes_sent", "reqs_done"]
    with open(filename, "w", newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=field_names)

        writer.writeheader()

        for entry in entries:
            writer.writerow({"timestamp": entry.timestamp,
                            "bytes_sent": entry.bytes_sent,
                            "reqs_done": entry.reqs_done})

def read_rs_app_log(out_filename, log_port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((IF_IP, IF_PORT))

    # 24 for all the fields, 2 for the address
    reader = NetworkLogReader(8, 2, (UDP_IP, log_port), sock, 24 + 2)
    entries = reader.read_log(RSEncStatsLogReq, RSEncStatsLogResp)

    entries.sort(key=lambda x: x.timestamp)
    entries_to_csv(out_filename, entries)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: rs_app_log_runner.py <output_file> <log_port>")
        exit(1)

    read_rs_app_log(sys.argv[1], int(sys.argv[2]))