package udp_rs_encode_pkg;

    localparam CLIENT_NUM_REQ_BLOCKS_BYTES = 4;
    localparam CLIENT_NUM_REQ_BLOCKS_W = CLIENT_NUM_REQ_BLOCKS_BYTES * 8;
    localparam CLIENT_NUM_REQ_BLOCKS = 2 ** CLIENT_NUM_REQ_BLOCKS_W;
    typedef struct packed {
        logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   num_req_blocks;
    } client_req_struct;
    localparam CLIENT_REQ_STRUCT_W = $bits(client_req_struct);

    localparam ENCODER_NUM_REQ_BLOCKS = 128;
    localparam ENCODER_NUM_REQ_BLOCKS_W = $clog2(ENCODER_NUM_REQ_BLOCKS);

    typedef enum logic[1:0] {
        HDR = 2'd0,
        META = 2'd1,
        DATA = 2'd2
    } udp_rs_tx_flit_e;

endpackage
