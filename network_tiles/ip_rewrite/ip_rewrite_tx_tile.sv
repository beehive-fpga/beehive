module ip_rewrite_tx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rewrite_tx_noc0_data_N // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rewrite_tx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rewrite_tx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_rewrite_tx_noc0_data_W 
                                                                     
    ,input                                  src_ip_rewrite_tx_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_ip_rewrite_tx_noc0_val_E  
    ,input                                  src_ip_rewrite_tx_noc0_val_S  
    ,input                                  src_ip_rewrite_tx_noc0_val_W  
                                                                     
    ,output                                 ip_rewrite_tx_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 ip_rewrite_tx_src_noc0_yummy_E
    ,output                                 ip_rewrite_tx_src_noc0_yummy_S
    ,output                                 ip_rewrite_tx_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rewrite_tx_dst_noc0_data_N // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rewrite_tx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rewrite_tx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_rewrite_tx_dst_noc0_data_W 
                                                                     
    ,output                                 ip_rewrite_tx_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 ip_rewrite_tx_dst_noc0_val_E  
    ,output                                 ip_rewrite_tx_dst_noc0_val_S  
    ,output                                 ip_rewrite_tx_dst_noc0_val_W  
                                                                     
    ,input                                  dst_ip_rewrite_tx_noc0_yummy_N// neighbor consumed output data
    ,input                                  dst_ip_rewrite_tx_noc0_yummy_E
    ,input                                  dst_ip_rewrite_tx_noc0_yummy_S
    ,input                                  dst_ip_rewrite_tx_noc0_yummy_W
);
    logic                           noc0_vrtoc_tile_tx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_tx_router_data;
    logic                           tile_tx_router_noc0_vrtoc_yummy;

    logic                           tile_tx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_tx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_tx_router_yummy;
    
    logic                           merger_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_merger_out_rdy;
    
    logic                           ip_rewrite_tx_out_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_tx_out_merger_data;    
    logic                           merger_ip_rewrite_tx_out_rdy;
    
    logic                           lookup_ctrl_out_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   lookup_ctrl_out_merger_data;    
    logic                           merger_lookup_ctrl_out_rdy;
    
    logic                           noc0_ctovr_splitter_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_in_data;
    logic                           splitter_in_noc0_ctovr_rdy;     
    
    logic                           splitter_ip_rewrite_tx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_ip_rewrite_tx_in_data;
    logic                           ip_rewrite_tx_in_splitter_rdy;     
    
    logic                           splitter_lookup_ctrl_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_lookup_ctrl_in_data;
    logic                           lookup_ctrl_in_splitter_rdy;     
    
    dynamic_node_top_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.XY_COORD_W        (`XY_WIDTH          )
        ,.CHIP_ID_W         (`CHIP_ID_WIDTH     )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
    ) tile_tx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_ip_rewrite_tx_noc0_data_N      )
        ,.src_router_data_E     (src_ip_rewrite_tx_noc0_data_E      )
        ,.src_router_data_S     (src_ip_rewrite_tx_noc0_data_S      )
        ,.src_router_data_W     (src_ip_rewrite_tx_noc0_data_W      )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data     )
                                
        ,.src_router_val_N      (src_ip_rewrite_tx_noc0_val_N       )
        ,.src_router_val_E      (src_ip_rewrite_tx_noc0_val_E       )
        ,.src_router_val_S      (src_ip_rewrite_tx_noc0_val_S       )
        ,.src_router_val_W      (src_ip_rewrite_tx_noc0_val_W       )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val      )
                                
        ,.router_src_yummy_N    (ip_rewrite_tx_src_noc0_yummy_N     )
        ,.router_src_yummy_E    (ip_rewrite_tx_src_noc0_yummy_E     )
        ,.router_src_yummy_S    (ip_rewrite_tx_src_noc0_yummy_S     )
        ,.router_src_yummy_W    (ip_rewrite_tx_src_noc0_yummy_W     )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (ip_rewrite_tx_dst_noc0_data_N      )
        ,.router_dst_data_E     (ip_rewrite_tx_dst_noc0_data_E      )
        ,.router_dst_data_S     (ip_rewrite_tx_dst_noc0_data_S      )
        ,.router_dst_data_W     (ip_rewrite_tx_dst_noc0_data_W      )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (ip_rewrite_tx_dst_noc0_val_N       )
        ,.router_dst_val_E      (ip_rewrite_tx_dst_noc0_val_E       )
        ,.router_dst_val_S      (ip_rewrite_tx_dst_noc0_val_S       )
        ,.router_dst_val_W      (ip_rewrite_tx_dst_noc0_val_W       )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_ip_rewrite_tx_noc0_yummy_N     )
        ,.dst_router_yummy_E    (dst_ip_rewrite_tx_noc0_yummy_E     )
        ,.dst_router_yummy_S    (dst_ip_rewrite_tx_noc0_yummy_S     )
        ,.dst_router_yummy_W    (dst_ip_rewrite_tx_noc0_yummy_W     )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_tx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_tx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_tx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_tx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_splitter_in_data    )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_in_val     )
        ,.dst_ctovr_rdy     (splitter_in_noc0_ctovr_rdy     )
    );

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_tx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_out_noc0_vrtoc_data     )
        ,.src_vrtoc_val     (merger_out_noc0_vrtoc_val      )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_out_rdy      )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_tx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_tx_router_val  )
		,.dst_vrtoc_yummy   (tile_tx_router_noc0_vrtoc_yummy)
    );
    
    // merge NoC traffic for sending data from the TCP engine to DRAM buffers and
    // traffic for answering whether or not data is available
    noc_prio_merger #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.num_sources       (2)
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (ip_rewrite_tx_out_merger_val   )
        ,.src0_merger_vr_noc_dat    (ip_rewrite_tx_out_merger_data  )
        ,.merger_src0_vr_noc_rdy    (merger_ip_rewrite_tx_out_rdy   )
    
        ,.src1_merger_vr_noc_val    (lookup_ctrl_out_merger_val     )
        ,.src1_merger_vr_noc_dat    (lookup_ctrl_out_merger_data    )
        ,.merger_src1_vr_noc_rdy    (merger_lookup_ctrl_out_rdy     )
    
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

    // split between the app interface requests and the buffer copy module response
    noc_fbits_splitter #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.FBITS_HI          (`MSG_DST_FBITS_HI  )
        ,.FBITS_LO          (`MSG_DST_FBITS_LO  )
        ,.num_targets       (3'd2)
        ,.fbits_type0       (PKT_IF_FBITS                   )
        ,.fbits_type1       (IP_REWRITE_TABLE_CTRL_FBITS    )
    ) splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_in_val     )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_in_data    )
        ,.splitter_src_vr_noc_rdy   (splitter_in_noc0_ctovr_rdy     )

        ,.splitter_dst0_vr_noc_val  (splitter_ip_rewrite_tx_in_val  )
        ,.splitter_dst0_vr_noc_dat  (splitter_ip_rewrite_tx_in_data )
        ,.dst0_splitter_vr_noc_rdy  (ip_rewrite_tx_in_splitter_rdy  )

        ,.splitter_dst1_vr_noc_val  (splitter_lookup_ctrl_in_val    )
        ,.splitter_dst1_vr_noc_dat  (splitter_lookup_ctrl_in_data   )
        ,.dst1_splitter_vr_noc_rdy  (lookup_ctrl_in_splitter_rdy    )

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

    ip_rewrite_noc_tx #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) rewrite_noc_tx (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_in_val      (splitter_ip_rewrite_tx_in_val  )
        ,.noc0_ctovr_ip_rewrite_in_data     (splitter_ip_rewrite_tx_in_data )
        ,.ip_rewrite_in_noc0_ctovr_rdy      (ip_rewrite_tx_in_splitter_rdy  )
                                                                                
        ,.ip_rewrite_out_noc0_vrtoc_val     (ip_rewrite_tx_out_merger_val   )
        ,.ip_rewrite_out_noc0_vrtoc_data    (ip_rewrite_tx_out_merger_data  )
        ,.noc0_vrtoc_ip_rewrite_out_rdy     (merger_ip_rewrite_tx_out_rdy   )
                                                                                
        ,.noc0_ctovr_lookup_ctrl_in_val     (splitter_lookup_ctrl_in_val    )
        ,.noc0_ctovr_lookup_ctrl_in_data    (splitter_lookup_ctrl_in_data   )
        ,.lookup_ctrl_in_noc0_ctovr_rdy     (lookup_ctrl_in_splitter_rdy    )
                                                                                
        ,.lookup_ctrl_out_noc0_vrtoc_val    (lookup_ctrl_out_merger_val     )
        ,.lookup_ctrl_out_noc0_vrtoc_data   (lookup_ctrl_out_merger_data    )
        ,.noc0_vrtoc_lookup_ctrl_out_rdy    (merger_lookup_ctrl_out_rdy     )
    );
endmodule
