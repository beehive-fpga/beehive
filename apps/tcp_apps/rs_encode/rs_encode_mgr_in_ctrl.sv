module rs_encode_mgr_in_ctrl (    
     input  clk
    ,input  rst
    
    ,input  logic                                   active_q_encode_in_empty
    ,output logic                                   encode_in_active_q_rd_req

    ,output logic                                   encode_in_msg_req_req_val
    ,input  logic                                   msg_req_encode_in_req_rdy

    ,input  logic                                   msg_req_encode_in_rsp_val
    ,output logic                                   encode_in_msg_req_rsp_rdy
    
    ,output                                         encode_in_rd_buf_req_val
    ,input  logic                                   rd_buf_encode_in_req_rdy

    ,input  logic                                   rd_buf_encode_in_data_val
    ,input  logic                                   rd_buf_encode_in_data_last
    ,output                                         encode_in_rd_buf_data_rdy
    
    ,output                                         encode_in_stream_encoder_req_val
    ,input  logic                                   stream_encoder_encode_in_req_rdy

    ,output                                         encode_in_stream_encoder_req_data_val
    ,input  logic                                   stream_encoder_encode_in_req_data_rdy
    
    ,output logic                                   encode_in_rx_cap_rd_req_val
    ,input  logic                                   rx_cap_encode_in_rd_req_rdy
    
    ,input  logic                                   rx_cap_encode_in_rd_rsp_val
    ,output logic                                   encode_in_rx_cap_rd_rsp_rdy
    
    ,output logic                                   in_out_meta_val
    ,input  logic                                   out_in_meta_rdy

    ,output logic                                   ctrl_datap_store_flowid
    ,output logic                                   ctrl_datap_store_offset
    ,output logic                                   ctrl_datap_store_cap_id
    ,output logic                                   ctrl_datap_store_req
    ,output cmd_type_e                              ctrl_datap_msg_req_cmd
);

    typedef enum logic[3:0] {
        READY = 4'd0,
        REQ_MSG = 4'd1,
        RECV_OFFSET = 4'd2,
        RD_CAP_INDEX = 4'd5,
        STORE_CAP_INDEX = 4'd6,
        RD_MEM = 4'd3,
        RECV_HDR_DATA = 4'd9,
        START_ENCODE = 4'd7,
        RECV_DATA = 4'd4,
        BUMP_RX_PTRS = 4'd10,
        META_WAIT = 4'd8,
    } state_e;

    typedef enum logic[1:0] {
        WAITING = 2'b0,
        META_OUT = 2'b1,
        DATA_WAIT = 2'd2
    } meta_state_e;

    state_e state_reg;
    state_e state_next;

    meta_state_e meta_state_next;
    meta_state_e meta_state_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            meta_state_reg <= WAITING;
        end
        else begin
            state_reg <= state_next;
            meta_state_reg <= meta_state_next;
        end
    end

    logic   output_metadata;

    always_comb begin
        dst_active_q_rd_req = 1'b0;

        ctrl_datap_store_flowid = 1'b0;
        ctrl_datap_store_offset = 1'b0;
        ctrl_datap_store_cap_id = 1'b0;
        ctrl_datap_store_req = 1'b0;
        ctrl_datap_msg_req_cmd = TCP_MSG_REQ;

        encode_in_msg_req_req_val = 1'b0;
        encode_in_msg_req_rsp_rdy = 1'b0;

        encode_in_rx_cap_rd_req_val = 1'b0;
        encode_in_rx_cap_rd_rsp_rdy = 1'b0;

        encode_in_rd_buf_req_val = 1'b0;

        encode_in_stream_encoder_req_val = 1'b0;
        encode_in_stream_encoder_req_data_val = 1'b0;
        encode_in_rd_buf_data_rdy = 1'b0;


        output_metadata = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_store_flowid = 1'b1;
                if (~active_q_dst_empty) begin
                    output_metadata = 1'b1;
                    dst_active_q_rd_req = 1'b1;
                end
            end
            REQ_MSG: begin
                encode_in_msg_req_req_val = 1'b1;
                ctrl_datap_msg_req_cmd = TCP_MSG_REQ;
                if (msg_req_encode_in_req_rdy) begin
                    state_next = RECV_OFFSET;
                end
            end
            RECV_OFFSET: begin
                ctrl_datap_store_offset = 1'b1;
                encode_in_msg_req_rsp_rdy = 1'b1;
                if (msg_req_encode_in_rsp_val) begin
                    state_next = RD_CAP_INDEX;
                end
            end
            RD_CAP_INDEX: begin
                encode_in_rx_cap_rd_req_val = 1'b1;
                if (rx_cap_encode_in_rd_req_rdy) begin
                    state_next = STORE_CAP_INDEX;
                end
            end
            STORE_CAP_INDEX: begin
                encode_in_rx_cap_rd_rsp_rdy = 1'b1;
                ctrl_datap_store_cap_id = 1'b1;
                if (rx_cap_encode_in_rd_rsp_val) begin
                    state_next = START_ENCODE;
                end
            end
            RD_MEM: begin
                encode_in_rd_buf_req_val = 1'b1;
                if (rd_buf_encode_in_req_rdy) begin
                    state_next = RECV_DATA;
                end
            end
            RECV_HDR_DATA: begin
                encode_in_rd_buf_data_rdy = 1'b1;
                ctrl_datap_store_req = 1'b1;
                if (rd_buf_encode_in_data_val) begin
                    state_next = START_ENCODE;
                end
            end
            START_ENCODE: begin
                encode_in_stream_encoder_req_val = 1'b1;
                if (stream_encoder_encode_in_req_rdy) begin
                    state_next = RD_MEM;
                end
            end
            RECV_DATA: begin
                encode_in_stream_encoder_req_data_val = rd_buf_encode_in_data_val;
                encode_in_rd_buf_data_rdy = stream_encoder_encode_in_req_data_rdy;
                if (encode_in_stream_encoder_req_data_val & encode_in_rd_buf_data_rdy) begin
                    if (rd_buf_encode_in_data_last) begin
                        state_next = META_WAIT;
                    end
                end
            end
            BUMP_RX_PTRS: begin
                ctrl_datap_msg_req_cmd = TCP_PTR_UPDATE;
                encode_in_msg_req_req_val = 1'b1;
                if (msg_req_encode_in_req_rdy) begin
                    state_next = META_WAIT;
                end
            end
            META_WAIT: begin
                if (meta_state_reg == DATA_WAIT) begin
                    state_next = READY;
                end
            end
        endcase
    end

    always_comb begin
        in_out_meta_val = 1'b0;
        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (output_metadata) begin
                    meta_state_next = META_OUT;
                end
            end
            META_OUT: begin
                in_out_meta_val = 1'b1;
                if (out_in_meta_rdy) begin
                    meta_state_next = DATA_WAIT;
                end
            end
            DATA_WAIT: begin
                if (state_reg == META_WAIT) begin
                    meta_state_next = WAITING;
                end
            end
        endcase
    end
endmodule