`include "noc_defs.vh"
module flit_hdr_join (
     input clk
    ,input rst

    ,input                                  src_join_hdr_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   src_join_hdr_data
    ,input                                  src_join_hdr_last
    ,output logic                           join_src_hdr_rdy

    ,input  logic                           src_join_body_val
    ,input  logic                           src_join_body_last
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   src_join_body_data
    ,output logic                           join_src_body_rdy

    ,output logic                           join_dst_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   join_dst_data
    ,input  logic                           dst_join_rdy
);

    typedef enum logic[1:0] {
        HDR_PASS = 2'd0,
        BODY_PASS = 2'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR_PASS;
        end
        else begin
            state_reg <= state_next;
        end
    end

    assign join_dst_data = state_reg == HDR_PASS
                        ? src_join_hdr_data
                        : src_join_body_data;

    always_comb begin
        join_dst_val = 1'b0;
        join_src_hdr_rdy = 1'b0;
        join_src_body_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg)
            HDR_PASS: begin
                join_dst_val = src_join_hdr_val;
                join_src_hdr_rdy = dst_join_rdy;
                if (src_join_hdr_val & dst_join_rdy & src_join_hdr_last) begin
                    state_next = BODY_PASS;
                end
            end
            BODY_PASS: begin
                join_dst_val = src_join_body_val;
                join_src_body_rdy = dst_join_rdy;
                if (src_join_body_val & dst_join_rdy & src_join_body_last) begin
                    state_next = HDR_PASS;
                end
            end
            default: begin
                join_dst_val = 1'b0;
                join_src_hdr_rdy = 1'b0;
                join_src_body_rdy = 1'b0;

                state_next = state_reg;
            end
        endcase
    end
    
endmodule
