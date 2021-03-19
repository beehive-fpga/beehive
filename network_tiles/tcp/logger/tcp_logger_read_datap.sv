`include "tcp_logger_read_defs.svh"
module tcp_logger_read_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter LOG_ADDR_W = -1
    ,parameter LOG_CLIENT_ADDR_W = -1
)(
     input  clk
    ,input  rst

    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_logger_read_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]   logger_read_noc_data
    
    ,output logic   [LOG_ADDR_W-1:0]        rd_req_logger_mem_addr

    ,input  log_entry_struct                rd_resp_logger_mem_entry
    
    ,input  logic                           ctrl_datap_store_meta_flit
    ,input  logic                           ctrl_datap_store_log_req
    ,input  logic                           ctrl_datap_store_log_resp
    ,input  logger_mux_out_sel              ctrl_datap_mux_out_sel
    ,input  logger_data_mux_sel             ctrl_datap_data_mux_sel

    ,output logic                           datap_ctrl_read_metadata

    ,input  logic   [LOG_ADDR_W:0]          recorder_read_curr_addr
);

    udp_rx_metadata_flit    meta_flit_reg;
    log_rd_req_struct       log_req_reg;
    udp_rx_metadata_flit    meta_flit_next;
    log_rd_req_struct       log_req_next;
    
    log_rd_req_flit         log_req_cast;

    log_entry_struct        entry_reg;
    log_entry_struct        entry_next;
    
    udp_noc_hdr_flit        resp_hdr_flit_cast;
    udp_tx_metadata_flit    resp_meta_flit_cast;
    log_rd_resp_flit        log_resp_cast;

    logic   [LOG_CLIENT_ADDR_W-1:0] padded_curr_addr;

    assign padded_curr_addr = {{(LOG_CLIENT_ADDR_W-LOG_ADDR_W-1){1'b0}},
                                recorder_read_curr_addr};

    always_ff @(posedge clk) begin
        meta_flit_reg <= meta_flit_next;
        log_req_reg <= log_req_next;
        entry_reg <= entry_next;
    end

    // get the top bit, which tells us whether we're trying to address the log memory
    // or the metadata about the log
    assign datap_ctrl_read_metadata = log_req_next.req_addr[LOG_ADDR_W];

    assign meta_flit_next = ctrl_datap_store_meta_flit
                            ? noc_logger_read_data
                            : meta_flit_reg;

    assign log_req_cast = noc_logger_read_data;
    assign log_req_next = ctrl_datap_store_log_req
                        ? log_req_cast.rd_req
                        : log_req_reg;

    assign entry_next = ctrl_datap_store_log_resp
                        ? rd_resp_logger_mem_entry
                        : entry_reg;

    assign rd_req_logger_mem_addr = log_req_reg.req_addr[LOG_ADDR_W-1:0];

    always_comb begin
        if (ctrl_datap_mux_out_sel == tcp_logger_pkg::HDR) begin
            logger_read_noc_data = resp_hdr_flit_cast;
        end
        else if (ctrl_datap_mux_out_sel == tcp_logger_pkg::META) begin
            logger_read_noc_data = resp_meta_flit_cast;
        end
        else begin
            logger_read_noc_data = log_resp_cast;
        end
    end

    always_comb begin
        log_resp_cast = '0;
        log_resp_cast.rd_resp.resp_addr = log_req_reg.req_addr;
        if (ctrl_datap_data_mux_sel == MEM) begin
            log_resp_cast.rd_resp.resp_data = entry_reg;
        end
        else begin
            log_resp_cast.rd_resp.resp_data = '0;
            log_resp_cast.rd_resp.resp_data[LOG_ENTRY_STRUCT_W-1 -: LOG_CLIENT_ADDR_W]
                = padded_curr_addr;
        end
    end
    
    always_comb begin
        resp_meta_flit_cast = '0;
        resp_meta_flit_cast.src_ip = meta_flit_reg.dst_ip;
        resp_meta_flit_cast.dst_ip = meta_flit_reg.src_ip;
        resp_meta_flit_cast.src_port = meta_flit_reg.dst_port;
        resp_meta_flit_cast.dst_port = meta_flit_reg.src_port;
        resp_meta_flit_cast.data_length = LOG_RD_RESP_BYTES;
    end

    always_comb begin
        resp_hdr_flit_cast = '0;

        resp_hdr_flit_cast.core.dst_x_coord = UDP_TX_TILE_X[`XY_WIDTH-1:0];
        resp_hdr_flit_cast.core.dst_y_coord = UDP_TX_TILE_Y[`XY_WIDTH-1:0];

        // 1 metadata flit, one response flit
        resp_hdr_flit_cast.core.msg_len = 2;
        resp_hdr_flit_cast.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        resp_hdr_flit_cast.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        resp_hdr_flit_cast.core.metadata_flits = 1;
        resp_hdr_flit_cast.core.msg_type = UDP_TX_SEGMENT;
    end

endmodule
