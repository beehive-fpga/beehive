module narrow_to_wide #(
     parameter IN_DATA_W = -1
    ,parameter IN_KEEP_W = IN_DATA_W/8
    ,parameter OUT_DATA_ELS = -1
)(
     input clk
    ,input rst

    ,input                                              src_n_to_w_val
    ,input          [IN_DATA_W-1:0]                     src_n_to_w_data
    ,input          [IN_KEEP_W-1:0]                     src_n_to_w_keep
    ,input                                              src_n_to_w_last
    ,output logic                                       n_to_w_src_rdy 

    ,output logic                                       n_to_w_dst_val
    ,output logic   [OUT_DATA_ELS-1:0][IN_DATA_W-1:0]   n_to_w_dst_data
    ,output logic   [OUT_DATA_ELS-1:0][IN_KEEP_W-1:0]   n_to_w_dst_keep
    ,output logic                                       n_to_w_dst_last
    ,input                                              dst_n_to_w_rdy
);

    localparam OUT_DATA_ELS_W = $clog2(OUT_DATA_ELS);

    logic   [OUT_DATA_ELS-1:0][IN_DATA_W-1:0]   data_reg;
    logic   [OUT_DATA_ELS-1:0][IN_KEEP_W-1:0]   keep_reg;
    logic   [OUT_DATA_ELS-1:0][IN_DATA_W-1:0]   data_next;
    logic   [OUT_DATA_ELS-1:0][IN_KEEP_W-1:0]   keep_next;

    logic   [OUT_DATA_ELS_W-1:0]                index_reg;
    logic   [OUT_DATA_ELS_W-1:0]                index_next;

    logic                                       advance_regs;
    logic                                       reset_keep;
    logic                                       reset_index;
    logic                                       advance_index;

    typedef enum logic[1:0] {
        READY = 2'd0,
        PASSTHRU = 2'd1,
        LINE_OUT = 2'd2,
        DRAIN = 2'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;
    
    assign n_to_w_dst_data = data_reg;
    assign n_to_w_dst_keep = keep_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            index_reg <= OUT_DATA_ELS-1;
            keep_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            data_reg <= data_next;
            keep_reg <= keep_next;
            index_reg <= index_next;
        end
    end

    always_comb begin
        data_next = data_reg;
        if (advance_regs) begin
            data_next[index_reg] = src_n_to_w_data;
        end
        else begin
            data_next[index_reg] = data_reg[index_reg];
        end
    end

    always_comb begin
        keep_next = keep_reg;
        if (reset_keep) begin
            keep_next = '0;
        end
        // we specifically don't have an else if here, because
        // we may be resetting keep at the same time as storing a
        // new mask value
        if (advance_regs) begin
            keep_next[index_reg] = src_n_to_w_keep;
        end
        else begin
            keep_next = keep_reg;
        end
    end
   
    always_comb begin
        index_next = index_reg;
        if (reset_index) begin
            index_next = OUT_DATA_ELS-1;
        end
        else if (advance_index) begin
            if (index_reg == '0) begin
                index_next = OUT_DATA_ELS-1;
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
        n_to_w_src_rdy = 1'b0;

        n_to_w_dst_val = 1'b0;
        n_to_w_dst_last = 1'b0;

        advance_regs = 1'b0;
        reset_keep = 1'b0;
        reset_index = 1'b0;
        advance_index = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                n_to_w_src_rdy = 1'b1;

                if (src_n_to_w_val) begin
                    advance_regs = 1'b1;
                    advance_index = 1'b1;
                    if (src_n_to_w_last) begin
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
                n_to_w_src_rdy = 1'b1;
                // if there's input available
                if (src_n_to_w_val) begin
                    advance_regs = 1'b1;
                    advance_index = 1'b1;
                    // if it's the last line
                    if (src_n_to_w_last) begin
                        state_next = DRAIN;
                    end
                    else begin
                        // if we've filled up the line
                        if (index_reg == '0) begin
                            state_next = LINE_OUT;
                        end
                        else begin
                            state_next = PASSTHRU;
                        end
                    end
                end
                else begin
                    state_next = PASSTHRU;
                end
            end
            LINE_OUT: begin
                n_to_w_dst_val = 1'b1;

                // can we output the line
                if (dst_n_to_w_rdy) begin
                    n_to_w_src_rdy = 1'b1;

                    // if there's new input available
                    if (src_n_to_w_val) begin
                        advance_regs = 1'b1;
                        advance_index = 1'b1;
                        reset_keep = 1'b1;
                        // is it the last line?
                        if (src_n_to_w_last) begin
                            state_next = DRAIN;
                        end
                        else begin
                            state_next = PASSTHRU;
                        end
                    end
                    else begin
                        state_next = PASSTHRU;
                    end
                end
                else begin
                    state_next = LINE_OUT;
                end
            end
            DRAIN: begin
                n_to_w_dst_val = 1'b1;
                n_to_w_dst_last = 1'b1;

                if (dst_n_to_w_rdy) begin
                    reset_index = 1'b1;
                    reset_keep = 1'b1;
                    state_next = READY;
                end
                else begin
                    state_next = DRAIN;
                end
            end
            default: begin
                n_to_w_src_rdy = 'X;

                n_to_w_dst_val = 'X;
                n_to_w_dst_last = 'X;

                advance_regs = 'X;
                reset_keep = 'X;
                reset_index = 'X;
                advance_index = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
