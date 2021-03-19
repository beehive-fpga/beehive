module rs_encode_rx_scheduler_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NUM_DSTS = -1
    ,parameter NUM_DSTS_W = (NUM_DSTS == 1) ? 1 : $clog2(NUM_DSTS)
)(
     input clk
    ,input rst 
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_rs_rx_scheduler_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_rs_rx_scheduler_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_rs_rx_scheduler_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_rs_rx_scheduler_noc0_data_W 
                                                                             
    ,input                                          src_rs_rx_scheduler_noc0_val_N  
    ,input                                          src_rs_rx_scheduler_noc0_val_E  
    ,input                                          src_rs_rx_scheduler_noc0_val_S  
    ,input                                          src_rs_rx_scheduler_noc0_val_W  
                                                                             
    ,output                                         rs_rx_scheduler_src_noc0_yummy_N
    ,output                                         rs_rx_scheduler_src_noc0_yummy_E
    ,output                                         rs_rx_scheduler_src_noc0_yummy_S
    ,output                                         rs_rx_scheduler_src_noc0_yummy_W
                                                                             
    ,output [`NOC_DATA_WIDTH-1:0]                   rs_rx_scheduler_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]                   rs_rx_scheduler_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]                   rs_rx_scheduler_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]                   rs_rx_scheduler_dst_noc0_data_W 
                                                                             
    ,output                                         rs_rx_scheduler_dst_noc0_val_N  
    ,output                                         rs_rx_scheduler_dst_noc0_val_E  
    ,output                                         rs_rx_scheduler_dst_noc0_val_S  
    ,output                                         rs_rx_scheduler_dst_noc0_val_W  
                                                                             
    ,input                                          dst_rs_rx_scheduler_noc0_yummy_N
    ,input                                          dst_rs_rx_scheduler_noc0_yummy_E
    ,input                                          dst_rs_rx_scheduler_noc0_yummy_S
    ,input                                          dst_rs_rx_scheduler_noc0_yummy_W
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           rs_rx_scheduler_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   rs_rx_scheduler_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_rs_rx_scheduler_rdy;
    
    logic                           noc0_ctovr_rs_rx_scheduler_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rs_rx_scheduler_data;
    logic                           rs_rx_scheduler_noc0_ctovr_rdy;

    logic                           scheduler_table_read_val;
    logic   [NUM_DSTS_W-1:0]        scheduler_table_read_index;
    logic                           table_scheduler_read_rdy;

    logic                           table_scheduler_read_resp_val;
    sched_table_struct              table_scheduler_read_resp_data;
    logic                           scheduler_table_read_resp_rdy;
    
    dynamic_node_top_wrap tile_rx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_rs_rx_scheduler_noc0_data_N    )
        ,.src_router_data_E     (src_rs_rx_scheduler_noc0_data_E    )
        ,.src_router_data_S     (src_rs_rx_scheduler_noc0_data_S    )
        ,.src_router_data_W     (src_rs_rx_scheduler_noc0_data_W    )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_rs_rx_scheduler_noc0_val_N     )
        ,.src_router_val_E      (src_rs_rx_scheduler_noc0_val_E     )
        ,.src_router_val_S      (src_rs_rx_scheduler_noc0_val_S     )
        ,.src_router_val_W      (src_rs_rx_scheduler_noc0_val_W     )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (rs_rx_scheduler_src_noc0_yummy_N   )
        ,.router_src_yummy_E    (rs_rx_scheduler_src_noc0_yummy_E   )
        ,.router_src_yummy_S    (rs_rx_scheduler_src_noc0_yummy_S   )
        ,.router_src_yummy_W    (rs_rx_scheduler_src_noc0_yummy_W   )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (rs_rx_scheduler_dst_noc0_data_N    )
        ,.router_dst_data_E     (rs_rx_scheduler_dst_noc0_data_E    )
        ,.router_dst_data_S     (rs_rx_scheduler_dst_noc0_data_S    )
        ,.router_dst_data_W     (rs_rx_scheduler_dst_noc0_data_W    )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (rs_rx_scheduler_dst_noc0_val_N     )
        ,.router_dst_val_E      (rs_rx_scheduler_dst_noc0_val_E     )
        ,.router_dst_val_S      (rs_rx_scheduler_dst_noc0_val_S     )
        ,.router_dst_val_W      (rs_rx_scheduler_dst_noc0_val_W     )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_rs_rx_scheduler_noc0_yummy_N   )
        ,.dst_router_yummy_E    (dst_rs_rx_scheduler_noc0_yummy_E   )
        ,.dst_router_yummy_S    (dst_rs_rx_scheduler_noc0_yummy_S   )
        ,.dst_router_yummy_W    (dst_rs_rx_scheduler_noc0_yummy_W   )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_rx_router_yummy    )
        
        
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
        ,.ctovr_dst_data    (noc0_ctovr_rs_rx_scheduler_data    )
        ,.ctovr_dst_val     (noc0_ctovr_rs_rx_scheduler_val     )
        ,.dst_ctovr_rdy     (rs_rx_scheduler_noc0_ctovr_rdy     )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (rs_rx_scheduler_noc0_vrtoc_data    )
        ,.src_vrtoc_val     (rs_rx_scheduler_noc0_vrtoc_val     )
        ,.vrtoc_src_rdy     (noc0_vrtoc_rs_rx_scheduler_rdy     )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data     )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val      )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy    )
    );

    rr_scheduler #(
         .SRC_X     (SRC_X      )
        ,.SRC_Y     (SRC_Y      )
        ,.NUM_DSTS  (NUM_DSTS   )
    ) scheduler (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_rr_scheduler_val              (noc0_ctovr_rs_rx_scheduler_val )
        ,.src_rr_scheduler_data             (noc0_ctovr_rs_rx_scheduler_data)
        ,.rr_scheduler_src_rdy              (rs_rx_scheduler_noc0_ctovr_rdy )
        
        ,.rr_scheduler_dst_val              (rs_rx_scheduler_noc0_vrtoc_val )
        ,.rr_scheduler_dst_data             (rs_rx_scheduler_noc0_vrtoc_data)
        ,.dst_rr_scheduler_rdy              (noc0_vrtoc_rs_rx_scheduler_rdy )
    
        ,.scheduler_table_read_val          (scheduler_table_read_val       )
        ,.scheduler_table_read_index        (scheduler_table_read_index     )
        ,.table_scheduler_read_rdy          (table_scheduler_read_rdy       )
                                                                            
        ,.table_scheduler_read_resp_val     (table_scheduler_read_resp_val  )
        ,.table_scheduler_read_resp_data    (table_scheduler_read_resp_data )
        ,.scheduler_table_read_resp_rdy     (scheduler_table_read_resp_rdy  )
    );

    rs_encode_rx_scheduler_table #(
         .NUM_DSTS  (NUM_DSTS)
    ) scheduler_table (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.scheduler_table_read_val          (scheduler_table_read_val       )
        ,.scheduler_table_read_index        (scheduler_table_read_index     )
        ,.table_scheduler_read_rdy          (table_scheduler_read_rdy       )
                                                                            
        ,.table_scheduler_read_resp_val     (table_scheduler_read_resp_val  )
        ,.table_scheduler_read_resp_data    (table_scheduler_read_resp_data )
        ,.scheduler_table_read_resp_rdy     (scheduler_table_read_resp_rdy  )
    );
endmodule
