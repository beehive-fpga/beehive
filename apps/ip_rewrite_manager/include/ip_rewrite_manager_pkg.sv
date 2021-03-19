package ip_rewrite_manager_pkg;
    `include "noc_defs.vh"
    import beehive_ip_rewrite_msg::*;

    typedef enum logic[1:0] {
        TCP_REQ = 2'd0,
        REWRITE_NOTIF_HDR = 2'd1,
        REWRITE_NOTIF_BODY = 2'd2
    } ip_manager_noc_sel;

    typedef enum logic {
        TCP_BUF_REQ = 1'b0,
        TCP_RX_PTR_UPDATE = 1'b1
    } ip_manager_if_sel;

    typedef enum logic[1:0] {
        TCP_TX_REQ = 2'd0,
        TCP_PTR_UPDATE = 2'd1
    } ip_manager_tx_noc_sel;

    typedef enum logic[1:0] {
        TCP_UPDATE_RX_HEAD_PTR = 2'd0,
        TCP_UPDATE_TX_TAIL_PTR = 2'd1
    } ip_manager_tx_tile_sel;

    typedef enum logic[1:0] {
        RX_REWRITE = 2'd0,
        TX_REWRITE = 2'd1
    } ip_manager_tile_sel;

    localparam IP_REWRITE_NETWORK_REQ_BYTES = `NOC_DATA_BYTES;
    localparam REQ_PADDING_BYTES = IP_REWRITE_NETWORK_REQ_BYTES 
                                   - IP_REWRITE_TABLE_REQ_BYTES;
    localparam REQ_PADDING_W = REQ_PADDING_BYTES * 8;
    typedef struct packed {
        ip_rewrite_table_req        rewrite_req;
        logic   [REQ_PADDING_W-1:0] padding;
    } ip_rewrite_network_req;

    typedef enum logic[7:0] {
        OK = 8'd0,
        BAD = 8'd1
    } ip_rewrite_status;

    localparam IP_REWRITE_NETWORK_RESP_BYTES = `NOC_DATA_BYTES;
    localparam RESP_PADDING_BYTES = IP_REWRITE_NETWORK_RESP_BYTES - 1;
    localparam RESP_PADDING_W = RESP_PADDING_BYTES * 8;
    typedef struct packed {
        ip_rewrite_status               status;
        logic   [RESP_PADDING_W-1:0]    padding;
    } ip_rewrite_network_resp;
endpackage
