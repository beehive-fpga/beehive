package tcp_logger_pkg;
    `include "packet_defs.vh"
    import packet_struct_pkg::*;

    localparam TIMESTAMP_W = 64;
    typedef struct packed {
        logic   [TIMESTAMP_W-1:0]   timestamp;
        logic   [`TOT_LEN_W-1:0]    pkt_len;
        tcp_pkt_hdr                 log_pkt_hdr;
    } log_entry_struct;
    localparam LOG_ENTRY_STRUCT_W = TIMESTAMP_W + `TOT_LEN_W + TCP_HDR_W;

    localparam TCP_LOG_ENTRIES_LOG_2 = 11;
    localparam TCP_LOG_CLIENT_ADDR_W = 16;

    typedef struct packed {
        logic   [TCP_LOG_CLIENT_ADDR_W-1:0]   req_addr;   
    } log_rd_req_struct;
    localparam LOG_RD_REQ_W = TCP_LOG_CLIENT_ADDR_W;

    localparam LOG_RD_REQ_PADDING = `NOC_DATA_WIDTH - LOG_RD_REQ_W;
    typedef struct packed {
        log_rd_req_struct rd_req;
        logic   [LOG_RD_REQ_PADDING-1:0]    padding;
    } log_rd_req_flit;

    // We need to be careful this doesn't get larger than 32 bytes. 
    // If it does, we need to modify the logger response logic
    typedef struct packed {
        logic   [TCP_LOG_CLIENT_ADDR_W-1:0] resp_addr;
        log_entry_struct                    resp_data;
    } log_rd_resp_struct;
    localparam LOG_RD_RESP_W = TCP_LOG_CLIENT_ADDR_W + LOG_ENTRY_STRUCT_W;
    localparam LOG_RD_RESP_BYTES = LOG_RD_RESP_W/8;

    localparam LOG_RD_RESP_PADDING = `NOC_DATA_WIDTH - LOG_RD_RESP_W;
    typedef struct packed {
        log_rd_resp_struct                  rd_resp;
        logic   [LOG_RD_RESP_PADDING-1:0]   padding;
    } log_rd_resp_flit;

    typedef enum logic [1:0]{
        HDR = 2'd0,
        META = 2'd1,
        DATA = 2'd2
    } logger_mux_out_sel;

    typedef enum logic {
        MEM = 1'b0,
        METADATA = 1'b1
    } logger_data_mux_sel;

endpackage
