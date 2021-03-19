import socket
import logging

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from tcp_driver import TCPFourTuple

from rs_encode_req_lib import RSEncodeReqLib, RSEncodeConstants

UDP_IP = "198.0.0.7"
UDP_PORT = 65432

IF_IP = "198.0.0.1"
IF_PORT = 51000
MAC_BYTES = 64

def single_rs_encode_req():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((IF_IP, IF_PORT))

    req_lib = RSEncodeReqLib(MAC_BYTES, 4)

    data_blocks = bytearray()
    num_blocks = 0

    with open("test_input_32blk.txt", "r") as input_file:
        for line in input_file:
            block_bytes = bytes.fromhex(line)
            data_blocks.extend(block_bytes)
            num_blocks += 1

    ref_parity = bytearray()
    with open("parity_output_32blk.txt", "r") as ref_file:
        for line in ref_file:
            parity_bytes = bytes.fromhex(line)
            ref_parity.extend(parity_bytes)

    resp_len = len(data_blocks) + len(ref_parity)

    print(f"Send {num_blocks} block request")

    test_req = req_lib.get_rs_req_buffer(num_blocks, data_blocks)

    for i in range(0, 4):
        print(f"Sending request {i}")
        sock.sendto(test_req, (UDP_IP, UDP_PORT))

        data, addr = sock.recvfrom(resp_len)

        assert len(data) == resp_len

        resp_data = data[:num_blocks*RSEncodeConstants.BLOCK_SIZE]
        parity = data[num_blocks*RSEncodeConstants.BLOCK_SIZE:]

        if (resp_data != data_blocks):
            print("Body data isn't the same")
        if (parity != ref_parity):
            print("Parity isn't the same")

if __name__ == "__main__":
    single_rs_encode_req()

