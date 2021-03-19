module tcp_msg_poller_meta_ctrl (
     input clk
    ,input rst
    
    ,input  logic                           src_poller_msg_req_val
    ,output logic                           poller_src_msg_req_rdy
    
    ,output logic                           meta_ctrl_msg_req_q_wr_req_val
    ,input                                  msg_req_q_meta_ctrl_wr_req_rdy

    ,output logic                           meta_ctrl_active_bitvec_set_req_val

    ,output logic                           meta_ctrl_msg_req_mem_wr_val
    ,input  logic                           msg_req_mem_meta_ctrl_wr_rdy

    ,output logic                           ctrl_data_store_inputs
    ,input  logic                           data_ctrl_req_pending
);
    typedef enum logic[1:0] {
        READY = 2'd0,
        UPDATE_REQ_MEM = 2'd2,
        ENQ_REQ = 2'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        poller_src_msg_req_rdy = 1'b0;
        meta_ctrl_msg_req_mem_wr_val = 1'b0;
        meta_ctrl_msg_req_q_wr_req_val = 1'b0;

        meta_ctrl_active_bitvec_set_req_val = 1'b0;

        ctrl_data_store_inputs = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                poller_src_msg_req_rdy = 1'b1;
                if (src_poller_msg_req_val) begin
                    ctrl_data_store_inputs = 1'b1;
                    state_next = UPDATE_REQ_MEM;
                end
                else begin
                    state_next = READY;
                end
            end
            UPDATE_REQ_MEM: begin
                meta_ctrl_msg_req_mem_wr_val = 1'b1;
                if (msg_req_mem_meta_ctrl_wr_rdy) begin
                    if (!data_ctrl_req_pending) begin
                        state_next = ENQ_REQ;
                    end
                    else begin
                        state_next = READY;
                    end
                end
                else begin
                    state_next = UPDATE_REQ_MEM;
                end
            end
            ENQ_REQ: begin
                meta_ctrl_msg_req_q_wr_req_val = 1'b1;
                meta_ctrl_active_bitvec_set_req_val = 1'b1;
                if (msg_req_q_meta_ctrl_wr_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = ENQ_REQ;
                end
            end
            default: begin
                poller_src_msg_req_rdy = 'X;
                meta_ctrl_msg_req_mem_wr_val = 'X;
                meta_ctrl_msg_req_q_wr_req_val = 'X;
                meta_ctrl_active_bitvec_set_req_val = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
