package beehive_ip_rewrite_msg;
    `include "packet_defs.vh"
    `include "noc_defs.vh"

    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]    their_ip;
        logic   [`PORT_NUM_W-1:0]   their_port;
        logic   [`PORT_NUM_W-1:0]   our_port;
        logic   [`IP_ADDR_W-1:0]    rewrite_addr;
    } ip_rewrite_table_req;
    localparam IP_REWRITE_TABLE_REQ_W = $bits(ip_rewrite_table_req);
    localparam IP_REWRITE_TABLE_REQ_BYTES = IP_REWRITE_TABLE_REQ_W/8;

    localparam IP_REWRITE_FLIT_PADDING = `NOC_DATA_WIDTH - IP_REWRITE_TABLE_REQ_W;
    typedef struct packed {
        ip_rewrite_table_req req;
        logic   [IP_REWRITE_FLIT_PADDING-1:0]   padding;
    } ip_rewrite_table_flit;
    
    localparam IP_REWRITE_TABLE_CTRL_FBITS_VALUE = 32'd1;
    
    localparam IP_REWRITE_MANAGER_RX_FBITS_VALUE = 32'd2;
    localparam IP_REWRITE_MANAGER_TX_FBITS_VALUE = 32'd2;
    localparam IP_REWRITE_TCP_RX_BUF_FBITS_VALUE = 32'd4;
    localparam IP_REWRITE_TCP_TX_BUF_FBITS_VALUE = 32'd5;

    localparam [`NOC_FBITS_WIDTH-1:0] IP_REWRITE_TABLE_CTRL_FBITS = {1'b1, IP_REWRITE_TABLE_CTRL_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};


    localparam [`NOC_FBITS_WIDTH-1:0] IP_REWRITE_MANAGER_RX_FBITS = {1'b1, IP_REWRITE_MANAGER_RX_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0] IP_REWRITE_MANAGER_TX_FBITS = {1'b1, IP_REWRITE_MANAGER_TX_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    localparam [`NOC_FBITS_WIDTH-1:0] IP_REWRITE_TCP_RX_BUF_FBITS = {1'b1, IP_REWRITE_TCP_RX_BUF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0] IP_REWRITE_TCP_TX_BUF_FBITS = {1'b1, IP_REWRITE_TCP_TX_BUF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
endpackage
