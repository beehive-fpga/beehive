`include "udp_echo_app_defs.svh"
module udp_echo_app_out_ctrl (
     input clk
    ,input rst
    
    ,output logic                           udp_app_out_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_udp_app_out_rdy

    ,input  logic                           in_data_val
    ,output logic                           out_data_rdy

    ,input  logic                           hdr_flit_val
    ,input  logic                           meta_flit_val

    ,input  logic   [`MSG_LENGTH_WIDTH-1:0] total_flits

    ,output         udp_app_out_mux_sel_e   out_data_mux_sel
);
    
    typedef enum logic[2:0] {
        READY = 3'd0,
        META_FLIT_OUT = 3'd2,
        DATA_PASSTHRU = 3'd3,
        UND = 'X
    } out_state_e;

    out_state_e state_reg;
    out_state_e state_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] curr_flit_num_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] curr_flit_num_next;
    logic                           reset_curr_flits_num;
    logic                           incr_curr_flits_num;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            curr_flit_num_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            curr_flit_num_reg <= curr_flit_num_next;
        end
    end
    
    always_comb begin
        curr_flit_num_next = curr_flit_num_reg;
        if (reset_curr_flits_num) begin
            if (incr_curr_flits_num) begin
                curr_flit_num_next = 1;
            end
            else begin
                curr_flit_num_next = '0;
            end
        end
        else if (incr_curr_flits_num) begin
            curr_flit_num_next = curr_flit_num_reg + 1'b1;
        end
        else begin
            curr_flit_num_next = curr_flit_num_reg;
        end
    end

    always_comb begin
        udp_app_out_noc0_vrtoc_val = 1'b0;
        
        out_data_mux_sel = DATA_FLITS;

        out_data_rdy = 1'b0;

        reset_curr_flits_num = 1'b0;
        incr_curr_flits_num = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                udp_app_out_noc0_vrtoc_val = hdr_flit_val;
                reset_curr_flits_num = 1'b1;
                out_data_mux_sel = HDR_FLIT;

                if (hdr_flit_val & noc0_vrtoc_udp_app_out_rdy) begin
                    incr_curr_flits_num = 1'b1;
                    state_next = META_FLIT_OUT;
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT_OUT: begin
                udp_app_out_noc0_vrtoc_val = meta_flit_val;
                out_data_mux_sel = META_FLIT;
                if (meta_flit_val & noc0_vrtoc_udp_app_out_rdy) begin
                    incr_curr_flits_num = 1'b1;
                    if (curr_flit_num_reg == total_flits) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_PASSTHRU;
                    end
                end
                else begin
                    state_next = META_FLIT_OUT;
                end
            end
            DATA_PASSTHRU: begin
                out_data_rdy = noc0_vrtoc_udp_app_out_rdy;
                udp_app_out_noc0_vrtoc_val = in_data_val;
                out_data_mux_sel = DATA_FLITS;

                if (noc0_vrtoc_udp_app_out_rdy & in_data_val) begin
                    incr_curr_flits_num = 1'b1;

                    if (curr_flit_num_reg == total_flits) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_PASSTHRU;
                    end
                end
                else begin
                    state_next = DATA_PASSTHRU;
                end
            end
            default: begin
                udp_app_out_noc0_vrtoc_val = 'X;

                out_data_rdy = 'X;

                reset_curr_flits_num = 'X;
                incr_curr_flits_num = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
