`include "udp_rs_encode_defs.svh"
module rs_encode_udp_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst 
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_app_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_app_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_app_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_app_noc0_data_W 
                                                                             
    ,input                                          src_udp_app_noc0_val_N  
    ,input                                          src_udp_app_noc0_val_E  
    ,input                                          src_udp_app_noc0_val_S  
    ,input                                          src_udp_app_noc0_val_W  
                                                                             
    ,output                                         udp_app_src_noc0_yummy_N
    ,output                                         udp_app_src_noc0_yummy_E
    ,output                                         udp_app_src_noc0_yummy_S
    ,output                                         udp_app_src_noc0_yummy_W
                                                                             
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_app_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_app_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_app_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_app_dst_noc0_data_W 
                                                                             
    ,output                                         udp_app_dst_noc0_val_N  
    ,output                                         udp_app_dst_noc0_val_E  
    ,output                                         udp_app_dst_noc0_val_S  
    ,output                                         udp_app_dst_noc0_val_W  
                                                                             
    ,input                                          dst_udp_app_noc0_yummy_N
    ,input                                          dst_udp_app_noc0_yummy_E
    ,input                                          dst_udp_app_noc0_yummy_S
    ,input                                          dst_udp_app_noc0_yummy_W
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           noc0_ctovr_splitter_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_in_data;
    logic                           splitter_in_noc0_ctovr_rdy;

    logic                           merger_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_out_noc0_vrtoc_data;
    logic                           noc0_vrtoc_merger_out_rdy;
    
    logic                           udp_app_out_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_app_out_merger_data;    
    logic                           merger_udp_app_out_rdy;
    
    logic                           splitter_udp_app_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_udp_app_in_data;
    logic                           udp_app_in_splitter_rdy;     
    
    logic                           rs_enc_stats_out_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   rs_enc_stats_out_merger_data;    
    logic                           merger_rs_enc_stats_out_rdy;
    
    logic                           splitter_rs_enc_stats_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_rs_enc_stats_in_data;
    logic                           rs_enc_stats_in_splitter_rdy;     
    
    dynamic_node_top_wrap tile_rx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_udp_app_noc0_data_N            )
        ,.src_router_data_E     (src_udp_app_noc0_data_E            )
        ,.src_router_data_S     (src_udp_app_noc0_data_S            )
        ,.src_router_data_W     (src_udp_app_noc0_data_W            )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_udp_app_noc0_val_N             )
        ,.src_router_val_E      (src_udp_app_noc0_val_E             )
        ,.src_router_val_S      (src_udp_app_noc0_val_S             )
        ,.src_router_val_W      (src_udp_app_noc0_val_W             )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (udp_app_src_noc0_yummy_N           )
        ,.router_src_yummy_E    (udp_app_src_noc0_yummy_E           )
        ,.router_src_yummy_S    (udp_app_src_noc0_yummy_S           )
        ,.router_src_yummy_W    (udp_app_src_noc0_yummy_W           )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                 )

        ,.router_dst_data_N     (udp_app_dst_noc0_data_N            )
        ,.router_dst_data_E     (udp_app_dst_noc0_data_E            )
        ,.router_dst_data_S     (udp_app_dst_noc0_data_S            )
        ,.router_dst_data_W     (udp_app_dst_noc0_data_W            )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (udp_app_dst_noc0_val_N             )
        ,.router_dst_val_E      (udp_app_dst_noc0_val_E             )
        ,.router_dst_val_S      (udp_app_dst_noc0_val_S             )
        ,.router_dst_val_W      (udp_app_dst_noc0_val_W             )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_udp_app_noc0_yummy_N           )
        ,.dst_router_yummy_E    (dst_udp_app_noc0_yummy_E           )
        ,.dst_router_yummy_S    (dst_udp_app_noc0_yummy_S           )
        ,.dst_router_yummy_W    (dst_udp_app_noc0_yummy_W           )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_rx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy tile_rx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_rx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_rx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_rx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_splitter_in_data    )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_in_val     )
        ,.dst_ctovr_rdy     (splitter_in_noc0_ctovr_rdy     )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_out_noc0_vrtoc_data     )
        ,.src_vrtoc_val     (merger_out_noc0_vrtoc_val      )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_out_rdy      )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );
    
    // split between the record and read paths
    beehive_noc_fbits_splitter #(
         .num_targets   (3'd2)
        ,.fbits_type0   (PKT_IF_FBITS                   )
        ,.fbits_type1   (RS_APP_STATS_IF_FBITS          )
    ) splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_in_val     )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_in_data    )
        ,.splitter_src_vr_noc_rdy   (splitter_in_noc0_ctovr_rdy     )

        ,.splitter_dst0_vr_noc_val  (splitter_udp_app_in_val        )
        ,.splitter_dst0_vr_noc_dat  (splitter_udp_app_in_data       )
        ,.dst0_splitter_vr_noc_rdy  (udp_app_in_splitter_rdy        )

        ,.splitter_dst1_vr_noc_val  (splitter_rs_enc_stats_in_val   )
        ,.splitter_dst1_vr_noc_dat  (splitter_rs_enc_stats_in_data  )
        ,.dst1_splitter_vr_noc_rdy  (rs_enc_stats_in_splitter_rdy   )

        ,.splitter_dst2_vr_noc_val  ()
        ,.splitter_dst2_vr_noc_dat  ()
        ,.dst2_splitter_vr_noc_rdy  (1'b0)

        ,.splitter_dst3_vr_noc_val  ()
        ,.splitter_dst3_vr_noc_dat  ()
        ,.dst3_splitter_vr_noc_rdy  (1'b0)

        ,.splitter_dst4_vr_noc_val  ()
        ,.splitter_dst4_vr_noc_dat  ()
        ,.dst4_splitter_vr_noc_rdy  (1'b0)
    );
    
    beehive_noc_prio_merger #(
        .num_sources    (2)
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (udp_app_out_merger_val         )
        ,.src0_merger_vr_noc_dat    (udp_app_out_merger_data        )
        ,.merger_src0_vr_noc_rdy    (merger_udp_app_out_rdy         )
    
        ,.src1_merger_vr_noc_val    (rs_enc_stats_out_merger_val    )
        ,.src1_merger_vr_noc_dat    (rs_enc_stats_out_merger_data   )
        ,.merger_src1_vr_noc_rdy    (merger_rs_enc_stats_out_rdy    )
    
        ,.src2_merger_vr_noc_val    ('0)
        ,.src2_merger_vr_noc_dat    ('0)
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ('0)
        ,.src3_merger_vr_noc_dat    ('0)
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ('0)
        ,.src4_merger_vr_noc_dat    ('0)
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (merger_out_noc0_vrtoc_val      )
        ,.merger_dst_vr_noc_dat     (merger_out_noc0_vrtoc_data     )
        ,.dst_merger_vr_noc_rdy     (noc0_vrtoc_merger_out_rdy      )
    );
    

    logic   fifo_wr_req;
    logic   fifo_full;
    logic   fifo_empty;
    logic   fifo_rd_req;
    
    logic                           fifo_app_val;
    logic   [`NOC_DATA_WIDTH-1:0]   fifo_app_data;
    logic                           app_fifo_rdy;

    assign udp_app_in_splitter_rdy = ~fifo_full;

    assign fifo_wr_req = ~fifo_full & splitter_udp_app_in_val;

    
    assign fifo_rd_req = ~fifo_empty & app_fifo_rdy;

    assign fifo_app_val = ~fifo_empty;

    fifo_1r1w #(
         .width_p       (`NOC_DATA_WIDTH    )
        ,.log2_els_p    (8                  )
    ) in_fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req    (fifo_wr_req                )
        ,.wr_data   (splitter_udp_app_in_data   )
        ,.full      (fifo_full                  )
        
        ,.rd_req    (fifo_rd_req                )
        ,.rd_data   (fifo_app_data              )
        ,.empty     (fifo_empty                 )
    
    );

    logic   fifo_wr_req;
    logic   fifo_full;
    logic   fifo_empty;
    logic   fifo_rd_req;
    
    logic                           fifo_app_val;
    logic   [`NOC_DATA_WIDTH-1:0]   fifo_app_data;
    logic                           app_fifo_rdy;

    assign udp_app_in_splitter_rdy = ~fifo_full;

    assign fifo_wr_req = ~fifo_full & splitter_udp_app_in_val;

    
    assign fifo_rd_req = ~fifo_empty & app_fifo_rdy;

    assign fifo_app_val = ~fifo_empty;

    fifo_1r1w #(
         .width_p       (`NOC_DATA_WIDTH    )
        ,.log2_els_p    (8                  )
    ) in_fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req    (fifo_wr_req                )
        ,.wr_data   (splitter_udp_app_in_data   )
        ,.full      (fifo_full                  )
        
        ,.rd_req    (fifo_rd_req                )
        ,.rd_data   (fifo_app_data              )
        ,.empty     (fifo_empty                 )
    
    );

    udp_rs_encode_wrap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) udp_rs_encode (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_app_in_val         (fifo_app_val                   )
        ,.noc0_ctovr_udp_app_in_data        (fifo_app_data                  )
        ,.udp_app_in_noc0_ctovr_rdy         (app_fifo_rdy                   )
                                                                              
        ,.udp_app_out_noc0_vrtoc_val        (udp_app_out_merger_val         )
        ,.udp_app_out_noc0_vrtoc_data       (udp_app_out_merger_data        )
        ,.noc0_vrtoc_udp_app_out_rdy        (merger_udp_app_out_rdy         )
    
        ,.noc0_ctovr_rs_enc_stats_in_val    (splitter_rs_enc_stats_in_val   )
        ,.noc0_ctovr_rs_enc_stats_in_data   (splitter_rs_enc_stats_in_data  )
        ,.rs_enc_stats_in_noc0_ctovr_rdy    (rs_enc_stats_in_splitter_rdy   )
                                                                                  
        ,.rs_enc_stats_out_noc0_vrtoc_val   (rs_enc_stats_out_merger_val    )
        ,.rs_enc_stats_out_noc0_vrtoc_data  (rs_enc_stats_out_merger_data   )
        ,.noc0_vrtoc_rs_enc_stats_out_rdy   (merger_rs_enc_stats_out_rdy    )
    );
endmodule
