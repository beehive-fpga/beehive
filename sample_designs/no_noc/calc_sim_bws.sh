#!/bin/bash
set -e

PACKET_SIZES=("64"
              "128"
              "256"
              "512"
              "1024"
              "2048"
              "3072"
              "4096" 
              "6144"
              "8192"
          )

LOG_SCRIPT_DIR=${BEEHIVE_PROJECT_ROOT}/util/logging
source ${LOG_SCRIPT_DIR}/bandwidth_log_ops.sh

echo "packet_size,bw_bps" > "sim_measured_bws.csv"

for PACKET_SIZE in ${PACKET_SIZES[@]}; do
    RES_DIR="bw_benchmark/${PACKET_SIZE}bytes"

    process_bw_log "${RES_DIR}" "bw_log.csv" "bws.csv"

    CMD="python ${BEEHIVE_PROJECT_ROOT}/util/logging/process_avg_bw.py\
        ${RES_DIR}/bws.csv ${RES_DIR}/avg_bw.txt --drop_reads 5"
    echo ${CMD}
    eval ${CMD}

    AVG_BW=$(cat "${RES_DIR}/avg_bw.txt")
    echo "${PACKET_SIZE},${AVG_BW}" >> "sim_measured_bws.csv"



done
