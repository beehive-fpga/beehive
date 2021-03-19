#!/bin/bash
set -e
OUT_FILE="sim_measured_bws.csv"
LOG_DIR="bw_benchmark"

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
source ${LOG_SCRIPT_DIR}/bandwidth_log_ops.sh\

echo "packet_size,bw_bps" > "${OUT_FILE}"

for PACKET_SIZE in ${PACKET_SIZES[@]}; do
    RES_DIR="${LOG_DIR}/${PACKET_SIZE}bytes"

    #process_bw_log "${RES_DIR}" "bw_log.csv" "bws.csv"

    CMD="python ${BEEHIVE_PROJECT_ROOT}/util/logging/process_avg_bw.py\
        --input_file ${RES_DIR}/bws.csv --output_file ${RES_DIR}/avg_bw.txt --drop_reads 5"
    echo ${CMD}
    eval ${CMD}

    AVG_BW=$(cat "${RES_DIR}/avg_bw.txt")
    echo "${PACKET_SIZE},${AVG_BW}" >> ${OUT_FILE}



done
