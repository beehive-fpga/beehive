module udp_rs_encode_in_ctrl (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_app_in_val
    ,output logic                           udp_app_in_noc0_ctovr_rdy
    
    ,output logic                           noc_in_stream_encoder_req_val
    ,input  logic                           stream_encoder_noc_in_req_rdy

    ,output logic                           noc_in_stream_encoder_req_data_val
    ,input  logic                           stream_encoder_noc_in_req_data_rdy

    ,output logic                           in_out_meta_val
    ,input  logic                           out_in_meta_rdy

    ,output logic                           in_ctrl_in_datap_store_hdr
    ,output logic                           in_ctrl_in_datap_store_meta
    ,output logic                           in_ctrl_in_datap_store_req
    ,output logic                           in_ctrl_in_datap_incr_flits

    ,input  logic                           in_datap_in_ctrl_last_flit
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        META_FLIT = 3'd1,
        REQ_HDR = 3'd2,
        PASS_REQ = 3'd3,
        PASS_DATA = 3'd4,
        META_WAIT = 3'd5,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        META_OUT = 2'd1,
        DATA_WAIT = 2'd2,
        UNDEF = 'X
    } meta_state_e;

    state_e state_reg;
    state_e state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    logic   output_metadata;

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

    always_comb begin
        udp_app_in_noc0_ctovr_rdy = 1'b0;

        in_ctrl_in_datap_store_hdr = 1'b0;
        in_ctrl_in_datap_store_meta = 1'b0;
        in_ctrl_in_datap_store_req = 1'b0;
        in_ctrl_in_datap_incr_flits = 1'b0;

        noc_in_stream_encoder_req_val = 1'b0;
        noc_in_stream_encoder_req_data_val = 1'b0;

        output_metadata = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                udp_app_in_noc0_ctovr_rdy = 1'b1;
                in_ctrl_in_datap_store_hdr = 1'b1;
                if (noc0_ctovr_udp_app_in_val) begin
                    state_next = META_FLIT;
                end
            end
            META_FLIT: begin
                udp_app_in_noc0_ctovr_rdy = 1'b1;
                in_ctrl_in_datap_store_meta = 1'b1;
                if (noc0_ctovr_udp_app_in_val) begin
                    in_ctrl_in_datap_incr_flits = 1'b1;
                    state_next = REQ_HDR;
                end
            end
            REQ_HDR: begin
                udp_app_in_noc0_ctovr_rdy = 1'b1;
                in_ctrl_in_datap_store_req = 1'b1;
                if (noc0_ctovr_udp_app_in_val) begin
                    output_metadata = 1'b1;
                    in_ctrl_in_datap_incr_flits = 1'b1;
                    noc_in_stream_encoder_req_val = 1'b1;
                    if (stream_encoder_noc_in_req_rdy) begin
                        state_next = PASS_DATA;
                    end
                    else begin
                        state_next = PASS_REQ;
                    end
                end
            end
            PASS_REQ: begin
                noc_in_stream_encoder_req_val = 1'b1;
                if (stream_encoder_noc_in_req_rdy) begin
                    state_next = PASS_DATA;
                end
            end
            PASS_DATA: begin
                noc_in_stream_encoder_req_data_val = noc0_ctovr_udp_app_in_val;
                udp_app_in_noc0_ctovr_rdy = stream_encoder_noc_in_req_data_rdy;

                if (noc0_ctovr_udp_app_in_val & stream_encoder_noc_in_req_data_rdy) begin
                    in_ctrl_in_datap_incr_flits = 1'b1;
                    if (in_datap_in_ctrl_last_flit) begin
                        state_next = META_WAIT;
                    end
                    else begin
                        state_next = PASS_DATA;
                    end
                end
            end
            META_WAIT: begin
                if (meta_state_reg == DATA_WAIT) begin
                    state_next = READY;
                end
            end
            default: begin
                udp_app_in_noc0_ctovr_rdy = 'X;

                in_ctrl_in_datap_store_hdr = 'X;
                in_ctrl_in_datap_store_meta = 'X;
                in_ctrl_in_datap_store_req = 'X;
                in_ctrl_in_datap_incr_flits = 'X;

                noc_in_stream_encoder_req_val = 'X;
                noc_in_stream_encoder_req_data_val = 'X;

                output_metadata = 'X;

                state_next = UND;
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
            default: begin
                in_out_meta_val = 'X;

                meta_state_next =  UNDEF;
            end
        endcase
    end
endmodule
