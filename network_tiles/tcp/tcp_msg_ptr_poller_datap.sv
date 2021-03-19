`include "tcp_msg_poller_defs.svh"
module tcp_msg_ptr_poller_datap #(
     parameter CHK_SPACE_EMPTY = 0
    ,parameter POLLER_PTR_W = 0
)(
     input clk
    ,input rst

    ,input          [FLOWID_W-1:0]          msg_req_q_poll_data_rd_data

    ,output logic   [FLOWID_W-1:0]          poll_data_msg_req_q_wr_data

    ,output logic   [FLOWID_W-1:0]          poll_data_msg_req_mem_rd_req_addr

    ,input          msg_req_mem_struct      msg_req_mem_poll_data_rd_resp_data
    
    ,output logic   [FLOWID_W-1:0]          poller_msg_dst_flowid
    ,output logic   [POLLER_PTR_W:0]        poller_msg_dst_base_ptr
    ,output logic   [POLLER_PTR_W-1:0]      poller_msg_dst_len
    ,output logic   [`XY_WIDTH-1:0]         poller_msg_dst_dst_x
    ,output logic   [`XY_WIDTH-1:0]         poller_msg_dst_dst_y
    ,output logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_dst_dst_fbits
    
    ,output logic   [FLOWID_W-1:0]          app_base_ptr_rd_req_addr
    
    ,input  logic   [POLLER_PTR_W:0]        base_ptr_app_rd_resp_data

    ,output logic   [FLOWID_W-1:0]          app_end_ptr_rd_req_addr

    ,input  logic   [POLLER_PTR_W:0]        end_ptr_app_rd_resp_data

    ,output logic   [FLOWID_W-1:0]          poll_active_bitvec_clear_req_flowid

    ,output logic                           data_ctrl_msg_satis
    ,input  logic                           ctrl_data_store_req_data
    ,input  logic                           ctrl_data_store_ptrs
    ,input  logic                           ctrl_data_store_flowid
);
    logic   [FLOWID_W-1:0]      flowid_reg;
    logic   [FLOWID_W-1:0]      flowid_next;

    msg_req_mem_struct          msg_req_data_reg;
    msg_req_mem_struct          msg_req_data_next;

    logic   [POLLER_PTR_W:0]    base_ptr_reg;
    logic   [POLLER_PTR_W:0]    base_ptr_next;
    logic   [POLLER_PTR_W:0]    end_ptr_reg;
    logic   [POLLER_PTR_W:0]    end_ptr_next;

    logic   [POLLER_PTR_W:0]    buf_space_used;
    logic   [POLLER_PTR_W:0]    buf_space_empty;

    assign poll_active_bitvec_clear_req_flowid = flowid_reg;
    assign poll_data_msg_req_q_wr_data = flowid_reg;

    assign poll_data_msg_req_mem_rd_req_addr = flowid_next;

    assign poller_msg_dst_flowid = flowid_reg;
    assign poller_msg_dst_base_ptr = base_ptr_reg;
    assign poller_msg_dst_len = msg_req_data_reg.length;
    assign poller_msg_dst_dst_x = msg_req_data_reg.dst_x;
    assign poller_msg_dst_dst_y = msg_req_data_reg.dst_y;
    assign poller_msg_dst_dst_fbits = msg_req_data_reg.dst_fbits;

    assign app_base_ptr_rd_req_addr = flowid_reg;
    assign app_end_ptr_rd_req_addr = flowid_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            msg_req_data_reg <= '0;
            base_ptr_reg <= '0;
            end_ptr_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            msg_req_data_reg <= msg_req_data_next;
            base_ptr_reg <= base_ptr_next;
            end_ptr_reg <= end_ptr_next;
        end
    end

    // FIXME: check this calculation
    generate
        if (CHK_SPACE_EMPTY) begin
            assign buf_space_used = base_ptr_reg - end_ptr_reg;
            assign buf_space_empty = {1'b1, {(POLLER_PTR_W){1'b0}}} - buf_space_used;
            assign data_ctrl_msg_satis = buf_space_empty >= msg_req_data_reg.length;
        end
        else begin
            assign buf_space_used = end_ptr_reg - base_ptr_reg;
            assign data_ctrl_msg_satis = buf_space_used >= msg_req_data_reg.length;
        end
    endgenerate

    assign flowid_next = ctrl_data_store_flowid
                        ? msg_req_q_poll_data_rd_data
                        : flowid_reg;

    assign msg_req_data_next = ctrl_data_store_req_data
                                ? msg_req_mem_poll_data_rd_resp_data
                                : msg_req_data_reg;
    assign base_ptr_next = ctrl_data_store_ptrs
                        ? base_ptr_app_rd_resp_data
                        : base_ptr_reg;
    assign end_ptr_next = ctrl_data_store_ptrs
                        ? end_ptr_app_rd_resp_data
                        : end_ptr_reg;

endmodule
