module wide_to_narrow_wrap #(
     parameter IN_DATA_ELS = 2
    ,parameter OUT_DATA_W = 256
    ,parameter OUT_KEEP_W = OUT_DATA_W/8
)(
     input  clk
    ,input  rst

    ,input                                              src_w_to_n_val
    ,input          [IN_DATA_ELS-1:0][OUT_DATA_W-1:0]   src_w_to_n_data
    ,input          [IN_DATA_ELS-1:0][OUT_KEEP_W-1:0]   src_w_to_n_keep
    ,input                                              src_w_to_n_last
    ,output logic                                       w_to_n_src_rdy

    ,output logic                                       w_to_n_dst_val
    ,output logic   [OUT_DATA_W-1:0]                    w_to_n_dst_data
    ,output logic   [OUT_KEEP_W-1:0]                    w_to_n_dst_keep
    ,output logic                                       w_to_n_dst_last
    ,input  logic                                       dst_w_to_n_rdy
);
    wide_to_narrow #(
         .OUT_DATA_W    (OUT_DATA_W     )
        ,.IN_DATA_ELS   (IN_DATA_ELS    )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_w_to_n_val    (src_w_to_n_val     )
        ,.src_w_to_n_data   (src_w_to_n_data    )
        ,.src_w_to_n_keep   (src_w_to_n_keep    )
        ,.src_w_to_n_last   (src_w_to_n_last    )
        ,.w_to_n_src_rdy    (w_to_n_src_rdy     )
                                                
        ,.w_to_n_dst_val    (w_to_n_dst_val     )
        ,.w_to_n_dst_data   (w_to_n_dst_data    )
        ,.w_to_n_dst_keep   (w_to_n_dst_keep    )
        ,.w_to_n_dst_last   (w_to_n_dst_last    )
        ,.dst_w_to_n_rdy    (dst_w_to_n_rdy     )
    );
endmodule
