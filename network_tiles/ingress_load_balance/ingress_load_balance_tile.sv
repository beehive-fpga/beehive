`include "ingress_load_balance_defs.svh"
module ingress_load_balance_tile 
    import hash_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input                                  mac_engine_rx_val
    ,input          [`MAC_INTERFACE_W-1:0]  mac_engine_rx_data
    ,input                                  mac_engine_rx_startframe
    ,input          [`MTU_SIZE_W-1:0]       mac_engine_rx_frame_size
    ,input                                  mac_engine_rx_endframe
    ,input          [`MAC_PADBYTES_W-1:0]   mac_engine_rx_padbytes
    ,output logic                           engine_mac_rx_rdy
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_load_balance_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]            src_load_balance_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_load_balance_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_load_balance_noc0_data_W 
                                                                     
    ,input                                  src_load_balance_noc0_val_N  
    ,input                                  src_load_balance_noc0_val_E  
    ,input                                  src_load_balance_noc0_val_S  
    ,input                                  src_load_balance_noc0_val_W  
                                                                     
    ,output                                 load_balance_src_noc0_yummy_N
    ,output                                 load_balance_src_noc0_yummy_E
    ,output                                 load_balance_src_noc0_yummy_S
    ,output                                 load_balance_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           load_balance_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]           load_balance_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           load_balance_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           load_balance_dst_noc0_data_W 
                                                                     
    ,output                                 load_balance_dst_noc0_val_N  
    ,output                                 load_balance_dst_noc0_val_E  
    ,output                                 load_balance_dst_noc0_val_S  
    ,output                                 load_balance_dst_noc0_val_W  
                                                                     
    ,input                                  dst_load_balance_noc0_yummy_N
    ,input                                  dst_load_balance_noc0_yummy_E
    ,input                                  dst_load_balance_noc0_yummy_S
    ,input                                  dst_load_balance_noc0_yummy_W
);
    logic                           noc0_vrtoc_tile_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_router_data;
    logic                           tile_router_noc0_vrtoc_yummy;

    logic                           tile_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_router_yummy;

    logic                           load_balance_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   load_balance_out_noc0_vrtoc_data;
    logic                           noc0_vrtoc_load_balance_out_rdy;

    logic                           noc0_ctovr_load_balance_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_load_balance_in_data;
    logic                           load_balance_in_noc0_ctovr_rdy;

    logic                           table_noc_out_val;
    hash_table_data                 table_noc_out_data;
    logic                           noc_out_table_rdy;
    
    typedef struct packed {
        logic   [`MAC_INTERFACE_W-1:0]  data;
        logic   [`MAC_PADBYTES_W-1:0]   padbytes;
        logic                           last;
        logic                           start;
        logic   [`MTU_SIZE_W-1:0]       framesize;
    } fifo_struct;
    localparam FIFO_STRUCT_W = $bits(fifo_struct);
    
    logic                           parser_data_fifo_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  parser_data_fifo_data;
    logic   [`MAC_PADBYTES_W-1:0]   parser_data_fifo_padbytes;
    logic                           parser_data_fifo_last;
    logic                           parser_data_fifo_start;
    logic   [`MTU_SIZE_W-1:0]       parser_data_fifo_framesize;
    logic                           data_fifo_parser_data_rdy;
    
    logic       data_out_fifo_wr_req;
    fifo_struct data_out_fifo_wr_data;
    logic       data_out_fifo_full;
    
    logic       data_out_fifo_rd_req;
    fifo_struct data_out_fifo_rd_data;
    logic       data_out_fifo_empty;
    logic       data_out_fifo_noc_out_val;
    logic       noc_out_data_out_fifo_rdy;

    logic       parser_table_val;
    logic       parser_table_tuple_val;
    hash_struct parser_table_tuple;
    logic       table_parser_rdy;

    
    dynamic_node_top_wrap tile_rx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_load_balance_noc0_data_N   )// data inputs from neighboring tiles
        ,.src_router_data_E     (src_load_balance_noc0_data_E   )
        ,.src_router_data_S     (src_load_balance_noc0_data_S   )
        ,.src_router_data_W     (src_load_balance_noc0_data_W   )
        ,.src_router_data_P     (noc0_vrtoc_tile_router_data    )// data input from processor
                                
        ,.src_router_val_N      (src_load_balance_noc0_val_N    )// valid signals from neighboring tiles
        ,.src_router_val_E      (src_load_balance_noc0_val_E    )
        ,.src_router_val_S      (src_load_balance_noc0_val_S    )
        ,.src_router_val_W      (src_load_balance_noc0_val_W    )
        ,.src_router_val_P      (noc0_vrtoc_tile_router_val     )// valid signal from processor
                                
        ,.router_src_yummy_N    (load_balance_src_noc0_yummy_N  )// yummy signal to neighbors' output buffers
        ,.router_src_yummy_E    (load_balance_src_noc0_yummy_E  )
        ,.router_src_yummy_S    (load_balance_src_noc0_yummy_S  )
        ,.router_src_yummy_W    (load_balance_src_noc0_yummy_W  )
        ,.router_src_yummy_P    (tile_router_noc0_vrtoc_yummy   )// yummy signal to processor's output buffer
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]           )// this tile's position
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]           )
        ,.myChipID              (`CHIP_ID_WIDTH'd0              )

        ,.router_dst_data_N     (load_balance_dst_noc0_data_N   )// data outputs to neighbors
        ,.router_dst_data_E     (load_balance_dst_noc0_data_E   )
        ,.router_dst_data_S     (load_balance_dst_noc0_data_S   )
        ,.router_dst_data_W     (load_balance_dst_noc0_data_W   )
        ,.router_dst_data_P     (tile_router_noc0_ctovr_data    )// data output to processor
                            
        ,.router_dst_val_N      (load_balance_dst_noc0_val_N    )// valid outputs to neighbors
        ,.router_dst_val_E      (load_balance_dst_noc0_val_E    )
        ,.router_dst_val_S      (load_balance_dst_noc0_val_S    )
        ,.router_dst_val_W      (load_balance_dst_noc0_val_W    )
        ,.router_dst_val_P      (tile_router_noc0_ctovr_val     )// valid output to processor
                            
        ,.dst_router_yummy_N    (dst_load_balance_noc0_yummy_N  )// neighbor consumed output data
        ,.dst_router_yummy_E    (dst_load_balance_noc0_yummy_E  )
        ,.dst_router_yummy_S    (dst_load_balance_noc0_yummy_S  )
        ,.dst_router_yummy_W    (dst_load_balance_noc0_yummy_W  )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_router_yummy   )// processor consumed output data
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy tile_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_router_noc0_ctovr_data        )
        ,.src_ctovr_val     (tile_router_noc0_ctovr_val         )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_router_yummy       )

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_load_balance_in_data    )
        ,.ctovr_dst_val     (noc0_ctovr_load_balance_in_val     )
        ,.dst_ctovr_rdy     (load_balance_in_noc0_ctovr_rdy     )
    );

    beehive_valrdy_to_credit tile_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (load_balance_out_noc0_vrtoc_data   )
        ,.src_vrtoc_val     (load_balance_out_noc0_vrtoc_val    )
        ,.vrtoc_src_rdy     (noc0_vrtoc_load_balance_out_rdy    )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_router_data        )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_router_val         )
		,.dst_vrtoc_yummy   (tile_router_noc0_vrtoc_yummy       )
    );

    fixed_parser #(
         .DATA_W        (`MAC_INTERFACE_W   )
        ,.HAS_ETH_HDR   (1)
        ,.HAS_IP_HDR    (1)
    ) parser (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_parser_data_val   (mac_engine_rx_val          )
        ,.src_parser_data       (mac_engine_rx_data         )
        ,.src_parser_padbytes   (mac_engine_rx_padbytes     )
        ,.src_parser_last       (mac_engine_rx_endframe     )
        ,.src_parser_start      (mac_engine_rx_startframe   )
        ,.src_parser_framesize  (mac_engine_rx_frame_size   )
        ,.parser_src_data_rdy   (engine_mac_rx_rdy          )
    
        ,.parser_dst_meta_val   (parser_table_val           )
        ,.parser_dst_hash_val   (parser_table_tuple_val     )
        ,.parser_dst_hash_data  (parser_table_tuple         )
        ,.dst_parser_meta_rdy   (table_parser_rdy           )
    
        ,.parser_dst_data_val   (parser_data_fifo_data_val  )
        ,.parser_dst_data       (parser_data_fifo_data      )
        ,.parser_dst_padbytes   (parser_data_fifo_padbytes  )
        ,.parser_dst_last       (parser_data_fifo_last      )
        ,.parser_dst_start      (parser_data_fifo_start     )
        ,.parser_dst_framesize  (parser_data_fifo_framesize )
        ,.dst_parser_data_rdy   (data_fifo_parser_data_rdy  )
    );
    
    logic                           init_wr_req_val;
    logic   [TABLE_ELS_LOG_2-1:0]   init_wr_req_addr;
    hash_table_data                 init_wr_req_data;
    logic                           init_reset_done;
    
    logic                           init_table_rd;
    logic   [INIT_TABLE_ADDR_W-1:0] init_table_addr;
    hash_table_data                 init_table_rd_data;
    logic                           hash_table_rdy_tmp;

    assign table_parser_rdy = hash_table_rdy_tmp & init_reset_done;
    
    ingress_hash_table_init_rom #(
        .INIT_TABLE_ELS (INIT_TABLE_ELS )
    ) init_rom (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.table_rd      (init_table_rd  )
        ,.table_rd_addr (init_table_addr)
    
        ,.table_rd_data ()
    );
    
    hash_table_init #(
         .TABLE_ELS         (2**TABLE_ELS_LOG_2 )
        ,.INIT_TABLE_ELS    (INIT_TABLE_ELS     )
    ) init_hash_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.reset_done            ()

        ,.wr_req_val            ()
        ,.wr_req_addr           ()
        ,.wr_req_data           ()
    
        ,.init_table_rd         ()
        ,.init_table_addr       ()
        ,.init_table_rd_data    ()
    );
    
    l4_hash_table #(
         .TABLE_DATA_W      (HASH_TABLE_DATA_W  )
        ,.TABLE_ELS_LOG_2   (6                  )
    ) hash_table (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_tuple_val      (parser_table_val   )
        ,.rd_tuple_data     (parser_table_tuple )
        ,.wr_en             ('0)
        ,.wr_index          ('0)
        ,.wr_data           ('0)
        ,.hash_table_rdy    (hash_table_rdy_tmp )
                                                
        ,.table_data_val    (table_noc_out_val  )
        ,.table_data_wr_en  ()
        ,.table_rd_index    ()
        ,.table_data        (table_noc_out_data )
        ,.table_data_rdy    (noc_out_table_rdy  )
    );

    assign data_out_fifo_wr_req = ~data_out_fifo_full & parser_data_fifo_data_val;
    assign data_fifo_parser_data_rdy = ~data_out_fifo_full;

    assign data_out_fifo_wr_data.data = parser_data_fifo_data;
    assign data_out_fifo_wr_data.padbytes = parser_data_fifo_padbytes;
    assign data_out_fifo_wr_data.last = parser_data_fifo_last;
    assign data_out_fifo_wr_data.start = parser_data_fifo_start;
    assign data_out_fifo_wr_data.framesize = parser_data_fifo_framesize;
    
    fifo_1r1w #(
         .width_p       (FIFO_STRUCT_W  )
        ,.log2_els_p    (6              )
    ) out_fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req    (data_out_fifo_wr_req   )
        ,.wr_data   (data_out_fifo_wr_data  )
        ,.full      (data_out_fifo_full     )
    
        ,.rd_req    (data_out_fifo_rd_req   )
        ,.rd_data   (data_out_fifo_rd_data  )
        ,.empty     (data_out_fifo_empty    )
    );

    assign data_out_fifo_rd_req = noc_out_data_out_fifo_rdy & ~data_out_fifo_empty;
    assign data_out_fifo_noc_out_val = ~data_out_fifo_empty;

    ingress_noc_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_out_val       (table_noc_out_val                  )
        ,.src_noc_out_x         (table_noc_out_data.x_coord         )
        ,.src_noc_out_y         (table_noc_out_data.y_coord         )
        ,.noc_out_src_rdy       (noc_out_table_rdy                  )
    
        ,.src_noc_out_data_val  (data_out_fifo_noc_out_val          )
        ,.src_noc_out_data      (data_out_fifo_rd_data.data         )
        ,.src_noc_out_start     (data_out_fifo_rd_data.start        )
        ,.src_noc_out_last      (data_out_fifo_rd_data.last         )
        ,.src_noc_out_padbytes  (data_out_fifo_rd_data.padbytes     )
        ,.src_noc_out_framesize (data_out_fifo_rd_data.framesize    )
        ,.noc_out_src_data_rdy  (noc_out_data_out_fifo_rdy          )
    
        ,.ingress_noc_val       (load_balance_out_noc0_vrtoc_val    )
        ,.ingress_noc_data      (load_balance_out_noc0_vrtoc_data   )
        ,.noc_ingress_rdy       (noc0_vrtoc_load_balance_out_rdy    )
    );


endmodule
