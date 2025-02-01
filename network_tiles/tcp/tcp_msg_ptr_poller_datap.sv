`include "tcp_msg_poller_defs.svh"
module tcp_msg_ptr_poller_datap #(
     parameter CHK_SPACE_EMPTY = 0
    ,parameter POLLER_PTR_W = 0
    ,parameter POLLER_IDX_W = 0
)(
     input clk
    ,input rst

    ,input          [FLOWID_W-1:0]          msg_req_q_poll_data_rd_data

    ,output logic   [FLOWID_W-1:0]          poll_data_msg_req_q_wr_data

    ,output logic   [FLOWID_W-1:0]          poll_data_msg_req_mem_rd_req_addr

    ,input          msg_req_mem_struct      msg_req_mem_poll_data_rd_resp_data
    
    ,output logic   [FLOWID_W-1:0]          poller_msg_dst_flowid
    ,output logic   [POLLER_PTR_W:0]        poller_msg_dst_base_ptr // OLD: for tx only
    ,output logic   [POLLER_PTR_W-1:0]      poller_msg_dst_len // OLD: for tx only
    ,output tcp_buf_with_idx                poller_msg_dst_base_buf // NEW: for rx
    ,output logic   [`XY_WIDTH-1:0]         poller_msg_dst_dst_x
    ,output logic   [`XY_WIDTH-1:0]         poller_msg_dst_dst_y
    ,output logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_dst_dst_fbits
    
    ,output logic   [FLOWID_W-1:0]          app_base_idx_rd_req_addr
    
    ,input  logic   [POLLER_IDX_W:0]        base_idx_app_rd_resp_data

    ,output logic   [FLOWID_W-1:0]          app_end_idx_rd_req_addr

    ,input  logic   [POLLER_IDX_W:0]        end_idx_app_rd_resp_data

    ,output logic   [FLOWID_W-1:0]          poll_active_bitvec_clear_req_flowid

    ,output logic                           data_ctrl_msg_satis
    ,input  logic                           ctrl_data_store_req_data
    ,input  logic                           ctrl_data_store_idxs
    ,input  logic                           ctrl_data_store_flowid
    ,input  logic                           ctrl_data_store_buf

    ,output logic   [FLOWID_W-1:0]          app_base_buf_rd_req_flowid
    ,output logic   [POLLER_IDX_W-1:0]      app_base_buf_rd_req_idx

    ,input          tcp_buf                 base_buf_app_rd_resp_data
);
    logic   [FLOWID_W-1:0]      flowid_reg;
    logic   [FLOWID_W-1:0]      flowid_next;

    msg_req_mem_struct          msg_req_data_reg;
    msg_req_mem_struct          msg_req_data_next;

    logic   [POLLER_IDX_W:0]    base_idx_reg;
    logic   [POLLER_IDX_W:0]    base_idx_next;
    logic   [POLLER_IDX_W:0]    end_idx_reg;
    logic   [POLLER_IDX_W:0]    end_idx_next;
    
    tcp_buf base_buf_reg;
    tcp_buf base_buf_next;

    logic   [POLLER_IDX_W:0]    buf_space_used;
    logic   [POLLER_IDX_W:0]    buf_space_empty;

    assign poll_active_bitvec_clear_req_flowid = flowid_reg;
    assign poll_data_msg_req_q_wr_data = flowid_reg;

    assign poll_data_msg_req_mem_rd_req_addr = flowid_next;

    assign poller_msg_dst_flowid = flowid_reg;
    assign poller_msg_dst_base_ptr = base_idx_reg;//old
    assign poller_msg_dst_len = msg_req_data_reg.tx_length;//old
    assign poller_msg_dst_base_buf.buf_info = base_buf_reg;//new
    assign poller_msg_dst_base_buf.idx.idx = base_idx_reg;//new
    assign poller_msg_dst_dst_x = msg_req_data_reg.dst_x;
    assign poller_msg_dst_dst_y = msg_req_data_reg.dst_y;
    assign poller_msg_dst_dst_fbits = msg_req_data_reg.dst_fbits;

    assign app_base_idx_rd_req_addr = flowid_reg;
    assign app_end_idx_rd_req_addr = flowid_reg;

    assign app_base_buf_rd_req_flowid = flowid_reg;
    assign app_base_buf_rd_req_idx = base_idx_reg[POLLER_IDX_W-1:0];

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            msg_req_data_reg <= '0;
            base_idx_reg <= '0;
            end_idx_reg <= '0;
            base_buf_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            msg_req_data_reg <= msg_req_data_next;
            base_idx_reg <= base_idx_next;
            end_idx_reg <= end_idx_next;
            base_buf_reg <= base_buf_next;
        end
    end

    // FIXME: check this calculation
    generate
        if (CHK_SPACE_EMPTY) begin
            assign buf_space_used = base_idx_reg - end_idx_reg;
            assign buf_space_empty = {1'b1, {(POLLER_IDX_W){1'b0}}} - buf_space_used;
            assign data_ctrl_msg_satis = buf_space_empty >= msg_req_data_reg.tx_length; // TODO: change to 1 when TX is done.
        end
        else begin // RX
            assign buf_space_used = end_idx_reg - base_idx_reg;
            assign data_ctrl_msg_satis = buf_space_used >= 1;//msg_req_data_reg.length;
        end
    endgenerate

    assign flowid_next = ctrl_data_store_flowid
                        ? msg_req_q_poll_data_rd_data
                        : flowid_reg;

    assign msg_req_data_next = ctrl_data_store_req_data
                                ? msg_req_mem_poll_data_rd_resp_data
                                : msg_req_data_reg;
    assign base_idx_next = ctrl_data_store_idxs
                        ? base_idx_app_rd_resp_data
                        : base_idx_reg;
    assign end_idx_next = ctrl_data_store_idxs
                        ? end_idx_app_rd_resp_data
                        : end_idx_reg;
    assign base_buf_next = ctrl_data_store_buf
                        ? base_buf_app_rd_resp_data
                        : base_buf_reg;

endmodule
