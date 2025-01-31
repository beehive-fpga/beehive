`include "tcp_rx_tile_defs.svh"
module tcp_rx_msg_noc_if_in_datap (
     input clk
    ,input rst
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_tcp_rx_ptr_if_data
    
    ,output logic   [FLOWID_W-1:0]              noc_if_poller_msg_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      noc_if_poller_msg_req_len
    ,output logic   [`MSG_SRC_X_WIDTH-1:0]      noc_if_poller_msg_dst_x
    ,output logic   [`MSG_SRC_Y_WIDTH-1:0]      noc_if_poller_msg_dst_y
    ,output logic   [`MSG_SRC_FBITS_WIDTH-1:0]  noc_if_poller_msg_dst_fbits

    ,output logic   [FLOWID_W-1:0]              app_rx_head_idx_wr_req_addr
    ,output tcp_buf_idx                         app_rx_head_idx_wr_req_data

    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      app_rx_free_req_addr
    ,output logic   [MALLOC_LEN_W-1:0]          app_rx_free_req_len

    ,input  logic                               ctrl_datap_store_hdr_flit
);

    tcp_noc_hdr_flit hdr_flit_reg;
    tcp_noc_hdr_flit hdr_flit_next;

    // for adjust_ptr
    assign app_rx_head_idx_wr_req_addr = hdr_flit_reg.inner.flowid;
    assign app_rx_head_idx_wr_req_data.idx = hdr_flit_reg.inner.msg_specific.tcp_adjust_idx.old_buf.idx.idx + 1; // go to the next idx. this buffer is done.
    assign app_rx_free_req_addr = hdr_flit_reg.inner.msg_specific.tcp_adjust_idx.old_buf.buf_info.ptr;
    assign app_rx_free_req_len = hdr_flit_reg.inner.msg_specific.tcp_adjust_idx.old_buf.buf_info.cap; // TODO: bit widths here are different...

    // for tcp_msg_req
    assign noc_if_poller_msg_req_flowid = hdr_flit_reg.inner.flowid;
    assign noc_if_poller_msg_req_len = hdr_flit_reg.inner.msg_specific.tcp_msg_req.__length;
    assign noc_if_poller_msg_dst_x = hdr_flit_reg.core.src_x_coord;
    assign noc_if_poller_msg_dst_y = hdr_flit_reg.core.src_y_coord;
    assign noc_if_poller_msg_dst_fbits = hdr_flit_reg.core.src_fbits;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_reg <= '0;
        end
        else begin
            hdr_flit_reg <= hdr_flit_next;
        end
    end

    assign hdr_flit_next = ctrl_datap_store_hdr_flit
                        ? noc_tcp_rx_ptr_if_data
                        : hdr_flit_reg;


endmodule
