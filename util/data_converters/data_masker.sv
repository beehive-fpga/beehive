module data_masker #(
     parameter width_p = -1
    ,parameter bits_shift_w = $clog2(width_p)
    ,parameter padbytes_w = $clog2(width_p/8)
)(  
     input  [width_p-1:0]       unmasked_data
    ,input  [padbytes_w-1:0]    padbytes
    ,input                      last

    ,output [width_p-1:0]       masked_data
);
    logic   [width_p-1:0]       data_mask;
    logic   [bits_shift_w-1:0]  mask_shift;

    assign mask_shift = last
                        ? padbytes << 3
                        : '0;

    assign data_mask = {(width_p){1'b1}} << mask_shift;
    assign masked_data = unmasked_data & data_mask;
endmodule
