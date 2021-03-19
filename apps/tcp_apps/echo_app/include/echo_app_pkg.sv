package echo_app_pkg;
    `include "noc_defs.vh"
    import beehive_tcp_msg::*;
    import tcp_pkg::*;

    typedef struct packed {
        logic   [FLOWID_W-1:0]      flowid;
        logic   [PAYLOAD_PTR_W:0]   head_ptr;
        logic   [PAYLOAD_PTR_W:0]   msg_len;
    } tx_msg_struct;


    localparam CLIENT_LEN_BYTES = 2;
    localparam CLIENT_LEN_W = 8 * CLIENT_LEN_BYTES;
    localparam CLIENT_PADDING_W = `NOC_DATA_WIDTH - (2 * CLIENT_LEN_W) - 8;
    typedef struct packed {
        logic   [CLIENT_LEN_W-1:0]      rd_len;
        logic   [CLIENT_LEN_W-1:0]      wr_len;
        logic   [7:0]                   last;
        logic   [CLIENT_PADDING_W-1:0]  padding;
    } app_hdr_struct;
    localparam APP_HDR_STRUCT_W = (2 * CLIENT_LEN_W) + 8 + CLIENT_PADDING_W;
    localparam APP_HDR_STRUCT_BYTES = APP_HDR_STRUCT_W/8;

    typedef struct packed {
        logic   [PAYLOAD_PTR_W:0]  ptr;
        logic   [PAYLOAD_PTR_W:0]  len;
    } notif_struct;

    typedef enum logic[1:0] {
        HDR_VALUES = 2'b0,
        BODY_VALUES = 2'b1,
        PTR_UPDATE = 2'd2
    } buf_mux_sel_e;

    localparam RX_CTRL_IF_FBITS = TCP_RX_APP_PTR_IF_FBITS;
    localparam RX_BUF_IF_FBITS = TCP_RX_BUF_IF_FBITS;
    localparam RX_APP_NOTIF_IF_FBITS = TCP_RX_APP_NOTIF_FBITS;
    localparam TX_CTRL_IF_FBITS = TCP_TX_APP_PTR_IF_FBITS;
    localparam TX_BUF_IF_FBITS = TCP_TX_BUF_IF_FBITS;
endpackage
