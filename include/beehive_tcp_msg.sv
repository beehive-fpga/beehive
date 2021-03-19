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
    // this is a TCP specific NoC flit
    localparam TCP_EXTRA_W = MAX_FLOWID_W + ((MAX_PAYLOAD_PTR_W + 1) * 3);
    localparam TCP_HDR_FLIT_W = BASE_FLIT_W + TCP_EXTRA_W;
    localparam TCP_HDR_FLIT_PAD_W = `NOC_DATA_WIDTH - TCP_HDR_FLIT_W;

    typedef struct packed {
        base_noc_hdr_flit                   core;
        logic   [MAX_FLOWID_W-1:0]          flowid;
        logic   [MAX_PAYLOAD_PTR_W:0]       length; 
        // these need to be one bit longer to save the wrap-around bit
        logic   [MAX_PAYLOAD_PTR_W:0]       head_ptr;
        logic   [MAX_PAYLOAD_PTR_W:0]       tail_ptr;
        logic   [TCP_HDR_FLIT_PAD_W-1:0]    padding;
    } tcp_noc_hdr_flit;

endpackage
