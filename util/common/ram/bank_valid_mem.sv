`include "bsg_defines.v"
module bank_valid_mem #(
     parameter els_p=-1
    ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
)
(
     input clk_i
    ,input reset_i

    ,input                      w0_val_i
    ,input  [addr_width_lp-1:0] w0_addr_i
    ,input                      w0_bank_i
    
    ,input                      w1_val_i
    ,input  [addr_width_lp-1:0] w1_addr_i
    ,input                      w1_bank_i
    
    ,input                      r_val_i
    ,input  [addr_width_lp-1:0] r_addr_i
    ,output                     r_bank_o
);
logic   [els_p-1:0] valid_bits_reg;
logic   [els_p-1:0] valid_bits_next;

// These zero out the bits we are going to write to
logic   [els_p-1:0] w0_and_0_mask;
logic   [els_p-1:0] w1_and_0_mask;

// These have the value of the bank address
logic   [els_p-1:0] w0_or_mask;
logic   [els_p-1:0] w1_or_mask;

// if the write is valid, set the appropriate bit to 0, so it clears when ANDed. Otherwise, we want
// to AND with all 1's
assign w0_and_0_mask = ~({{(els_p-1){1'b0}}, w0_val_i} << w0_addr_i);
assign w1_and_0_mask = ~({{(els_p-1){1'b0}}, w1_val_i} << w1_addr_i);

// if the write is valid, or in the value at the appropriate bit. Otherwise, just or in all
// zeros to maintain the state
assign w0_or_mask = w0_val_i ? 
                      {{(els_p-1){1'b0}}, w0_bank_i} << w0_addr_i
                    : {els_p{1'b0}};
assign w1_or_mask = w1_val_i ? 
                      {{(els_p-1){1'b0}}, w1_bank_i} << w1_addr_i
                    : {els_p{1'b0}};
    

assign r_bank_o = r_val_i ? valid_bits_reg[r_addr_i] : 1'b0;

assign valid_bits_next = (valid_bits_reg & w0_and_0_mask & w1_and_0_mask) | w0_or_mask | w1_or_mask;

// check every bit...if the bit index matches a valid write address, write that value,
// otherwise, just use the existing index value
//genvar i;
//generate
//    for (i = 0; i < els_p; i = i + 1) begin: valid_bits_gen
//        always_comb begin
//            valid_bits_next[i] = (w0_val_i & (i == w0_addr_i)) ? w0_bank_i
//                            : (w1_val_i & (i == w1_addr_i)) ? w1_bank_i
//                            : valid_bits_reg[i];
//        end
//    end
//endgenerate

always_ff @(posedge clk_i) begin
    if (reset_i) begin
        valid_bits_reg <= 'b0;
    end
    else begin
        valid_bits_reg <= valid_bits_next;
    end
end
endmodule
