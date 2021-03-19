import socket
import logging

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from tcp_driver import TCPFourTuple

from eth_latency_log_read import EthLatencyLogReq, EthLatencyLogResp
from eth_latency_log_read import EthLatencyLogEntry, entries_to_csv

from network_log_reader import NetworkLogReader
UDP_IP = "198.19.100.19"
ETH_LATENCY_LOG_PORT = 60001

IF_IP = "198.19.100.20"
IF_PORT = 51000

def read_eth_latency_log():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((IF_IP, IF_PORT))

    reader = NetworkLogReader(10, 2, (UDP_IP, ETH_LATENCY_LOG_PORT), sock, 16 + 2)
    entries = reader.read_log(EthLatencyLogReq, EthLatencyLogResp)

    entries.sort(key=lambda x: x.start_timestamp)

    entries_to_csv("latency_log.csv", entries)

if __name__ == "__main__":
    read_eth_latency_log()
