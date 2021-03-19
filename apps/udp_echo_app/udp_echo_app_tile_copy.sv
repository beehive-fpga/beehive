`include "udp_echo_app_defs.svh"
module udp_echo_app_tile_copy #(
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
    
    logic                           udp_app_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_app_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_udp_app_out_rdy;
    
    logic                           noc0_ctovr_udp_app_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_app_in_data;
    logic                           udp_app_in_noc0_ctovr_rdy;     
    
    logic                           noc0_ctovr_udp_stats_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_stats_in_data;
    logic                           udp_stats_in_noc0_ctovr_rdy;

    logic                           udp_stats_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_stats_out_noc0_vrtoc_data;
    logic                           noc0_vrtoc_udp_stats_out_rdy;
    
    logic                           noc0_ctovr_splitter_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_in_data;
    logic                           splitter_in_noc0_ctovr_rdy;

    logic                           merger_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_out_noc0_vrtoc_data;
    logic                           noc0_vrtoc_merger_out_rdy;
    
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
    
    noc_prio_merger #(
         .num_sources       (2)
        ,.NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (udp_app_out_noc0_vrtoc_val     )
        ,.src0_merger_vr_noc_dat    (udp_app_out_noc0_vrtoc_data    )
        ,.merger_src0_vr_noc_rdy    (noc0_vrtoc_udp_app_out_rdy     )
    
        ,.src1_merger_vr_noc_val    (udp_stats_out_noc0_vrtoc_val   )
        ,.src1_merger_vr_noc_dat    (udp_stats_out_noc0_vrtoc_data  )
        ,.merger_src1_vr_noc_rdy    (noc0_vrtoc_udp_stats_out_rdy   )
    
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
    
    // split between the record and read paths
    noc_fbits_splitter #(
         .num_targets       (3'd2)
        ,.fbits_type0       (PKT_IF_FBITS                   )
        ,.fbits_type1       (UDP_APP_LOGGER_READ_IF_FBITS   )
        ,.NOC_FBITS_W       (`NOC_FBITS_WIDTH               )
        ,.NOC_DATA_W        (`NOC_DATA_WIDTH                )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH              )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI                 )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO                 )
        ,.FBITS_HI          (`MSG_DST_FBITS_HI              )
        ,.FBITS_LO          (`MSG_DST_FBITS_LO              )
    ) splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_in_val     )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_in_data    )
        ,.splitter_src_vr_noc_rdy   (splitter_in_noc0_ctovr_rdy     )

        ,.splitter_dst0_vr_noc_val  (noc0_ctovr_udp_app_in_val      )
        ,.splitter_dst0_vr_noc_dat  (noc0_ctovr_udp_app_in_data     )
        ,.dst0_splitter_vr_noc_rdy  (udp_app_in_noc0_ctovr_rdy      )

        ,.splitter_dst1_vr_noc_val  (noc0_ctovr_udp_stats_in_val    )
        ,.splitter_dst1_vr_noc_dat  (noc0_ctovr_udp_stats_in_data   )
        ,.dst1_splitter_vr_noc_rdy  (udp_stats_in_noc0_ctovr_rdy    )

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

    udp_echo_app_copy #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) app (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_app_in_val     (noc0_ctovr_udp_app_in_val      )
        ,.noc0_ctovr_udp_app_in_data    (noc0_ctovr_udp_app_in_data     )
        ,.udp_app_in_noc0_ctovr_rdy     (udp_app_in_noc0_ctovr_rdy      )
                                                                        
        ,.udp_app_out_noc0_vrtoc_val    (udp_app_out_noc0_vrtoc_val     )
        ,.udp_app_out_noc0_vrtoc_data   (udp_app_out_noc0_vrtoc_data    )
        ,.noc0_vrtoc_udp_app_out_rdy    (noc0_vrtoc_udp_app_out_rdy     )

        ,.noc0_ctovr_udp_stats_in_val   (noc0_ctovr_udp_stats_in_val    )
        ,.noc0_ctovr_udp_stats_in_data  (noc0_ctovr_udp_stats_in_data   )
        ,.udp_stats_in_noc0_ctovr_rdy   (udp_stats_in_noc0_ctovr_rdy    )
                                                                        
        ,.udp_stats_out_noc0_vrtoc_val  (udp_stats_out_noc0_vrtoc_val   )
        ,.udp_stats_out_noc0_vrtoc_data (udp_stats_out_noc0_vrtoc_data  )
        ,.noc0_vrtoc_udp_stats_out_rdy  (noc0_vrtoc_udp_stats_out_rdy   )
    );

endmodule
