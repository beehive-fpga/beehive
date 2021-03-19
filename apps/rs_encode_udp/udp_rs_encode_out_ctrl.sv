`include "udp_rs_encode_defs.svh"
module udp_rs_encode_out_ctrl (
     input clk
    ,input rst
    
    ,input  logic                           in_out_meta_val
    ,output logic                           out_in_meta_rdy
    
    ,output logic                           udp_app_out_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_udp_app_out_rdy
    
    ,input  logic                           stream_encoder_noc_out_resp_data_val
    ,output logic                           noc_out_stream_encoder_resp_data_rdy

    ,output logic                           out_ctrl_out_datap_store_meta
    ,output udp_rs_tx_flit_e                out_ctrl_out_datap_out_sel
    ,output logic                           out_ctrl_out_datap_incr_data_flit

    ,input  logic                           out_datap_out_ctrl_last_data_flit
    ,input  logic   [`UDP_LENGTH_W-1:0]     out_datap_out_ctrl_data_len
    
    ,output logic                           rs_enc_incr_bytes_sent
    ,output logic   [`NOC_DATA_BYTES_W:0]   rs_enc_num_bytes_sent
    ,output logic                           rs_enc_incr_reqs_done
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        HDR_FLIT = 3'd1,
        META_FLIT = 3'd2,
        DATA_FLITS = 3'd3,
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
        rs_enc_num_bytes_sent = `NOC_DATA_BYTES;
        if (out_datap_out_ctrl_last_data_flit) begin
            if (out_datap_out_ctrl_data_len[`NOC_DATA_BYTES_W-1:0] == '0) begin
                rs_enc_num_bytes_sent = `NOC_DATA_BYTES;
            end
            else begin
                rs_enc_num_bytes_sent = 
                    {1'b0, out_datap_out_ctrl_data_len[`NOC_DATA_BYTES_W-1:0]};
            end
        end
        else begin
            rs_enc_num_bytes_sent = `NOC_DATA_BYTES;
        end
    end


    always_comb begin
        out_in_meta_rdy = 1'b0;

        udp_app_out_noc0_vrtoc_val = 1'b0;

        noc_out_stream_encoder_resp_data_rdy = 1'b0;

        out_ctrl_out_datap_store_meta = 1'b0;
        out_ctrl_out_datap_out_sel = udp_rs_encode_pkg::HDR;
        out_ctrl_out_datap_incr_data_flit = 1'b0;

        rs_enc_incr_bytes_sent = 1'b0;
        rs_enc_incr_reqs_done = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                out_in_meta_rdy = 1'b1;
                out_ctrl_out_datap_store_meta = 1'b1;
                if (in_out_meta_val) begin
                    state_next = HDR_FLIT;
                end
            end
            HDR_FLIT: begin
                out_ctrl_out_datap_out_sel = udp_rs_encode_pkg::HDR;
                // wait until the data is actually available before trying to send
                udp_app_out_noc0_vrtoc_val = stream_encoder_noc_out_resp_data_val;

                if (stream_encoder_noc_out_resp_data_val & noc0_vrtoc_udp_app_out_rdy) begin
                    state_next = META_FLIT;
                end
            end
            META_FLIT: begin
                out_ctrl_out_datap_out_sel = udp_rs_encode_pkg::META;
                udp_app_out_noc0_vrtoc_val = 1'b1;
                if (noc0_vrtoc_udp_app_out_rdy & udp_app_out_noc0_vrtoc_val) begin
                    state_next = DATA_FLITS;
                end
            end
            DATA_FLITS: begin
                udp_app_out_noc0_vrtoc_val = stream_encoder_noc_out_resp_data_val;
                noc_out_stream_encoder_resp_data_rdy = noc0_vrtoc_udp_app_out_rdy;

                out_ctrl_out_datap_out_sel = udp_rs_encode_pkg::DATA;

                if (stream_encoder_noc_out_resp_data_val & noc0_vrtoc_udp_app_out_rdy) begin
                    out_ctrl_out_datap_incr_data_flit = 1'b1;
                    rs_enc_incr_bytes_sent = 1'b1;
                    if (out_datap_out_ctrl_last_data_flit) begin
                        rs_enc_incr_reqs_done = 1'b1;
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_FLITS;
                    end
                end
            end
            default: begin
                out_in_meta_rdy = 'X;

                udp_app_out_noc0_vrtoc_val = 'X;

                noc_out_stream_encoder_resp_data_rdy = 'X;

                out_ctrl_out_datap_store_meta = 'X;
                out_ctrl_out_datap_incr_data_flit = 'X;
                
                out_ctrl_out_datap_out_sel = udp_rs_encode_pkg::HDR;

                rs_enc_incr_bytes_sent = 'X;
                rs_enc_incr_reqs_done = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
