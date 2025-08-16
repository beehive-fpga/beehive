`include "simple_log_udp_noc_read_defs.svh"
module simple_log_udp_noc_read_ctrl (
     input clk
    ,input rst
    
    ,input                                      ctovr_reader_in_val
    ,output logic                               reader_in_ctovr_rdy
    
    ,output logic                               reader_out_vrtoc_val
    ,input                                      vrtoc_reader_out_rdy
    
    ,output logic                               ctrl_datap_store_meta
    ,output logic                               ctrl_datap_store_req
    ,output logic                               ctrl_datap_store_log_resp
    ,output         simple_log_resp_sel_e       ctrl_datap_output_flit_sel

    ,input  logic                               datap_ctrl_rd_meta

    ,output logic                               log_rd_req_val
    
    ,input  logic                               log_rd_resp_val
);

    typedef enum logic[2:0] {
        READY = 3'b0,
        META_FLIT = 3'b1,
        REQ = 3'd2,
        RD_LOG = 3'd3,
        SAVE_LOG_RD = 3'd4,
        HDR_RESP = 3'd5,
        META_RESP = 3'd6,
        DATA_RESP = 3'd7,
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
        reader_in_ctovr_rdy = 1'b0;
        reader_out_vrtoc_val = 1'b0;

        ctrl_datap_store_meta = 1'b0;
        ctrl_datap_store_req = 1'b0;
        ctrl_datap_store_log_resp = 1'b0;
        ctrl_datap_output_flit_sel = simple_log_udp_noc_read_pkg::HDR;

        log_rd_req_val = 1'b0;

        state_next = state_reg;

        case (state_reg)
            READY: begin
                reader_in_ctovr_rdy = 1'b1;
                if (ctovr_reader_in_val) begin
                    state_next = META_FLIT;
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT: begin
                reader_in_ctovr_rdy = 1'b1;
                ctrl_datap_store_meta = 1'b1;
                if (ctovr_reader_in_val) begin
                    state_next = REQ;
                end
                else begin
                    state_next = META_FLIT;
                end
            end
            REQ: begin
                reader_in_ctovr_rdy = 1'b1;
                ctrl_datap_store_req = 1'b1;
                if (ctovr_reader_in_val) begin
                    state_next = RD_LOG;
                end
                else begin
                    state_next = REQ;
                end 
            end
            RD_LOG: begin
                log_rd_req_val = ~datap_ctrl_rd_meta;
                state_next = SAVE_LOG_RD;
            end
            SAVE_LOG_RD: begin
                ctrl_datap_store_log_resp = 1'b1;
                if (~datap_ctrl_rd_meta) begin
                    if (log_rd_resp_val) begin
                        state_next = HDR_RESP;
                    end
                    else begin
                        state_next = SAVE_LOG_RD;
                    end
                end
                else begin
                    state_next = HDR_RESP;
                end
            end
            HDR_RESP: begin
                reader_out_vrtoc_val = 1'b1;
                ctrl_datap_output_flit_sel = simple_log_udp_noc_read_pkg::HDR;
                if (vrtoc_reader_out_rdy) begin
                    state_next = META_RESP;
                end
                else begin
                    state_next = HDR_RESP;
                end
            end
            META_RESP: begin
                reader_out_vrtoc_val = 1'b1;
                ctrl_datap_output_flit_sel = simple_log_udp_noc_read_pkg::META;
                if (vrtoc_reader_out_rdy) begin
                    state_next = DATA_RESP;
                end
                else begin
                    state_next = META_RESP;
                end
            end
            DATA_RESP: begin
                reader_out_vrtoc_val = 1'b1;
                ctrl_datap_output_flit_sel = simple_log_udp_noc_read_pkg::DATA;
                if (vrtoc_reader_out_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = DATA_RESP;
                end
            end
            default: begin
                reader_in_ctovr_rdy = 'X;
                reader_out_vrtoc_val = 'X;

                ctrl_datap_store_meta = 'X;
                ctrl_datap_store_req = 'X;
                ctrl_datap_store_log_resp = 'X;
                
                log_rd_req_val = 'X;

                ctrl_datap_output_flit_sel = simple_log_udp_noc_read_pkg::HDR;

                state_next = UND;
            end
        endcase
    end

endmodule
