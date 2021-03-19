`include "tcp_logger_record_defs.svh"
module tcp_logger_record_ctrl (
     input clk
    ,input rst
    
    ,input  logic                           noc0_logger_record_val
    ,output logic                           logger_record_noc0_rdy

    ,output logic                           logger_record_noc0_val
    ,input  logic                           noc0_logger_record_rdy

    ,output logic                           wr_logger_mem_val
    ,input  logic                           wr_logger_mem_rdy 

    ,output logic                           ctrl_datap_store_len
    ,output logic                           ctrl_datap_incr_addr
    ,output logic                           ctrl_datap_incr_num_flits
    ,output logic                           ctrl_datap_store_hdr
    ,output logic                           ctrl_datap_mod_hdr_flit

    ,input  logic                           datap_ctrl_last_flit
    ,input  logic                           datap_ctrl_log_full
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        PASS_META = 2'd1,
        GRAB_HDR = 2'd2,
        PASS_DATA = 2'd3,
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
        logger_record_noc0_rdy = 1'b0;
        logger_record_noc0_val = 1'b0;

        ctrl_datap_store_len = 1'b0;
        ctrl_datap_incr_addr = 1'b0;
        ctrl_datap_incr_num_flits = 1'b0;
        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_mod_hdr_flit = 1'b0;

        wr_logger_mem_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                logger_record_noc0_val = noc0_logger_record_val;
                logger_record_noc0_rdy = noc0_logger_record_rdy;
                ctrl_datap_mod_hdr_flit = noc0_logger_record_val;
                ctrl_datap_store_hdr = 1'b1;
                
                if (noc0_logger_record_val & noc0_logger_record_rdy) begin
                    state_next = PASS_META;
                end
                else begin
                    state_next = READY;
                end
            end
            PASS_META: begin
                logger_record_noc0_val = noc0_logger_record_val;
                logger_record_noc0_rdy = noc0_logger_record_rdy;
                ctrl_datap_store_len = 1'b1;

                if (noc0_logger_record_val & noc0_logger_record_rdy) begin
                    ctrl_datap_incr_num_flits = 1'b1;
                    state_next = GRAB_HDR;
                end
                else begin
                    state_next = PASS_META;
                end
            end
            GRAB_HDR: begin
                logger_record_noc0_val = noc0_logger_record_val & wr_logger_mem_rdy;
                logger_record_noc0_rdy = noc0_logger_record_rdy & wr_logger_mem_rdy;
                wr_logger_mem_val = noc0_logger_record_val & ~datap_ctrl_log_full;

                if (noc0_logger_record_val & noc0_logger_record_rdy & wr_logger_mem_rdy) begin
                    ctrl_datap_incr_addr = ~datap_ctrl_log_full;
                    ctrl_datap_incr_num_flits = 1'b1;
                    if (datap_ctrl_last_flit) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = PASS_DATA;
                    end
                end
                else begin
                    state_next = GRAB_HDR;
                end
            end
            PASS_DATA: begin
                logger_record_noc0_val = noc0_logger_record_val;
                logger_record_noc0_rdy = noc0_logger_record_rdy;

                if (noc0_logger_record_val & noc0_logger_record_rdy) begin
                    ctrl_datap_incr_num_flits = 1'b1;
                    if (datap_ctrl_last_flit) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = PASS_DATA;
                    end
                end
                else begin
                    state_next = PASS_DATA;
                end
            end
            default: begin
                logger_record_noc0_rdy = 'X;
                logger_record_noc0_val = 'X;

                ctrl_datap_store_len = 'X;
                ctrl_datap_incr_addr = 'X;
                ctrl_datap_incr_num_flits = 'X;
                ctrl_datap_store_hdr = 'X;

                wr_logger_mem_val = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
