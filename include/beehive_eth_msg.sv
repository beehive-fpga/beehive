package beehive_eth_msg;
    `include "noc_defs.vh"
    `include "packet_defs.vh"

    import beehive_noc_msg::*;

    localparam ETH_TX_META_PADDING = (`NOC_DATA_WIDTH - (2*`MAC_ADDR_W) - `ETH_TYPE_W - `TOT_LEN_W);
    typedef struct packed {
        logic   [`MAC_ADDR_W-1:0]           eth_dst;
        logic   [`MAC_ADDR_W-1:0]           eth_src;
        logic   [`ETH_TYPE_W-1:0]           eth_type;
        logic   [`TOT_LEN_W-1:0]            payload_size;
        logic   [ETH_TX_META_PADDING-1:0]   padding;
    } eth_tx_metadata_flit;
   
    localparam ETH_RX_META_PADDING = (`NOC_DATA_WIDTH - (2 * `MAC_ADDR_W) - `MTU_SIZE_W);
    typedef struct packed {
        logic   [`MAC_ADDR_W-1:0]           eth_dst;
        logic   [`MAC_ADDR_W-1:0]           eth_src;
        logic   [`MTU_SIZE_W-1:0]           eth_data_len;
        logic   [ETH_RX_META_PADDING-1:0]   padding;
    } eth_rx_metadata_flit;

    localparam ETH_RX_HDR_PADDING = `NOC_DATA_WIDTH - DATA_NOC_HDR_FLIT_W - `MTU_SIZE_W;
    typedef struct packed {
        data_noc_hdr_flit                   core;
        logic   [`MTU_SIZE_W-1:0]           frame_size;
        logic   [ETH_RX_HDR_PADDING-1:0]    padding;
    } eth_rx_hdr_flit;

endpackage
