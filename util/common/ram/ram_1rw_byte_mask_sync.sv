// single ported ram with byte mask implemented to infer on Xilinx FPGAs
module ram_1rw_byte_mask_sync #(
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
    ,input  [DATA_MASK_W-1:0]   wr_mask_a
    ,output [DATA_W-1:0]        dout_a
);

    logic   [DATA_W-1:0]   ram[DEPTH-1:0];
    logic   [DATA_W-1:0]    data_out_reg;

    generate
    genvar i;
    for (i = 0; i < DATA_MASK_W; i = i+1) begin: byte_write
        always_ff @(posedge clk)
            if (en_a) begin
                if (wr_mask_a[i]) begin
                    ram[addr_a][((i+1)*8)-1:i*8] <= din_a[((i+1)*8)-1:i*8];
                end
           end
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (en_a) begin
            data_out_reg <= ram[addr_a];
        end
    end
    
    assign dout_a = data_out_reg;
endmodule
