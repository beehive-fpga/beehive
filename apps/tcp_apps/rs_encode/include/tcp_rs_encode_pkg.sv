package tcp_rs_encode_pkg;

    localparam CLIENT_NUM_REQ_BLOCKS_BYTES = 4;
    localparam CLIENT_NUM_REQ_BLOCKS_W = CLIENT_NUM_REQ_BLOCKS_BYTES * 8;
    localparam CLIENT_NUM_REQ_BLOCKS = 2 ** CLIENT_NUM_REQ_BLOCKS_W;
    localparam CLIENT_SIZE_W = 32;
    localparam REQ_PADDING = 512 - CLIENT_NUM_REQ_BLOCKS - (CLIENT_SIZE_W*2);
    typedef struct packed {
        logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   num_req_blocks;
        logic   [CLIENT_SIZE_W-1:0]             req_size;
        logic   [CLIENT_SIZE_W-1:0]             resp_size;
        logic   [REQ_PADDING-1:0]               padding;
    } client_req_struct;
    localparam CLIENT_REQ_STRUCT_W = $bits(client_req_struct);

    localparam ENCODER_NUM_REQ_BLOCKS = 128;
    localparam ENCODER_NUM_REQ_BLOCKS_W = $clog2(ENCODER_NUM_REQ_BLOCKS);

    typedef struct packed {
        logic   [FLOWID_W-1:0]      flowid;
        logic   [CLIENT_SIZE_W-1:0] req_size;
        logic   [CLIENT_SIZE_W-1:0] resp_size;
    } tcp_rs_metadata;
    
    localparam TX_MEM_FBITS_VALUE = 32'd6;   
    localparam RX_MEM_FBITS_VALUE = 32'd7;
    
    localparam [`NOC_FBITS_WIDTH-1:0]   TX_MEM_FBITS = {1'b1, {TX_MEM_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]}};
    localparam [`NOC_FBITS_WIDTH-1:0]   RX_MEM_FBITS_VALUE = {1'b1, {RX_MEM_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]}};
endpackage