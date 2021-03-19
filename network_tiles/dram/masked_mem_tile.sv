`include "noc_defs.vh"
`include "bsg_defines.v"
module masked_mem_tile #(
     parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter MEM_ADDR_W = 0
    ,parameter MEM_DATA_W = 0
    ,parameter MEM_WR_MASK_W = MEM_DATA_W/8
)(
     input  clk
    ,input  rst

    ,input [`NOC_DATA_WIDTH-1:0]            src_masked_mem_noc0_data_N  // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_masked_mem_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_masked_mem_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_masked_mem_noc0_data_W 

    ,input                                  src_masked_mem_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_masked_mem_noc0_val_E  
    ,input                                  src_masked_mem_noc0_val_S  
    ,input                                  src_masked_mem_noc0_val_W  

    ,output                                 masked_mem_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 masked_mem_src_noc0_yummy_E
    ,output                                 masked_mem_src_noc0_yummy_S
    ,output                                 masked_mem_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]           masked_mem_dst_noc0_data_N  // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           masked_mem_dst_noc0_data_E  
    ,output [`NOC_DATA_WIDTH-1:0]           masked_mem_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           masked_mem_dst_noc0_data_W 

    ,output                                 masked_mem_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 masked_mem_dst_noc0_val_E  
    ,output                                 masked_mem_dst_noc0_val_S  
    ,output                                 masked_mem_dst_noc0_val_W  

    ,input                                  dst_masked_mem_noc0_yummy_N // neighbor consumed output data
    ,input                                  dst_masked_mem_noc0_yummy_E
    ,input                                  dst_masked_mem_noc0_yummy_S
    ,input                                  dst_masked_mem_noc0_yummy_W

    ,output logic                           controller_mem_read_en
    ,output logic                           controller_mem_write_en
    ,output logic   [MEM_ADDR_W-1:0]        controller_mem_addr
    ,output logic   [MEM_DATA_W-1:0]        controller_mem_wr_data
    ,output logic   [MEM_WR_MASK_W-1:0]     controller_mem_byte_en
    ,output logic   [7-1:0]                 controller_mem_burst_cnt
    ,input                                  mem_controller_rdy

    ,input                                  mem_controller_rd_data_val
    ,input          [MEM_DATA_W-1:0]        mem_controller_rd_data
);
    logic                           controller_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   controller_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_controller_rdy;
    
    logic                           noc0_ctovr_controller_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_controller_data;
    logic                           controller_noc0_ctovr_rdy;
    
    logic                           queue_controller_val;
    logic   [`NOC_DATA_WIDTH-1:0]   queue_controller_data;
    logic                           controller_queue_rdy;
    logic                           controller_queue_yummy;

    logic                           noc0_vrtoc_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_router_data;
    logic                           router_noc0_vrtoc_yummy;

    logic                           router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   router_noc0_ctovr_data;
    logic                           noc0_ctovr_router_yummy;
    
    //logic                           controller_mem_read_en;
    //logic                           controller_mem_write_en;
    //logic   [mem_addr_w_p-1:0]      controller_mem_addr;
    //logic   [mem_data_w_p-1:0]      controller_mem_wr_data;
    //logic   [mem_wr_mask_w_p-1:0]   controller_mem_byte_en;
    //logic   [7-1:0]                 controller_mem_burst_cnt;
    //logic                           mem_controller_rdy;

    //logic                           mem_controller_rd_data_val;
    //logic   [mem_data_w_p-1:0]      mem_controller_rd_data;

    dynamic_node_top_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.XY_COORD_W        (`XY_WIDTH          )
        ,.CHIP_ID_W         (`CHIP_ID_WIDTH     )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
    ) noc0_router (
     .clk                   (clk)
    ,.reset_in              (rst)
    
    ,.src_router_data_N     (src_masked_mem_noc0_data_N     )
    ,.src_router_data_E     (src_masked_mem_noc0_data_E     )
    ,.src_router_data_S     (src_masked_mem_noc0_data_S     )
    ,.src_router_data_W     (src_masked_mem_noc0_data_W     )
    ,.src_router_data_P     (noc0_vrtoc_router_data         )
                            
    ,.src_router_val_N      (src_masked_mem_noc0_val_N      )
    ,.src_router_val_E      (src_masked_mem_noc0_val_E      )
    ,.src_router_val_S      (src_masked_mem_noc0_val_S      )
    ,.src_router_val_W      (src_masked_mem_noc0_val_W      )
    ,.src_router_val_P      (noc0_vrtoc_router_val          )
                            
    ,.router_src_yummy_N    (masked_mem_src_noc0_yummy_N    )
    ,.router_src_yummy_E    (masked_mem_src_noc0_yummy_E    )
    ,.router_src_yummy_S    (masked_mem_src_noc0_yummy_S    )
    ,.router_src_yummy_W    (masked_mem_src_noc0_yummy_W    )
    ,.router_src_yummy_P    (router_noc0_vrtoc_yummy        )
    
    ,.myLocX                (SRC_X[`XY_WIDTH-1:0]           )
    ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]           )
    ,.myChipID              (`CHIP_ID_WIDTH'b0              )

    ,.router_dst_data_N     (masked_mem_dst_noc0_data_N     )
    ,.router_dst_data_E     (masked_mem_dst_noc0_data_E     )
    ,.router_dst_data_S     (masked_mem_dst_noc0_data_S     )
    ,.router_dst_data_W     (masked_mem_dst_noc0_data_W     )
    ,.router_dst_data_P     (router_noc0_ctovr_data         )
                        
    ,.router_dst_val_N      (masked_mem_dst_noc0_val_N      )
    ,.router_dst_val_E      (masked_mem_dst_noc0_val_E      )
    ,.router_dst_val_S      (masked_mem_dst_noc0_val_S      )
    ,.router_dst_val_W      (masked_mem_dst_noc0_val_W      )
    ,.router_dst_val_P      (router_noc0_ctovr_val          )
                        
    ,.dst_router_yummy_N    (dst_masked_mem_noc0_yummy_N    )
    ,.dst_router_yummy_E    (dst_masked_mem_noc0_yummy_E    )
    ,.dst_router_yummy_S    (dst_masked_mem_noc0_yummy_S    )
    ,.dst_router_yummy_W    (dst_masked_mem_noc0_yummy_W    )
    ,.dst_router_yummy_P    (noc0_ctovr_router_yummy        )
    
    
    ,.router_src_thanks_P   ( )

    );
    
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH)
    ) noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (router_noc0_ctovr_data     )
        ,.src_ctovr_val     (router_noc0_ctovr_val      )
        ,.ctovr_src_yummy   (noc0_ctovr_router_yummy    )

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_controller_data )
        ,.ctovr_dst_val     (noc0_ctovr_controller_val  )
        ,.dst_ctovr_rdy     (controller_noc0_ctovr_rdy  )
    );

    bsg_fifo_1r1w_small #( 
         .width_p   (`NOC_DATA_WIDTH    )
        ,.els_p     (2                  )
    ) buf_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (noc0_ctovr_controller_val  )
        ,.ready_o   (controller_noc0_ctovr_rdy  )
        ,.data_i    (noc0_ctovr_controller_data )
    
        ,.v_o       (queue_controller_val       )
        ,.data_o    (queue_controller_data      )
        ,.yumi_i    (controller_queue_yummy     )
    );

    assign controller_queue_yummy = controller_queue_rdy & queue_controller_val;

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (controller_noc0_vrtoc_data )
        ,.src_vrtoc_val     (controller_noc0_vrtoc_val  )
        ,.vrtoc_src_rdy     (noc0_vrtoc_controller_rdy  )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_router_data     )
        ,.vrtoc_dst_val     (noc0_vrtoc_router_val      )
		,.dst_vrtoc_yummy   (router_noc0_vrtoc_yummy    )
    );

    masked_mem_controller #(
         .MEM_DATA_W    (MEM_DATA_W     )
        ,.MEM_ADDR_W    (MEM_ADDR_W     )
        ,.MEM_WR_MASK_W (MEM_WR_MASK_W  )
        ,.SRC_X         (SRC_X          )
        ,.SRC_Y         (SRC_Y          )
    ) mem_controller (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_controller_val     (queue_controller_val   )
        ,.noc0_ctovr_controller_data    (queue_controller_data  )
        ,.controller_noc0_ctovr_rdy     (controller_queue_rdy   )
                                                                    
        ,.controller_noc0_vrtoc_val     (controller_noc0_vrtoc_val  )
        ,.controller_noc0_vrtoc_data    (controller_noc0_vrtoc_data )
        ,.noc0_vrtoc_controller_rdy     (noc0_vrtoc_controller_rdy  )
                                                                    
        ,.controller_mem_write_en       (controller_mem_write_en    )
        ,.controller_mem_addr           (controller_mem_addr        )
        ,.controller_mem_wr_data        (controller_mem_wr_data     )
        ,.controller_mem_byte_en        (controller_mem_byte_en     )
        ,.controller_mem_burst_cnt      (controller_mem_burst_cnt   )
        ,.mem_controller_rdy            (mem_controller_rdy         )
                                                                    
        ,.controller_mem_read_en        (controller_mem_read_en     )
        ,.mem_controller_rd_data_val    (mem_controller_rd_data_val )
        ,.mem_controller_rd_data        (mem_controller_rd_data     )
    );
endmodule
