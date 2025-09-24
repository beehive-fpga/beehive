module rs_encode_mgr_out_ctrl (
     input clk
    ,input rst

    ,input  logic                           encode_out_active_q_wr_val
    ,output logic                           active_q_encode_out_rdy

    ,output logic                   encode_out_msg_req_req_val
    ,input  logic                   msg_req_encode_out_req_rdy

    ,input  logic                   msg_req_encode_out_rsp_val
    ,output logic                   encode_out_msg_req_rsp_rdy
    
    ,output                                     encode_out_wr_buf_req_val
    ,input  logic                               wr_buf_encode_out_req_rdy
    
    ,output                                     encode_out_wr_buf_req_data_val
    ,input  logic                               wr_buf_encode_out_req_data_rdy
    
    ,output logic                               wr_buf_encode_out_req_done
    ,input  logic                               encode_out_wr_buf_done_rdy
    
    ,input  logic                           stream_encoder_out_resp_data_val
    ,output logic                           out_stream_encoder_resp_data_rdy
    
    ,output logic                                   encode_out_tx_cap_rd_req_val
    ,input  logic                                   tx_cap_encode_out_rd_req_rdy

    ,input  logic                                   tx_cap_encode_out_rd_rsp_val
    ,output logic                                   encode_out_tx_cap_rd_rsp_rdy
    
    ,input  logic                                   in_out_meta_val
    ,output logic                                   out_in_meta_rdy

    ,output logic                                   ctrl_datap_store_meta
    ,output logic                                   ctrl_datap_store_offset
    ,output logic                                   ctrl_datap_store_cap_id
    ,output cmd_type_e                              ctrl_datap_msg_req_cmd
);

    typedef enum logic[3:0] {
        READY = 4'd0,
        REQ_MEM_BUF = 4'd1,
        STORE_MEM_OFFSET = 4'd2,
        RD_CAP = 4'd5,
        STORE_CAP = 4'd6,
        MEM_WR_REQ = 4'd3,
        PASS_DATA = 4'd4,
        WAIT_WR = 4'd9,
        BUMP_TX_PTR = 4'd7,
        ENQUEUE_FLOW = 4'd8
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next
        end
    end

    always_comb begin
        out_in_meta_rdy = 1'b0;
    
        ctrl_datap_store_meta = 1'b0;
        ctrl_datap_store_offset = 1'b0;
        ctrl_datap_store_cap_id = 1'b0;
        ctrl_datap_msg_req_cmd = TCP_MSG_REQ;

        encode_out_msg_req_req_val = 1'b0;
        encode_out_msg_req_rsp_rdy = 1'b0;

        encode_out_tx_cap_rd_req_val = 1'b0;
        encode_out_tx_cap_rd_rsp_rdy = 1'b0;

        encode_out_wr_buf_req_val = 1'b0;
        encode_out_wr_buf_req_data_val = 1'b0;
        encode_out_wr_buf_done_rdy = 1'b0;

        out_stream_encoder_resp_data_rdy = 1'b0;

        encode_out_active_q_wr_req = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_store_meta = 1'b1;
                out_in_meta_rdy = 1'b1;
                if (in_out_meta_val) begin
                    state_next = REQ_MEM_BUF;
                end
            end
            REQ_MEM_BUF: begin
                ctrl_datap_msg_req_cmd = TCP_MSG_REQ;
                encode_out_msg_req_req_val = 1'b1;
                if (msg_req_encode_out_req_rdy) begin
                    state_next = STORE_MEM_OFFSET;
                end
            end
            STORE_MEM_OFFSET: begin
                encode_out_msg_req_rsp_rdy = 1'b1;
                ctrl_datap_store_offset = 1'b1;
                if (msg_req_encode_out_rsp_val) begin
                    state_next = RD_CAP;
                end
            end
            RD_CAP: begin
                encode_out_tx_cap_rd_req_val = 1'b1;
                if (tx_cap_encode_out_rd_req_rdy) begin
                    state_next = STORE_CAP;
                end
            end
            STORE_CAP: begin
                ctrl_datap_store_cap_id = 1'b1;
                encode_out_tx_cap_rd_rsp_rdy = 1'b1;
                if (tx_cap_encode_out_rd_rsp_val) begin
                    state_next = MEM_WR_REQ;
                end
            end
            MEM_WR_REQ: begin
                encode_out_wr_buf_req_val = 1'b1;
                if (wr_buf_encode_out_req_data_rdy) begin
                    state_next = PASS_DATA;
                end
            end
            PASS_DATA: begin
                encode_out_wr_buf_req_data_val = stream_encoder_out_resp_data_val;
                out_stream_encoder_resp_data_rdy = wr_buf_encode_out_req_data_rdy;

                if (encode_out_wr_buf_req_data_val & out_stream_encoder_resp_data_rdy) begin
                    if (stream_encoder_out_resp_last) begin
                        state_next = WAIT_WR;
                    end
                end
            end
            WAIT_WR: begin
                encode_out_wr_buf_done_rdy = 1'b1;
                if(wr_buf_encode_out_req_done) begin
                    state_next = BUMP_TX_PTR;
                end
            end
            BUMP_TX_PTR: begin
                ctrl_datap_msg_req_cmd = TCP_PTR_UPDATE;
                encode_out_msg_req_req_val = 1'b1;
                if (msg_req_encode_in_req_rdy) begin
                    state_next = ENQUEUE_FLOW;
                end
            end
            ENQUEUE_FLOW: begin
                encode_out_active_q_wr_val = 1'b1;
                if (active_q_encode_out_rdy) begin
                    state_next = READY;
                end
            end
        endcase
    end
endmodule