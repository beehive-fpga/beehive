#!/bin/bash
set -e
TRIAL_SIZES=(
    "64"
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

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 output_file"
    exit
fi

AVG_SCRIPT="${BEEHIVE_PROJECT_ROOT}/util/logging/process_avg_bw.py"

average_bw() {
    SIZE_DIR=${1}
    BWS_FILE=${2}
    AVG_FILE=${3}

    CMD="python3 ${AVG_SCRIPT} ${BWS_FILE} ${AVG_FILE}"
    echo "${CMD}"
    eval "${CMD}"
}

collect_stats() {
    OUT_CSV=${1}
    RES_DIR=${2}
    echo "packet_size,bw_bps" > ${OUT_CSV}
    for SIZE in ${TRIAL_SIZES[@]}; do
        SIZE_DIR="${RES_DIR}/${SIZE}bytes"
        BWS_FILE="${SIZE_DIR}/bws.csv"
        AVG_FILE="${SIZE_DIR}/avg_bw.txt"
        average_bw ${SIZE_DIR} ${BWS_FILE} ${AVG_FILE}
        AVG=$(cat ${AVG_FILE})
        echo "${SIZE},${AVG}" >> ${OUT_CSV}
    done
}

OUTPUT_FILE=${1}
collect_stats ${OUTPUT_FILE} "${BEEHIVE_PROJECT_ROOT}/util/logging/bw_benchmark"
