package tcp_msg_poller_pkg;
    `include "noc_defs.vh"
    `include "bsg_defines.v"

    import tcp_pkg::*;

    localparam REQ_PTR_W = RX_PAYLOAD_PTR_W > TX_PAYLOAD_PTR_W
                        ? RX_PAYLOAD_PTR_W
                        : TX_PAYLOAD_PTR_W;

    typedef struct packed {
        logic   [REQ_PTR_W-1:0]         length; // TODO: change this to tcp_msg_req (w/o padding) (think also about what that type should be...)
        logic   [`XY_WIDTH-1:0]         dst_x;
        logic   [`XY_WIDTH-1:0]         dst_y;
        logic   [`NOC_FBITS_WIDTH-1:0]  dst_fbits;
    } msg_req_mem_struct;
    localparam MSG_REQ_MEM_STRUCT_W = $bits(msg_req_mem_struct);
endpackage
