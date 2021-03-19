`include "udp_tx_tile_defs.svh"
module udp_tx_tile_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter USE_INT_LB = 1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_tx_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_tx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_tx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_udp_tx_noc0_data_W 
                                                                             
    ,input                                          src_udp_tx_noc0_val_N  
    ,input                                          src_udp_tx_noc0_val_E  
    ,input                                          src_udp_tx_noc0_val_S  
    ,input                                          src_udp_tx_noc0_val_W  
                                                                             
    ,output                                         udp_tx_src_noc0_yummy_N
    ,output                                         udp_tx_src_noc0_yummy_E
    ,output                                         udp_tx_src_noc0_yummy_S
    ,output                                         udp_tx_src_noc0_yummy_W
                                                                             
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_tx_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_tx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_tx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]                   udp_tx_dst_noc0_data_W 
                                                                             
    ,output                                         udp_tx_dst_noc0_val_N  
    ,output                                         udp_tx_dst_noc0_val_E  
    ,output                                         udp_tx_dst_noc0_val_S  
    ,output                                         udp_tx_dst_noc0_val_W  
                                                                             
    ,input                                          dst_udp_tx_noc0_yummy_N
    ,input                                          dst_udp_tx_noc0_yummy_E
    ,input                                          dst_udp_tx_noc0_yummy_S
    ,input                                          dst_udp_tx_noc0_yummy_W
);
    
    logic                           noc0_vrtoc_tile_tx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_tx_router_data;
    logic                           tile_tx_router_noc0_vrtoc_yummy;

    logic                           tile_tx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_tx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_tx_router_yummy;
    
    logic                           udp_tx_out_lb_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_tx_out_lb_data;    
    logic                           lb_udp_tx_out_rdy;

    logic                           lb_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   lb_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_lb_rdy;
    
    logic                           noc0_ctovr_udp_tx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_tx_in_data;
    logic                           udp_tx_in_noc0_ctovr_rdy;     
    
    logic                           udp_tx_in_udp_to_stream_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_src_ip_addr;
    logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_dst_ip_addr;
    udp_pkt_hdr                     udp_tx_in_udp_to_stream_udp_hdr;
    logic   [MSG_TIMESTAMP_W-1:0]   udp_tx_in_udp_to_stream_timestamp;
    logic                           udp_to_stream_udp_tx_in_hdr_rdy;
    
    logic                           udp_tx_in_udp_to_stream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_tx_in_udp_to_stream_data;
    logic                           udp_tx_in_udp_to_stream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_tx_in_udp_to_stream_data_padbytes;
    logic                           udp_to_stream_udp_tx_in_data_rdy;
    
    logic                           udp_to_stream_udp_tx_out_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_to_stream_udp_tx_out_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_to_stream_udp_tx_out_dst_ip;
    logic   [`TOT_LEN_W-1:0]        udp_to_stream_udp_tx_out_udp_len;
    logic   [`PROTOCOL_W-1:0]       udp_to_stream_udp_tx_out_protocol;
    logic   [MSG_TIMESTAMP_W-1:0]   udp_to_stream_udp_tx_out_timestamp;
    logic                           udp_tx_out_udp_to_stream_hdr_rdy;

    logic                           udp_to_stream_udp_tx_out_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_to_stream_udp_tx_out_data;
    logic                           udp_to_stream_udp_tx_out_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_to_stream_udp_tx_out_padbytes;
    logic                           udp_tx_out_udp_to_stream_rdy;
    
    dynamic_node_top_wrap tile_tx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_udp_tx_noc0_data_N             )
        ,.src_router_data_E     (src_udp_tx_noc0_data_E             )
        ,.src_router_data_S     (src_udp_tx_noc0_data_S             )
        ,.src_router_data_W     (src_udp_tx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data     )
                                
        ,.src_router_val_N      (src_udp_tx_noc0_val_N              )
        ,.src_router_val_E      (src_udp_tx_noc0_val_E              )
        ,.src_router_val_S      (src_udp_tx_noc0_val_S              )
        ,.src_router_val_W      (src_udp_tx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val      )
                                
        ,.router_src_yummy_N    (udp_tx_src_noc0_yummy_N            )
        ,.router_src_yummy_E    (udp_tx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (udp_tx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (udp_tx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                 )

        ,.router_dst_data_N     (udp_tx_dst_noc0_data_N             )
        ,.router_dst_data_E     (udp_tx_dst_noc0_data_E             )
        ,.router_dst_data_S     (udp_tx_dst_noc0_data_S             )
        ,.router_dst_data_W     (udp_tx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (udp_tx_dst_noc0_val_N              )
        ,.router_dst_val_E      (udp_tx_dst_noc0_val_E              )
        ,.router_dst_val_S      (udp_tx_dst_noc0_val_S              )
        ,.router_dst_val_W      (udp_tx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_udp_tx_noc0_yummy_N            )
        ,.dst_router_yummy_E    (dst_udp_tx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_udp_tx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_udp_tx_noc0_yummy_W            )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail
    );
    
    beehive_credit_to_valrdy tile_tx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_tx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_tx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_tx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_udp_tx_in_data      )
        ,.ctovr_dst_val     (noc0_ctovr_udp_tx_in_val       )
        ,.dst_ctovr_rdy     (udp_tx_in_noc0_ctovr_rdy       )
    );

    beehive_valrdy_to_credit tile_tx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (lb_noc0_vrtoc_data             )
        ,.src_vrtoc_val     (lb_noc0_vrtoc_val              )
        ,.vrtoc_src_rdy     (noc0_vrtoc_lb_rdy              )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_tx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_tx_router_val  )
		,.dst_vrtoc_yummy   (tile_tx_router_noc0_vrtoc_yummy)
    );

   udp_tx_noc_in tx_noc_in (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_tx_in_val              (noc0_ctovr_udp_tx_in_val               )
        ,.noc0_ctovr_udp_tx_in_data             (noc0_ctovr_udp_tx_in_data              )
        ,.udp_tx_in_noc0_ctovr_rdy              (udp_tx_in_noc0_ctovr_rdy               )
        
        ,.udp_tx_in_udp_to_stream_hdr_val       (udp_tx_in_udp_to_stream_hdr_val        )
        ,.udp_tx_in_udp_to_stream_src_ip_addr   (udp_tx_in_udp_to_stream_src_ip_addr    )
        ,.udp_tx_in_udp_to_stream_dst_ip_addr   (udp_tx_in_udp_to_stream_dst_ip_addr    )
        ,.udp_tx_in_udp_to_stream_udp_hdr       (udp_tx_in_udp_to_stream_udp_hdr        )
        ,.udp_tx_in_udp_to_stream_timestamp     (udp_tx_in_udp_to_stream_timestamp      )
        ,.udp_to_stream_udp_tx_in_hdr_rdy       (udp_to_stream_udp_tx_in_hdr_rdy        )
                                                                                        
        ,.udp_tx_in_udp_to_stream_data_val      (udp_tx_in_udp_to_stream_data_val       )
        ,.udp_tx_in_udp_to_stream_data          (udp_tx_in_udp_to_stream_data           )
        ,.udp_tx_in_udp_to_stream_data_last     (udp_tx_in_udp_to_stream_data_last      )
        ,.udp_tx_in_udp_to_stream_data_padbytes (udp_tx_in_udp_to_stream_data_padbytes  )
        ,.udp_to_stream_udp_tx_in_data_rdy      (udp_to_stream_udp_tx_in_data_rdy       )
    );

    udp_to_stream #(
        .DATA_WIDTH (`MAC_INTERFACE_W   )
    ) udp_to_stream (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_to_stream_hdr_val         (udp_tx_in_udp_to_stream_hdr_val        )
        ,.src_udp_to_stream_src_ip_addr     (udp_tx_in_udp_to_stream_src_ip_addr    )
        ,.src_udp_to_stream_dst_ip_addr     (udp_tx_in_udp_to_stream_dst_ip_addr    )
        ,.src_udp_to_stream_udp_hdr         (udp_tx_in_udp_to_stream_udp_hdr        )
        ,.src_udp_to_stream_timestamp       (udp_tx_in_udp_to_stream_timestamp      )
        ,.udp_to_stream_src_hdr_rdy         (udp_to_stream_udp_tx_in_hdr_rdy        )
        
        ,.src_udp_to_stream_data_val        (udp_tx_in_udp_to_stream_data_val       )
        ,.src_udp_to_stream_data            (udp_tx_in_udp_to_stream_data           )
        ,.src_udp_to_stream_data_last       (udp_tx_in_udp_to_stream_data_last      )
        ,.src_udp_to_stream_data_padbytes   (udp_tx_in_udp_to_stream_data_padbytes  )
        ,.udp_to_stream_src_data_rdy        (udp_to_stream_udp_tx_in_data_rdy       )
    
        ,.udp_to_stream_dst_hdr_val         (udp_to_stream_udp_tx_out_hdr_val       )
        ,.udp_to_stream_dst_src_ip          (udp_to_stream_udp_tx_out_src_ip        )
        ,.udp_to_stream_dst_dst_ip          (udp_to_stream_udp_tx_out_dst_ip        )
        ,.udp_to_stream_dst_udp_len         (udp_to_stream_udp_tx_out_udp_len       )
        ,.udp_to_stream_dst_protocol        (udp_to_stream_udp_tx_out_protocol      )
        ,.udp_to_stream_dst_timestamp       (udp_to_stream_udp_tx_out_timestamp     )
        ,.dst_udp_to_stream_hdr_rdy         (udp_tx_out_udp_to_stream_hdr_rdy       )
        
        ,.udp_to_stream_dst_val             (udp_to_stream_udp_tx_out_val           )
        ,.udp_to_stream_dst_data            (udp_to_stream_udp_tx_out_data          )
        ,.udp_to_stream_dst_last            (udp_to_stream_udp_tx_out_last          )
        ,.udp_to_stream_dst_padbytes        (udp_to_stream_udp_tx_out_padbytes      )
        ,.dst_udp_to_stream_rdy             (udp_tx_out_udp_to_stream_rdy           )
    );

    udp_tx_noc_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) tx_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_tx_out_noc0_vrtoc_val         (udp_tx_out_lb_val                  )
        ,.udp_tx_out_noc0_vrtoc_data        (udp_tx_out_lb_data                 )
        ,.noc0_vrtoc_udp_tx_out_rdy         (lb_udp_tx_out_rdy                  )
                                                                                
        ,.udp_to_stream_udp_tx_out_hdr_val  (udp_to_stream_udp_tx_out_hdr_val   )
        ,.udp_to_stream_udp_tx_out_src_ip   (udp_to_stream_udp_tx_out_src_ip    )
        ,.udp_to_stream_udp_tx_out_dst_ip   (udp_to_stream_udp_tx_out_dst_ip    )
        ,.udp_to_stream_udp_tx_out_udp_len  (udp_to_stream_udp_tx_out_udp_len   )
        ,.udp_to_stream_udp_tx_out_protocol (udp_to_stream_udp_tx_out_protocol  )
        ,.udp_to_stream_udp_tx_out_timestamp(udp_to_stream_udp_tx_out_timestamp )
        ,.udp_tx_out_udp_to_stream_hdr_rdy  (udp_tx_out_udp_to_stream_hdr_rdy   )
                                                                                
        ,.udp_to_stream_udp_tx_out_val      (udp_to_stream_udp_tx_out_val       )
        ,.udp_to_stream_udp_tx_out_data     (udp_to_stream_udp_tx_out_data      )
        ,.udp_to_stream_udp_tx_out_last     (udp_to_stream_udp_tx_out_last      )
        ,.udp_to_stream_udp_tx_out_padbytes (udp_to_stream_udp_tx_out_padbytes  )
        ,.udp_tx_out_udp_to_stream_rdy      (udp_tx_out_udp_to_stream_rdy       )
    );

generate
    if (USE_INT_LB == 1) begin
        udp_tx_lb_out lb (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_udp_tx_lb_val     (udp_tx_out_lb_val  )
            ,.src_udp_tx_lb_data    (udp_tx_out_lb_data )
            ,.udp_tx_lb_src_rdy     (lb_udp_tx_out_rdy  )
        
            ,.udp_tx_lb_dst_val     (lb_noc0_vrtoc_val  )
            ,.udp_tx_lb_dst_data    (lb_noc0_vrtoc_data )
            ,.dst_udp_tx_lb_rdy     (noc0_vrtoc_lb_rdy  )
        );
    end
    else begin
        assign lb_noc0_vrtoc_val = udp_tx_out_lb_val;
        assign lb_noc0_vrtoc_data = udp_tx_out_lb_data;
        assign lb_udp_tx_out_rdy = noc0_vrtoc_lb_rdy;
    end
endgenerate
endmodule
