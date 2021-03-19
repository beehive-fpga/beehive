module realign_runtime_wrap #(
     parameter DATA_W = -1
    ,parameter BUF_STAGES = -1
    ,parameter DATA_PADBYTES = DATA_W/8
    ,parameter DATA_PADBYTES_W = $clog2(DATA_PADBYTES)
)(
     input clk
    ,input rst

    ,input          [DATA_PADBYTES_W-1:0]   realign_bytes

    ,input  logic                           src_realign_data_val
    ,input  logic   [DATA_W-1:0]            src_realign_data
    ,input  logic   [DATA_PADBYTES_W-1:0]   src_realign_data_padbytes 
    ,input  logic                           src_realign_data_last
    ,output logic                           realign_src_data_rdy

    ,output logic                           realign_dst_data_val
    ,output logic   [DATA_W-1:0]            realign_dst_data
    ,output logic   [DATA_PADBYTES_W-1:0]   realign_dst_data_padbytes
    ,output logic                           realign_dst_data_last
    ,input  logic                           dst_realign_data_rdy
);
    
    logic   [DATA_W-1:0]    unmasked_data;
   
    data_masker #(
         .width_p   (DATA_W )
    ) masker (  
         .unmasked_data (unmasked_data              )
        ,.padbytes      (realign_dst_data_padbytes  )
        ,.last          (realign_dst_data_last      )
    
        ,.masked_data   (realign_dst_data           )
    );

    realign_runtime #(
         .DATA_W        (DATA_W     )
        ,.BUF_STAGES    (BUF_STAGES )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.realign_bytes             (realign_bytes              )
                                                                
        ,.src_realign_data_val      (src_realign_data_val       )
        ,.src_realign_data          (src_realign_data           )
        ,.src_realign_data_padbytes (src_realign_data_padbytes  )
        ,.src_realign_data_last     (src_realign_data_last      )
        ,.realign_src_data_rdy      (realign_src_data_rdy       )
                                                                
        ,.realign_dst_data_val      (realign_dst_data_val       )
        ,.realign_dst_data          (unmasked_data              )
        ,.realign_dst_data_padbytes (realign_dst_data_padbytes  )
        ,.realign_dst_data_last     (realign_dst_data_last      )
        ,.dst_realign_data_rdy      (dst_realign_data_rdy       )
                                                                
        ,.full_line                 ()
    );
endmodule
