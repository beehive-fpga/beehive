package rs_encode_stats_pkg;
    `include "noc_defs.vh"

    localparam TIMESTAMP_W = 64;
    localparam BYTES_SENT_W = 64;
    localparam REQS_DONE_W = 64;

    localparam STATS_DEPTH_LOG2 = 8;

    localparam RECORD_PERIOD = 125000000;

    typedef struct packed {
        logic   [TIMESTAMP_W-1:0]   timestamp;
        logic   [BYTES_SENT_W-1:0]  bytes_sent;
        logic   [REQS_DONE_W-1:0]   reqs_done;
    } rs_enc_stats_struct;
    localparam RS_ENC_STATS_STRUCT_W = $bits(rs_enc_stats_struct);
    localparam RS_ENC_STATS_STRUCT_BTYES = RS_ENC_STATS_STRUCT_W/8;

    localparam CLIENT_ADDR_W = 16;
    localparam CLIENT_ADDR_BYTES = CLIENT_ADDR_W/8;

    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0] req_addr;
    } rs_enc_stats_req_struct;
    localparam RS_ENC_STATS_REQ_STRUCT_W = $bits(rs_enc_stats_req_struct);

    localparam RESP_PAYLOAD_W = `NOC_DATA_WIDTH - CLIENT_ADDR_W;
    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0]     resp_addr;
        logic   [RESP_PAYLOAD_W-1:0]    resp_payload;
    } rs_enc_stats_resp_flit;

    localparam RS_ENC_STATS_RESP_W = CLIENT_ADDR_W + RS_ENC_STATS_STRUCT_W;
    localparam RS_ENC_STATS_RESP_BYTES = RS_ENC_STATS_RESP_W/8;

endpackage
