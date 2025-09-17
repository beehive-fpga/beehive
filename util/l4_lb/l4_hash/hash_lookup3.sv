// Originally from Pigasus on Github: https://github.com/crossroadsfpga/pigasus
// 8/17/22: modified to reset the valid signals
// Pipelined RTL implementation of the Lookup3 hash:
// https://burtleburtle.net/bob/c/lookup3.c
module hash_func 
    import hash_pkg::*;
(
    input                   clk,
    input                   rst,
    input                   stall,
    input   logic [31:0]    initval,
    input   hash_struct     tuple_in,
    input                   tuple_in_valid,
    output  logic           hashed_valid,
    output  logic [31:0]    hashed
);

logic [31:0] a;
logic [31:0] b;
logic [31:0] c;
logic [31:0] a1;
logic [31:0] b1;
logic [31:0] c1;
logic [31:0] a2;
logic [31:0] b2;
logic [31:0] c2;
logic [31:0] a3;
logic [31:0] b3;
logic [31:0] c3;
logic [31:0] a4;
logic [31:0] b4;
logic [31:0] c4;
logic [31:0] a5;
logic [31:0] b5;
logic [31:0] c5;
logic [31:0] a6;
logic [31:0] b6;
logic [31:0] c6;
logic [31:0] mix_b;
    logic [31:0] mix_c;

    hash_struct tuple_reg0;
    hash_struct tuple_reg1;
    hash_struct tuple_reg2;
    hash_struct tuple_reg3;
    hash_struct tuple_reg4;
    hash_struct tuple_reg5;
    hash_struct tuple_reg6;
    hash_struct tuple_reg_out;

logic valid;
logic valid1;
logic valid2;
logic valid3;
logic valid4;
logic valid5;
logic valid6;

logic [95:0] key;
assign key = {tuple_in.src_ip, tuple_in.src_port,
              tuple_in.dst_ip, tuple_in.dst_port};

always_ff @(posedge clk) begin
    if (rst) begin
        valid <= '0;
        valid1 <= '0;
        valid2 <= '0;
        valid3 <= '0;
        valid4 <= '0;
        valid5 <= '0;
        valid6 <= '0;
        hashed_valid <= '0;
    end
    else begin
        if (!stall) begin
            valid <= tuple_in_valid;
            valid1 <= valid;
            valid2 <= valid1;
            valid3 <= valid2;
            valid4 <= valid3;
            valid5 <= valid4;
            valid6 <= valid5;
            hashed_valid <= valid6;

            tuple_reg0 <= tuple_in;
            tuple_reg1 <= tuple_reg0;
            tuple_reg2 <= tuple_reg1;
            tuple_reg3 <= tuple_reg2;
            tuple_reg4 <= tuple_reg3;
            tuple_reg5 <= tuple_reg4;
            tuple_reg6 <= tuple_reg5;
            tuple_reg_out <= tuple_reg6;
        end
    end
end

// Pipelined design
always @(posedge clk) begin
    if (!stall) begin
        a <= 32'hdeadbefb + key[31:0] + initval;
        b <= 32'hdeadbefb + key[63:32] + initval;
        c <= 32'hdeadbefb + key[95:64] + initval;

        a1 <= a;
        b1 <= b;
        mix_b <= {b[17:0], b[31:18]};
        c1 <= (c ^ b) - {b[17:0], b[31:18]};

        a2 <= (a1 ^ c1) - {c1[20:0], c1[31:21]};
        b2 <= b1;
        c2 <= c1;

        a3 <= a2;
        b3 <= (b2 ^ a2) - {a2[6:0], a2[31:7]};
        c3 <= c2;

        a4 <= a3;
        b4 <= b3;
        c4 <= (c3 ^ b3) - {b3[15:0], b3[31:16]};

        a5 <= (a4 ^ c4) - {c4[27:0], c4[31:28]};
        mix_c <= {c4[27:0], c4[31:28]};
        b5 <= b4;
        c5 <= c4;

        a6 <= a5;
        b6 <= (b5 ^ a5) - {a5[17:0], a5[31:18]};
        c6 <= c5;

        hashed <= (c6 ^ b6) - {b6[7:0], b6[31:8]};
    end
end

endmodule
