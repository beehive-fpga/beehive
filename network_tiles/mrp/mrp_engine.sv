`include "mrp_defs.svh"
module mrp_engine (
     input  clk
    ,input  rst 

    ,input                                      src_mrp_rx_meta_val
    ,input      [`IP_ADDR_W-1:0]                src_mrp_rx_src_ip
    ,input      [`IP_ADDR_W-1:0]                src_mrp_rx_dst_ip
    ,input      [`PORT_NUM_W-1:0]               src_mrp_rx_src_port
    ,input      [`PORT_NUM_W-1:0]               src_mrp_rx_dst_port
    ,output                                     mrp_src_rx_meta_rdy

    ,input                                      src_mrp_rx_data_val
    ,input          [`MAC_INTERFACE_W-1:0]      src_mrp_rx_data
    ,input                                      src_mrp_rx_data_last
    ,input          [`MAC_PADBYTES_W-1:0]       src_mrp_rx_data_padbytes
    ,output logic                               mrp_src_rx_data_rdy

    ,output logic                               mrp_dst_rx_meta_val
    ,output logic   [CONN_ID_W-1:0]             mrp_dst_rx_conn_id
    ,output logic   [RX_CONN_BUF_ADDR_W-1:0]    mrp_dst_rx_msg_len
    ,input                                      dst_mrp_rx_meta_rdy

    ,output logic                               mrp_dst_rx_outstream_val
    ,output         mrp_stream                  mrp_dst_rx_outstream
    ,input  logic                               dst_mrp_rx_outstream_rdy
    
    ,input  logic                               src_mrp_tx_meta_val
    ,input  logic   [`UDP_LENGTH_W-1:0]         src_mrp_tx_req_len
    ,input  logic   [CONN_ID_W-1:0]             src_mrp_tx_conn_id
    ,input  logic                               src_mrp_tx_msg_done
    ,output logic                               mrp_src_tx_meta_rdy

    ,input  logic                               src_mrp_tx_instream_val
    ,input          mrp_stream                  src_mrp_tx_instream
    ,output logic                               mrp_src_tx_instream_rdy
    
    ,output logic                               mrp_dst_tx_meta_val
    ,output logic   [`IP_ADDR_W-1:0]            mrp_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            mrp_dst_tx_dst_ip
    ,output logic   [`PORT_NUM_W-1:0]           mrp_dst_tx_src_port
    ,output logic   [`PORT_NUM_W-1:0]           mrp_dst_tx_dst_port
    ,output logic   [`UDP_LENGTH_W-1:0]         mrp_dst_tx_len
    ,input                                      dst_mrp_tx_meta_rdy

    ,output logic                               mrp_dst_tx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]      mrp_dst_tx_data
    ,output logic                               mrp_dst_tx_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       mrp_dst_tx_data_padbytes
    ,input  logic                               dst_mrp_tx_data_rdy
    
    ,output logic   [63:0]                      pkts_sent_cnt
    
    ,input                                      rd_cmd_queue_empty
    ,output                                     rd_cmd_queue_rd_req
    ,input          [63:0]                      rd_cmd_queue_rd_data
    
    ,output                                     rd_resp_val
    ,output logic   [63:0]                      shell_reg_rd_data
);
    logic                   mrp_rx_conn_id_table_wr_val;
    logic   [CONN_ID_W-1:0] mrp_rx_conn_id_table_wr_addr;
    mrp_req_key             mrp_rx_conn_id_table_wr_data;

    logic                   mrp_rx_conn_id_table_rd_req_val;
    logic   [CONN_ID_W-1:0] mrp_rx_conn_id_table_rd_req_addr;

    logic                   conn_id_table_mrp_rx_rd_resp_val;
    mrp_req_key             conn_id_table_mrp_rx_rd_resp_data;
    
    logic                   mrp_tx_dealloc_msg_finalize_val;
    mrp_req_key             mrp_tx_dealloc_msg_finalize_key;
    logic   [CONN_ID_W-1:0] mrp_tx_dealloc_msg_finalize_conn_id;
    logic                   dealloc_mrp_tx_msg_finalize_rdy;
    
    logic                   mrp_tx_conn_id_table_rd_req_val;
    logic   [CONN_ID_W-1:0] mrp_tx_conn_id_table_rd_req_addr;

    logic                   conn_id_table_mrp_tx_rd_resp_val;
    mrp_req_key             conn_id_table_mrp_tx_rd_resp_data;
    
    logic                   mrp_rx_mrp_tx_new_flow_val;
    logic   [CONN_ID_W-1:0] mrp_rx_mrp_tx_new_flow_conn_id;
    
    logic                   mrp_rx_buffer_outstream_meta_val;
    logic                   mrp_rx_buffer_outstream_start;
    logic                   mrp_rx_buffer_outstream_msg_done;
    logic   [CONN_ID_W-1:0] mrp_rx_buffer_outstream_conn_id;
    logic                   rx_buffer_mrp_outstream_meta_rdy;

    logic                   mrp_rx_buffer_rx_outstream_val;
    mrp_stream              mrp_rx_buffer_rx_outstream;
    logic                   rx_buffer_mrp_rx_outstream_rdy;

    mrp_rx mrp_rx_engine (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_mrp_rx_meta_val                   (src_mrp_rx_meta_val                    )
        ,.src_mrp_rx_src_ip                     (src_mrp_rx_src_ip                      )
        ,.src_mrp_rx_dst_ip                     (src_mrp_rx_dst_ip                      )
        ,.src_mrp_rx_src_port                   (src_mrp_rx_src_port                    )
        ,.src_mrp_rx_dst_port                   (src_mrp_rx_dst_port                    )
        ,.mrp_src_rx_meta_rdy                   (mrp_src_rx_meta_rdy                    )
                                                                                        
        ,.src_mrp_rx_data_val                   (src_mrp_rx_data_val                    )
        ,.src_mrp_rx_data                       (src_mrp_rx_data                        )
        ,.src_mrp_rx_data_last                  (src_mrp_rx_data_last                   )
        ,.src_mrp_rx_data_padbytes              (src_mrp_rx_data_padbytes               )
        ,.mrp_src_rx_data_rdy                   (mrp_src_rx_data_rdy                    )
    
        ,.mrp_dst_rx_outstream_meta_val         (mrp_rx_buffer_outstream_meta_val       )
        ,.mrp_dst_rx_outstream_start            (mrp_rx_buffer_outstream_start          )
        ,.mrp_dst_rx_outstream_msg_done         (mrp_rx_buffer_outstream_msg_done       )
        ,.mrp_dst_rx_outstream_conn_id          (mrp_rx_buffer_outstream_conn_id        )
        ,.dst_mrp_rx_outstream_meta_rdy         (rx_buffer_mrp_outstream_meta_rdy       )

        ,.mrp_dst_rx_outstream_val              (mrp_rx_buffer_rx_outstream_val         )
        ,.mrp_dst_rx_outstream                  (mrp_rx_buffer_rx_outstream             )
        ,.dst_mrp_rx_outstream_rdy              (rx_buffer_mrp_rx_outstream_rdy         )
    
    
        ,.mrp_rx_conn_id_table_wr_val           (mrp_rx_conn_id_table_wr_val            )
        ,.mrp_rx_conn_id_table_wr_addr          (mrp_rx_conn_id_table_wr_addr           )
        ,.mrp_rx_conn_id_table_wr_data          (mrp_rx_conn_id_table_wr_data           )
                                                                                        
        ,.mrp_rx_conn_id_table_rd_req_val       (mrp_rx_conn_id_table_rd_req_val        )
        ,.mrp_rx_conn_id_table_rd_req_addr      (mrp_rx_conn_id_table_rd_req_addr       )
                                                                                        
        ,.conn_id_table_mrp_rx_rd_resp_val      (conn_id_table_mrp_rx_rd_resp_val       )
        ,.conn_id_table_mrp_rx_rd_resp_data     (conn_id_table_mrp_rx_rd_resp_data      )
                                                                                        
        ,.mrp_tx_dealloc_msg_finalize_val       (mrp_tx_dealloc_msg_finalize_val        )
        ,.mrp_tx_dealloc_msg_finalize_key       (mrp_tx_dealloc_msg_finalize_key        )
        ,.mrp_tx_dealloc_msg_finalize_conn_id   (mrp_tx_dealloc_msg_finalize_conn_id    )
        ,.dealloc_mrp_tx_msg_finalize_rdy       (dealloc_mrp_tx_msg_finalize_rdy        )
        
        ,.rd_cmd_queue_empty                    (rd_cmd_queue_empty                     )
        ,.rd_cmd_queue_rd_req                   (rd_cmd_queue_rd_req                    )
        ,.rd_cmd_queue_rd_data                  (rd_cmd_queue_rd_data                   )

        ,.rd_resp_val                           (rd_resp_val                            )
        ,.shell_reg_rd_data                     (shell_reg_rd_data                      )
        
    );

    mrp_rx_buffer rx_buffer (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.mrp_rx_buffer_outstream_meta_val  (mrp_rx_buffer_outstream_meta_val   )
        ,.mrp_rx_buffer_outstream_conn_id   (mrp_rx_buffer_outstream_conn_id    )
        ,.mrp_rx_buffer_outstream_start     (mrp_rx_buffer_outstream_start      )
        ,.mrp_rx_buffer_outstream_msg_done  (mrp_rx_buffer_outstream_msg_done   )
        ,.rx_buffer_mrp_outstream_meta_rdy  (rx_buffer_mrp_outstream_meta_rdy   )

        ,.mrp_rx_buffer_outstream_val       (mrp_rx_buffer_rx_outstream_val     )
        ,.mrp_rx_buffer_outstream           (mrp_rx_buffer_rx_outstream         )
        ,.rx_buffer_mrp_outstream_rdy       (rx_buffer_mrp_rx_outstream_rdy     )

        ,.rx_buffer_dst_meta_val            (mrp_dst_rx_meta_val                )
        ,.rx_buffer_dst_msg_len             (mrp_dst_rx_msg_len                 )
        ,.rx_buffer_dst_conn_id             (mrp_dst_rx_conn_id                 )
        ,.dst_rx_buffer_meta_rdy            (dst_mrp_rx_meta_rdy                )

        ,.rx_buffer_dst_outstream_val       (mrp_dst_rx_outstream_val           )
        ,.rx_buffer_dst_outstream           (mrp_dst_rx_outstream               )
        ,.dst_rx_buffer_outstream_rdy       (dst_mrp_rx_outstream_rdy           )
    );

    ram_2r1w_sync_backpressure #(
         .width_p   (MRP_REQ_KEY_W  )
        ,.els_p     (MAX_CONNS      )
    ) conn_id_table (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (mrp_rx_conn_id_table_wr_val        )
        ,.wr_req_addr   (mrp_rx_conn_id_table_wr_addr       )
        ,.wr_req_data   (mrp_rx_conn_id_table_wr_data       )
        ,.wr_req_rdy    ()
    
        ,.rd0_req_val   (mrp_rx_conn_id_table_rd_req_val    )
        ,.rd0_req_addr  (mrp_rx_conn_id_table_rd_req_addr   )
        ,.rd0_req_rdy   ()
    
        ,.rd0_resp_val  (conn_id_table_mrp_rx_rd_resp_val   )
        ,.rd0_resp_addr ()
        ,.rd0_resp_data (conn_id_table_mrp_rx_rd_resp_data  )
        ,.rd0_resp_rdy  (1'b1)
        
        ,.rd1_req_val   (mrp_tx_conn_id_table_rd_req_val    )
        ,.rd1_req_addr  (mrp_tx_conn_id_table_rd_req_addr   )
        ,.rd1_req_rdy   ()
    
        ,.rd1_resp_val  (conn_id_table_mrp_tx_rd_resp_val   )
        ,.rd1_resp_addr ()
        ,.rd1_resp_data (conn_id_table_mrp_tx_rd_resp_data  )
        ,.rd1_resp_rdy  (1'b1)
    );

    assign mrp_rx_mrp_tx_new_flow_val = mrp_rx_conn_id_table_wr_val;
    assign mrp_rx_mrp_tx_new_flow_conn_id = mrp_rx_conn_id_table_wr_addr;

    mrp_tx mrp_tx_engine (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.mrp_tx_conn_id_table_rd_req_val       (mrp_tx_conn_id_table_rd_req_val        )
        ,.mrp_tx_conn_id_table_rd_req_addr      (mrp_tx_conn_id_table_rd_req_addr       )
                                                                                        
        ,.conn_id_table_mrp_tx_rd_resp_val      (conn_id_table_mrp_tx_rd_resp_val       )
        ,.conn_id_table_mrp_tx_rd_resp_data     (conn_id_table_mrp_tx_rd_resp_data      )
    
        ,.mrp_rx_mrp_tx_new_flow_val            (mrp_rx_mrp_tx_new_flow_val             )
        ,.mrp_rx_mrp_tx_new_flow_conn_id        (mrp_rx_mrp_tx_new_flow_conn_id         )
        
        ,.src_mrp_tx_meta_val                   (src_mrp_tx_meta_val                    )
        ,.src_mrp_tx_req_len                    (src_mrp_tx_req_len                     )
        ,.src_mrp_tx_conn_id                    (src_mrp_tx_conn_id                     )
        ,.src_mrp_tx_msg_done                   (src_mrp_tx_msg_done                    )
        ,.mrp_src_tx_meta_rdy                   (mrp_src_tx_meta_rdy                    )
                                                                                        
        ,.src_mrp_tx_instream_val               (src_mrp_tx_instream_val                )
        ,.src_mrp_tx_instream                   (src_mrp_tx_instream                    )
        ,.mrp_src_tx_instream_rdy               (mrp_src_tx_instream_rdy                )
                                                                                        
        ,.mrp_dst_tx_meta_val                   (mrp_dst_tx_meta_val                    )
        ,.mrp_dst_tx_src_ip                     (mrp_dst_tx_src_ip                      )
        ,.mrp_dst_tx_dst_ip                     (mrp_dst_tx_dst_ip                      )
        ,.mrp_dst_tx_src_port                   (mrp_dst_tx_src_port                    )
        ,.mrp_dst_tx_dst_port                   (mrp_dst_tx_dst_port                    )
        ,.mrp_dst_tx_len                        (mrp_dst_tx_len                         )
        ,.dst_mrp_tx_meta_rdy                   (dst_mrp_tx_meta_rdy                    )
                                                                                        
        ,.mrp_dst_tx_data_val                   (mrp_dst_tx_data_val                    )
        ,.mrp_dst_tx_data                       (mrp_dst_tx_data                        )
        ,.mrp_dst_tx_data_last                  (mrp_dst_tx_data_last                   )
        ,.mrp_dst_tx_data_padbytes              (mrp_dst_tx_data_padbytes               )
        ,.dst_mrp_tx_data_rdy                   (dst_mrp_tx_data_rdy                    )
    
        ,.mrp_tx_dealloc_msg_finalize_val       (mrp_tx_dealloc_msg_finalize_val        )
        ,.mrp_tx_dealloc_msg_finalize_key       (mrp_tx_dealloc_msg_finalize_key        )
        ,.mrp_tx_dealloc_msg_finalize_conn_id   (mrp_tx_dealloc_msg_finalize_conn_id    )
        ,.dealloc_mrp_tx_msg_finalize_rdy       (dealloc_mrp_tx_msg_finalize_rdy        )
    
        ,.pkts_sent_cnt                         (pkts_sent_cnt                          )
    );
endmodule
