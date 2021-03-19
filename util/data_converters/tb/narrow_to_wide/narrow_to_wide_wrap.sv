module narrow_to_wide_wrap #(
     parameter IN_DATA_W = 256
    ,parameter IN_KEEP_W = 256/8
    ,parameter OUT_DATA_ELS = 2
)(
     input clk
    ,input rst

    ,input                                              src_n_to_w_val
    ,input          [IN_DATA_W-1:0]                     src_n_to_w_data
    ,input          [IN_KEEP_W-1:0]                     src_n_to_w_keep
    ,input                                              src_n_to_w_last
    ,output logic                                       n_to_w_src_rdy 

    ,output logic                                       n_to_w_dst_val
    ,output logic   [OUT_DATA_ELS-1:0][IN_DATA_W-1:0]   n_to_w_dst_data
    ,output logic   [OUT_DATA_ELS-1:0][IN_KEEP_W-1:0]   n_to_w_dst_keep
    ,output logic                                       n_to_w_dst_last
    ,input                                              dst_n_to_w_rdy
);

    narrow_to_wide #(
         .IN_DATA_W     (IN_DATA_W      )
        ,.OUT_DATA_ELS  (OUT_DATA_ELS   )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_w_val    (src_n_to_w_val     )
        ,.src_n_to_w_data   (src_n_to_w_data    )
        ,.src_n_to_w_keep   (src_n_to_w_keep    )
        ,.src_n_to_w_last   (src_n_to_w_last    )
        ,.n_to_w_src_rdy    (n_to_w_src_rdy     )
                                                
        ,.n_to_w_dst_val    (n_to_w_dst_val     )
        ,.n_to_w_dst_data   (n_to_w_dst_data    )
        ,.n_to_w_dst_keep   (n_to_w_dst_keep    )
        ,.n_to_w_dst_last   (n_to_w_dst_last    )
        ,.dst_n_to_w_rdy    (dst_n_to_w_rdy     )
    );
endmodule
