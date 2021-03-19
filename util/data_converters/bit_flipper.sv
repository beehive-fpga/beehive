module bit_flipper #(
     parameter DATA_W = -1
)(
     input  logic   [DATA_W-1:0]    input_data
    ,output logic   [DATA_W-1:0]    flipped_data
);

    genvar i;
    generate
        for (i = 0; i < DATA_W; i = i + 1) begin : generate_bit_flip
            assign flipped_data[DATA_W - 1 - i] = input_data[i];
        end
    endgenerate
endmodule
