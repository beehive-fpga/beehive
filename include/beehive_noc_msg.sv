package beehive_noc_msg;
    `include "noc_defs.vh"

    localparam MSG_METADATA_FLITS_W = 8;

    // this is a localparam, because I really don't want a literal insertion of all this
    // junk in something as a macro
    // This evaluates to 184 with default values
    localparam MSG_TIMESTAMP_W = 64;
    localparam MAX_FLOWID_W = 20;


    // the base header flit. this should be a member of a larger flit structure
    typedef struct packed {
        logic   [`MSG_DST_CHIPID_WIDTH-1:0] dst_chip_id;
        logic   [`MSG_DST_X_WIDTH-1:0]      dst_x_coord;
        logic   [`MSG_DST_Y_WIDTH-1:0]      dst_y_coord;
        logic   [`MSG_DST_FBITS_WIDTH-1:0]  dst_fbits;
        logic   [`MSG_LENGTH_WIDTH-1:0]     msg_len;
        logic   [`MSG_TYPE_WIDTH-1:0]       msg_type;
        logic   [`MSG_SRC_CHIPID_WIDTH-1:0] src_chip_id;
        logic   [`MSG_SRC_X_WIDTH-1:0]      src_x_coord;
        logic   [`MSG_SRC_Y_WIDTH-1:0]      src_y_coord;
        logic   [`MSG_SRC_FBITS_WIDTH-1:0]  src_fbits;
    } base_noc_hdr_flit;

    localparam BASE_FLIT_W = $bits(base_noc_hdr_flit);


    localparam PACKET_ID_W = 64;

    typedef struct packed {
        logic   [`MSG_DST_X_WIDTH-1:0]  x_src;
        logic   [`MSG_DST_Y_WIDTH-1:0]  y_src;
    } origin_struct;
    localparam ORIGIN_ID_W = $bits(origin_struct);
    
    localparam PACKET_NUM_W = 64 - ORIGIN_ID_W;


    typedef struct packed {
        origin_struct               origin;
        logic   [PACKET_NUM_W-1:0]  packet_num;
    } packet_id_struct;
    
    typedef struct packed {
        base_noc_hdr_flit   core;
        logic   [MSG_METADATA_FLITS_W-1:0]      metadata_flits;
        packet_id_struct                        packet_id;
        logic   [MSG_TIMESTAMP_W-1:0]           timestamp;
    } data_noc_hdr_flit;
    localparam DATA_NOC_HDR_FLIT_W = $bits(data_noc_hdr_flit);

    typedef struct packed {
        logic   [`MSG_ADDR_WIDTH-1:0]       addr;
        logic   [`MSG_DATA_SIZE_WIDTH-1:0]  data_size;
    } dram_req;
    localparam DRAM_REQ_W = $bits(dram_req);
    
    localparam DRAM_HDR_PADDING = `NOC_DATA_WIDTH - (BASE_FLIT_W + DRAM_REQ_W);

    typedef struct packed {
        base_noc_hdr_flit   core;
        dram_req            req;
        logic   [DRAM_HDR_PADDING-1:0]      padding;
    } dram_noc_hdr_flit;


    // use this flit if you don't have protocol specific data to send
    localparam BASIC_HDR_PADDING_W =  (`NOC_DATA_WIDTH - DATA_NOC_HDR_FLIT_W);
    typedef struct packed {
        data_noc_hdr_flit                   core;
        logic   [BASIC_HDR_PADDING_W-1:0]   padding;
    } beehive_noc_hdr_flit;

    localparam [`MSG_TYPE_WIDTH-1:0]    ETH_RX_FRAME = `MSG_TYPE_WIDTH'd12;
    localparam [`MSG_TYPE_WIDTH-1:0]    ETH_TX_FRAME = `MSG_TYPE_WIDTH'd1;
    localparam [`MSG_TYPE_WIDTH-1:0]    IP_RX_DATAGRAM = `MSG_TYPE_WIDTH'd2;
    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_RX_SEGMENT = `MSG_TYPE_WIDTH'd3;
    localparam [`MSG_TYPE_WIDTH-1:0]    UDP_RX_SEGMENT = `MSG_TYPE_WIDTH'd12;
    localparam [`MSG_TYPE_WIDTH-1:0]    UDP_TX_SEGMENT = `MSG_TYPE_WIDTH'd13;
    localparam [`MSG_TYPE_WIDTH-1:0]    IP_TX_DATAGRAM = `MSG_TYPE_WIDTH'd4;

    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_NEW_FLOW_NOTIF = `MSG_TYPE_WIDTH'd5;
    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_RX_MSG_REQ2 = `MSG_TYPE_WIDTH'd6;
    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_RX_MSG_RESP2 = `MSG_TYPE_WIDTH'd8;
    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_RX_ADJUST_IDX = `MSG_TYPE_WIDTH'd7;

    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_TX_MSG_REQ = `MSG_TYPE_WIDTH'd9;
    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_TX_MSG_RESP = `MSG_TYPE_WIDTH'd10;
    localparam [`MSG_TYPE_WIDTH-1:0]    TCP_TX_ADJUST_PTR = `MSG_TYPE_WIDTH'd11;
    
    localparam [`MSG_TYPE_WIDTH-1:0]    IP_REWRITE_ADJUST_TABLE = `MSG_TYPE_WIDTH'd15;

    localparam [`MSG_TYPE_WIDTH-1:0]    TRACKER_MSG = `MSG_TYPE_WIDTH'd16;
    
    localparam PKT_IF_FBITS = {1'b1, {(`NOC_FBITS_WIDTH-1){1'd0}}};
endpackage
