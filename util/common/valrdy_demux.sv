module valrdy_demux #(
     parameter NUM_OUTPUTS = -1
    ,parameter NUM_LOG_OUTPUTS = $clog2(NUM_OUTPUTS)
    ,parameter DATA_W = -1
)(
     input                          src_val
    ,input  [NUM_LOG_OUTPUTS-1:0]   input_sel
    ,input  [DATA_W-1:0]            src_data
    ,output                         rdy_src

    ,output [NUM_OUTPUTS-1:0]               vals_dst
    ,output [NUM_OUTPUTS-1:0][DATA_W-1:0]   datas_dst
    ,input  [NUM_OUTPUTS-1:0]               dst_rdys
);

    demux #(
         .NUM_OUTPUTS       (NUM_OUTPUTS    )
        ,.INPUT_WIDTH       (1)
    ) vals_demux (
         .input_sel     (input_sel  )
        ,.data_input    (src_val    )
        ,.data_outputs  (vals_dst   )
    );

    assign datas_dst = {NUM_OUTPUTS{src_data}};

    bsg_mux #(
         .width_p   (1              )
        ,.els_p     (NUM_OUTPUTS    )
    ) rdys_mux (
         .data_i    (dst_rdys   )
        ,.sel_i     (input_sel  )
        ,.data_o    (rdy_src    )
    );
    
endmodule