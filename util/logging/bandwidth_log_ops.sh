
process_bw_log() {
    RES_DIR=${1}
    mkdir -p ${RES_DIR}
    BW_LOG_FILE=${2}
    PROCESSED_FILE=${3}

    CMD="python3 ${BEEHIVE_PROJECT_ROOT}/util/logging/process_bw_log.py\
        ${RES_DIR}/${BW_LOG_FILE} ${RES_DIR}/${PROCESSED_FILE}"
    echo ${CMD}
    eval ${CMD}
}

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

