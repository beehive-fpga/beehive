`include "tcp_msg_poller_defs.svh"
module tcp_msg_poller_meta_datap #(
    parameter POLLER_PTR_W = 0
)(
     input clk
    ,input rst
    
    ,input  logic   [FLOWID_W-1:0]              src_poller_msg_req_flowid
    ,input  logic   [POLLER_PTR_W-1:0]          src_poller_msg_req_len
    ,input  logic   [`MSG_SRC_X_WIDTH-1:0]      src_poller_msg_dst_x
    ,input  logic   [`MSG_SRC_Y_WIDTH-1:0]      src_poller_msg_dst_y
    ,input  logic   [`MSG_SRC_FBITS_WIDTH-1:0]  src_poller_msg_dst_fbits

    ,output logic   [FLOWID_W-1:0]              meta_data_msg_req_q_wr_req_data

    ,output logic   [FLOWID_W-1:0]              meta_data_active_bitvec_set_req_flowid

    ,output logic   [FLOWID_W-1:0]              meta_data_msg_req_mem_wr_addr
    ,output         msg_req_mem_struct          meta_data_msg_req_mem_wr_data

    ,input  logic   [MAX_FLOW_CNT-1:0]          meta_active_bitvec
    
    ,input                                      ctrl_data_store_inputs
    ,output logic                               data_ctrl_req_pending
);
    logic   [FLOWID_W-1:0]    flowid_reg;
    logic   [FLOWID_W-1:0]    flowid_next;

    msg_req_mem_struct          wr_data_reg;
    msg_req_mem_struct          wr_data_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            wr_data_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            wr_data_reg <= wr_data_next;
        end
    end

    assign flowid_next = ctrl_data_store_inputs
                        ? src_poller_msg_req_flowid
                        : flowid_reg;

    always_comb begin
        wr_data_next = wr_data_reg;
        if (ctrl_data_store_inputs) begin
            wr_data_next.tx_length = src_poller_msg_req_len;
            wr_data_next.dst_x = src_poller_msg_dst_x;
            wr_data_next.dst_y = src_poller_msg_dst_y;
            wr_data_next.dst_fbits = src_poller_msg_dst_fbits;
        end
        else begin
            wr_data_next = wr_data_reg;
        end
    end

    assign meta_data_msg_req_q_wr_req_data = flowid_reg;
    assign meta_data_msg_req_mem_wr_addr = flowid_reg;
    assign meta_data_msg_req_mem_wr_data = wr_data_reg;

    assign meta_data_active_bitvec_set_req_flowid = flowid_reg;

    assign data_ctrl_req_pending = meta_active_bitvec[flowid_reg];
endmodule
