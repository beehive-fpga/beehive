`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager_noc_if #(
     parameter RX_SRC_X = -1
    ,parameter RX_SRC_Y = -1
    ,parameter TX_SRC_X = -1
    ,parameter TX_SRC_Y = -1
)(
     input clk
    ,input rst 

    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_W

    ,input                                          src_ip_rewrite_manager_rx_noc0_val_N
    ,input                                          src_ip_rewrite_manager_rx_noc0_val_E
    ,input                                          src_ip_rewrite_manager_rx_noc0_val_S
    ,input                                          src_ip_rewrite_manager_rx_noc0_val_W

    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_N
    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_E
    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_S
    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_W

    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_N
    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_E
    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_S
    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_W

    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_N
    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_E
    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_S
    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_W
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_W

    ,input                                          src_ip_rewrite_manager_tx_noc0_val_N
    ,input                                          src_ip_rewrite_manager_tx_noc0_val_E
    ,input                                          src_ip_rewrite_manager_tx_noc0_val_S
    ,input                                          src_ip_rewrite_manager_tx_noc0_val_W

    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_N
    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_E
    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_S
    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_W

    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_N
    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_E
    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_S
    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_W

    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_N
    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_E
    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_S
    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_W
    
    ,output logic                                   splitter_ip_rewrite_manager_rx_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]           splitter_ip_rewrite_manager_rx_data
    ,input  logic                                   ip_rewrite_manager_rx_splitter_rdy
    
    ,input  logic                                   ip_rewrite_manager_rx_merger_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           ip_rewrite_manager_rx_merger_data
    ,output                                         merger_ip_rewrite_manager_rx_rdy
    
    ,output                                         splitter_ip_rewrite_manager_tx_val
    ,output         [`NOC_DATA_WIDTH-1:0]           splitter_ip_rewrite_manager_tx_data
    ,input  logic                                   ip_rewrite_manager_tx_splitter_rdy
    
    ,input  logic                                   ip_rewrite_manager_tx_merger_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           ip_rewrite_manager_tx_merger_data
    ,output                                         merger_ip_rewrite_manager_tx_rdy
    
    ,output                                         splitter_rd_rx_buf_val
    ,output         [`NOC_DATA_WIDTH-1:0]           splitter_rd_rx_buf_data
    ,input  logic                                   rd_rx_buf_splitter_rdy
    
    ,input  logic                                   rd_rx_buf_merger_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           rd_rx_buf_merger_data
    ,output                                         merger_rd_rx_buf_rdy
    
    ,output                                         splitter_wr_tx_buf_val
    ,output         [`NOC_DATA_WIDTH-1:0]           splitter_wr_tx_buf_data
    ,input  logic                                   wr_tx_buf_splitter_rdy
    
    ,input  logic                                   wr_tx_buf_merger_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           wr_tx_buf_merger_data
    ,output                                         merger_wr_tx_buf_rdy
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
    
    logic                           merger_noc0_vrtoc_rx_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_noc0_vrtoc_rx_data;    
    logic                           noc0_vrtoc_merger_rx_rdy;
    
    logic                           noc0_ctovr_splitter_rx_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_rx_data;
    logic                           splitter_noc0_ctovr_rx_rdy;     
    
    logic                           merger_noc0_vrtoc_tx_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_noc0_vrtoc_tx_data;    
    logic                           noc0_vrtoc_merger_tx_rdy;
    
    logic                           noc0_ctovr_splitter_tx_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_tx_data;
    logic                           splitter_noc0_ctovr_tx_rdy;     
    
    
    dynamic_node_top_wrap tile_rx_noc0_router (
         .clk                   (clk    )
        ,.reset_in              (rst    )
        
        ,.src_router_data_N     (src_ip_rewrite_manager_rx_noc0_data_N  )
        ,.src_router_data_E     (src_ip_rewrite_manager_rx_noc0_data_E  )
        ,.src_router_data_S     (src_ip_rewrite_manager_rx_noc0_data_S  )
        ,.src_router_data_W     (src_ip_rewrite_manager_rx_noc0_data_W  )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data         )
                                
        ,.src_router_val_N      (src_ip_rewrite_manager_rx_noc0_val_N   )
        ,.src_router_val_E      (src_ip_rewrite_manager_rx_noc0_val_E   )
        ,.src_router_val_S      (src_ip_rewrite_manager_rx_noc0_val_S   )
        ,.src_router_val_W      (src_ip_rewrite_manager_rx_noc0_val_W   )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val          )
                                
        ,.router_src_yummy_N    (ip_rewrite_manager_rx_src_noc0_yummy_N )
        ,.router_src_yummy_E    (ip_rewrite_manager_rx_src_noc0_yummy_E )
        ,.router_src_yummy_S    (ip_rewrite_manager_rx_src_noc0_yummy_S )
        ,.router_src_yummy_W    (ip_rewrite_manager_rx_src_noc0_yummy_W )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy        )
        
        ,.myLocX                (RX_SRC_X[`XY_WIDTH-1:0]                )
        ,.myLocY                (RX_SRC_Y[`XY_WIDTH-1:0]                )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                      )

        ,.router_dst_data_N     (ip_rewrite_manager_rx_dst_noc0_data_N  )
        ,.router_dst_data_E     (ip_rewrite_manager_rx_dst_noc0_data_E  )
        ,.router_dst_data_S     (ip_rewrite_manager_rx_dst_noc0_data_S  )
        ,.router_dst_data_W     (ip_rewrite_manager_rx_dst_noc0_data_W  )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data         )
                            
        ,.router_dst_val_N      (ip_rewrite_manager_rx_dst_noc0_val_N   )
        ,.router_dst_val_E      (ip_rewrite_manager_rx_dst_noc0_val_E   )
        ,.router_dst_val_S      (ip_rewrite_manager_rx_dst_noc0_val_S   )
        ,.router_dst_val_W      (ip_rewrite_manager_rx_dst_noc0_val_W   )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val          )
                            
        ,.dst_router_yummy_N    (dst_ip_rewrite_manager_rx_noc0_yummy_N )
        ,.dst_router_yummy_E    (dst_ip_rewrite_manager_rx_noc0_yummy_E )
        ,.dst_router_yummy_S    (dst_ip_rewrite_manager_rx_noc0_yummy_S )
        ,.dst_router_yummy_W    (dst_ip_rewrite_manager_rx_noc0_yummy_W )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_rx_router_yummy        )
        
        
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
        ,.ctovr_dst_data    (noc0_ctovr_splitter_rx_data    )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_rx_val     )
        ,.dst_ctovr_rdy     (splitter_noc0_ctovr_rx_rdy     )
    );

    beehive_valrdy_to_credit tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_noc0_vrtoc_rx_data       )
        ,.src_vrtoc_val     (merger_noc0_vrtoc_rx_val        )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_rx_rdy        )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );

    beehive_noc_prio_merger #(
        .num_sources    (2)
    ) rx_merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (ip_rewrite_manager_rx_merger_val   )
        ,.src0_merger_vr_noc_dat    (ip_rewrite_manager_rx_merger_data  )
        ,.merger_src0_vr_noc_rdy    (merger_ip_rewrite_manager_rx_rdy   )
    
        ,.src1_merger_vr_noc_val    (rd_rx_buf_merger_val               )
        ,.src1_merger_vr_noc_dat    (rd_rx_buf_merger_data              )
        ,.merger_src1_vr_noc_rdy    (merger_rd_rx_buf_rdy               )
    
        ,.src2_merger_vr_noc_val    ('0)
        ,.src2_merger_vr_noc_dat    ('0)
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ('0)
        ,.src3_merger_vr_noc_dat    ('0)
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ('0)
        ,.src4_merger_vr_noc_dat    ('0)
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (merger_noc0_vrtoc_rx_val   )
        ,.merger_dst_vr_noc_dat     (merger_noc0_vrtoc_rx_data  )
        ,.dst_merger_vr_noc_rdy     (noc0_vrtoc_merger_rx_rdy   )
    );
    
    beehive_noc_fbits_splitter #(
         .num_targets   (3'd2)
        ,.fbits_type0   (IP_REWRITE_MANAGER_RX_FBITS    )
        ,.fbits_type1   (IP_REWRITE_TCP_RX_BUF_FBITS    )
    ) rx_splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_rx_val         )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_rx_data        )
        ,.splitter_src_vr_noc_rdy   (splitter_noc0_ctovr_rx_rdy         )

        ,.splitter_dst0_vr_noc_val  (splitter_ip_rewrite_manager_rx_val )
        ,.splitter_dst0_vr_noc_dat  (splitter_ip_rewrite_manager_rx_data)
        ,.dst0_splitter_vr_noc_rdy  (ip_rewrite_manager_rx_splitter_rdy )

        ,.splitter_dst1_vr_noc_val  (splitter_rd_rx_buf_val             )
        ,.splitter_dst1_vr_noc_dat  (splitter_rd_rx_buf_data            )
        ,.dst1_splitter_vr_noc_rdy  (rd_rx_buf_splitter_rdy             )

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

    // TX routing
    dynamic_node_top_wrap tile_tx_noc0_router (
         .clk                   (clk    )
        ,.reset_in              (rst    )
        
        ,.src_router_data_N     (src_ip_rewrite_manager_tx_noc0_data_N  )
        ,.src_router_data_E     (src_ip_rewrite_manager_tx_noc0_data_E  )
        ,.src_router_data_S     (src_ip_rewrite_manager_tx_noc0_data_S  )
        ,.src_router_data_W     (src_ip_rewrite_manager_tx_noc0_data_W  )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data         )
                                
        ,.src_router_val_N      (src_ip_rewrite_manager_tx_noc0_val_N   )
        ,.src_router_val_E      (src_ip_rewrite_manager_tx_noc0_val_E   )
        ,.src_router_val_S      (src_ip_rewrite_manager_tx_noc0_val_S   )
        ,.src_router_val_W      (src_ip_rewrite_manager_tx_noc0_val_W   )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val          )
                                
        ,.router_src_yummy_N    (ip_rewrite_manager_tx_src_noc0_yummy_N )
        ,.router_src_yummy_E    (ip_rewrite_manager_tx_src_noc0_yummy_E )
        ,.router_src_yummy_S    (ip_rewrite_manager_tx_src_noc0_yummy_S )
        ,.router_src_yummy_W    (ip_rewrite_manager_tx_src_noc0_yummy_W )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy        )
        
        ,.myLocX                (TX_SRC_X[`XY_WIDTH-1:0]                )
        ,.myLocY                (TX_SRC_Y[`XY_WIDTH-1:0]                )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                      )

        ,.router_dst_data_N     (ip_rewrite_manager_tx_dst_noc0_data_N  )
        ,.router_dst_data_E     (ip_rewrite_manager_tx_dst_noc0_data_E  )
        ,.router_dst_data_S     (ip_rewrite_manager_tx_dst_noc0_data_S  )
        ,.router_dst_data_W     (ip_rewrite_manager_tx_dst_noc0_data_W  )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data         )
                            
        ,.router_dst_val_N      (ip_rewrite_manager_tx_dst_noc0_val_N   )
        ,.router_dst_val_E      (ip_rewrite_manager_tx_dst_noc0_val_E   )
        ,.router_dst_val_S      (ip_rewrite_manager_tx_dst_noc0_val_S   )
        ,.router_dst_val_W      (ip_rewrite_manager_tx_dst_noc0_val_W   )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val          )
                            
        ,.dst_router_yummy_N    (dst_ip_rewrite_manager_tx_noc0_yummy_N )
        ,.dst_router_yummy_E    (dst_ip_rewrite_manager_tx_noc0_yummy_E )
        ,.dst_router_yummy_S    (dst_ip_rewrite_manager_tx_noc0_yummy_S )
        ,.dst_router_yummy_W    (dst_ip_rewrite_manager_tx_noc0_yummy_W )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy        )
        
        
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
        ,.ctovr_dst_data    (noc0_ctovr_splitter_tx_data    )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_tx_val     )
        ,.dst_ctovr_rdy     (splitter_noc0_ctovr_tx_rdy     )
    );

    beehive_valrdy_to_credit tile_tx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_noc0_vrtoc_tx_data       )
        ,.src_vrtoc_val     (merger_noc0_vrtoc_tx_val        )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_tx_rdy        )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_tx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_tx_router_val  )
		,.dst_vrtoc_yummy   (tile_tx_router_noc0_vrtoc_yummy)
    );
    
    beehive_noc_prio_merger #(
        .num_sources    (2)
    ) tx_merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (ip_rewrite_manager_tx_merger_val   )
        ,.src0_merger_vr_noc_dat    (ip_rewrite_manager_tx_merger_data  )
        ,.merger_src0_vr_noc_rdy    (merger_ip_rewrite_manager_tx_rdy   )
    
        ,.src1_merger_vr_noc_val    (wr_tx_buf_merger_val               )
        ,.src1_merger_vr_noc_dat    (wr_tx_buf_merger_data              )
        ,.merger_src1_vr_noc_rdy    (merger_wr_tx_buf_rdy               )
    
        ,.src2_merger_vr_noc_val    ('0)
        ,.src2_merger_vr_noc_dat    ('0)
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ('0)
        ,.src3_merger_vr_noc_dat    ('0)
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ('0)
        ,.src4_merger_vr_noc_dat    ('0)
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (merger_noc0_vrtoc_tx_val   )
        ,.merger_dst_vr_noc_dat     (merger_noc0_vrtoc_tx_data  )
        ,.dst_merger_vr_noc_rdy     (noc0_vrtoc_merger_tx_rdy   )
    );
    
    beehive_noc_fbits_splitter #(
         .num_targets   (3'd2)
        ,.fbits_type0   (IP_REWRITE_MANAGER_TX_FBITS    )
        ,.fbits_type1   (IP_REWRITE_TCP_TX_BUF_FBITS    )
    ) tx_splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_tx_val         )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_tx_data        )
        ,.splitter_src_vr_noc_rdy   (splitter_noc0_ctovr_tx_rdy         )

        ,.splitter_dst0_vr_noc_val  (splitter_ip_rewrite_manager_tx_val )
        ,.splitter_dst0_vr_noc_dat  (splitter_ip_rewrite_manager_tx_data)
        ,.dst0_splitter_vr_noc_rdy  (ip_rewrite_manager_tx_splitter_rdy )

        ,.splitter_dst1_vr_noc_val  (splitter_wr_tx_buf_val             )
        ,.splitter_dst1_vr_noc_dat  (splitter_wr_tx_buf_data            )
        ,.dst1_splitter_vr_noc_rdy  (wr_tx_buf_splitter_rdy             )

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
endmodule
