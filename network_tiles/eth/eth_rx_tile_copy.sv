`include "eth_rx_tile_defs.svh"
module eth_rx_tile_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter USE_INT_LB = 1
) (
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_rx_noc0_data_N // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_rx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_rx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_rx_noc0_data_W 
                                                                     
    ,input                                  src_eth_rx_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_eth_rx_noc0_val_E  
    ,input                                  src_eth_rx_noc0_val_S  
    ,input                                  src_eth_rx_noc0_val_W  
                                                                     
    ,output                                 eth_rx_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 eth_rx_src_noc0_yummy_E
    ,output                                 eth_rx_src_noc0_yummy_S
    ,output                                 eth_rx_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           eth_rx_dst_noc0_data_N // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           eth_rx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           eth_rx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           eth_rx_dst_noc0_data_W 
                                                                     
    ,output                                 eth_rx_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 eth_rx_dst_noc0_val_E  
    ,output                                 eth_rx_dst_noc0_val_S  
    ,output                                 eth_rx_dst_noc0_val_W  
                                                                     
    ,input                                  dst_eth_rx_noc0_yummy_N// neighbor consumed output data
    ,input                                  dst_eth_rx_noc0_yummy_E
    ,input                                  dst_eth_rx_noc0_yummy_S
    ,input                                  dst_eth_rx_noc0_yummy_W
);
    
    logic                           eth_rx_out_lb_val;
    logic   [`NOC_DATA_WIDTH-1:0]   eth_rx_out_lb_data;    
    logic                           lb_eth_rx_out_rdy;
    
    logic                           lb_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   lb_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_lb_rdy;
    
    logic                           noc0_ctovr_eth_rx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_eth_rx_in_data;
    logic                           eth_rx_in_noc0_ctovr_rdy;     

    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    eth_hdr                         eth_format_eth_rx_out_eth_hdr;
    logic                           eth_format_eth_rx_out_hdr_val;
    logic   [`MTU_SIZE_W-1:0]       eth_format_eth_rx_out_data_size;
    logic                           eth_rx_out_eth_format_hdr_rdy;

    logic                           eth_format_eth_rx_out_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  eth_format_eth_rx_out_data;
    logic                           eth_rx_out_eth_format_data_rdy;
    logic                           eth_format_eth_rx_out_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   eth_format_eth_rx_out_data_padbytes;
    
    logic                           eth_rx_in_eth_format_val;
    logic   [`MAC_INTERFACE_W-1:0]  eth_rx_in_eth_format_data;
    logic   [`MTU_SIZE_W-1:0]       eth_rx_in_eth_format_frame_size;
    logic                           eth_rx_in_eth_format_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   eth_rx_in_eth_format_data_padbytes;
    logic                           eth_format_eth_rx_in_rdy;
    
    dynamic_node_top_wrap tile_rx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_eth_rx_noc0_data_N             )// data inputs from neighboring tiles
        ,.src_router_data_E     (src_eth_rx_noc0_data_E             )
        ,.src_router_data_S     (src_eth_rx_noc0_data_S             )
        ,.src_router_data_W     (src_eth_rx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )// data input from processor
                                
        ,.src_router_val_N      (src_eth_rx_noc0_val_N              )// valid signals from neighboring tiles
        ,.src_router_val_E      (src_eth_rx_noc0_val_E              )
        ,.src_router_val_S      (src_eth_rx_noc0_val_S              )
        ,.src_router_val_W      (src_eth_rx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )// valid signal from processor
                                
        ,.router_src_yummy_N    (eth_rx_src_noc0_yummy_N            )// yummy signal to neighbors' output buffers
        ,.router_src_yummy_E    (eth_rx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (eth_rx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (eth_rx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )// yummy signal to processor's output buffer
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )// this tile's position
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (eth_rx_dst_noc0_data_N             )// data outputs to neighbors
        ,.router_dst_data_E     (eth_rx_dst_noc0_data_E             )
        ,.router_dst_data_S     (eth_rx_dst_noc0_data_S             )
        ,.router_dst_data_W     (eth_rx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )// data output to processor
                            
        ,.router_dst_val_N      (eth_rx_dst_noc0_val_N              )// valid outputs to neighbors
        ,.router_dst_val_E      (eth_rx_dst_noc0_val_E              )
        ,.router_dst_val_S      (eth_rx_dst_noc0_val_S              )
        ,.router_dst_val_W      (eth_rx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )// valid output to processor
                            
        ,.dst_router_yummy_N    (dst_eth_rx_noc0_yummy_N            )// neighbor consumed output data
        ,.dst_router_yummy_E    (dst_eth_rx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_eth_rx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_eth_rx_noc0_yummy_W            )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_rx_router_yummy    )// processor consumed output data
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy tile_rx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_rx_router_noc0_ctovr_data     )
        ,.src_ctovr_val     (tile_rx_router_noc0_ctovr_val      )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_rx_router_yummy    )

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_eth_rx_in_data          )
        ,.ctovr_dst_val     (noc0_ctovr_eth_rx_in_val           )
        ,.dst_ctovr_rdy     (eth_rx_in_noc0_ctovr_rdy           )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (lb_noc0_vrtoc_data                 )
        ,.src_vrtoc_val     (lb_noc0_vrtoc_val                  )
        ,.vrtoc_src_rdy     (noc0_vrtoc_lb_rdy                  )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data     )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val      )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy    )
    );

    eth_rx_noc_in eth_rx_noc_in (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc_eth_rx_in_val             (noc0_ctovr_eth_rx_in_val           )
        ,.noc_eth_rx_in_data            (noc0_ctovr_eth_rx_in_data          )
        ,.eth_rx_in_noc_rdy             (eth_rx_in_noc0_ctovr_rdy           )
    
        ,.eth_rx_in_dst_val             (eth_rx_in_eth_format_val           )
        ,.eth_rx_in_dst_data            (eth_rx_in_eth_format_data          )
        ,.eth_rx_in_dst_frame_size      (eth_rx_in_eth_format_frame_size    )
        ,.eth_rx_in_dst_data_last       (eth_rx_in_eth_format_data_last     )
        ,.eth_rx_in_dst_data_padbytes   (eth_rx_in_eth_format_data_padbytes )
        ,.dst_eth_rx_in_rdy             (eth_format_eth_rx_in_rdy           )
    );

    eth_frame_format rx_eth_frame_format (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_eth_format_val            (eth_rx_in_eth_format_val               )
        ,.src_eth_format_data           (eth_rx_in_eth_format_data              )
        ,.src_eth_format_frame_size     (eth_rx_in_eth_format_frame_size        )
        ,.src_eth_format_data_last      (eth_rx_in_eth_format_data_last         )
        ,.src_eth_format_data_padbytes  (eth_rx_in_eth_format_data_padbytes     )
        ,.eth_format_src_rdy            (eth_format_eth_rx_in_rdy               )

        ,.eth_format_dst_eth_hdr        (eth_format_eth_rx_out_eth_hdr          )
        ,.eth_format_dst_data_size      (eth_format_eth_rx_out_data_size        )
        ,.eth_format_dst_hdr_val        (eth_format_eth_rx_out_hdr_val          )
        ,.dst_eth_format_hdr_rdy        (eth_rx_out_eth_format_hdr_rdy          )

        ,.eth_format_dst_data_val       (eth_format_eth_rx_out_data_val         )
        ,.eth_format_dst_data           (eth_format_eth_rx_out_data             )
        ,.eth_format_dst_data_last      (eth_format_eth_rx_out_data_last        )
        ,.eth_format_dst_data_padbytes  (eth_format_eth_rx_out_data_padbytes    )
        ,.dst_eth_format_data_rdy       (eth_rx_out_eth_format_data_rdy         )
    );

    eth_rx_noc_out_copy #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) eth_rx_noc_out (
         .clk   (clk)
        ,.rst   (rst)
                                                 
        ,.eth_rx_out_noc0_vrtoc_val             (eth_rx_out_lb_val                  )
        ,.eth_rx_out_noc0_vrtoc_data            (eth_rx_out_lb_data                 )
        ,.noc0_vrtoc_eth_rx_out_rdy             (lb_eth_rx_out_rdy                  )
                                                                                    
        ,.eth_format_eth_rx_out_eth_hdr         (eth_format_eth_rx_out_eth_hdr      )
        ,.eth_format_eth_rx_out_hdr_val         (eth_format_eth_rx_out_hdr_val      )
        ,.eth_format_eth_rx_out_data_size       (eth_format_eth_rx_out_data_size    )
        ,.eth_rx_out_eth_format_hdr_rdy         (eth_rx_out_eth_format_hdr_rdy      )
                                                                                    
        ,.eth_format_eth_rx_out_data_val        (eth_format_eth_rx_out_data_val     )
        ,.eth_format_eth_rx_out_data            (eth_format_eth_rx_out_data         )
        ,.eth_rx_out_eth_format_data_rdy        (eth_rx_out_eth_format_data_rdy     )
        ,.eth_format_eth_rx_out_data_last       (eth_format_eth_rx_out_data_last    )
        ,.eth_format_eth_rx_out_data_padbytes   (eth_format_eth_rx_out_data_padbytes)
    );

generate
    if (USE_INT_LB == 1) begin
        eth_rx_lb_out lb_out (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_eth_rx_lb_noc_val     (eth_rx_out_lb_val  )
            ,.src_eth_rx_lb_noc_data    (eth_rx_out_lb_data )
            ,.eth_rx_lb_src_noc_rdy     (lb_eth_rx_out_rdy  )
        
            ,.eth_rx_lb_dst_noc_val     (lb_noc0_vrtoc_val  )
            ,.eth_rx_lb_dst_noc_data    (lb_noc0_vrtoc_data )
            ,.dst_eth_rx_lb_noc_rdy     (noc0_vrtoc_lb_rdy  )
        );
    end
    else begin
        assign lb_noc0_vrtoc_val = eth_rx_out_lb_val;
        assign lb_noc0_vrtoc_data = eth_rx_out_lb_data;
        assign lb_eth_rx_out_rdy = noc0_vrtoc_lb_rdy;
    end
endgenerate

endmodule
