`include "tcp_rx_tile_defs.svh"
module tcp_rx_msg_noc_if_out_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_ptr_if_noc_data
    
    ,input  logic   [FLOWID_W-1:0]          poller_msg_noc_if_flowid
    ,input  tcp_buf_with_idx                poller_msg_noc_if_head_buf
    ,input  logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_x
    ,input  logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_y
    ,input  logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_noc_if_dst_fbits

    ,input  logic                           ctrl_datap_store_inputs
);

    logic   [FLOWID_W-1:0]          flowid_reg;
    tcp_buf_with_idx                head_buf_reg;
    logic   [`XY_WIDTH-1:0]         dst_x_reg;
    logic   [`XY_WIDTH-1:0]         dst_y_reg;
    logic   [`NOC_FBITS_WIDTH-1:0]  dst_fbits_reg;
    
    logic   [FLOWID_W-1:0]          flowid_next;
    tcp_buf_with_idx                head_buf_next;
    logic   [`XY_WIDTH-1:0]         dst_x_next;
    logic   [`XY_WIDTH-1:0]         dst_y_next;
    logic   [`NOC_FBITS_WIDTH-1:0]  dst_fbits_next;

    tcp_noc_hdr_flit    hdr_flit_cast;

    assign tcp_rx_ptr_if_noc_data = hdr_flit_cast;

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            head_buf_reg <= '0;
            dst_x_reg <= '0;
            dst_y_reg <= '0;
            dst_fbits_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            head_buf_reg <= head_buf_next;
            dst_x_reg <= dst_x_next;
            dst_y_reg <= dst_y_next;
            dst_fbits_reg <= dst_fbits_next;
        end
    end

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            flowid_next = poller_msg_noc_if_flowid;
            head_buf_next = poller_msg_noc_if_head_buf;
            dst_x_next = poller_msg_noc_if_dst_x;
            dst_y_next = poller_msg_noc_if_dst_y;
            dst_fbits_next = poller_msg_noc_if_dst_fbits;
        end
        else begin
            flowid_next = flowid_reg;
            head_buf_next = head_buf_reg;
            dst_x_next = dst_x_reg;
            dst_y_next = dst_y_reg;
            dst_fbits_next = dst_fbits_reg;
        end
    end

    always_comb begin
        hdr_flit_cast = '0;

        hdr_flit_cast.core.dst_x_coord = dst_x_reg;
        hdr_flit_cast.core.dst_y_coord = dst_y_reg;
        hdr_flit_cast.core.dst_fbits = dst_fbits_reg;
        hdr_flit_cast.core.msg_len = '0;
        hdr_flit_cast.core.msg_type = TCP_RX_MSG_RESP2;
        hdr_flit_cast.core.src_x_coord = SRC_X[`MSG_SRC_X_WIDTH-1:0];
        hdr_flit_cast.core.src_y_coord = SRC_Y[`MSG_SRC_Y_WIDTH-1:0];
        hdr_flit_cast.core.src_fbits = TCP_RX_APP_PTR_IF_FBITS;
        
        hdr_flit_cast.inner.flowid = flowid_reg;
        hdr_flit_cast.inner.msg_specific.tcp_msg_resp.resp_buf = head_buf_reg;
    end

endmodule
