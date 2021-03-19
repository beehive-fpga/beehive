module merger_ctrl (
     input clk
    ,input rst

    ,input  logic   src_merger_ctrl_hdr_val
    ,output logic   merger_ctrl_src_hdr_rdy

    ,input  logic   src_merger_ctrl_data_val
    ,input  logic   src_merger_ctrl_data_last
    ,output logic   merger_ctrl_src_data_rdy

    ,output logic   merger_ctrl_dst_hdr_val
    ,input  logic   dst_merger_ctrl_hdr_rdy

    ,output logic   merger_ctrl_dst_data_val
    ,input  logic   dst_merger_ctrl_data_rdy
    
    ,output logic   store_grant
    ,output logic   advance_grant
);

    typedef enum logic [1:0] {
        READY = 2'd0,
        PASS_HDR = 2'd1,
        PASS_DATA = 2'd2,
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
        store_grant = 1'b0;
        advance_grant = 1'b0;

        merger_ctrl_dst_hdr_val = 1'b0;
        merger_ctrl_dst_data_val = 1'b0;
        merger_ctrl_src_hdr_rdy = 1'b0;
        merger_ctrl_src_data_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                store_grant = 1'b1;
                merger_ctrl_src_hdr_rdy = dst_merger_ctrl_hdr_rdy;

                if (src_merger_ctrl_hdr_val) begin
                    advance_grant = 1'b1;
                    merger_ctrl_dst_hdr_val = 1'b1;
                    if (dst_merger_ctrl_hdr_rdy) begin
                        state_next = PASS_DATA;
                    end
                    else begin
                        state_next = PASS_HDR;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            PASS_HDR: begin
                merger_ctrl_dst_hdr_val = 1'b1;
                merger_ctrl_src_hdr_rdy = dst_merger_ctrl_hdr_rdy;
                if (dst_merger_ctrl_hdr_rdy) begin
                    state_next = PASS_DATA;
                end
                else begin
                    state_next = PASS_HDR;
                end
            end
            PASS_DATA: begin
                merger_ctrl_dst_data_val = src_merger_ctrl_data_val;
                merger_ctrl_src_data_rdy = dst_merger_ctrl_data_rdy;
                if (src_merger_ctrl_data_val & dst_merger_ctrl_data_rdy) begin
                    if (src_merger_ctrl_data_last) begin
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
                store_grant = 'X;
                advance_grant = 'X;

                merger_ctrl_dst_hdr_val = 'X;
                merger_ctrl_dst_data_val = 'X;
                merger_ctrl_src_hdr_rdy = 'X;
                merger_ctrl_src_data_rdy = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
