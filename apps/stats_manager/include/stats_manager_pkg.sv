package stats_manager_pkg;
    `include "noc_defs.vh"
    import tracker_pkg::*;
    import beehive_tcp_msg::*;

    localparam X_BYTES = 1;
    localparam Y_BYTES = 1;
    localparam X_W = X_BYTES * 8;
    localparam Y_W = Y_BYTES * 8;
    typedef struct packed {
        logic   [X_W-1:0]   x_coord;
        logic   [Y_W-1:0]   y_coord;
    } tracker_req_pkt;

    localparam TRACKER_REQ_PKT_W = $bits(tracker_req_pkt);
    localparam TRACKER_REQ_PKT_BYTES = TRACKER_REQ_PKT_W/8;

    localparam TRACKER_FBITS_VALUE = 32'd4;
    localparam [`NOC_FBITS_WIDTH-1:0] TRACKER_FBITS = {1'b1, TRACKER_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    typedef struct packed {
        logic   [`XY_WIDTH-1:0]             dst_x;
        logic   [`XY_WIDTH-1:0]             dst_y;
        logic   [`MSG_DST_FBITS_WIDTH-1:0]  dst_fbits;
        tracker_req_type                    req_type;
        logic   [TRACKER_ADDR_W-1:0]        start_addr;
        logic   [TRACKER_ADDR_W-1:0]        end_addr;
    } requester_input;
    
    localparam APP_NOTIF_IF_FBITS = TCP_RX_APP_NOTIF_FBITS;
    localparam RX_IF_FBITS = TCP_RX_APP_PTR_IF_FBITS;
    
    localparam TX_IF_FBITS_VALUE = 32'd5;
    localparam TX_IF_FBITS = {1'b1, TX_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    
    localparam PTR_IF_FBITS_VALUE = 32'd6;
    localparam [`NOC_FBITS_WIDTH-1:0]   PTR_IF_FBITS = {1'b1, PTR_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
endpackage
