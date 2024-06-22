package udp_echo_app_stats_pkg;
    `include "noc_defs.vh"

    localparam TIMESTAMP_W = 64;
    localparam BYTES_RECV_W = 64;
    
    localparam STATS_DEPTH_LOG2 = 8;
    
    localparam RECORD_PERIOD = 500;//125000000;
    
    typedef struct packed {
        logic   [TIMESTAMP_W-1:0]   timestamp;
        logic   [BYTES_RECV_W-1:0]  bytes_recv;
    } udp_app_stats_struct;
    localparam UDP_APP_STATS_STRUCT_W = TIMESTAMP_W + BYTES_RECV_W;
    localparam UDP_APP_STATS_STRUCT_BYTES = UDP_APP_STATS_STRUCT_W/8;
    
    localparam CLIENT_ADDR_W = 16;
    localparam CLIENT_ADDR_BYTES = CLIENT_ADDR_W/8;
    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0] req_addr;
    } udp_app_stats_req_struct;
    localparam UDP_APP_STATS_REQ_STRUCT_W = CLIENT_ADDR_W;
    
    localparam RESP_PAYLOAD_W = `NOC_DATA_WIDTH - CLIENT_ADDR_W;
    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0]     resp_addr;
        logic   [RESP_PAYLOAD_W-1:0]    resp_payload;
    } udp_app_stats_resp_flit;
    localparam UDP_APP_STATS_RESP_BYTES = CLIENT_ADDR_BYTES + UDP_APP_STATS_STRUCT_BYTES;
    
    typedef enum logic[1:0] {
        HDR = 2'd0,
        META = 2'd1,
        DATA = 2'd2
    } udp_log_resp_sel_e;

endpackage
