package beehive_ctrl_noc_msg;
    `include "noc_defs.vh"

    import beehive_noc_msg::*;
    
    typedef struct packed {
        logic   [`MSG_DST_CHIPID_WIDTH-1:0] dst_chip_id;
        logic   [`MSG_DST_X_WIDTH-1:0]      dst_x_coord;
        logic   [`MSG_DST_Y_WIDTH-1:0]      dst_y_coord;
        logic   [`MSG_DST_FBITS_WIDTH-1:0]  dst_fbits;
        logic   [`MSG_LENGTH_WIDTH-1:0]     msg_len;
        logic   [`MSG_TYPE_WIDTH-1:0]       msg_type;
    } routing_hdr_flit;

    localparam CTRL_MSG_LEN_OFFSET = `CTRL_NOC_DATA_W - `MSG_DST_CHIPID_WIDTH -
                                `MSG_DST_X_WIDTH - `MSG_DST_Y_WIDTH - `MSG_DST_FBITS_WIDTH;

    localparam MISC_FLIT_PADDING_W = `CTRL_NOC_DATA_W - `MSG_SRC_CHIPID_WIDTH -
                            `MSG_SRC_X_WIDTH - `MSG_SRC_Y_WIDTH -
                            `MSG_SRC_FBITS_WIDTH - MSG_METADATA_FLITS_W;
    typedef struct packed {
        logic   [`MSG_SRC_CHIPID_WIDTH-1:0] src_chip_id;
        logic   [`MSG_SRC_X_WIDTH-1:0]      src_x_coord;
        logic   [`MSG_SRC_Y_WIDTH-1:0]      src_y_coord;
        logic   [`MSG_SRC_FBITS_WIDTH-1:0]  src_fbits;
        logic   [MSG_METADATA_FLITS_W-1:0]  metadata_flits;
        logic   [MISC_FLIT_PADDING_W-1:0]   padding;
    } misc_hdr_flit;
endpackage
