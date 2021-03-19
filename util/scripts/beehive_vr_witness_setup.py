import argparse
import socket
import sys, os

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/vr_testing")
from vr_helpers import VRState, BeehiveVRHdr, get_setup_payload

def setup_argparse():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rep_index', required=True, help='replica index of the FPGA node', type=int)
    parser.add_argument('--witness_addr', required=True, help="the IP address of the FPGA witness being configured")
    parser.add_argument('--witness_port', required=True, help="the setup port of the FPGA witness", type=int)
    parser.add_argument('--src_addr', required=True, help="IP address on the interface to use")
    parser.add_argument('--src_port', required=True, help="port to bind to", type=int)
    parser.add_argument('--config_file', required=True, help="path to the VR config file")

    return parser

def get_nodes_from_config(config_file_name):
    nodes = []
    with open(config_file_name, "r") as config_file:
        for line in config_file:
            if line.startswith("replica "):
                parts = line[len("replica "):].split(":")
                if len(parts) == 2:
                    ip, port = parts
                    nodes.append((ip, int(port)))

    return nodes

def run_setup(setup_args):
    setup_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    setup_socket.bind((setup_args.src_addr, setup_args.src_port))

    nodes = get_nodes_from_config(setup_args.config_file)
    print(nodes)

    payload = get_setup_payload(hdr_log_depth=2048, data_log_depth=2048,
        rep_index=1, first_log_op=1, machine_config=nodes, rep_tuple=nodes[1])
    
    setup_socket.sendto(payload, (setup_args.witness_addr, setup_args.witness_port))

    # wait for the confirmation response
    data, addr = setup_socket.recvfrom(64)

    ref_data = BeehiveVRHdr(msg_type=BeehiveVRHdr.SetupBeehiveResp)
    ref_data_bytes = ref_data.to_bytearray()
    assert data == ref_data_bytes

    print(f"Received response {data}")

def main():
    parser = setup_argparse()
    args = parser.parse_args()

    run_setup(args)

if __name__ == "__main__":
    main()
