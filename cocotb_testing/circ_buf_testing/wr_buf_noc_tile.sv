module wr_buf_noc_tile #(
     parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter BUF_PTR_W=-1
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
)(

     input  clk
    ,input  rst
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_wr_circ_buf_noc0_data_N  // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_wr_circ_buf_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_wr_circ_buf_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_wr_circ_buf_noc0_data_W 

    ,input                                  src_wr_circ_buf_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_wr_circ_buf_noc0_val_E  
    ,input                                  src_wr_circ_buf_noc0_val_S  
    ,input                                  src_wr_circ_buf_noc0_val_W  

    ,output                                 wr_circ_buf_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 wr_circ_buf_src_noc0_yummy_E
    ,output                                 wr_circ_buf_src_noc0_yummy_S
    ,output                                 wr_circ_buf_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]           wr_circ_buf_dst_noc0_data_N  // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           wr_circ_buf_dst_noc0_data_E  
    ,output [`NOC_DATA_WIDTH-1:0]           wr_circ_buf_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           wr_circ_buf_dst_noc0_data_W 

    ,output                                 wr_circ_buf_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 wr_circ_buf_dst_noc0_val_E  
    ,output                                 wr_circ_buf_dst_noc0_val_S  
    ,output                                 wr_circ_buf_dst_noc0_val_W  

    ,input                                  dst_wr_circ_buf_noc0_yummy_N // neighbor consumed output data
    ,input                                  dst_wr_circ_buf_noc0_yummy_E
    ,input                                  dst_wr_circ_buf_noc0_yummy_S
    ,input                                  dst_wr_circ_buf_noc0_yummy_W
    
    ,input                                      src_wr_buf_req_val
    ,input          [`FLOW_ID_W-1:0]            src_wr_buf_req_flowid
    ,input          [BUF_PTR_W-1:0]             src_wr_buf_req_wr_ptr
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]  src_wr_buf_req_size
    ,output logic                               wr_buf_src_req_rdy

    ,input                                      src_wr_buf_req_data_val
    ,input          [`NOC_DATA_WIDTH-1:0]       src_wr_buf_req_data
    ,output logic                               wr_buf_src_req_data_rdy
    
    ,output logic                               wr_buf_src_req_done
    ,input  logic                               src_wr_buf_done_rdy
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           wr_circ_buf_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   wr_circ_buf_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_wr_circ_buf_rdy;
    
    logic                           noc0_ctovr_wr_circ_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_wr_circ_buf_data;
    logic                           wr_circ_buf_noc0_ctovr_rdy;     
    
    
    dynamic_node_top_wrap tile_rx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_wr_circ_buf_noc0_data_N        )
        ,.src_router_data_E     (src_wr_circ_buf_noc0_data_E        )
        ,.src_router_data_S     (src_wr_circ_buf_noc0_data_S        )
        ,.src_router_data_W     (src_wr_circ_buf_noc0_data_W        )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_wr_circ_buf_noc0_val_N         )
        ,.src_router_val_E      (src_wr_circ_buf_noc0_val_E         )
        ,.src_router_val_S      (src_wr_circ_buf_noc0_val_S         )
        ,.src_router_val_W      (src_wr_circ_buf_noc0_val_W         )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (wr_circ_buf_src_noc0_yummy_N       )
        ,.router_src_yummy_E    (wr_circ_buf_src_noc0_yummy_E       )
        ,.router_src_yummy_S    (wr_circ_buf_src_noc0_yummy_S       )
        ,.router_src_yummy_W    (wr_circ_buf_src_noc0_yummy_W       )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (wr_circ_buf_dst_noc0_data_N        )
        ,.router_dst_data_E     (wr_circ_buf_dst_noc0_data_E        )
        ,.router_dst_data_S     (wr_circ_buf_dst_noc0_data_S        )
        ,.router_dst_data_W     (wr_circ_buf_dst_noc0_data_W        )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (wr_circ_buf_dst_noc0_val_N         )
        ,.router_dst_val_E      (wr_circ_buf_dst_noc0_val_E         )
        ,.router_dst_val_S      (wr_circ_buf_dst_noc0_val_S         )
        ,.router_dst_val_W      (wr_circ_buf_dst_noc0_val_W         )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_wr_circ_buf_noc0_yummy_N       )
        ,.dst_router_yummy_E    (dst_wr_circ_buf_noc0_yummy_E       )
        ,.dst_router_yummy_S    (dst_wr_circ_buf_noc0_yummy_S       )
        ,.dst_router_yummy_W    (dst_wr_circ_buf_noc0_yummy_W       )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_rx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    credit_to_valrdy tile_rx_noc0_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_rx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_rx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_rx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_wr_circ_buf_data    )
        ,.ctovr_dst_val     (noc0_ctovr_wr_circ_buf_val     )
        ,.dst_ctovr_rdy     (wr_circ_buf_noc0_ctovr_rdy     )
    );

    valrdy_to_credit tile_rx_noc0_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (wr_circ_buf_noc0_vrtoc_data    )
        ,.src_vrtoc_val     (wr_circ_buf_noc0_vrtoc_val     )
        ,.vrtoc_src_rdy     (noc0_vrtoc_wr_circ_buf_rdy     )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );

    wr_circ_buf #(
         .BUF_PTR_W (BUF_PTR_W )
        ,.SRC_X     (SRC_X     )
        ,.SRC_Y     (SRC_Y     )
        ,.DST_DRAM_X(DST_DRAM_X)
        ,.DST_DRAM_Y(DST_DRAM_Y)
        ,.FBITS     (FBITS     )
    ) wr_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc_wr_buf_resp_noc0_val  (noc0_ctovr_wr_circ_buf_val )
        ,.noc_wr_buf_resp_noc0_data (noc0_ctovr_wr_circ_buf_data)
        ,.wr_buf_noc_resp_noc0_rdy  (wr_circ_buf_noc0_ctovr_rdy )
        
        ,.wr_buf_noc_req_noc0_val   (wr_circ_buf_noc0_vrtoc_val )
        ,.wr_buf_noc_req_noc0_data  (wr_circ_buf_noc0_vrtoc_data)
        ,.noc_wr_buf_req_noc0_rdy   (noc0_vrtoc_wr_circ_buf_rdy )
    
        ,.src_wr_buf_req_val        (src_wr_buf_req_val         )
        ,.src_wr_buf_req_flowid     (src_wr_buf_req_flowid      )
        ,.src_wr_buf_req_wr_ptr     (src_wr_buf_req_wr_ptr      )
        ,.src_wr_buf_req_size       (src_wr_buf_req_size        )
        ,.wr_buf_src_req_rdy        (wr_buf_src_req_rdy         )
                                                                
        ,.src_wr_buf_req_data_val   (src_wr_buf_req_data_val    )
        ,.src_wr_buf_req_data       (src_wr_buf_req_data        )
        ,.wr_buf_src_req_data_rdy   (wr_buf_src_req_data_rdy    )
                                                                
        ,.wr_buf_src_req_done       (wr_buf_src_req_done        )
        ,.src_wr_buf_done_rdy       (src_wr_buf_done_rdy        )
    );

endmodule
