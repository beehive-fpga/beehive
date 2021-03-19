module filter_ctrl (
     input clk
    ,input rst

    ,input  logic   src_filter_hdr_val
    ,output logic   filter_src_hdr_rdy

    ,input  logic   src_filter_data_val
    ,input  logic   src_filter_data_last
    ,output logic   filter_src_data_rdy

    ,output logic   filter_dst_hdr_val
    ,input  logic   dst_filter_hdr_rdy

    ,output logic   filter_dst_data_val
    ,input  logic   dst_filter_data_rdy

    ,input  logic   table_hit
    ,output logic   table_read
    ,output logic   store_table_res
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        PASS_HDR = 2'd1,
        PASS_DATA = 2'd2,
        DROP_DATA = 2'd3,
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
        filter_dst_hdr_val = 1'b0;
        filter_src_hdr_rdy = 1'b0;

        filter_dst_data_val = 1'b0;
        filter_src_data_rdy = 1'b0;

        table_read = 1'b0;
        store_table_res = 1'b1;

        state_next = state_reg;
        case (state_reg) 
            READY: begin
                table_read = 1'b1;
                store_table_res = 1'b1;
                if (src_filter_hdr_val) begin
                    // did we hit in the CAM
                    if (table_hit) begin
                        filter_dst_hdr_val = 1'b1;
                        filter_src_hdr_rdy = dst_filter_hdr_rdy;
                        // if the receiver is ready for the header
                        if (dst_filter_hdr_rdy) begin
                            state_next = PASS_DATA;
                        end
                        // otherwise, we need to wait for the receiver
                        // to be ready for the header
                        else begin
                            state_next = PASS_HDR;
                        end
                    end
                    // drop the header and data if we didn't hit in the table
                    else begin
                        filter_src_hdr_rdy = 1'b1;
                        state_next = DROP_DATA;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            PASS_HDR: begin
                filter_dst_hdr_val = 1'b1;
                filter_src_hdr_rdy = dst_filter_hdr_rdy;
                if (dst_filter_hdr_rdy) begin
                    state_next = PASS_DATA;
                end
                else begin
                    state_next = PASS_HDR;
                end
            end
            PASS_DATA: begin
                filter_dst_data_val = src_filter_data_val;
                filter_src_data_rdy = dst_filter_data_rdy;

                if (src_filter_data_val & dst_filter_data_rdy) begin
                    if (src_filter_data_last) begin
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
            DROP_DATA: begin
                filter_src_data_rdy = 1'b1;
                if (src_filter_data_val & src_filter_data_last) begin
                    state_next = READY;
                end
                else begin
                    state_next = DROP_DATA;
                end
            end
            default: begin
                filter_dst_hdr_val = 'X;
                filter_src_hdr_rdy = 'X;

                filter_dst_data_val = 'X;
                filter_src_data_rdy = 'X;

                state_next = UND;
            end
        endcase
    end
    
endmodule
