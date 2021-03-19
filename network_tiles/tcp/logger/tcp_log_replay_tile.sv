`include "tcp_logger_tile_defs.svh"
module tcp_log_replay_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter FORWARD_X = -1
    ,parameter FORWARD_Y = -1
    ,parameter INJECT=1
)(
     input  clk
    ,input  rst

    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_logger_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_logger_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_logger_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_logger_noc0_data_W

    ,input                                          src_tcp_logger_noc0_val_N
    ,input                                          src_tcp_logger_noc0_val_E
    ,input                                          src_tcp_logger_noc0_val_S
    ,input                                          src_tcp_logger_noc0_val_W

    ,output                                         tcp_logger_src_noc0_yummy_N
    ,output                                         tcp_logger_src_noc0_yummy_E
    ,output                                         tcp_logger_src_noc0_yummy_S
    ,output                                         tcp_logger_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_logger_dst_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_logger_dst_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_logger_dst_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_logger_dst_noc0_data_W

    ,output                                         tcp_logger_dst_noc0_val_N
    ,output                                         tcp_logger_dst_noc0_val_E
    ,output                                         tcp_logger_dst_noc0_val_S
    ,output                                         tcp_logger_dst_noc0_val_W

    ,input                                          dst_tcp_logger_noc0_yummy_N
    ,input                                          dst_tcp_logger_noc0_yummy_E
    ,input                                          dst_tcp_logger_noc0_yummy_S
    ,input                                          dst_tcp_logger_noc0_yummy_W
    
    ,input  logic                                   inject_logger_replay_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           inject_logger_replay_data
    ,output logic                                   logger_replay_inject_rdy
    
    ,output logic                                   logger_replay_inject_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]           logger_replay_inject_data
    ,input  logic                                   inject_logger_replay_rdy
);
    logic                           noc0_vrtoc_tile_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_router_data;
    logic                           tile_router_noc0_vrtoc_yummy;

    logic                           tile_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_router_yummy;
    
    logic                           noc0_ctovr_splitter_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_data;
    logic                           splitter_noc0_ctovr_rdy;

    logic                           merger_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_noc0_vrtoc_data;
    logic                           noc0_vrtoc_merger_rdy;
    
    logic                           noc0_logger_replay_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_logger_replay_data;
    logic                           logger_replay_noc0_rdy;
    
    logic                           logger_replay_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   logger_replay_noc0_data;
    logic                           noc0_logger_replay_rdy;
    
    logic                           noc0_logger_read_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_logger_read_data;
    logic                           logger_read_noc0_rdy;

    logic                           logger_read_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   logger_read_noc0_data;
    logic                           noc0_logger_read_rdy;
    
    dynamic_node_top_wrap tile_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_tcp_logger_noc0_data_N     )
        ,.src_router_data_E     (src_tcp_logger_noc0_data_E     )
        ,.src_router_data_S     (src_tcp_logger_noc0_data_S     )
        ,.src_router_data_W     (src_tcp_logger_noc0_data_W     )
        ,.src_router_data_P     (noc0_vrtoc_tile_router_data    )
                                
        ,.src_router_val_N      (src_tcp_logger_noc0_val_N      )
        ,.src_router_val_E      (src_tcp_logger_noc0_val_E      )
        ,.src_router_val_S      (src_tcp_logger_noc0_val_S      )
        ,.src_router_val_W      (src_tcp_logger_noc0_val_W      )
        ,.src_router_val_P      (noc0_vrtoc_tile_router_val     )
                                
        ,.router_src_yummy_N    (tcp_logger_src_noc0_yummy_N    )
        ,.router_src_yummy_E    (tcp_logger_src_noc0_yummy_E    )
        ,.router_src_yummy_S    (tcp_logger_src_noc0_yummy_S    )
        ,.router_src_yummy_W    (tcp_logger_src_noc0_yummy_W    )
        ,.router_src_yummy_P    (tile_router_noc0_vrtoc_yummy   )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]           )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]           )
        ,.myChipID              (`CHIP_ID_WIDTH'd0              )

        ,.router_dst_data_N     (tcp_logger_dst_noc0_data_N     )
        ,.router_dst_data_E     (tcp_logger_dst_noc0_data_E     )
        ,.router_dst_data_S     (tcp_logger_dst_noc0_data_S     )
        ,.router_dst_data_W     (tcp_logger_dst_noc0_data_W     )
        ,.router_dst_data_P     (tile_router_noc0_ctovr_data    )
                            
        ,.router_dst_val_N      (tcp_logger_dst_noc0_val_N      )
        ,.router_dst_val_E      (tcp_logger_dst_noc0_val_E      )
        ,.router_dst_val_S      (tcp_logger_dst_noc0_val_S      )
        ,.router_dst_val_W      (tcp_logger_dst_noc0_val_W      )
        ,.router_dst_val_P      (tile_router_noc0_ctovr_val     )
                            
        ,.dst_router_yummy_N    (dst_tcp_logger_noc0_yummy_N    )
        ,.dst_router_yummy_E    (dst_tcp_logger_noc0_yummy_E    )
        ,.dst_router_yummy_S    (dst_tcp_logger_noc0_yummy_S    )
        ,.dst_router_yummy_W    (dst_tcp_logger_noc0_yummy_W    )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_router_yummy   )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy tile_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_router_noc0_ctovr_data    )
        ,.src_ctovr_val     (tile_router_noc0_ctovr_val     )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_router_yummy   )

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_splitter_data       )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_val        )
        ,.dst_ctovr_rdy     (splitter_noc0_ctovr_rdy        )
    );

    beehive_valrdy_to_credit tile_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_noc0_vrtoc_data         )
        ,.src_vrtoc_val     (merger_noc0_vrtoc_val          )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_rdy          )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_router_data    )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_router_val     )
		,.dst_vrtoc_yummy   (tile_router_noc0_vrtoc_yummy   )
    );

    beehive_noc_prio_merger #(
        .num_sources    (2)
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (logger_replay_noc0_val     )
        ,.src0_merger_vr_noc_dat    (logger_replay_noc0_data    )
        ,.merger_src0_vr_noc_rdy    (noc0_logger_replay_rdy     )
    
        ,.src1_merger_vr_noc_val    (logger_read_noc0_val       )
        ,.src1_merger_vr_noc_dat    (logger_read_noc0_data      )
        ,.merger_src1_vr_noc_rdy    (noc0_logger_read_rdy       )
    
        ,.src2_merger_vr_noc_val    ('0)
        ,.src2_merger_vr_noc_dat    ('0)
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ('0)
        ,.src3_merger_vr_noc_dat    ('0)
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ('0)
        ,.src4_merger_vr_noc_dat    ('0)
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (merger_noc0_vrtoc_val      )
        ,.merger_dst_vr_noc_dat     (merger_noc0_vrtoc_data     )
        ,.dst_merger_vr_noc_rdy     (noc0_vrtoc_merger_rdy      )
    );

    // split between the replay and read paths
    beehive_noc_fbits_splitter #(
         .num_targets   (3'd2)
        ,.fbits_type0   (PKT_IF_FBITS               )
        ,.fbits_type1   (TCP_LOGGER_READ_IF_FBITS   )
    ) splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_val    )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_data   )
        ,.splitter_src_vr_noc_rdy   (splitter_noc0_ctovr_rdy    )

        ,.splitter_dst0_vr_noc_val  (noc0_logger_replay_val     )
        ,.splitter_dst0_vr_noc_dat  (noc0_logger_replay_data    )
        ,.dst0_splitter_vr_noc_rdy  (logger_replay_noc0_rdy     )

        ,.splitter_dst1_vr_noc_val  (noc0_logger_read_val       )
        ,.splitter_dst1_vr_noc_dat  (noc0_logger_read_data      )
        ,.dst1_splitter_vr_noc_rdy  (logger_replay_noc0_rdy     )

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

    tcp_log_replay #(
         .LOG_ENTRIES_LOG_2 (TCP_LOG_ENTRIES_LOG_2  )
        ,.LOG_CLIENT_ADDR_W (TCP_LOG_CLIENT_ADDR_W  )
        ,.SRC_X             (SRC_X                  )
        ,.SRC_Y             (SRC_Y                  )
        ,.FORWARD_X         (FORWARD_X              )
        ,.FORWARD_Y         (FORWARD_Y              )
        ,.INJECT            (INJECT                 )
    ) logger_wrap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.inject_logger_replay_val (inject_logger_replay_val    )
        ,.inject_logger_replay_data(inject_logger_replay_data   )
        ,.logger_replay_inject_rdy (logger_replay_inject_rdy    )
                                                                
        ,.logger_replay_inject_val (logger_replay_inject_val    )
        ,.logger_replay_inject_data(logger_replay_inject_data   )
        ,.inject_logger_replay_rdy (inject_logger_replay_rdy    )

        ,.noc0_logger_replay_val    (noc0_logger_replay_val     )
        ,.noc0_logger_replay_data   (noc0_logger_replay_data    )
        ,.logger_replay_noc0_rdy    (logger_replay_noc0_rdy     )

        ,.logger_replay_noc0_val    (logger_replay_noc0_val     )
        ,.logger_replay_noc0_data   (logger_replay_noc0_data    )
        ,.noc0_logger_replay_rdy    (noc0_logger_replay_rdy     )

        ,.noc0_logger_read_val      (noc0_logger_read_val       )
        ,.noc0_logger_read_data     (noc0_logger_read_data      )
        ,.logger_read_noc0_rdy      (logger_read_noc0_rdy       )

        ,.logger_read_noc0_val      (logger_read_noc0_val       )
        ,.logger_read_noc0_data     (logger_read_noc0_data      )
        ,.noc0_logger_read_rdy      (noc0_logger_read_rdy       )
    );

endmodule
