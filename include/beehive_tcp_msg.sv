package beehive_tcp_msg;
    `include "packet_defs.vh"
    `include "noc_defs.vh"

    import beehive_noc_msg::*;
   
    // Look...Verilog number literals are hard okay? This is the only way we
    // can get the values so that we can size them some way and guarantee the 
    // actual fbits number has a 1 in the top bit. I mean I guess we could also
    // work out the actual number, but this is more in line with what we actually want.
    // Except for the part where this number constructing stuff is ugly. We don't want
    // that
    localparam TCP_RX_BUF_IF_FBITS_VALUE = 32'd1;
    localparam TCP_RX_APP_PTR_IF_FBITS_VALUE = 32'd2;
    localparam TCP_RX_APP_NOTIF_FBITS_VALUE = 32'd3;

    localparam TCP_TX_BUF_IF_FBITS_VALUE = 32'd1;
    localparam TCP_TX_APP_PTR_IF_FBITS_VALUE = 32'd2;

    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_RX_BUF_IF_FBITS = {1'b1, TCP_RX_BUF_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_RX_APP_PTR_IF_FBITS = {1'b1, TCP_RX_APP_PTR_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_RX_APP_NOTIF_FBITS = {1'b1, TCP_RX_APP_NOTIF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_TX_BUF_IF_FBITS = {1'b1, TCP_TX_BUF_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_TX_APP_PTR_IF_FBITS = {1'b1, TCP_TX_APP_PTR_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    localparam MAX_PAYLOAD_PTR_W = 32;
    localparam MAX_PAYLOAD_IDX_W = 8;
    // subscribe(num bytes)
    // resp(ptr)
    // done(???)
    //

    typedef struct packed {
        logic   [MAX_PAYLOAD_PTR_W:0]       length;
        logic   [TCP_MSG_RESP_W-MAX_PAYLOAD_PTR_W-1:0] padding;
    } tcp_msg_req;
    localparam TCP_MSG_REQ_W = $bits(tcp_msg_req);
    typedef struct packed {
        logic   [MAX_PAYLOAD_PTR_W-1:0]     bufptr;
        // these need to be one bit longer to save the wrap-around bit
        logic   [MAX_PAYLOAD_IDX_W:0] idx;
        logic   [MAX_PAYLOAD_PTR_W:0] len;
        logic   [MAX_PAYLOAD_PTR_W:0] cap;
    } tcp_msg_resp;
    localparam TCP_MSG_RESP_W = $bits(tcp_msg_resp);

    typedef struct packed {
        logic   [MAX_PAYLOAD_PTR_W-1:0]     bufptr; // probably unneeded.
        // these need to be one bit longer to save the wrap-around bit
        logic   [MAX_PAYLOAD_IDX_W:0] idx; // this is the only field that should be changed from the msg resp to the adjust idx.
        logic   [MAX_PAYLOAD_PTR_W:0] len;
        logic   [MAX_PAYLOAD_PTR_W:0] cap;
    } tcp_adjust_idx;
    localparam TCP_ADJUST_IDX_W = $bits(tcp_adjust_idx);

    // this is a TCP specific NoC flit
    typedef struct packed {
        logic   [MAX_FLOWID_W-1:0]          flowid;
        union packed {
            logic   [TCP_MSG_REQ_W-1:0]    tcp_msg_req;
            logic   [TCP_MSG_RESP_W-1:0]   tcp_msg_resp;
            logic   [TCP_ADJUST_IDX_W-1:0] tcp_adjust_idx;
        } msg_specific;
    } tcp_flit_inner;
    localparam TCP_FLIT_INNER_W = $bits(tcp_flit_inner);
    
    // TODO: check to make sure this doesn't go below 0
    localparam TCP_HDR_FLIT_PAD_W = `NOC_DATA_WIDTH - BASE_FLIT_W - TCP_FLIT_INNER_W;
    localparam TCP_EXTRA_W = TCP_FLIT_INNER_W;

    typedef struct packed {
        base_noc_hdr_flit                   core;
        tcp_flit_inner                      inner;
        logic   [TCP_HDR_FLIT_PAD_W-1:0]    padding;
    } tcp_noc_hdr_flit;

    typedef struct packed {
        bufptr;
        len;
        capacity;
    } tcp_buf_info;

    localparam TCP_BUF_INFO_W = $bits(tcp_buf_info);

endpackage
