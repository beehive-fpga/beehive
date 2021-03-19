#!/bin/bash
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 [passwd_file] [server_output_file] \\
        [server_scripts_dir] [pcie_fpga_addr] [fpga_ip_addr]"
    exit 1
fi

PASSWD_FILE=${1}
SERVER_OUTPUT_FILE=${2}
SERVER_SCRIPTS_DIR=${3}
PCIE_FPGA_ADDR=${4}
FPGA_IP_ADDR=${5}

start_fpga_server() {
    local passwd_file="${1}"
    local server_output_file="${2}"
    local server_scripts_dir="${3}"
    local pcie_fpga_addr="${4}"
    local fpga_ip_addr="${5}"


    cat ${passwd_file} | ssh -tt n99 "cd ${server_scripts_dir}; sudo ./pcie_hot_reset.sh ${pcie_fpga_addr}" > ${server_output_file}
    local pkts_recv="0"
    while [[ "${pkts_recv}" -ne "10" ]]; do
        pkts_recv=$(ping ${fpga_ip_addr} -c 10 | grep -A 1 "ping statistics" | tail -n 1 | cut -d , -f 2 | cut -d " " -f 2)
        echo "Received ${pkts_recv} packets"
    done
    echo "fpga server running"
}

set -e
start_fpga_server ${PASSWD_FILE} ${SERVER_OUTPUT_FILE} ${SERVER_SCRIPTS_DIR} ${PCIE_FPGA_ADDR} ${FPGA_IP_ADDR}
