package eth_latency_stats_pkg;
    import beehive_noc_msg::*;
    `include "noc_defs.vh"

    localparam ETH_STATS_DEPTH_LOG2 = 10;

    typedef struct packed {
        logic   [MSG_TIMESTAMP_W-1:0]   start_timestamp;
        logic   [MSG_TIMESTAMP_W-1:0]   end_timestamp;
    } eth_latency_stats_struct;

    localparam ETH_LATENCY_STATS_STRUCT_W = MSG_TIMESTAMP_W * 2;
    localparam ETH_LATENCY_STATS_STRUCT_BYTES = ETH_LATENCY_STATS_STRUCT_W/8;

    localparam ETH_CLIENT_ADDR_W = 16;
    localparam ETH_CLIENT_ADDR_BYTES = ETH_CLIENT_ADDR_W/8;
    typedef struct packed {
        logic   [ETH_CLIENT_ADDR_W-1:0] req_addr;
    } eth_latency_stats_req_struct;
    localparam ETH_LATENCY_STATS_REQ_STRUCT_W = ETH_CLIENT_ADDR_W;

    localparam RESP_PAYLOAD = `NOC_DATA_WIDTH - ETH_CLIENT_ADDR_W;
    typedef struct packed {
        logic   [ETH_CLIENT_ADDR_W-1:0] resp_addr;
        logic   [RESP_PAYLOAD-1:0]      resp_payload;
    } eth_latency_stats_resp_flit;
    localparam ETH_LATENCY_STATS_RESP_W = ETH_CLIENT_ADDR_W + ETH_LATENCY_STATS_STRUCT_W;
    localparam ETH_LATENCY_STATS_RESP_BYTES = ETH_LATENCY_STATS_RESP_W/8;

endpackage
