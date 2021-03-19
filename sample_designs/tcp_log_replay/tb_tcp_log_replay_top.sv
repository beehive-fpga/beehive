`include "noc_defs.vh"
`include "soc_defs.vh"
import beehive_topology::*;
module tb_tcp_log_replay_top (
     input clk
    ,input rst
    
    ,input  logic                               inject_logger_replay_rx_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       inject_logger_replay_rx_data
    ,output logic                               logger_replay_inject_rx_rdy
    
    ,output logic                               logger_replay_inject_tx_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       logger_replay_inject_tx_data
    ,input  logic                               inject_logger_replay_tx_rdy
);
    localparam DROP_QUEUE_STRUCT_W = `MAC_INTERFACE_W + 1 + 1 + `MAC_PADBYTES_W;
    localparam DROP_QUEUE_LOG_ELS = 6;
    typedef struct packed {
        logic   [`MAC_INTERFACE_W-1:0]  data;
        logic                           startframe;
        logic                           endframe;
        logic   [`MAC_PADBYTES_W-1:0]   padbytes;
    } drop_queue_struct;
    
    logic                           mac_engine_rx_val;
    logic   [`MAC_INTERFACE_W-1:0]  mac_engine_rx_data;
    logic                           mac_engine_rx_startframe;
    logic   [`MTU_SIZE_W-1:0]       mac_engine_rx_frame_size;
    logic                           mac_engine_rx_endframe;
    logic   [`MAC_PADBYTES_W-1:0]   mac_engine_rx_padbytes;
    logic                           engine_mac_rx_rdy;

    logic                           engine_mac_tx_val;
    logic                           mac_engine_tx_rdy;
    logic                           engine_mac_tx_startframe;
    logic   [`MTU_SIZE_W-1:0]       engine_mac_tx_frame_size;
    logic                           engine_mac_tx_endframe;
    logic   [`MAC_INTERFACE_W-1:0]  engine_mac_tx_data;
    logic   [`MAC_PADBYTES_W-1:0]   engine_mac_tx_padbytes;

    assign mac_engine_rx_val = '0;
    assign mac_engine_rx_data = '0; 
    assign mac_engine_rx_startframe = '0;
    assign mac_engine_rx_endframe = '0;
    assign mac_engine_rx_padbytes = '0;

    assign mac_engine_tx_rdy = 1'b1;
    
    logic                           pkt_queue_engine_rx_val;
    logic   [`MAC_INTERFACE_W-1:0]  pkt_queue_engine_rx_data;
    logic                           pkt_queue_engine_rx_startframe;
    logic   [`MTU_SIZE_W-1:0]       pkt_queue_engine_rx_frame_size;
    logic                           pkt_queue_engine_rx_endframe;
    logic   [`MAC_PADBYTES_W-1:0]   pkt_queue_engine_rx_padbytes;
    logic                           engine_pkt_queue_rx_rdy;
    
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
    
    // For now, adjust so we don't drop any packets at the start
    assign pkt_queue_wr_req = mac_engine_rx_val & ~pkt_queue_full;
    assign pkt_queue_wr_data.data = mac_engine_rx_data;
    assign pkt_queue_wr_data.endframe = mac_engine_rx_endframe;
    assign pkt_queue_wr_data.startframe = mac_engine_rx_startframe;
    assign pkt_queue_wr_data.padbytes = mac_engine_rx_padbytes;
    assign engine_mac_rx_rdy = ~pkt_queue_full;
    
    packet_queue_controller #(
         .width_p           (DROP_QUEUE_STRUCT_W    )
        ,.log2_els_p        (DROP_QUEUE_LOG_ELS     )
    ) rx_pkt_queue (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.wr_req                    (pkt_queue_wr_req           )
        ,.wr_data                   (pkt_queue_wr_data          )
        ,.full                      (pkt_queue_full             )
        ,.start_frame               (mac_engine_rx_startframe   )
        ,.end_frame                 (mac_engine_rx_endframe     )
        ,.end_padbytes              (mac_engine_rx_padbytes     )

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
    
    tcp_log_replay_top #(
         .MEM_ADDR_W        (`MEM_ADDR_W        )
        ,.MEM_DATA_W        (`MEM_DATA_W        )
        ,.MEM_BURST_CNT_W   (`MEM_BURST_CNT_W   )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.mac_engine_rx_val         (pkt_queue_engine_rx_val        )
        ,.mac_engine_rx_data        (pkt_queue_engine_rx_data       )
        ,.mac_engine_rx_startframe  (pkt_queue_engine_rx_startframe )
        ,.mac_engine_rx_frame_size  (pkt_queue_engine_rx_frame_size )
        ,.mac_engine_rx_endframe    (pkt_queue_engine_rx_endframe   )
        ,.mac_engine_rx_padbytes    (pkt_queue_engine_rx_padbytes   )
        ,.engine_mac_rx_rdy         (engine_pkt_queue_rx_rdy        )
	
        ,.engine_mac_tx_val         (engine_mac_tx_val              )
	    ,.engine_mac_tx_startframe  (engine_mac_tx_startframe       )
	    ,.engine_mac_tx_frame_size  (engine_mac_tx_frame_size       )
	    ,.engine_mac_tx_endframe    (engine_mac_tx_endframe         )
	    ,.engine_mac_tx_data        (engine_mac_tx_data             )
	    ,.engine_mac_tx_padbytes    (engine_mac_tx_padbytes         )
	    ,.mac_engine_tx_rdy         (mac_engine_tx_rdy              )
        
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
    
        ,.inject_logger_replay_rx_val   (inject_logger_replay_rx_val    )
        ,.inject_logger_replay_rx_data  (inject_logger_replay_rx_data   )
        ,.logger_replay_inject_rx_rdy   (logger_replay_inject_rx_rdy    )
                                                                        
        ,.logger_replay_inject_tx_val   (logger_replay_inject_tx_val    )
        ,.logger_replay_inject_tx_data  (logger_replay_inject_tx_data   )
        ,.inject_logger_replay_tx_rdy   (inject_logger_replay_tx_rdy    )
    );
    assign memA_ready = 1'b1;

    ram_1rw_byte_mask_out_reg_wrap #(
         .DATA_W(`MEM_DATA_W)
        ,.DEPTH (2 ** `MEM_ADDR_W)
    ) memA (
         .clk           (clk                    )
        ,.rst           (rst                    )
        ,.en_a          (memA_read | memA_write )
        ,.wr_en_a       (memA_write             )
        ,.addr_a        (memA_address           )
        ,.din_a         (memA_writedata         )
        ,.wr_mask_a     (memA_byteenable        )

        ,.dout_val_a    (memA_readdatavalid     )
        ,.dout_a        (memA_readdata          )
    );

    assign memB_ready = 1'b1;
     
    ram_1rw_byte_mask_out_reg_wrap #(
         .DATA_W(`MEM_DATA_W        )
        ,.DEPTH (2 ** `MEM_ADDR_W   )
    ) memB (
         .clk           (clk                    )
        ,.rst           (rst                    )
        ,.en_a          (memB_read | memB_write )
        ,.wr_en_a       (memB_write             )
        ,.addr_a        (memB_address           )
        ,.din_a         (memB_writedata         )
        ,.wr_mask_a     (memB_byteenable        )

        ,.dout_val_a    (memB_readdatavalid     )
        ,.dout_a        (memB_readdata          )
    );
      
    parameter_checker parameter_checker (.clk(clk));
    tcp_logger_param_checker tcp_log_checker (.clk(clk));
endmodule
