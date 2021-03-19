module byte_flipper #(
     parameter DATA_W = -1
    ,parameter BYTES = DATA_W/8
)(
     input  logic   [DATA_W-1:0]    input_data
    ,output logic   [DATA_W-1:0]    flipped_data
);

    generate 
        if (DATA_W%8 != 0) begin
            $error("Data width is %d, but must be a multiple of 8", DATA_W);
        end
    endgenerate


    genvar i;
    generate
        for (i = 0; i < BYTES; i = i + 1) begin : generate_byte_flip
            assign flipped_data[(DATA_W - 1) - (i * 8) -: 8] = input_data[(i*8) +: 8];
        end
    endgenerate
endmodule
