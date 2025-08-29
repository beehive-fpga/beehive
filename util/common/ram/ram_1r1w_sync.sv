//  2-port ram with one read and one write port implemented to infer on Xilinx FPGAs
module ram_1r1w_sync #(
     parameter DATA_W = -1
    ,parameter DEPTH = -1
    ,parameter ADDR_W = $clog2(DEPTH)
) (
     input  clk
    ,input  rst

    ,input                          wr_en_a
    ,input          [ADDR_W-1:0]    wr_addr_a
    ,input          [DATA_W-1:0]    wr_data_a

    ,input                          rd_en_a
    ,input          [ADDR_W-1:0]    rd_addr_a

    ,output logic   [DATA_W-1:0]    rd_data_a
);

    logic   [DATA_W-1:0]    ram [DEPTH-1:0];
    logic   [DATA_W-1:0]    data_out_reg;

    always_ff @(posedge clk) begin
        if (wr_en_a) begin
            ram[wr_addr_a] <= wr_data_a;
        end
    end

    always_ff @(posedge clk) begin
        if (rd_en_a) begin
            data_out_reg <= ram[rd_addr_a];
        end
    end

    assign rd_data_a = data_out_reg;

//    always_ff @(negedge clk) begin
//        if (~rst && wr_en_a && rd_en_a && (rd_addr_a == wr_addr_a)) begin
//            $error("Read and write operation to the same address %x", rd_addr_a);
//        end
//    end
endmodule
