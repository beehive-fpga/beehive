package echo_app_stats_pkg;
    `include "noc_defs.vh"

    localparam TIMESTAMP_W = 64;
    localparam REQS_DONE_W = 64;

    localparam STATS_DEPTH_LOG2 = 8;

    // record every 10 us
    localparam RECORD_PERIOD = 2500;//125000000;

    typedef struct packed {
        logic   [TIMESTAMP_W-1:0]   timestamp;
        logic   [REQS_DONE_W-1:0]   reqs_done;
    } echo_app_stats_struct;
    localparam ECHO_APP_STATS_STRUCT_W = $bits(echo_app_stats_struct);
    localparam ECHO_APP_STATS_STRUCT_BYTES = ECHO_APP_STATS_STRUCT_W/8;

    localparam CLIENT_ADDR_W = 16;
    localparam CLIENT_ADDR_BYTES = CLIENT_ADDR_W/8;

    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0] req_addr;
    } echo_app_stats_req_struct;
    localparam ECHO_APP_STATS_REQ_STRUCT_W = $bits(echo_app_stats_req_struct);

endpackage
