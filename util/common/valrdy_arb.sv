module valrdy_arb #(
     parameter DATA_W = -1
    ,parameter NUM_ELS = -1
)(
     input clk
    ,input rst

    ,input  [NUM_ELS-1:0]               src_vals
    ,input  [NUM_ELS-1:0][DATA_W-1:0]   src_datas
    ,output [NUM_ELS-1:0]               rdys_src

    ,output                             val_dst
    ,output [DATA_W-1:0]                data_dst
    ,input                              dst_rdy
);
    logic   [NUM_ELS-1:0]   grants;

    assign val_dst = |grants;

    bsg_mux_one_hot #(
         .width_p   (DATA_W )
        ,.els_p     (NUM_ELS)
    ) data_mux (
         .data_i        (src_datas      )
        ,.sel_one_hot_i (grants         )
        ,.data_o        (data_dst       )
    );

    demux_one_hot #(
         .NUM_OUTPUTS   (NUM_ELS)
        ,.INPUT_WIDTH   (1)
    ) rdy_demux (
         .input_sel     (grants)
        ,.data_input    (dst_rdy    )
        ,.data_outputs  (rdys_src   )
    );


    bsg_arb_round_robin #(
        .width_p    (NUM_ELS)
    ) arbiter (
        .clk_i      (clk            )
       ,.reset_i    (rst            )

       ,.reqs_i     (src_vals       )
       ,.grants_o   (grants         )
       ,.yumi_i     (dst_rdy        )
    );
endmodule