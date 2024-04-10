package open_loop_pkg;
    `include "noc_defs.vh"

    import beehive_tcp_msg::*;
    import tcp_pkg::*;

    typedef enum logic[7:0] {
        SEND = 8'd0,
        RECV = 8'd1
    } client_dir_e;

    typedef enum logic[7:0] {
        FALSE = 8'd0,
        TRUE = 8'd1
    } flag_e;

    typedef struct packed {
        logic   [31:0]  total_reqs;
        logic   [31:0]  bufsize;
        logic   [31:0]  curr_reqs;
        flag_e          should_copy;
    } app_cntxt_struct;
    localparam APP_CNTXT_W = $bits(app_cntxt_struct);
    
    typedef struct packed {
        logic   [PAYLOAD_PTR_W:0]  ptr;
        logic   [PAYLOAD_PTR_W:0]  len;
    } notif_struct;

    localparam APP_NOTIF_IF_FBITS = TCP_RX_APP_NOTIF_FBITS;
    localparam RX_IF_FBITS = TCP_RX_APP_PTR_IF_FBITS;
    localparam SETUP_IF_FBITS_VALUE = 32'd4;
    localparam [`NOC_FBITS_WIDTH-1:0]   SETUP_IF_FBITS = {1'b1, SETUP_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam TX_IF_FBITS_VALUE = 32'd5;
    localparam TX_IF_FBITS = {1'b1, TX_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    localparam PTR_IF_FBITS_VALUE = 32'd4;
    localparam [`NOC_FBITS_WIDTH-1:0]   PTR_IF_FBITS = {1'b1, PTR_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
endpackage
