package beehive_ip_msg;
    `include "noc_defs.vh"
    `include "packet_defs.vh"
    import beehive_noc_msg::*;
    
    `define IP_RX_META_PADDING (`NOC_DATA_WIDTH - (2*`IP_ADDR_W) - `TOT_LEN_W - `PROTOCOL_W - MSG_TIMESTAMP_W)
    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]            src_ip;
        logic   [`IP_ADDR_W-1:0]            dst_ip;
        logic   [`TOT_LEN_W-1:0]            data_payload_len;
        logic   [`PROTOCOL_W-1:0]           protocol;
        logic   [MSG_TIMESTAMP_W-1:0]       timestamp;
        logic   [`IP_RX_META_PADDING-1:0]   padding;
    } ip_rx_metadata_flit;

    `define IP_TX_META_PADDING (`NOC_DATA_WIDTH - (2*`IP_ADDR_W) - `TOT_LEN_W - `PROTOCOL_W - MSG_TIMESTAMP_W)
    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]            src_ip;
        logic   [`IP_ADDR_W-1:0]            dst_ip;
        logic   [`TOT_LEN_W-1:0]            data_payload_len;
        logic   [`PROTOCOL_W-1:0]           protocol;
        logic   [MSG_TIMESTAMP_W-1:0]       timestamp;
        logic   [`IP_TX_META_PADDING-1:0]   padding;
    } ip_tx_metadata_flit;

endpackage
