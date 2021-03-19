`include "echo_app_defs.svh"
module echo_app_rx_tile #(
     parameter RX_SRC_X = -1
    ,parameter RX_SRC_Y = -1
    ,parameter RX_DST_BUF_X = -1
    ,parameter RX_DST_BUF_Y = -1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]                        src_app_tile_rx_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                        src_app_tile_rx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                        src_app_tile_rx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                        src_app_tile_rx_noc0_data_W 
                                                                                 
    ,input                                              src_app_tile_rx_noc0_val_N  
    ,input                                              src_app_tile_rx_noc0_val_E  
    ,input                                              src_app_tile_rx_noc0_val_S  
    ,input                                              src_app_tile_rx_noc0_val_W  
                                                                                 
    ,output                                             app_tile_rx_src_noc0_yummy_N
    ,output                                             app_tile_rx_src_noc0_yummy_E
    ,output                                             app_tile_rx_src_noc0_yummy_S
    ,output                                             app_tile_rx_src_noc0_yummy_W
                                                                                 
    ,output [`NOC_DATA_WIDTH-1:0]                       app_tile_rx_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]                       app_tile_rx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]                       app_tile_rx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]                       app_tile_rx_dst_noc0_data_W 
                                                                                 
    ,output                                             app_tile_rx_dst_noc0_val_N  
    ,output                                             app_tile_rx_dst_noc0_val_E  
    ,output                                             app_tile_rx_dst_noc0_val_S  
    ,output                                             app_tile_rx_dst_noc0_val_W  
                                                                                 
    ,input                                              dst_app_tile_rx_noc0_yummy_N
    ,input                                              dst_app_tile_rx_noc0_yummy_E
    ,input                                              dst_app_tile_rx_noc0_yummy_S
    ,input                                              dst_app_tile_rx_noc0_yummy_W
    
    ,output logic                                       rx_if_tx_if_msg_val
    ,output tx_msg_struct                               rx_if_tx_if_msg_data
    ,input  logic                                       tx_if_rx_if_msg_rdy
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           noc0_vrtoc_tile_tx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_tx_router_data;
    logic                           tile_tx_router_noc0_vrtoc_yummy;

    logic                           tile_tx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_tx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_tx_router_yummy;
    
    logic                           merger_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_merger_rdy;
    
    logic                           tcp_rx_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_tcp_rx_out_rdy;
    
    logic                           noc0_ctovr_splitter_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_data;
    logic                           splitter_noc0_ctovr_rdy;     
    
    logic                           noc0_ctovr_tcp_rx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_rx_in_data;
    logic                           tcp_rx_in_noc0_ctovr_rdy;     
    
    logic                           rx_app_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   rx_app_noc0_vrtoc_data;
    logic                           noc0_vrtoc_rx_app_rdy;

    logic                           noc0_ctovr_rx_app_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rx_app_data;
    logic                           rx_app_noc0_ctovr_rdy;
    
    logic                           rx_buf_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   rx_buf_noc0_vrtoc_data;
    logic                           noc0_vrtoc_rx_buf_rdy;

    logic                           noc0_ctovr_rx_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rx_buf_data;
    logic                           rx_buf_noc0_ctovr_rdy;
    
    logic                           noc0_ctovr_rx_notif_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rx_notif_data;
    logic                           rx_notif_noc0_ctovr_rdy;
    
    dynamic_node_top_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.XY_COORD_W        (`XY_COORD_W        )
        ,.CHIP_ID_W         (`CHIP_ID_WIDTH     )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
    ) tile_rx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_app_rx_noc0_data_N             )
        ,.src_router_data_E     (src_app_rx_noc0_data_E             )
        ,.src_router_data_S     (src_app_rx_noc0_data_S             )
        ,.src_router_data_W     (src_app_rx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_app_rx_noc0_val_N              )
        ,.src_router_val_E      (src_app_rx_noc0_val_E              )
        ,.src_router_val_S      (src_app_rx_noc0_val_S              )
        ,.src_router_val_W      (src_app_rx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (app_rx_src_noc0_yummy_N            )
        ,.router_src_yummy_E    (app_rx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (app_rx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (app_rx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (RX_SRC_X[`XY_WIDTH-1:0]            )
        ,.myLocY                (RX_SRC_Y[`XY_WIDTH-1:0]            )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (app_rx_dst_noc0_data_N             )
        ,.router_dst_data_E     (app_rx_dst_noc0_data_E             )
        ,.router_dst_data_S     (app_rx_dst_noc0_data_S             )
        ,.router_dst_data_W     (app_rx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (app_rx_dst_noc0_val_N              )
        ,.router_dst_val_E      (app_rx_dst_noc0_val_E              )
        ,.router_dst_val_S      (app_rx_dst_noc0_val_S              )
        ,.router_dst_val_W      (app_rx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_app_rx_noc0_yummy_N            )
        ,.dst_router_yummy_E    (dst_app_rx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_app_rx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_app_rx_noc0_yummy_W            )
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
        ,.ctovr_dst_data    (noc0_ctovr_splitter_data       )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_val        )
        ,.dst_ctovr_rdy     (splitter_noc0_ctovr_rdy        )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_noc0_vrtoc_data        )
        ,.src_vrtoc_val     (merger_noc0_vrtoc_val         )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_rdy         )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );
endmodule
