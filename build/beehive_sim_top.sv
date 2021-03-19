`timescale 1ns/1ps
`include "soc_defs.vh"

module beehive_sim_top ();
    
    localparam DROP_QUEUE_STRUCT_W = `MAC_INTERFACE_W + 1 + 1 + `MAC_PADBYTES_W;
    localparam DROP_QUEUE_LOG_ELS = 6;
    // Simulation Parameters
    localparam  CLOCK_PERIOD      = 10000;
    localparam  CLOCK_HALF_PERIOD = CLOCK_PERIOD/2;
    localparam  RST_TIME          = 10 * CLOCK_PERIOD;
    
    typedef struct packed {
        logic   [`MAC_INTERFACE_W-1:0]  data;
        logic                           startframe;
        logic                           endframe;
        logic   [`MAC_PADBYTES_W-1:0]   padbytes;
    } drop_queue_struct;

    logic clk;
    logic rst;
    
    logic                           mac_engine_rx_val;
    logic   [`MAC_INTERFACE_W-1:0]  mac_engine_rx_data;
    logic                           mac_engine_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   mac_engine_rx_padbytes;
    logic                           engine_mac_rx_rdy;
    
    logic                           startframe_convert_pkt_q_val;
    logic                           startframe_convert_pkt_q_startframe;
    logic                           startframe_convert_pkt_q_endframe;
    logic   [`MAC_INTERFACE_W-1:0]  startframe_convert_pkt_q_data;
    logic   [`MAC_PADBYTES_W-1:0]   startframe_convert_pkt_q_padbytes;
    logic                           pkt_q_startframe_convert_rdy;
    
    logic                           pkt_queue_engine_rx_val;
    logic   [`MAC_INTERFACE_W-1:0]  pkt_queue_engine_rx_data;
    logic                           pkt_queue_engine_rx_startframe;
    logic   [`MTU_SIZE_W-1:0]       pkt_queue_engine_rx_frame_size;
    logic                           pkt_queue_engine_rx_endframe;
    logic   [`MAC_PADBYTES_W-1:0]   pkt_queue_engine_rx_padbytes;
    logic                           engine_pkt_queue_rx_rdy;
    
    logic                           engine_mac_tx_val;
    logic                           mac_engine_tx_rdy;
    logic   [`MAC_INTERFACE_W-1:0]  engine_mac_tx_data;
    logic                           engine_mac_tx_last;
    logic   [`MAC_PADBYTES_W-1:0]   engine_mac_tx_padbytes;
    
    logic                           memA_ready;
    logic                           memA_read;
    logic                           memA_write;
    logic   [`MEM_ADDR_W-1:0]       memA_address;
    logic   [`MEM_DATA_W-1:0]       memA_readdata;
    logic   [`MEM_DATA_W-1:0]       memA_writedata;
    logic   [`MEM_BURST_CNT_W-1:0]  memA_burstcount;
    logic   [`MEM_WR_MASK_W-1:0]    memA_byteenable;
    logic                           memA_readdatavalid;
    logic                           memA_readdatavalid_reg;

    logic                           memB_ready;
    logic                           memB_read;
    logic                           memB_write;
    logic   [`MEM_ADDR_W-1:0]       memB_address;
    logic   [`MEM_DATA_W-1:0]       memB_readdata;
    logic   [`MEM_DATA_W-1:0]       memB_writedata;
    logic   [`MEM_BURST_CNT_W-1:0]  memB_burstcount;
    logic   [`MEM_WR_MASK_W-1:0]    memB_byteenable;
    logic                           memB_readdatavalid;
    logic                           memB_readdatavalid_reg;
    
    logic                           pkt_queue_wr_req;
    drop_queue_struct               pkt_queue_wr_data;
    logic                           pkt_queue_full;
    logic                           pkt_queue_start_frame;
    logic                           pkt_queue_end_frame;

    logic                           pkt_queue_rd_req;
    logic                           pkt_queue_empty;
    drop_queue_struct               pkt_queue_rd_data;

    logic                           pkt_size_queue_rd_req;
    logic                           pkt_size_queue_empty;
    logic   [`MTU_SIZE_W-1:0]       pkt_size_queue_rd_data;

    
    // Clock generation
    initial begin
        clk = 0;
        forever begin
            #(CLOCK_HALF_PERIOD) clk = ~clk;
        end
    end
    
    // Reset generation
    initial begin
        rst = 1'b1;
        #RST_TIME rst = 1'b0; 
    end
    
    sim_network_side_queue sim_mac(
         .clk   (clk)
        ,.rst   (rst)
    
        // RX testing interface
        ,.mac_engine_rx_val         (mac_engine_rx_val          )
        ,.mac_engine_rx_data        (mac_engine_rx_data         )
        ,.mac_engine_rx_last        (mac_engine_rx_last         )
        ,.mac_engine_rx_padbytes    (mac_engine_rx_padbytes     )
        ,.engine_mac_rx_rdy         (engine_mac_rx_rdy          )
    
        
        // TX testing interface
        ,.engine_mac_tx_val         (engine_mac_tx_val          )
        ,.mac_engine_tx_rdy         (mac_engine_tx_rdy          )
        ,.engine_mac_tx_data        (engine_mac_tx_data         )
        ,.engine_mac_tx_last        (engine_mac_tx_last         )
        ,.engine_mac_tx_padbytes    (engine_mac_tx_padbytes     )
    );

    if_w_startframe_convert #(
         .DATA_W    (`MAC_INTERFACE_W)
    ) rx_converter (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_startframe_convert_data_val       (mac_engine_rx_val                      )
        ,.src_startframe_convert_data           (mac_engine_rx_data                     )
        ,.src_startframe_convert_data_last      (mac_engine_rx_last                     )
        ,.src_startframe_convert_data_padbytes  (mac_engine_rx_padbytes                 )
        ,.startframe_convert_src_data_rdy       (engine_mac_rx_rdy                      )
    
        ,.startframe_convert_dst_val            (startframe_convert_pkt_q_val           )
        ,.startframe_convert_dst_startframe     (startframe_convert_pkt_q_startframe    )
        ,.startframe_convert_dst_endframe       (startframe_convert_pkt_q_endframe      )
        ,.startframe_convert_dst_data           (startframe_convert_pkt_q_data          )
        ,.startframe_convert_dst_padbytes       (startframe_convert_pkt_q_padbytes      )
        ,.dst_startframe_convert_rdy            (pkt_q_startframe_convert_rdy           )
    );

    assign pkt_queue_wr_req = startframe_convert_pkt_q_val;
    assign pkt_queue_wr_data.data = startframe_convert_pkt_q_data;
    assign pkt_queue_wr_data.endframe = startframe_convert_pkt_q_endframe;
    assign pkt_queue_wr_data.startframe = startframe_convert_pkt_q_startframe;
    assign pkt_queue_wr_data.padbytes = startframe_convert_pkt_q_padbytes;
    assign pkt_q_startframe_convert_rdy = 1'b1;

    packet_queue_controller #(
         .width_p           (DROP_QUEUE_STRUCT_W    )
        ,.log2_els_p        (DROP_QUEUE_LOG_ELS     )
    ) rx_pkt_queue (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.wr_req                    (pkt_queue_wr_req           )
        ,.wr_data                   (pkt_queue_wr_data          )
        ,.full                      (pkt_queue_full             )
        ,.start_frame               (startframe_convert_pkt_q_startframe   )
        ,.end_frame                 (startframe_convert_pkt_q_endframe     )
        ,.end_padbytes              (startframe_convert_pkt_q_padbytes     )

        ,.rd_req                    (pkt_queue_rd_req           )
        ,.empty                     (pkt_queue_empty            )
        ,.rd_data                   (pkt_queue_rd_data          )

        ,.pkt_size_queue_rd_req     (pkt_size_queue_rd_req      )
        ,.pkt_size_queue_empty      (pkt_size_queue_empty       )
        ,.pkt_size_queue_rd_data    (pkt_size_queue_rd_data     )
    );

    assign pkt_queue_rd_req = ~pkt_queue_empty & engine_pkt_queue_rx_rdy;
    assign pkt_queue_engine_rx_val = ~pkt_queue_empty;
    assign pkt_queue_engine_rx_data = pkt_queue_rd_data.data;
    assign pkt_queue_engine_rx_startframe = pkt_queue_rd_data.startframe;
    assign pkt_queue_engine_rx_endframe = pkt_queue_rd_data.endframe;
    assign pkt_queue_engine_rx_padbytes = pkt_queue_rd_data.padbytes;

    packet_size_queue_reader packet_size_queue_reader (
        // is the main interface reading from the data queue
         .data_queue_engine_rx_val          (pkt_queue_engine_rx_val        )
        ,.data_queue_engine_rx_startframe   (pkt_queue_engine_rx_startframe )
        ,.engine_data_queue_rx_rdy          (engine_pkt_queue_rx_rdy        )
   
        // how we request from the size queue
        ,.reader_size_queue_rd_req          (pkt_size_queue_rd_req          )
        ,.size_queue_reader_rd_data         (pkt_size_queue_rd_data         )
        ,.mac_engine_rx_frame_size          (pkt_queue_engine_rx_frame_size )
    );

    beehive_top #(
         .MEM_ADDR_W        (`MEM_ADDR_W        )
        ,.MEM_DATA_W        (`MEM_DATA_W        )
        ,.MEM_WR_MASK_W     (`MEM_WR_MASK_W     )
        ,.MEM_BURST_CNT_W   (`MEM_BURST_CNT_W   )
    ) DUT (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.mac_engine_rx_val         (pkt_queue_engine_rx_val        )
        ,.mac_engine_rx_data        (pkt_queue_engine_rx_data       )
        ,.mac_engine_rx_startframe  (pkt_queue_engine_rx_startframe )
        ,.mac_engine_rx_frame_size  (pkt_queue_engine_rx_frame_size )
        ,.mac_engine_rx_endframe    (pkt_queue_engine_rx_endframe   )
        ,.mac_engine_rx_padbytes    (pkt_queue_engine_rx_padbytes   )
        ,.engine_mac_rx_rdy         (engine_pkt_queue_rx_rdy        )
        
        ,.engine_mac_tx_val         (engine_mac_tx_val              )
        ,.mac_engine_tx_rdy         (mac_engine_tx_rdy              )
        ,.engine_mac_tx_data        (engine_mac_tx_data             )
        ,.engine_mac_tx_last        (engine_mac_tx_last             )
        ,.engine_mac_tx_padbytes    (engine_mac_tx_padbytes         )
        
        ,.memA_ready_in             (memA_ready                     )
        ,.memA_read_out             (memA_read                      )
        ,.memA_write_out            (memA_write                     )
        ,.memA_address_out          (memA_address                   )
        ,.memA_readdata_in          (memA_readdata                  )
        ,.memA_writedata_out        (memA_writedata                 )
        ,.memA_burstcount_out       (memA_burstcount                )
        ,.memA_byteenable_out       (memA_byteenable                )
        ,.memA_readdatavalid_in     (memA_readdatavalid             )

        ,.memB_ready_in             (memB_ready                     )
        ,.memB_read_out             (memB_read                      )
        ,.memB_write_out            (memB_write                     )
        ,.memB_address_out          (memB_address                   )
        ,.memB_readdata_in          (memB_readdata                  )
        ,.memB_writedata_out        (memB_writedata                 )
        ,.memB_burstcount_out       (memB_burstcount                )
        ,.memB_byteenable_out       (memB_byteenable                )
        ,.memB_readdatavalid_in     (memB_readdatavalid             )
    );
    
    assign memA_ready = 1'b1;
    assign memA_readdatavalid = memA_readdatavalid_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            memA_readdatavalid_reg <= 1'b0;
        end
        else begin
            memA_readdatavalid_reg <= memA_read;
        end
    end

    bsg_mem_1rw_sync_mask_write_byte #( 
         .els_p         (2 ** `MEM_ADDR_W)
        ,.data_width_p  (`MEM_DATA_W     )
    ) memA ( 
         .clk_i         (clk    )
        ,.reset_i       (rst    )

        ,.v_i           (memA_read | memA_write )
        ,.w_i           (memA_write             )

        ,.addr_i        (memA_address           )
        ,.data_i        (memA_writedata         )
         // for each bit set in the mask, a byte is written
        ,.write_mask_i  (memA_byteenable        )
        ,.data_o        (memA_readdata          )
    );

    assign memB_ready = 1'b1;
    assign memB_readdatavalid = memB_readdatavalid_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            memB_readdatavalid_reg <= 1'b0;
        end
        else begin
            memB_readdatavalid_reg <= memB_read;
        end
    end
      
    bsg_mem_1rw_sync_mask_write_byte #( 
         .els_p         (2 ** `MEM_ADDR_W)
        ,.data_width_p  (`MEM_DATA_W     )
    ) memB ( 
         .clk_i         (clk    )
        ,.reset_i       (rst    )

        ,.v_i           (memB_read | memB_write )
        ,.w_i           (memB_write             )

        ,.addr_i        (memB_address           )
        ,.data_i        (memB_writedata         )
         // for each bit set in the mask, a byte is written
        ,.write_mask_i  (memB_byteenable        )
        ,.data_o        (memB_readdata          )
    );


endmodule
