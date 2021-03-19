`include "ip_rx_tile_defs.svh"
module ip_rx_tile_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter USE_INT_LB = 1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rx_noc0_data_N // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rx_noc0_data_W 
                                                                     
    ,input                                  src_ip_rx_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_ip_rx_noc0_val_E  
    ,input                                  src_ip_rx_noc0_val_S  
    ,input                                  src_ip_rx_noc0_val_W  
                                                                     
    ,output                                 ip_rx_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 ip_rx_src_noc0_yummy_E
    ,output                                 ip_rx_src_noc0_yummy_S
    ,output                                 ip_rx_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rx_dst_noc0_data_N // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rx_dst_noc0_data_W 
                                                                     
    ,output                                 ip_rx_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 ip_rx_dst_noc0_val_E  
    ,output                                 ip_rx_dst_noc0_val_S  
    ,output                                 ip_rx_dst_noc0_val_W  
                                                                     
    ,input                                  dst_ip_rx_noc0_yummy_N// neighbor consumed output data
    ,input                                  dst_ip_rx_noc0_yummy_E
    ,input                                  dst_ip_rx_noc0_yummy_S
    ,input                                  dst_ip_rx_noc0_yummy_W
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           ip_rx_out_lb_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ip_rx_out_lb_data;    
    logic                           lb_ip_rx_out_rdy;
    
    logic                           lb_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   lb_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_lb_rdy;
    
    logic                           noc0_ctovr_ip_rx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_rx_in_data;
    logic                           ip_rx_in_noc0_ctovr_rdy;     
    
    logic                           ip_rx_in_ip_format_rx_val;
    logic   [MSG_TIMESTAMP_W-1:0]   ip_rx_in_ip_format_rx_timestamp;
    logic   [`MAC_INTERFACE_W-1:0]  ip_rx_in_ip_format_rx_data;
    logic                           ip_rx_in_ip_format_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   ip_rx_in_ip_format_rx_padbytes;
    logic                           ip_format_ip_rx_in_rx_rdy;
    
    logic                           ip_format_ip_rx_out_rx_hdr_val;
    ip_pkt_hdr                      ip_format_ip_rx_out_rx_ip_hdr;
    logic   [MSG_TIMESTAMP_W-1:0]   ip_format_ip_rx_out_rx_timestamp;
    logic                           ip_rx_out_ip_format_rx_hdr_rdy;

    logic                           ip_format_ip_rx_out_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  ip_format_ip_rx_out_rx_data;
    logic                           ip_format_ip_rx_out_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   ip_format_ip_rx_out_rx_padbytes;
    logic                           ip_rx_out_ip_format_rx_data_rdy;
    
    dynamic_node_top_wrap tile_rx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_ip_rx_noc0_data_N              )
        ,.src_router_data_E     (src_ip_rx_noc0_data_E              )
        ,.src_router_data_S     (src_ip_rx_noc0_data_S              )
        ,.src_router_data_W     (src_ip_rx_noc0_data_W              )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_ip_rx_noc0_val_N               )
        ,.src_router_val_E      (src_ip_rx_noc0_val_E               )
        ,.src_router_val_S      (src_ip_rx_noc0_val_S               )
        ,.src_router_val_W      (src_ip_rx_noc0_val_W               )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (ip_rx_src_noc0_yummy_N             )
        ,.router_src_yummy_E    (ip_rx_src_noc0_yummy_E             )
        ,.router_src_yummy_S    (ip_rx_src_noc0_yummy_S             )
        ,.router_src_yummy_W    (ip_rx_src_noc0_yummy_W             )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (ip_rx_dst_noc0_data_N              )
        ,.router_dst_data_E     (ip_rx_dst_noc0_data_E              )
        ,.router_dst_data_S     (ip_rx_dst_noc0_data_S              )
        ,.router_dst_data_W     (ip_rx_dst_noc0_data_W              )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (ip_rx_dst_noc0_val_N               )
        ,.router_dst_val_E      (ip_rx_dst_noc0_val_E               )
        ,.router_dst_val_S      (ip_rx_dst_noc0_val_S               )
        ,.router_dst_val_W      (ip_rx_dst_noc0_val_W               )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_ip_rx_noc0_yummy_N             )
        ,.dst_router_yummy_E    (dst_ip_rx_noc0_yummy_E             )
        ,.dst_router_yummy_S    (dst_ip_rx_noc0_yummy_S             )
        ,.dst_router_yummy_W    (dst_ip_rx_noc0_yummy_W             )
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
        ,.ctovr_dst_data    (noc0_ctovr_ip_rx_in_data      )
        ,.ctovr_dst_val     (noc0_ctovr_ip_rx_in_val       )
        ,.dst_ctovr_rdy     (ip_rx_in_noc0_ctovr_rdy       )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (lb_noc0_vrtoc_data             )
        ,.src_vrtoc_val     (lb_noc0_vrtoc_val              )
        ,.vrtoc_src_rdy     (noc0_vrtoc_lb_rdy              )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );

    ip_rx_noc_in ip_rx_noc_in (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_rx_in_val           (noc0_ctovr_ip_rx_in_val        )
        ,.noc0_ctovr_ip_rx_in_data          (noc0_ctovr_ip_rx_in_data       )
        ,.ip_rx_in_noc0_ctovr_rdy           (ip_rx_in_noc0_ctovr_rdy        )
                                                                            
        ,.ip_rx_in_ip_format_rx_val         (ip_rx_in_ip_format_rx_val      )
        ,.ip_rx_in_ip_format_rx_timestamp   (ip_rx_in_ip_format_rx_timestamp)
        ,.ip_rx_in_ip_format_rx_data        (ip_rx_in_ip_format_rx_data     )
        ,.ip_rx_in_ip_format_rx_last        (ip_rx_in_ip_format_rx_last     )
        ,.ip_rx_in_ip_format_rx_padbytes    (ip_rx_in_ip_format_rx_padbytes )
        ,.ip_format_ip_rx_in_rx_rdy         (ip_format_ip_rx_in_rx_rdy      )
    );

    ip_stream_format_pipe #(
        .DATA_WIDTH (`NOC_DATA_WIDTH    )
    ) ip_format (
         .clk   (clk)
        ,.rst   (rst)
        
        // Data stream in from MAC
        ,.src_ip_format_rx_val      (ip_rx_in_ip_format_rx_val          )
        ,.src_ip_format_rx_timestamp(ip_rx_in_ip_format_rx_timestamp    )
        ,.ip_format_src_rx_rdy      (ip_format_ip_rx_in_rx_rdy          )
        ,.src_ip_format_rx_data     (ip_rx_in_ip_format_rx_data         )
        ,.src_ip_format_rx_last     (ip_rx_in_ip_format_rx_last         )
        ,.src_ip_format_rx_padbytes (ip_rx_in_ip_format_rx_padbytes     )

        // Header and data out
        ,.ip_format_dst_rx_hdr_val  (ip_format_ip_rx_out_rx_hdr_val     )
        ,.ip_format_dst_rx_ip_hdr   (ip_format_ip_rx_out_rx_ip_hdr      )
        ,.ip_format_dst_rx_timestamp(ip_format_ip_rx_out_rx_timestamp   )
        ,.dst_ip_format_rx_hdr_rdy  (ip_rx_out_ip_format_rx_hdr_rdy     )

        ,.ip_format_dst_rx_data_val (ip_format_ip_rx_out_rx_data_val    )
        ,.ip_format_dst_rx_data     (ip_format_ip_rx_out_rx_data        )
        ,.ip_format_dst_rx_last     (ip_format_ip_rx_out_rx_last        )
        ,.ip_format_dst_rx_padbytes (ip_format_ip_rx_out_rx_padbytes    )
        ,.dst_ip_format_rx_data_rdy (ip_rx_out_ip_format_rx_data_rdy    )
    );

    ip_rx_noc_out_copy #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) rx_noc_out (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.ip_format_ip_rx_out_rx_hdr_val    (ip_format_ip_rx_out_rx_hdr_val     )
        ,.ip_format_ip_rx_out_rx_ip_hdr     (ip_format_ip_rx_out_rx_ip_hdr      )
        ,.ip_format_ip_rx_out_rx_timestamp  (ip_format_ip_rx_out_rx_timestamp   )
        ,.ip_rx_out_ip_format_rx_hdr_rdy    (ip_rx_out_ip_format_rx_hdr_rdy     )
                                                                                
        ,.ip_format_ip_rx_out_rx_data_val   (ip_format_ip_rx_out_rx_data_val    )
        ,.ip_format_ip_rx_out_rx_data       (ip_format_ip_rx_out_rx_data        )
        ,.ip_format_ip_rx_out_rx_last       (ip_format_ip_rx_out_rx_last        )
        ,.ip_format_ip_rx_out_rx_padbytes   (ip_format_ip_rx_out_rx_padbytes    )
        ,.ip_rx_out_ip_format_rx_data_rdy   (ip_rx_out_ip_format_rx_data_rdy    )
        
        ,.ip_rx_out_noc0_vrtoc_val          (ip_rx_out_lb_val                   )
        ,.ip_rx_out_noc0_vrtoc_data         (ip_rx_out_lb_data                  )
        ,.noc0_vrtoc_ip_rx_out_rdy          (lb_ip_rx_out_rdy                   )
    );

generate
    if (USE_INT_LB == 1) begin
        ip_rx_lb_out lb (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_ip_rx_lb_val  (ip_rx_out_lb_val   )
            ,.src_ip_rx_lb_data (ip_rx_out_lb_data  )
            ,.ip_rx_lb_src_rdy  (lb_ip_rx_out_rdy   )
        
            ,.ip_rx_lb_dst_val  (lb_noc0_vrtoc_val  )
            ,.ip_rx_lb_dst_data (lb_noc0_vrtoc_data )
            ,.dst_ip_rx_lb_rdy  (noc0_vrtoc_lb_rdy  )
        );
    end
    else begin
        assign lb_noc0_vrtoc_val = ip_rx_out_lb_val;
        assign lb_noc0_vrtoc_data = ip_rx_out_lb_data;
        assign lb_ip_rx_out_rdy = noc0_vrtoc_lb_rdy;
    end
endgenerate

endmodule
