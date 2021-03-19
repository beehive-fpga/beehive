if [ "$#" -ne 2 ]; then
    echo "Usage: $0 out_dir port_num"
    exit
fi

process_bw_log() {
    RES_DIR=${1}
    PORT_NUM=${2}
    mkdir -p ${RES_DIR}
    BW_LOG_FILE=${3}
    PROCESSED_FILE="bws_${PORT_NUM}.csv"

    python3 ${BEEHIVE_PROJECT_ROOT}/util/logging/process_bw_log.py\
        "${RES_DIR}/${BW_LOG_FILE}" "${RES_DIR}/${PROCESSED_FILE}"
}


read_bw_log() {
    RES_DIR=${1}
    PORT_NUM=${2}
    mkdir -p ${RES_DIR}
    BW_LOG_FILE="bw_log_${PORT_NUM}.csv"

    python3 ${BEEHIVE_PROJECT_ROOT}/util/logging/udp_app_log_runner.py\
        "${RES_DIR}/${BW_LOG_FILE}" ${PORT_NUM}

    process_bw_log ${RES_DIR} ${PORT_NUM} ${BW_LOG_FILE}
}

set -e
OUT_DIR=$1
LOG_PORT_NUM=$2
read_bw_log "${OUT_DIR}" ${LOG_PORT_NUM}
