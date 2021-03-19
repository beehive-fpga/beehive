`include "udp_rx_tile_defs.svh"
module udp_rx_tile_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_rx_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_rx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_rx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_rx_noc0_data_W 
                                                                             
    ,input                                          src_udp_rx_noc0_val_N  
    ,input                                          src_udp_rx_noc0_val_E  
    ,input                                          src_udp_rx_noc0_val_S  
    ,input                                          src_udp_rx_noc0_val_W  
                                                                             
    ,output                                         udp_rx_src_noc0_yummy_N
    ,output                                         udp_rx_src_noc0_yummy_E
    ,output                                         udp_rx_src_noc0_yummy_S
    ,output                                         udp_rx_src_noc0_yummy_W
                                                                             
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_rx_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_rx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_rx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_rx_dst_noc0_data_W 
                                                                             
    ,output                                         udp_rx_dst_noc0_val_N  
    ,output                                         udp_rx_dst_noc0_val_E  
    ,output                                         udp_rx_dst_noc0_val_S  
    ,output                                         udp_rx_dst_noc0_val_W  
                                                                             
    ,input                                          dst_udp_rx_noc0_yummy_N
    ,input                                          dst_udp_rx_noc0_yummy_E
    ,input                                          dst_udp_rx_noc0_yummy_S
    ,input                                          dst_udp_rx_noc0_yummy_W
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           udp_rx_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_rx_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_udp_rx_out_rdy;
    
    logic                           noc0_ctovr_udp_rx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_rx_in_data;
    logic                           udp_rx_in_noc0_ctovr_rdy;     
    
    logic                           udp_rx_in_udp_formatter_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_rx_in_udp_formatter_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_rx_in_udp_formatter_rx_dst_ip;
    logic   [`TOT_LEN_W-1:0]        udp_rx_in_udp_formatter_rx_udp_len;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_rx_in_udp_formatter_rx_timestamp;
    logic                           udp_formatter_udp_rx_in_rx_hdr_rdy;

    logic                           udp_rx_in_udp_formatter_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_rx_in_udp_formatter_rx_data;
    logic                           udp_rx_in_udp_formatter_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_rx_in_udp_formatter_rx_padbytes;
    logic                           udp_formatter_udp_rx_in_rx_data_rdy;
    
    logic                           udp_formatter_udp_rx_out_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_formatter_udp_rx_out_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_formatter_udp_rx_out_rx_dst_ip;
    udp_pkt_hdr                     udp_formatter_udp_rx_out_rx_udp_hdr;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_formatter_udp_rx_out_rx_timestamp;
    logic                           udp_rx_out_udp_formatter_rx_hdr_rdy;

    logic                           udp_formatter_udp_rx_out_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_formatter_udp_rx_out_rx_data;
    logic                           udp_formatter_udp_rx_out_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_formatter_udp_rx_out_rx_padbytes;
    logic                           udp_rx_out_udp_formatter_rx_data_rdy;
    
    
    
    dynamic_node_top_wrap tile_rx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_udp_rx_noc0_data_N             )
        ,.src_router_data_E     (src_udp_rx_noc0_data_E             )
        ,.src_router_data_S     (src_udp_rx_noc0_data_S             )
        ,.src_router_data_W     (src_udp_rx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_udp_rx_noc0_val_N              )
        ,.src_router_val_E      (src_udp_rx_noc0_val_E              )
        ,.src_router_val_S      (src_udp_rx_noc0_val_S              )
        ,.src_router_val_W      (src_udp_rx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (udp_rx_src_noc0_yummy_N            )
        ,.router_src_yummy_E    (udp_rx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (udp_rx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (udp_rx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                 )

        ,.router_dst_data_N     (udp_rx_dst_noc0_data_N             )
        ,.router_dst_data_E     (udp_rx_dst_noc0_data_E             )
        ,.router_dst_data_S     (udp_rx_dst_noc0_data_S             )
        ,.router_dst_data_W     (udp_rx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (udp_rx_dst_noc0_val_N              )
        ,.router_dst_val_E      (udp_rx_dst_noc0_val_E              )
        ,.router_dst_val_S      (udp_rx_dst_noc0_val_S              )
        ,.router_dst_val_W      (udp_rx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_udp_rx_noc0_yummy_N            )
        ,.dst_router_yummy_E    (dst_udp_rx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_udp_rx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_udp_rx_noc0_yummy_W            )
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
        ,.ctovr_dst_data    (noc0_ctovr_udp_rx_in_data      )
        ,.ctovr_dst_val     (noc0_ctovr_udp_rx_in_val       )
        ,.dst_ctovr_rdy     (udp_rx_in_noc0_ctovr_rdy       )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (udp_rx_out_noc0_vrtoc_data     )
        ,.src_vrtoc_val     (udp_rx_out_noc0_vrtoc_val      )
        ,.vrtoc_src_rdy     (noc0_vrtoc_udp_rx_out_rdy      )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );

    udp_rx_noc_in udp_rx_noc_in (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_rx_in_val              (noc0_ctovr_udp_rx_in_val               )
        ,.noc0_ctovr_udp_rx_in_data             (noc0_ctovr_udp_rx_in_data              )
        ,.udp_rx_in_noc0_ctovr_rdy              (udp_rx_in_noc0_ctovr_rdy               )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_hdr_val    (udp_rx_in_udp_formatter_rx_hdr_val     )
        ,.udp_rx_in_udp_formatter_rx_src_ip     (udp_rx_in_udp_formatter_rx_src_ip      )
        ,.udp_rx_in_udp_formatter_rx_dst_ip     (udp_rx_in_udp_formatter_rx_dst_ip      )
        ,.udp_rx_in_udp_formatter_rx_udp_len    (udp_rx_in_udp_formatter_rx_udp_len     )
        ,.udp_rx_in_udp_formatter_rx_timestamp  (udp_rx_in_udp_formatter_rx_timestamp   )
        ,.udp_formatter_udp_rx_in_rx_hdr_rdy    (udp_formatter_udp_rx_in_rx_hdr_rdy     )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_data_val   (udp_rx_in_udp_formatter_rx_data_val    )
        ,.udp_rx_in_udp_formatter_rx_data       (udp_rx_in_udp_formatter_rx_data        )
        ,.udp_rx_in_udp_formatter_rx_last       (udp_rx_in_udp_formatter_rx_last        )
        ,.udp_rx_in_udp_formatter_rx_padbytes   (udp_rx_in_udp_formatter_rx_padbytes    )
        ,.udp_formatter_udp_rx_in_rx_data_rdy   (udp_formatter_udp_rx_in_rx_data_rdy    )
    );

    udp_stream_format #(
        .DATA_WIDTH (`NOC_DATA_WIDTH)
    ) rx_udp_formatter (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_udp_formatter_rx_hdr_val  (udp_rx_in_udp_formatter_rx_hdr_val     )
        ,.src_udp_formatter_rx_src_ip   (udp_rx_in_udp_formatter_rx_src_ip      )
        ,.src_udp_formatter_rx_dst_ip   (udp_rx_in_udp_formatter_rx_dst_ip      )
        ,.src_udp_formatter_rx_udp_len  (udp_rx_in_udp_formatter_rx_udp_len     )
        ,.src_udp_formatter_rx_timestamp(udp_rx_in_udp_formatter_rx_timestamp   )
        ,.udp_formatter_src_rx_hdr_rdy  (udp_formatter_udp_rx_in_rx_hdr_rdy     )
                                                                                
        ,.src_udp_formatter_rx_data_val (udp_rx_in_udp_formatter_rx_data_val    )
        ,.src_udp_formatter_rx_data     (udp_rx_in_udp_formatter_rx_data        )
        ,.src_udp_formatter_rx_last     (udp_rx_in_udp_formatter_rx_last        )
        ,.src_udp_formatter_rx_padbytes (udp_rx_in_udp_formatter_rx_padbytes    )
        ,.udp_formatter_src_rx_data_rdy (udp_formatter_udp_rx_in_rx_data_rdy    )
        
        ,.udp_formatter_dst_rx_hdr_val  (udp_formatter_udp_rx_out_rx_hdr_val    )
        ,.udp_formatter_dst_rx_src_ip   (udp_formatter_udp_rx_out_rx_src_ip     )
        ,.udp_formatter_dst_rx_dst_ip   (udp_formatter_udp_rx_out_rx_dst_ip     )
        ,.udp_formatter_dst_rx_udp_hdr  (udp_formatter_udp_rx_out_rx_udp_hdr    )
        ,.udp_formatter_dst_rx_timestamp(udp_formatter_udp_rx_out_rx_timestamp  )
        ,.dst_udp_formatter_rx_hdr_rdy  (udp_rx_out_udp_formatter_rx_hdr_rdy    )
                                                                                 
        ,.udp_formatter_dst_rx_data_val (udp_formatter_udp_rx_out_rx_data_val   )
        ,.udp_formatter_dst_rx_data     (udp_formatter_udp_rx_out_rx_data       )
        ,.udp_formatter_dst_rx_last     (udp_formatter_udp_rx_out_rx_last       )
        ,.udp_formatter_dst_rx_padbytes (udp_formatter_udp_rx_out_rx_padbytes   )
        ,.dst_udp_formatter_rx_data_rdy (udp_rx_out_udp_formatter_rx_data_rdy   )
    );

    udp_rx_noc_out_copy #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) udp_rx_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_formatter_udp_rx_out_rx_hdr_val   (udp_formatter_udp_rx_out_rx_hdr_val    )
        ,.udp_formatter_udp_rx_out_rx_src_ip    (udp_formatter_udp_rx_out_rx_src_ip     )
        ,.udp_formatter_udp_rx_out_rx_dst_ip    (udp_formatter_udp_rx_out_rx_dst_ip     )
        ,.udp_formatter_udp_rx_out_rx_udp_hdr   (udp_formatter_udp_rx_out_rx_udp_hdr    )
        ,.udp_formatter_udp_rx_out_rx_timestamp (udp_formatter_udp_rx_out_rx_timestamp  )
        ,.udp_rx_out_udp_formatter_rx_hdr_rdy   (udp_rx_out_udp_formatter_rx_hdr_rdy    )
                                                                                        
        ,.udp_formatter_udp_rx_out_rx_data_val  (udp_formatter_udp_rx_out_rx_data_val   )
        ,.udp_formatter_udp_rx_out_rx_data      (udp_formatter_udp_rx_out_rx_data       )
        ,.udp_formatter_udp_rx_out_rx_last      (udp_formatter_udp_rx_out_rx_last       )
        ,.udp_formatter_udp_rx_out_rx_padbytes  (udp_formatter_udp_rx_out_rx_padbytes   )
        ,.udp_rx_out_udp_formatter_rx_data_rdy  (udp_rx_out_udp_formatter_rx_data_rdy   )
                                                                                        
        ,.udp_rx_out_noc0_vrtoc_val             (udp_rx_out_noc0_vrtoc_val              )
        ,.udp_rx_out_noc0_vrtoc_data            (udp_rx_out_noc0_vrtoc_data             )
        ,.noc0_vrtoc_udp_rx_out_rdy             (noc0_vrtoc_udp_rx_out_rdy              )
    );
    

endmodule
