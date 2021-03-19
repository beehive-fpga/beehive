`include "tcp_tx_tile_defs.svh"

module tcp_tx_ptr_if_datap #(
     parameter SRC_X = "inv"
    ,parameter SRC_Y = "inv"
)(
     input clk
    ,input rst
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_tx_ptr_if_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_ptr_if_noc0_vrtoc_data
    
    ,output logic   [`FLOW_ID_W-1:0]        app_tail_ptr_tx_wr_req_flowid
    ,output logic   [`PAYLOAD_PTR_W:0]      app_tail_ptr_tx_wr_req_data
    
    ,output logic   [`FLOW_ID_W-1:0]        app_tail_ptr_tx_rd_req_flowid

    ,output logic   [`FLOW_ID_W-1:0]        tail_ptr_app_tx_rd_resp_flowid
    ,output logic   [`PAYLOAD_PTR_W:0]      tail_ptr_app_tx_rd_resp_data

    ,input          [`FLOW_ID_W-1:0]        app_head_ptr_tx_rd_req_flowid

    ,output logic   [`FLOW_ID_W-1:0]        head_ptr_app_tx_rd_resp_flowid
    ,output logic   [`PAYLOAD_PTR_W:0]      head_ptr_app_tx_rd_resp_data
    
    ,input  logic                           ctrl_datap_store_hdr_flit
    ,input  logic                           ctrl_datap_store_ptrs
);

    tcp_noc_hdr_flit hdr_flit_reg;
    tcp_noc_hdr_flit hdr_flit_next;

    tcp_noc_hdr_flit resp_flit;

    logic   [`PAYLOAD_PTR_W-1:0]    head_ptr_reg;
    logic   [`PAYLOAD_PTR_W-1:0]    head_ptr_next;
    logic   [`PAYLOAD_PTR_W-1:0]    tail_ptr_reg;
    logic   [`PAYLOAD_PTR_W-1:0]    tail_ptr_next;

    assign app_tail_ptr_tx_wr_req_flowid = hdr_flit_reg.flowid;
    assign app_tail_ptr_tx_rd_req_flowid = hdr_flit_reg.flowid;
    assign app_head_ptr_tx_rd_req_flowid = hdr_flit_reg.flowid;

    assign app_tail_ptr_tx_wr_req_data = hdr_flit_reg.tail_ptr;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_reg <= '0;
            head_ptr_reg <= '0;
            tail_ptr_reg <= '0;
        end
        else begin
            hdr_flit_reg <= hdr_flit_next;
            head_ptr_reg <= head_ptr_next;
            tail_ptr_reg <= tail_ptr_next;
        end
    end

    assign hdr_flit_next = ctrl_datap_store_hdr_flit
                            ? noc0_ctovr_tcp_tx_ptr_if_data 
                            : hdr_flit_reg;

    always_comb begin
        if (ctrl_datap_store_ptrs) begin
            head_ptr_next = head_ptr_app_tx_rd_resp_data;
            tail_ptr_next = tail_ptr_app_tx_rd_resp_data;
        end
        else begin
            head_ptr_next = head_ptr_reg;
            tail_ptr_next = tail_ptr_reg;
        end
    end

    always_comb begin
        resp_flit = '0;

        resp_flit.core.dst_x_coord = hdr_flit_reg.core.src_x_coord;
        resp_flit.core.dst_y_coord = hdr_flit_reg.core.src_y_coord;
        resp_flit.core.dst_fbits = hdr_flit_reg.core.src_fbits;

        resp_flit.core.msg_len = '0;
        resp_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        resp_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        resp_flit.core.src_fbits = TCP_TX_BUF_IF_FBITS;

        resp_flit.core.msg_type = TCP_TX_PTRS_RESP;
        resp_flit.head_ptr = head_ptr_reg;
        resp_flit.tail_ptr = tail_ptr_reg;
    end
endmodule
