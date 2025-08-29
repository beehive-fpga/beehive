// wrapper for a single ported ram with 2 cycle read latency (as opposed to the
// typicacl 1 cycle of a synchronous memory). uses a primitive that is meant to
// infer on Xilinx FPGAs.
// adds a valid signal on the read output, so you don't have to count the two
// cycles externally

module ram_1rw_byte_mask_out_reg_wrap #(
     parameter DATA_W = -1
    ,parameter DATA_MASK_W = DATA_W/8
    ,parameter DEPTH = -1
    ,parameter ADDR_W = $clog2(DEPTH)
)(
     input clk
    ,input rst
    ,input                      en_a
    ,input  [ADDR_W-1:0]        addr_a
    ,input  [DATA_W-1:0]        din_a
    ,input                      wr_en_a
    ,input  [DATA_MASK_W-1:0]   wr_mask_a
   
    ,output                     dout_val_a
    ,output [DATA_W-1:0]        dout_a
);
    logic   val_reg_1;
    logic   val_reg_2;

    logic   [DATA_MASK_W-1:0]   wr_mask_a_int;

    assign wr_mask_a_int = wr_en_a
                        ? wr_mask_a
                        : '0;

    assign dout_val_a = val_reg_2;

    always_ff @(posedge clk) begin
        if (rst) begin
            val_reg_1 <= '0;
            val_reg_2 <= '0;
        end
        else begin
            val_reg_1 <= en_a & ~wr_en_a;
            val_reg_2 <= val_reg_1;
        end
    end


    ram_1rw_byte_mask_out_reg #(
         .DATA_W    (DATA_W )
        ,.DEPTH     (DEPTH  )
    ) ram (
         .clk   (clk    )
        ,.rst   (rst    )
        ,.en_a      (en_a           )
        ,.addr_a    (addr_a         )
        ,.din_a     (din_a          )
        ,.wr_mask_a (wr_mask_a_int  )
        
        ,.dout_a    (dout_a         )
    );
endmodule
