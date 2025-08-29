module valid_bitvector #(
     parameter BITVECTOR_SIZE = 64
    ,parameter BITVECTOR_INDEX_W = $clog2(BITVECTOR_SIZE)
)(
     input clk
    ,input rst

    ,input                          set_val
    ,input  [BITVECTOR_INDEX_W-1:0] set_index

    ,input                          clear_val
    ,input  [BITVECTOR_INDEX_W-1:0] clear_index

    ,output [BITVECTOR_SIZE-1:0]    valid_bitvector
);

    logic   [BITVECTOR_SIZE-1:0]    valid_bits_reg;
    logic   [BITVECTOR_SIZE-1:0]    valid_bits_next;

    logic   [BITVECTOR_SIZE-1:0]    set_bitmask;
    logic   [BITVECTOR_SIZE-1:0]    clear_bitmask;

    assign valid_bitvector = valid_bits_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_bits_reg <= '0;
        end
        else begin
            valid_bits_reg <= valid_bits_next;
        end
    end

    assign set_bitmask = set_val
                        ? {{(BITVECTOR_SIZE-1){1'b0}}, set_val} << set_index
                        : '0;

    assign clear_bitmask = clear_val
                        ? ~({{(BITVECTOR_SIZE-1){1'b0}}, clear_val} << clear_index)
                        : '1;

    assign valid_bits_next = (valid_bits_reg | set_bitmask) & clear_bitmask;
endmodule
