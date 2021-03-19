module noc_wide_to_narrow #(
     parameter WIDE_NOC_W = 512
    ,parameter NARROW_NOC_W = 64
    ,parameter WIDE_NOC_MSG_LEN_W = -1
    ,parameter WIDE_NOC_MSG_LEN_HI = 477
    ,parameter WIDE_NOC_MSG_LEN_LO = WIDE_NOC_MSG_LEN_HI - WIDE_NOC_MSG_LEN_HI - 1
)(
     input clk
    ,input rst

    ,input                      src_noc_wtn_val
    ,input  [WIDE_NOC_W-1:0]    src_noc_wtn_data
    ,output                     noc_wtn_src_rdy

    ,output                     noc_wtn_dst_val
    ,output [NARROW_NOC_W-1:0]  noc_wtn_dst_data
    ,input                      dst_noc_wtn_rdy
);

    localparam NUM_ELS = WIDE_NOC_W/NARROW_NOC_W;

    typedef enum logic[1:0] {
        READY = 2'd0,
        PASS_DATA = 2'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   converter_val;
    logic   converter_last;
    logic   converter_rdy;
    logic   converter_data;

    logic   store_count;
    logic   decr_count;
    logic   [WIDE_NOC_MSG_LEN_W-1:0]    count_reg;
    logic   [WIDE_NOC_MSG_LEN_W-1:0]    count_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            count_reg <= count_next;
        end
    end

    assign count_next = store_count
                        ? src_noc_wtn_data[WIDE_NOC_MSG_LEN_HI:WIDE_NOC_MSG_LEN_LO]
                        : decr_count
                            ? count_reg - 1'b1
                            : count_reg;

    always_comb begin
        converter_val = 1'b0;
        converter_last = 1'b0;

        store_count = 1'b0;
        decr_count = 1'b0;

        state_next = state_reg;
        case (state_reg) begin
            READY: begin
                store_count = 1'b1;
                converter_val = src_noc_wtn_val;
                noc_wtn_src_rdy = converter_rdy;
                if (src_noc_wtn_val & converter_rdy) begin
                    if (count_next == 0) begin
                        converter_last = 1'b1;
                    end
                    else begin
                        state_next = PASS_DATA;
                    end
                end
            end
            PASS_DATA: begin
                converter_val = src_noc_wtn_val;
                noc_wtn_src_rdy = converter_rdy;
                if (src_noc_wtn_val & converter_rdy) begin
                    decr_count = 1'b1;
                    if (count_reg == 1) begin
                        converter_last = 1'b1;
                        state_next = READY;
                    end
                end
            end
            default: begin
            end
        end
    end

    wide_to_narrow #(
         .OUT_DATA_W    (NARROW_NOC_W   )
        ,.IN_DATA_ELS   (WIDE_NOC_W/NARROW_NOC_W    )
    ) wtn_converter (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_w_to_n_val    (converter_val      )
        ,.src_w_to_n_data   (converter_data     )
        ,.src_w_to_n_keep   ('1                 )
        ,.src_w_to_n_last   (converter_last     )
        ,.w_to_n_src_rdy    (converter_rdy      )
    
        ,.w_to_n_dst_val    (noc_wtn_dst_val    )
        ,.w_to_n_dst_data   (noc_wtn_dst_data   )
        ,.w_to_n_dst_keep   ()
        ,.w_to_n_dst_last   ()
        ,.dst_w_to_n_rdy    (dst_noc_wtn_rdy    )
    );


generate
    if (WIDE_NOC_W % NARROW_NOC_W) != 0) begin
        $error("The wide noc must be an even multiple of the narrow noc");
    end

    if (NARROW_NOC_W < 64) begin
        $error("Widths of less than 64 bits are not supported");
    end
endgenerate
endmodule
