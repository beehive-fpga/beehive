`include "mrp_defs.svh"
`include "mrp_rx_defs.svh"
`include "mrp_tx_defs.svh"
module mrp_noc_wrap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input                                      noc0_ctovr_mrp_rx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_mrp_rx_in_data
    ,output logic                               mrp_rx_in_noc0_ctovr_rdy
    
    ,output logic                               mrp_tx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       mrp_tx_out_noc0_vrtoc_data    
    ,input  logic                               noc0_vrtoc_mrp_tx_out_rdy
    
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
    
    ,output logic   [63:0]                      pkts_sent_cnt
    
    ,input                                      rd_cmd_queue_empty
    ,output                                     rd_cmd_queue_rd_req
    ,input          [63:0]                      rd_cmd_queue_rd_data
    
    ,output                                     rd_resp_val
    ,output logic   [63:0]                      shell_reg_rd_data
);
    
    logic                           mrp_rx_in_mrp_engine_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        mrp_rx_in_mrp_engine_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        mrp_rx_in_mrp_engine_rx_dst_ip;
    logic   [`PORT_NUM_W-1:0]       mrp_rx_in_mrp_engine_rx_src_port;
    logic   [`PORT_NUM_W-1:0]       mrp_rx_in_mrp_engine_rx_dst_port;
    logic                           mrp_engine_mrp_rx_in_rx_hdr_rdy;

    logic                           mrp_rx_in_mrp_engine_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  mrp_rx_in_mrp_engine_rx_data;
    logic                           mrp_rx_in_mrp_engine_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   mrp_rx_in_mrp_engine_rx_padbytes;
    logic                           mrp_engine_mrp_rx_in_rx_data_rdy;
    
    logic                           mrp_engine_mrp_tx_out_tx_meta_val;
    logic   [`IP_ADDR_W-1:0]        mrp_engine_mrp_tx_out_tx_src_ip;
    logic   [`IP_ADDR_W-1:0]        mrp_engine_mrp_tx_out_tx_dst_ip;
    logic   [`PORT_NUM_W-1:0]       mrp_engine_mrp_tx_out_tx_src_port;
    logic   [`PORT_NUM_W-1:0]       mrp_engine_mrp_tx_out_tx_dst_port;
    logic   [`UDP_LENGTH_W-1:0]     mrp_engine_mrp_tx_out_tx_len;
    logic                           mrp_tx_out_mrp_engine_tx_meta_rdy;

    logic                           mrp_engine_mrp_tx_out_tx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  mrp_engine_mrp_tx_out_tx_data;
    logic                           mrp_engine_mrp_tx_out_tx_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   mrp_engine_mrp_tx_out_tx_data_padbytes;
    logic                           mrp_tx_out_mrp_engine_tx_data_rdy;
    
    mrp_rx_noc_in mrp_rx_noc_in (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_mrp_rx_in_val          (noc0_ctovr_mrp_rx_in_val           )
        ,.noc0_ctovr_mrp_rx_in_data         (noc0_ctovr_mrp_rx_in_data          )
        ,.mrp_rx_in_noc0_ctovr_rdy          (mrp_rx_in_noc0_ctovr_rdy           )
        
        ,.mrp_rx_in_mrp_engine_rx_hdr_val   (mrp_rx_in_mrp_engine_rx_hdr_val    )
        ,.mrp_rx_in_mrp_engine_rx_src_ip    (mrp_rx_in_mrp_engine_rx_src_ip     )
        ,.mrp_rx_in_mrp_engine_rx_dst_ip    (mrp_rx_in_mrp_engine_rx_dst_ip     )
        ,.mrp_rx_in_mrp_engine_rx_src_port  (mrp_rx_in_mrp_engine_rx_src_port   )
        ,.mrp_rx_in_mrp_engine_rx_dst_port  (mrp_rx_in_mrp_engine_rx_dst_port   )
        ,.mrp_engine_mrp_rx_in_rx_hdr_rdy   (mrp_engine_mrp_rx_in_rx_hdr_rdy    )
                                                                                
        ,.mrp_rx_in_mrp_engine_rx_data_val  (mrp_rx_in_mrp_engine_rx_data_val   )
        ,.mrp_rx_in_mrp_engine_rx_data      (mrp_rx_in_mrp_engine_rx_data       )
        ,.mrp_rx_in_mrp_engine_rx_last      (mrp_rx_in_mrp_engine_rx_last       )
        ,.mrp_rx_in_mrp_engine_rx_padbytes  (mrp_rx_in_mrp_engine_rx_padbytes   )
        ,.mrp_engine_mrp_rx_in_rx_data_rdy  (mrp_engine_mrp_rx_in_rx_data_rdy   )
    );

    mrp_engine mrp_engine (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_mrp_rx_meta_val       (mrp_rx_in_mrp_engine_rx_hdr_val        )
        ,.src_mrp_rx_src_ip         (mrp_rx_in_mrp_engine_rx_src_ip         )
        ,.src_mrp_rx_dst_ip         (mrp_rx_in_mrp_engine_rx_dst_ip         )
        ,.src_mrp_rx_src_port       (mrp_rx_in_mrp_engine_rx_src_port       )
        ,.src_mrp_rx_dst_port       (mrp_rx_in_mrp_engine_rx_dst_port       )
        ,.mrp_src_rx_meta_rdy       (mrp_engine_mrp_rx_in_rx_hdr_rdy        )
    
        ,.src_mrp_rx_data_val       (mrp_rx_in_mrp_engine_rx_data_val       )
        ,.src_mrp_rx_data           (mrp_rx_in_mrp_engine_rx_data           )
        ,.src_mrp_rx_data_last      (mrp_rx_in_mrp_engine_rx_last           )
        ,.src_mrp_rx_data_padbytes  (mrp_rx_in_mrp_engine_rx_padbytes       )
        ,.mrp_src_rx_data_rdy       (mrp_engine_mrp_rx_in_rx_data_rdy       )
    
        ,.mrp_dst_rx_meta_val       (mrp_dst_rx_meta_val                    )
        ,.mrp_dst_rx_conn_id        (mrp_dst_rx_conn_id                     )
        ,.mrp_dst_rx_msg_len        (mrp_dst_rx_msg_len                     )
        ,.dst_mrp_rx_meta_rdy       (dst_mrp_rx_meta_rdy                    )
    
        ,.mrp_dst_rx_outstream_val  (mrp_dst_rx_outstream_val               )
        ,.mrp_dst_rx_outstream      (mrp_dst_rx_outstream                   )
        ,.dst_mrp_rx_outstream_rdy  (dst_mrp_rx_outstream_rdy               )
        
        ,.src_mrp_tx_meta_val       (src_mrp_tx_meta_val                    )
        ,.src_mrp_tx_req_len        (src_mrp_tx_req_len                     )
        ,.src_mrp_tx_conn_id        (src_mrp_tx_conn_id                     )
        ,.src_mrp_tx_msg_done       (src_mrp_tx_msg_done                    )
        ,.mrp_src_tx_meta_rdy       (mrp_src_tx_meta_rdy                    )
    
        ,.src_mrp_tx_instream_val   (src_mrp_tx_instream_val                )
        ,.src_mrp_tx_instream       (src_mrp_tx_instream                    )
        ,.mrp_src_tx_instream_rdy   (mrp_src_tx_instream_rdy                )
        
        ,.mrp_dst_tx_meta_val       (mrp_engine_mrp_tx_out_tx_meta_val      )
        ,.mrp_dst_tx_src_ip         (mrp_engine_mrp_tx_out_tx_src_ip        )
        ,.mrp_dst_tx_dst_ip         (mrp_engine_mrp_tx_out_tx_dst_ip        )
        ,.mrp_dst_tx_src_port       (mrp_engine_mrp_tx_out_tx_src_port      )
        ,.mrp_dst_tx_dst_port       (mrp_engine_mrp_tx_out_tx_dst_port      )
        ,.mrp_dst_tx_len            (mrp_engine_mrp_tx_out_tx_len           )
        ,.dst_mrp_tx_meta_rdy       (mrp_tx_out_mrp_engine_tx_meta_rdy      )
    
        ,.mrp_dst_tx_data_val       (mrp_engine_mrp_tx_out_tx_data_val      )
        ,.mrp_dst_tx_data           (mrp_engine_mrp_tx_out_tx_data          )
        ,.mrp_dst_tx_data_last      (mrp_engine_mrp_tx_out_tx_data_last     )
        ,.mrp_dst_tx_data_padbytes  (mrp_engine_mrp_tx_out_tx_data_padbytes )
        ,.dst_mrp_tx_data_rdy       (mrp_tx_out_mrp_engine_tx_data_rdy      )
    
        ,.pkts_sent_cnt             (pkts_sent_cnt                          )

        ,.rd_cmd_queue_empty        (rd_cmd_queue_empty                     )
        ,.rd_cmd_queue_rd_req       (rd_cmd_queue_rd_req                    )
        ,.rd_cmd_queue_rd_data      (rd_cmd_queue_rd_data                   )

        ,.rd_resp_val               (rd_resp_val                            )
        ,.shell_reg_rd_data         (shell_reg_rd_data                      )
    );

    mrp_tx_noc_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) mrp_tx_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.mrp_tx_out_noc0_vrtoc_val                 (mrp_tx_out_noc0_vrtoc_val              )
        ,.mrp_tx_out_noc0_vrtoc_data                (mrp_tx_out_noc0_vrtoc_data             )
        ,.noc0_vrtoc_mrp_tx_out_rdy                 (noc0_vrtoc_mrp_tx_out_rdy              )
                                                                                            
        ,.mrp_engine_mrp_tx_out_tx_meta_val         (mrp_engine_mrp_tx_out_tx_meta_val      )
        ,.mrp_engine_mrp_tx_out_tx_src_ip           (mrp_engine_mrp_tx_out_tx_src_ip        )
        ,.mrp_engine_mrp_tx_out_tx_dst_ip           (mrp_engine_mrp_tx_out_tx_dst_ip        )
        ,.mrp_engine_mrp_tx_out_tx_src_port         (mrp_engine_mrp_tx_out_tx_src_port      )
        ,.mrp_engine_mrp_tx_out_tx_dst_port         (mrp_engine_mrp_tx_out_tx_dst_port      )
        ,.mrp_engine_mrp_tx_out_tx_len              (mrp_engine_mrp_tx_out_tx_len           )
        ,.mrp_tx_out_mrp_engine_tx_meta_rdy         (mrp_tx_out_mrp_engine_tx_meta_rdy      )
                                                                                            
        ,.mrp_engine_mrp_tx_out_tx_data_val         (mrp_engine_mrp_tx_out_tx_data_val      )
        ,.mrp_engine_mrp_tx_out_tx_data             (mrp_engine_mrp_tx_out_tx_data          )
        ,.mrp_engine_mrp_tx_out_tx_data_last        (mrp_engine_mrp_tx_out_tx_data_last     )
        ,.mrp_engine_mrp_tx_out_tx_data_padbytes    (mrp_engine_mrp_tx_out_tx_data_padbytes )
        ,.mrp_tx_out_mrp_engine_tx_data_rdy         (mrp_tx_out_mrp_engine_tx_data_rdy      )
    );
endmodule
