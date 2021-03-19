module tcp_msg_ptr_poller_ctrl (
     input clk
    ,input rst

    ,input                                  msg_req_q_poll_ctrl_empty
    ,output logic                           poll_ctrl_msg_req_q_rd_req_val

    ,output logic                           poll_ctrl_msg_req_q_wr_req_val
    ,input                                  msg_req_q_poll_ctrl_wr_req_rdy

    ,output logic                           poll_ctrl_msg_req_mem_rd_req_val
    ,input                                  msg_req_mem_poll_ctrl_rd_req_rdy

    ,input                                  msg_req_mem_poll_ctrl_rd_resp_val
    ,output logic                           poll_ctrl_msg_req_mem_rd_resp_rdy
    
    ,output logic                           poller_msg_dst_meta_val
    ,input  logic                           dst_poller_msg_meta_rdy

    ,output logic                           app_base_ptr_rd_req_val
    ,input  logic                           base_ptr_app_rd_req_rdy
    
    ,input  logic                           base_ptr_app_rd_resp_val
    ,output logic                           app_base_ptr_rd_resp_rdy

    ,output logic                           app_end_ptr_rd_req_val
    ,input  logic                           end_ptr_app_rd_req_rdy

    ,input  logic                           end_ptr_app_rd_resp_val
    ,output logic                           app_end_ptr_rd_resp_rdy

    ,output logic                           poll_active_bitvec_clear_req_val

    ,input                                  data_ctrl_msg_satis
    ,output logic                           ctrl_data_store_req_data
    ,output logic                           ctrl_data_store_ptrs
    ,output logic                           ctrl_data_store_flowid
);
    typedef enum logic[2:0] {
        READY = 3'd0,
        RD_PTRS = 3'd1,
        STATE_RESP = 3'd2,
        CALC = 3'd3,
        REQUEUE_FLOW = 3'd4,
        SEND_NOTIF = 3'd5,
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
        poller_msg_dst_meta_val = 1'b0;

        poll_ctrl_msg_req_q_wr_req_val = 1'b0;
        poll_ctrl_msg_req_q_rd_req_val = 1'b0;
        poll_ctrl_msg_req_mem_rd_req_val = 1'b0;

        app_base_ptr_rd_req_val = 1'b0;
        app_end_ptr_rd_req_val = 1'b0;

        app_base_ptr_rd_resp_rdy = 1'b0;
        app_end_ptr_rd_resp_rdy = 1'b0;
        poll_ctrl_msg_req_mem_rd_resp_rdy = 1'b0;

        ctrl_data_store_req_data = 1'b0;
        ctrl_data_store_ptrs = 1'b0;
        ctrl_data_store_flowid = 1'b0;

        poll_active_bitvec_clear_req_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                if (~msg_req_q_poll_ctrl_empty & msg_req_mem_poll_ctrl_rd_req_rdy) begin
                    ctrl_data_store_flowid = 1'b1;
                    poll_ctrl_msg_req_q_rd_req_val = 1'b1;
                    poll_ctrl_msg_req_mem_rd_req_val = 1'b1;
                    state_next = RD_PTRS;
                end
                else begin
                    state_next = READY;
                end
            end
            RD_PTRS: begin
                if (base_ptr_app_rd_req_rdy & end_ptr_app_rd_req_rdy) begin
                    app_base_ptr_rd_req_val = 1'b1;
                    app_end_ptr_rd_req_val = 1'b1;
                    state_next = STATE_RESP;
                end
                else begin
                    state_next = RD_PTRS;
                end
            end
            STATE_RESP: begin
                ctrl_data_store_req_data = 1'b1;
                ctrl_data_store_ptrs = 1'b1;
                if (base_ptr_app_rd_resp_val & end_ptr_app_rd_resp_val & msg_req_mem_poll_ctrl_rd_resp_val) begin
                    app_base_ptr_rd_resp_rdy = 1'b1;
                    app_end_ptr_rd_resp_rdy = 1'b1;
                    poll_ctrl_msg_req_mem_rd_resp_rdy = 1'b1;
                    
                    state_next = CALC;
                end
                else begin
                    state_next = STATE_RESP;
                end
            end
            CALC: begin
                if (data_ctrl_msg_satis) begin
                    state_next = SEND_NOTIF;
                end
                else begin
                    state_next = REQUEUE_FLOW;
                end
            end
            REQUEUE_FLOW: begin
                poll_ctrl_msg_req_q_wr_req_val = 1'b1;
                if (msg_req_q_poll_ctrl_wr_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = REQUEUE_FLOW;
                end
            end
            SEND_NOTIF: begin
                poller_msg_dst_meta_val = 1'b1;
                if (dst_poller_msg_meta_rdy) begin
                    poll_active_bitvec_clear_req_val = 1'b1;
                    state_next = READY;
                end
                else begin
                    state_next = SEND_NOTIF;
                end
            end
            default: begin
                poller_msg_dst_meta_val = 'X;

                poll_ctrl_msg_req_q_wr_req_val = 'X;
                poll_ctrl_msg_req_q_rd_req_val = 'X;
                poll_ctrl_msg_req_mem_rd_req_val = 'X;

                app_base_ptr_rd_req_val = 'X;
                app_end_ptr_rd_req_val = 'X;

                app_base_ptr_rd_resp_rdy = 'X;
                app_end_ptr_rd_resp_rdy = 'X;
                poll_ctrl_msg_req_mem_rd_resp_rdy = 'X;

                ctrl_data_store_req_data = 'X;
                ctrl_data_store_ptrs = 'X;
                
                poll_active_bitvec_clear_req_val = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
