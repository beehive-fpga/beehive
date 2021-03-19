/* 
 * Transition from a wider input to a narrow output
 * Input ready is demanding, output is helpful 
 */
module wide_to_narrow #(
     parameter OUT_DATA_W = -1
    ,parameter OUT_KEEP_W = OUT_DATA_W/8
    ,parameter IN_DATA_ELS = -1
)(
     input  clk
    ,input  rst

    ,input                                              src_w_to_n_val
    ,input          [IN_DATA_ELS-1:0][OUT_DATA_W-1:0]   src_w_to_n_data
    ,input          [IN_DATA_ELS-1:0][OUT_KEEP_W-1:0]   src_w_to_n_keep
    ,input                                              src_w_to_n_last
    ,output logic                                       w_to_n_src_rdy

    ,output logic                                       w_to_n_dst_val
    ,output logic   [OUT_DATA_W-1:0]                    w_to_n_dst_data
    ,output logic   [OUT_KEEP_W-1:0]                    w_to_n_dst_keep
    ,output logic                                       w_to_n_dst_last
    ,input  logic                                       dst_w_to_n_rdy
);

    localparam IN_DATA_ELS_W = $clog2(IN_DATA_ELS);

    logic   [IN_DATA_ELS-1:0][OUT_DATA_W-1:0]   data_reg;
    logic   [IN_DATA_ELS-1:0][OUT_KEEP_W-1:0]   keep_reg;
    logic   [IN_DATA_ELS-1:0][OUT_DATA_W-1:0]   data_next;
    logic   [IN_DATA_ELS-1:0][OUT_KEEP_W-1:0]   keep_next;

    logic   [IN_DATA_ELS_W-1:0]                 index_reg;
    logic   [IN_DATA_ELS_W-1:0]                 index_next;

    logic                                       advance_regs;
    logic                                       reset_index;
    logic                                       advance_index;

    logic                                       is_last;

    typedef enum logic [1:0] {
        READY = 2'd0,
        PASSTHRU = 2'd1,
        WAIT_FOR_LINE = 2'd2,
        DRAIN = 2'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            data_reg <= data_next;
            keep_reg <= keep_next;
            index_reg <= index_next;
            state_reg <= state_next;
        end
    end
    
    assign data_next = advance_regs
                    ? src_w_to_n_data
                    : data_reg;
    assign keep_next = advance_regs
                    ? src_w_to_n_keep
                    : keep_reg;

    assign w_to_n_dst_data = data_reg[index_reg];
    assign w_to_n_dst_keep = keep_reg[index_reg];

    assign is_last = index_reg == '0
                    ? 1'b1
                    : keep_reg[index_reg - 1] == '0;

    always_comb begin
        index_next = index_reg;
        if (reset_index) begin
            index_next = IN_DATA_ELS-1;
        end
        else if (advance_index) begin
            if (index_reg == '0) begin
                index_next = IN_DATA_ELS-1;
            end
            else begin
                index_next = index_reg - 1'b1;
            end
        end
        else begin
            index_next = index_reg;
        end
    end

    always_comb begin
        w_to_n_src_rdy = 1'b0;

        w_to_n_dst_val = 1'b0;
        w_to_n_dst_last = 1'b0;

        advance_regs = 1'b0;
        reset_index = 1'b0;
        advance_index = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                w_to_n_src_rdy = 1'b1;
                advance_regs = 1'b1;
                reset_index = 1'b1;

                if (src_w_to_n_val) begin
                    if (src_w_to_n_last) begin
                        state_next = DRAIN;
                    end
                    else begin
                        state_next = PASSTHRU;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            PASSTHRU: begin
                w_to_n_dst_val = 1'b1;
                // if we can pass to the output
                if (dst_w_to_n_rdy) begin
                    advance_index = 1'b1;
                    // if we're passing the last output
                    if (index_reg == '0) begin
                        // is there another line available right now?
                        w_to_n_src_rdy = 1'b1;
                        if (src_w_to_n_val) begin
                            advance_regs = 1'b1;
                            // is it the last line
                            if (src_w_to_n_last) begin
                                state_next = DRAIN;
                            end
                            else begin
                                state_next = PASSTHRU;
                            end
                        end
                        else begin
                            state_next = WAIT_FOR_LINE;
                        end
                    end
                    else begin
                        state_next = PASSTHRU;
                    end
                end
                else begin
                    state_next = PASSTHRU;
                end
            end
            WAIT_FOR_LINE: begin
                w_to_n_src_rdy = 1'b1;
                if (src_w_to_n_val) begin
                    advance_regs = 1'b1;
                    if (src_w_to_n_last) begin
                        state_next = DRAIN;
                    end
                    else begin
                        state_next = PASSTHRU;
                    end
                end
                else begin
                    state_next = WAIT_FOR_LINE;
                end
            end
            DRAIN: begin
                w_to_n_dst_val = 1'b1;

                if (dst_w_to_n_rdy) begin
                    if (is_last) begin
                        w_to_n_dst_last = 1'b1;
                        state_next = READY;
                    end
                    else begin
                        advance_index = 1'b1;
                        state_next = DRAIN;
                    end
                end
                else begin
                    state_next = DRAIN;
                end
            end
            default: begin
                w_to_n_src_rdy = 'X;

                w_to_n_dst_val = 'X;
                w_to_n_dst_last = 'X;

                advance_regs = 'X;
                reset_index = 'X;
                advance_index = 'X;

                state_next = UND;
            end
        endcase
    end



endmodule
