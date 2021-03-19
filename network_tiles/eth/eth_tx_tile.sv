`include "eth_tx_tile_defs.svh"
`include "eth_latency_stats_defs.svh"
module eth_tx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
) (
     input clk
    ,input rst
    
    ,output logic                               engine_mac_tx_val
    ,input                                      mac_engine_tx_rdy
    ,output logic                               engine_mac_tx_startframe
    ,output logic   [`MTU_SIZE_W-1:0]           engine_mac_tx_frame_size 
    ,output logic                               engine_mac_tx_endframe
    ,output logic   [`MAC_INTERFACE_W-1:0]      engine_mac_tx_data
    ,output logic   [`MAC_PADBYTES_W-1:0]       engine_mac_tx_padbytes
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_tx_noc0_data_N // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_tx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_tx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_eth_tx_noc0_data_W 
                                                                     
    ,input                                  src_eth_tx_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_eth_tx_noc0_val_E  
    ,input                                  src_eth_tx_noc0_val_S  
    ,input                                  src_eth_tx_noc0_val_W  
                                                                     
    ,output                                 eth_tx_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 eth_tx_src_noc0_yummy_E
    ,output                                 eth_tx_src_noc0_yummy_S
    ,output                                 eth_tx_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           eth_tx_dst_noc0_data_N // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           eth_tx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           eth_tx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           eth_tx_dst_noc0_data_W 
                                                                     
    ,output                                 eth_tx_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 eth_tx_dst_noc0_val_E  
    ,output                                 eth_tx_dst_noc0_val_S  
    ,output                                 eth_tx_dst_noc0_val_W  
                                                                     
    ,input                                  dst_eth_tx_noc0_yummy_N// neighbor consumed output data
    ,input                                  dst_eth_tx_noc0_yummy_E
    ,input                                  dst_eth_tx_noc0_yummy_S
    ,input                                  dst_eth_tx_noc0_yummy_W
);
    
    logic                           eth_tx_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   eth_tx_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_eth_tx_out_rdy;
    
    logic                           noc0_ctovr_eth_tx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_eth_tx_in_data;
    logic                           eth_tx_in_noc0_ctovr_rdy;     

    logic                           noc0_vrtoc_tile_tx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_tx_router_data;
    logic                           tile_tx_router_noc0_vrtoc_yummy;

    logic                           tile_tx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_tx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_tx_router_yummy;
    
    logic                           eth_tx_in_eth_tostream_eth_hdr_val;
    eth_hdr                         eth_tx_in_eth_tostream_eth_hdr;
    logic   [`MTU_SIZE_W-1:0]       eth_tx_in_eth_tostream_payload_len;
    logic   [MSG_TIMESTAMP_W-1:0]   eth_tx_in_eth_tostream_timestamp;
    logic                           eth_tostream_eth_tx_in_eth_hdr_rdy;

    logic                           eth_tx_in_eth_tostream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  eth_tx_in_eth_tostream_data;
    logic                           eth_tx_in_eth_tostream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   eth_tx_in_eth_tostream_data_padbytes;
    logic                           eth_tostream_eth_tx_in_data_rdy;
    
    logic                           noc0_ctovr_splitter_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_in_data;
    logic                           splitter_in_noc0_ctovr_rdy;

    logic                           merger_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_out_noc0_vrtoc_data;
    logic                           noc0_vrtoc_merger_out_rdy;
    
    logic                           noc0_ctovr_eth_stats_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_eth_stats_in_data;
    logic                           eth_stats_in_noc0_ctovr_rdy;

    logic                           eth_stats_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   eth_stats_out_noc0_vrtoc_data;
    logic                           noc0_vrtoc_eth_stats_out_rdy;
    
    logic                           eth_wr_log;
    logic   [MSG_TIMESTAMP_W-1:0]   eth_wr_log_start_timestamp;
    
    dynamic_node_top_wrap tile_tx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_eth_tx_noc0_data_N             )// data inputs from neighboring tiles
        ,.src_router_data_E     (src_eth_tx_noc0_data_E             )
        ,.src_router_data_S     (src_eth_tx_noc0_data_S             )
        ,.src_router_data_W     (src_eth_tx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data     )// data input from processor
                                
        ,.src_router_val_N      (src_eth_tx_noc0_val_N              )// valid signals from neighboring tiles
        ,.src_router_val_E      (src_eth_tx_noc0_val_E              )
        ,.src_router_val_S      (src_eth_tx_noc0_val_S              )
        ,.src_router_val_W      (src_eth_tx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val      )// valid signal from processor
                                
        ,.router_src_yummy_N    (eth_tx_src_noc0_yummy_N            )// yummy signal to neighbors' output buffers
        ,.router_src_yummy_E    (eth_tx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (eth_tx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (eth_tx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy    )// yummy signal to processor's output buffer
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )// this tile's position
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (eth_tx_dst_noc0_data_N             )// data outputs to neighbors
        ,.router_dst_data_E     (eth_tx_dst_noc0_data_E             )
        ,.router_dst_data_S     (eth_tx_dst_noc0_data_S             )
        ,.router_dst_data_W     (eth_tx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data     )// data output to processor
                            
        ,.router_dst_val_N      (eth_tx_dst_noc0_val_N              )// valid outputs to neighbors
        ,.router_dst_val_E      (eth_tx_dst_noc0_val_E              )
        ,.router_dst_val_S      (eth_tx_dst_noc0_val_S              )
        ,.router_dst_val_W      (eth_tx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val      )// valid output to processor
                            
        ,.dst_router_yummy_N    (dst_eth_tx_noc0_yummy_N            )// neighbor consumed output data
        ,.dst_router_yummy_E    (dst_eth_tx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_eth_tx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_eth_tx_noc0_yummy_W            )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy    )// processor consumed output data
        
        
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
        ,.ctovr_dst_data    (noc0_ctovr_splitter_in_data    )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_in_val     )
        ,.dst_ctovr_rdy     (splitter_in_noc0_ctovr_rdy     )
    );

    beehive_valrdy_to_credit tile_tx_noc0_beehive_valrdy_to_credit (
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

    assign eth_tx_out_noc0_vrtoc_val = 1'b0;
    assign eth_tx_out_noc0_vrtoc_data = '0;
    
    noc_prio_merger #(
        .num_sources    (2)
        ,.NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (eth_tx_out_noc0_vrtoc_val      )
        ,.src0_merger_vr_noc_dat    (eth_tx_out_noc0_vrtoc_data     )
        ,.merger_src0_vr_noc_rdy    (noc0_vrtoc_eth_tx_out_rdy      )
    
        ,.src1_merger_vr_noc_val    (eth_stats_out_noc0_vrtoc_val   )
        ,.src1_merger_vr_noc_dat    (eth_stats_out_noc0_vrtoc_data  )
        ,.merger_src1_vr_noc_rdy    (noc0_vrtoc_eth_stats_out_rdy   )
    
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
         .num_targets   (3'd2)
        ,.fbits_type0   (PKT_IF_FBITS                       )
        ,.fbits_type1   (ETH_LATENCY_LOGGER_READ_IF_FBITS   )
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

        ,.splitter_dst0_vr_noc_val  (noc0_ctovr_eth_tx_in_val       )
        ,.splitter_dst0_vr_noc_dat  (noc0_ctovr_eth_tx_in_data      )
        ,.dst0_splitter_vr_noc_rdy  (eth_tx_in_noc0_ctovr_rdy       )

        ,.splitter_dst1_vr_noc_val  (noc0_ctovr_eth_stats_in_val    )
        ,.splitter_dst1_vr_noc_dat  (noc0_ctovr_eth_stats_in_data   )
        ,.dst1_splitter_vr_noc_rdy  (eth_stats_in_noc0_ctovr_rdy    )

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

    eth_tx_noc_in eth_tx_noc_in (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_eth_tx_in_val              (noc0_ctovr_eth_tx_in_val               )
        ,.noc0_ctovr_eth_tx_in_data             (noc0_ctovr_eth_tx_in_data              )
        ,.eth_tx_in_noc0_ctovr_rdy              (eth_tx_in_noc0_ctovr_rdy               )

        ,.eth_tx_in_eth_tostream_eth_hdr_val    (eth_tx_in_eth_tostream_eth_hdr_val     )
        ,.eth_tx_in_eth_tostream_eth_hdr        (eth_tx_in_eth_tostream_eth_hdr         )
        ,.eth_tx_in_eth_tostream_payload_len    (eth_tx_in_eth_tostream_payload_len     )
        ,.eth_tostream_eth_tx_in_eth_hdr_rdy    (eth_tostream_eth_tx_in_eth_hdr_rdy     )
                                                                                        
        ,.eth_tx_in_eth_tostream_data_val       (eth_tx_in_eth_tostream_data_val        )
        ,.eth_tx_in_eth_tostream_data           (eth_tx_in_eth_tostream_data            )
        ,.eth_tx_in_eth_tostream_data_last      (eth_tx_in_eth_tostream_data_last       )
        ,.eth_tx_in_eth_tostream_data_padbytes  (eth_tx_in_eth_tostream_data_padbytes   )
        ,.eth_tostream_eth_tx_in_data_rdy       (eth_tostream_eth_tx_in_data_rdy        )

        ,.eth_wr_log                            (eth_wr_log                             )
        ,.eth_wr_log_start_timestamp            (eth_wr_log_start_timestamp             )
    );

    eth_latency_stats #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) stats (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.eth_wr_log                    (eth_wr_log                     )
        ,.eth_wr_log_start_timestamp    (eth_wr_log_start_timestamp     )
        
        ,.noc0_ctovr_eth_stats_in_val   (noc0_ctovr_eth_stats_in_val    )
        ,.noc0_ctovr_eth_stats_in_data  (noc0_ctovr_eth_stats_in_data   )
        ,.eth_stats_in_noc0_ctovr_rdy   (eth_stats_in_noc0_ctovr_rdy    )
                                                                        
        ,.eth_stats_out_noc0_vrtoc_val  (eth_stats_out_noc0_vrtoc_val   )
        ,.eth_stats_out_noc0_vrtoc_data (eth_stats_out_noc0_vrtoc_data  )
        ,.noc0_vrtoc_eth_stats_out_rdy  (noc0_vrtoc_eth_stats_out_rdy   )
    );
    

    eth_hdrtostream eth_hdrtostream (
         .clk   (clk)
        ,.rst   (rst)
    
        ,.src_eth_hdrtostream_eth_hdr_val   (eth_tx_in_eth_tostream_eth_hdr_val     )
        ,.src_eth_hdrtostream_eth_hdr       (eth_tx_in_eth_tostream_eth_hdr         )
        ,.src_eth_hdrtostream_payload_len   (eth_tx_in_eth_tostream_payload_len     )
        ,.eth_hdrtostream_src_eth_hdr_rdy   (eth_tostream_eth_tx_in_eth_hdr_rdy     )
    
        ,.src_eth_hdrtostream_data_val      (eth_tx_in_eth_tostream_data_val        )
        ,.src_eth_hdrtostream_data          (eth_tx_in_eth_tostream_data            )
        ,.src_eth_hdrtostream_data_last     (eth_tx_in_eth_tostream_data_last       )
        ,.src_eth_hdrtostream_data_padbytes (eth_tx_in_eth_tostream_data_padbytes   )
        ,.eth_hdrtostream_src_data_rdy      (eth_tostream_eth_tx_in_data_rdy        )
    
        ,.eth_hdrtostream_dst_data_val      (engine_mac_tx_val                      )
        ,.eth_hdrtostream_dst_startframe    (engine_mac_tx_startframe               )
        ,.eth_hdrtostream_dst_frame_size    (engine_mac_tx_frame_size               )
        ,.eth_hdrtostream_dst_endframe      (engine_mac_tx_endframe                 )
        ,.eth_hdrtostream_dst_data          (engine_mac_tx_data                     )
        ,.eth_hdrtostream_dst_data_padbytes (engine_mac_tx_padbytes                 )
        ,.dst_eth_hdrtostream_data_rdy      (mac_engine_tx_rdy                      )
    );
endmodule
