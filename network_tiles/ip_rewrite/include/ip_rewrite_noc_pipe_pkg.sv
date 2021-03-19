package ip_rewrite_noc_pipe_pkg;
    `include "packet_defs.vh"

    typedef enum logic[1:0] {
        HDR_OUT = 2'd0,
        META_OUT = 2'd1,
        DATA_OUT = 2'd2
    } ip_rewrite_out_sel_e;

    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]    their_addr;
        logic   [`PORT_NUM_W-1:0]   their_port;
        logic   [`PORT_NUM_W-1:0]   our_port;
    } flow_lookup_tuple;
    localparam FLOW_LOOKUP_TUPLE_W = $bits(flow_lookup_tuple);
endpackage
