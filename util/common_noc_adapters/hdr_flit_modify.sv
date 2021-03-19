`include "noc_defs.vh"
module hdr_flit_modify
    import beehive_noc_msg::*;
    import hash_pkg::*;
(
     input clk
    ,input rst

    ,input                                  src_mod_data_val
    ,input  [`NOC_DATA_WIDTH-1:0]           src_mod_data_data
    ,input                                  src_mod_data_last
    ,output logic                           mod_src_data_rdy

    ,input                                  src_mod_new_dst_val
    ,input  hash_table_data                 src_mod_new_dst
    ,output logic                           mod_src_new_dst_rdy

    ,output logic                           mod_dst_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   mod_dst_data
    ,output logic                           mod_dst_last
    ,input                                  dst_mod_rdy
);

    typedef enum logic {
        HDR_FLIT = 1'd0,
        PASS = 1'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    beehive_noc_hdr_flit hdr_flit_cast;

    always_comb begin
        hdr_flit_cast = src_mod_data_data;
        hdr_flit_cast.core.dst_x_coord = src_mod_new_dst.x_coord;
        hdr_flit_cast.core.dst_y_coord = src_mod_new_dst.y_coord;
    end

    assign mod_dst_data = state_reg == HDR_FLIT
                        ? hdr_flit_cast
                        : src_mod_data_data;
    assign mod_dst_last = src_mod_data_last;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR_FLIT;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        mod_dst_val = 1'b0;
        mod_src_data_rdy = 1'b0;
        mod_src_new_dst_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg)
            HDR_FLIT: begin
                mod_dst_val = src_mod_data_val & src_mod_new_dst_val;
                if (src_mod_data_val & src_mod_new_dst_val & dst_mod_rdy) begin
                    mod_src_data_rdy = 1'b1;
                    mod_src_new_dst_rdy = 1'b1;
                    if (!src_mod_data_last) begin
                        state_next = PASS;
                    end
                end
            end
            PASS: begin
                mod_dst_val = src_mod_data_val;
                mod_src_data_rdy = dst_mod_rdy;
                if (src_mod_data_val & dst_mod_rdy & src_mod_data_last) begin
                    state_next = HDR_FLIT;
                end
            end
            default: begin
                mod_dst_val = 'X;
                mod_src_data_rdy = 'X;
                mod_src_new_dst_rdy = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
