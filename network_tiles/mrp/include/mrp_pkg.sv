package mrp_pkg;
    `include "packet_defs.vh"
    `include "soc_defs.vh"

    localparam MRP_MAX_DATA_SIZE = 1024;
    localparam MAX_CONNS = 8;
    localparam CONN_ID_W = $clog2(MAX_CONNS);

    localparam TIMEOUT_CYCLES = 10 ** 8;
    localparam TIMESTAMP_W = 64;

    localparam MRP_PKT_FLAGS_W = 32;
    localparam MRP_PKT_FLAGS_PAD_W = 32 - 1;
    typedef struct packed {
        logic [MRP_PKT_FLAGS_PAD_W-1:0] pad;
        logic                           last_pkt;
    } mrp_flags;
    
    localparam MRP_ID_W = 32;
    localparam MRP_PKT_NUM_W = 32;

    typedef struct packed {
        logic   [MRP_ID_W-1:0]      req_id;
        logic   [MRP_PKT_NUM_W-1:0] pkt_num;
        mrp_flags                   flags;
    } mrp_pkt_hdr;
    localparam MRP_PKT_HDR_W = MRP_ID_W + MRP_PKT_NUM_W + MRP_PKT_FLAGS_W;
    localparam MRP_PKT_HDR_BYTES = MRP_PKT_HDR_W/8;

    typedef struct packed {
        logic   [MRP_PKT_NUM_W-1:0] pkt_num;
    } mrp_rx_state;
    localparam MRP_RX_STATE_W = MRP_PKT_NUM_W;
    
    typedef struct packed {
        logic   [MRP_PKT_NUM_W-1:0] pkt_num;
    } mrp_tx_state;
    localparam MRP_TX_STATE_W = MRP_PKT_NUM_W;

    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]    src_ip;
        logic   [`IP_ADDR_W-1:0]    dst_ip;
        logic   [`PORT_NUM_W-1:0]   src_port;
        logic   [`PORT_NUM_W-1:0]   dst_port;
        logic   [MRP_ID_W-1:0]      req_id;
    } mrp_req_key;
    localparam MRP_REQ_KEY_W = (2 * `IP_ADDR_W) + (2 * `PORT_NUM_W) + MRP_ID_W;

    typedef struct packed {
        logic   [`MAC_INTERFACE_W-1:0]  data;
        logic                           last;
        logic   [`MAC_PADBYTES_W-1:0]   padbytes;
    } mrp_stream;
    localparam MRP_STREAM_W = `MAC_INTERFACE_W + 1 + `MAC_PADBYTES_W;

    typedef enum logic {
        DATAP = 1'b0,
        TIMEOUT = 1'b1
    } addr_mux_sel_e;

    typedef enum logic {
        HDR = 1'b0,
        DATA = 1'b1
    } tx_hold_mux_sel_e;
    
    typedef enum logic {
        INPUT = 1'b0,
        ZERO = 1'b1
    } tx_padbytes_mux_sel_e;

    typedef enum logic {
        MEM = 1'b0,
        RESET = 1'b1
    } rx_ptr_mux_sel_e;
   
    localparam RX_CONN_BUF_SIZE = 2**16;
    localparam RX_CONN_BUF_ADDR_W = $clog2(RX_CONN_BUF_SIZE);
    localparam RX_BUF_SIZE = RX_CONN_BUF_SIZE * MAX_CONNS;
    localparam RX_BUF_ADDR_W = $clog2(RX_BUF_SIZE);
    localparam RX_BUF_LINES = RX_BUF_SIZE/`MAC_INTERFACE_BYTES;
    localparam RX_BUF_LINE_ADDR_W = $clog2(RX_BUF_LINES);

    typedef struct packed {
        logic   [CONN_ID_W-1:0]     conn_id;
        logic   [RX_CONN_BUF_ADDR_W-1:0] head_ptr;
    } output_ctrl_enq_struct;
    localparam OUTPUT_CTRL_ENQ_STRUCT_W = CONN_ID_W + RX_CONN_BUF_ADDR_W;

    typedef struct packed {
        logic   [RX_CONN_BUF_ADDR_W-1:0] head_ptr;
        logic   [RX_CONN_BUF_ADDR_W-1:0] tail_ptr;
    } rx_ptrs_struct;
    localparam RX_PTRS_STRUCT_W = 2 * RX_CONN_BUF_ADDR_W;


endpackage
