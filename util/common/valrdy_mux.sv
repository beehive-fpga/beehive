module valrdy_mux #(
     parameter DATA_W = -1
    ,parameter ELS_P = -1
    ,parameter LG_ELS_P = $clog2(ELS_P)
)(
     input   [LG_ELS_P-1:0]          sel_i

    ,input  [ELS_P-1:0]             src_vals_i 
    ,input  [ELS_P-1:0][DATA_W-1:0] src_datas_i
    ,output [ELS_P-1:0]             rdys_src_o

    ,output                         val_dst_o
    ,output [DATA_W-1:0]            data_dst_o
    ,input  [ELS_P-1:0]             dst_rdy_i
);

    bsg_mux #(
         .width_p   (1      )
        ,.els_p     (ELS_P  )
    ) vals_mux (
         .data_i    (src_vals_i )
        ,.sel_i     (sel_i      )
        ,.data_o    (val_dst_o  )
    );

    bsg_mux #(
         .width_p   (DATA_W )
        ,.els_p     (ELS_P  )
    ) datas_mux (
         .data_i    (src_datas_i)
        ,.sel_i     (sel_i      )
        ,.data_o    (data_dst_o )
    );

    bsg_mux #(
         .width_p   (1      )
        ,.els_p     (ELS_P  )
    ) rdys_mux (
         .data_i    (dst_rdy_i  )
        ,.sel_i     (sel_i      )
        ,.data_o    (rdys_src_o )
    );

endmodule