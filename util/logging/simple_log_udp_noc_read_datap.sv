`include "simple_log_udp_noc_read_defs.svh"
module simple_log_udp_noc_read_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter ADDR_W = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter CLIENT_ADDR_W = -1
)(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]       ctovr_reader_in_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       reader_out_vrtoc_data
    
    ,output logic   [ADDR_W-1:0]                log_rd_req_addr

    ,input          [RESP_DATA_STRUCT_W-1:0]    log_rd_resp_data

    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped

    ,input  logic                               ctrl_datap_store_hdr
    ,input  logic                               ctrl_datap_store_meta
    ,input  logic                               ctrl_datap_store_req
    ,input  logic                               ctrl_datap_store_log_resp
    ,input          simple_log_resp_sel_e       ctrl_datap_output_flit_sel
    
    ,output logic                               datap_ctrl_rd_meta
);

    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0] req_addr;
    } simple_log_req_struct;
    localparam SIMPLE_LOG_REQ_STRUCT_W = CLIENT_ADDR_W;
    
    localparam RESP_PAYLOAD_W = `NOC_DATA_WIDTH - CLIENT_ADDR_W;
    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0]     resp_addr;
        logic   [RESP_PAYLOAD_W-1:0]    resp_payload;
    } simple_log_resp_flit;
    localparam SIMPLE_LOG_RESP_STRUCT_BYTES = `NOC_DATA_BYTES;

    udp_rx_metadata_flit                meta_flit_reg;
    udp_rx_metadata_flit                meta_flit_next;
    
    simple_log_req_struct               log_req_reg;
    simple_log_req_struct               log_req_next;

    logic   [RESP_DATA_STRUCT_W-1:0]        entry_reg;
    logic   [RESP_DATA_STRUCT_W-1:0]        entry_next;
    
    udp_noc_hdr_flit            resp_hdr_flit_cast;
    udp_tx_metadata_flit        resp_meta_flit_cast;
    simple_log_resp_flit        log_resp_cast;

    logic   [CLIENT_ADDR_W-1:0] padded_addr_reg;
    logic   [CLIENT_ADDR_W-1:0] padded_addr_next;
    logic   [CLIENT_ADDR_W-1:0] padded_curr_addr;

    assign datap_ctrl_rd_meta = log_req_reg.req_addr[ADDR_W];
    assign log_rd_req_addr = log_req_reg.req_addr[ADDR_W-1:0];

    assign padded_curr_addr = {{(CLIENT_ADDR_W-ADDR_W-1){1'b0}}, 
                                    has_wrapped, curr_wr_addr};

    always_ff @(posedge clk) begin
        if (rst) begin
            meta_flit_reg <= '0;
            log_req_reg <= '0;
            entry_reg <= '0;
            padded_addr_reg <= '0;
        end
        else begin
            meta_flit_reg <= meta_flit_next;
            log_req_reg <= log_req_next;
            entry_reg <= entry_next;
            padded_addr_reg <= padded_addr_next;
        end
    end

    assign meta_flit_next = ctrl_datap_store_meta
                            ? ctovr_reader_in_data
                            : meta_flit_reg;
    assign log_req_next = ctrl_datap_store_req
                        ? ctovr_reader_in_data[`NOC_DATA_WIDTH-1 
                          -: SIMPLE_LOG_REQ_STRUCT_W]
                        : log_req_reg;

    assign entry_next = ctrl_datap_store_log_resp
                        ? log_rd_resp_data
                        : entry_reg;

    assign padded_addr_next = ctrl_datap_store_log_resp
                            ? padded_curr_addr
                            : padded_addr_reg;

    always_comb begin
        if (ctrl_datap_output_flit_sel == simple_log_udp_noc_read_pkg::HDR) begin
            reader_out_vrtoc_data = resp_hdr_flit_cast;
        end
        else if (ctrl_datap_output_flit_sel == simple_log_udp_noc_read_pkg::META) begin
            reader_out_vrtoc_data = resp_meta_flit_cast;
        end
        else begin
            reader_out_vrtoc_data = log_resp_cast;
        end
    end

    always_comb begin
        resp_meta_flit_cast = '0;
        resp_meta_flit_cast.src_ip = meta_flit_reg.dst_ip;
        resp_meta_flit_cast.dst_ip = meta_flit_reg.src_ip;
        resp_meta_flit_cast.src_port = meta_flit_reg.dst_port;
        resp_meta_flit_cast.dst_port = meta_flit_reg.src_port;
        resp_meta_flit_cast.data_length = SIMPLE_LOG_RESP_STRUCT_BYTES;
    end

    always_comb begin
        log_resp_cast = '0;
        log_resp_cast.resp_addr = log_req_reg.req_addr;
        if (datap_ctrl_rd_meta) begin
            log_resp_cast.resp_payload[RESP_PAYLOAD_W-1 -: CLIENT_ADDR_W] = 
                padded_addr_reg;
        end
        else begin
            log_resp_cast.resp_payload[RESP_PAYLOAD_W-1 -: RESP_DATA_STRUCT_W] =
                entry_reg;
        end
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
