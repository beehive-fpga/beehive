package beehive_udp_msg;
    `include "packet_defs.vh"
    `include "noc_defs.vh"

    import beehive_noc_msg::*;
    
    localparam UDP_RX_META_PADDING = `NOC_DATA_WIDTH - (2 * `IP_ADDR_W) - (2 * `PORT_NUM_W) - `UDP_LENGTH_W;

    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]            src_ip;
        logic   [`IP_ADDR_W-1:0]            dst_ip;
        logic   [`PORT_NUM_W-1:0]           src_port;
        logic   [`PORT_NUM_W-1:0]           dst_port;
        logic   [`UDP_LENGTH_W-1:0]         data_length; 
    } udp_info;
    localparam UDP_INFO_W = $bits(udp_info);

    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]            src_ip;
        logic   [`IP_ADDR_W-1:0]            dst_ip;
        logic   [`PORT_NUM_W-1:0]           src_port;
        logic   [`PORT_NUM_W-1:0]           dst_port;
        logic   [`UDP_LENGTH_W-1:0]         data_length; 
    } udp_info;
    localparam UDP_INFO_W = $bits(udp_info);

    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]            src_ip;
        logic   [`IP_ADDR_W-1:0]            dst_ip;
        logic   [`PORT_NUM_W-1:0]           src_port;
        logic   [`PORT_NUM_W-1:0]           dst_port;
        logic   [`UDP_LENGTH_W-1:0]         data_length; 
        logic   [MSG_TIMESTAMP_W-1:0]       timestamp;
        logic   [UDP_RX_META_PADDING-1:0]   padding;
    } udp_rx_metadata_flit;

    localparam UDP_TX_META_PADDING = UDP_RX_META_PADDING;
    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]            src_ip;
        logic   [`IP_ADDR_W-1:0]            dst_ip;
        logic   [`PORT_NUM_W-1:0]           src_port;
        logic   [`PORT_NUM_W-1:0]           dst_port;
        logic   [`UDP_LENGTH_W-1:0]         data_length; 
        logic   [MSG_TIMESTAMP_W-1:0]       timestamp;
        logic   [UDP_TX_META_PADDING-1:0]   padding;
    } udp_tx_metadata_flit;

    localparam UDP_RX_NUM_DST = 1;
endpackage
