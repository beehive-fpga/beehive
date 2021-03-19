`include "udp_rs_encode_defs.svh"
module udp_rs_encode_wrap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_app_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_app_in_data
    ,output logic                           udp_app_in_noc0_ctovr_rdy
    
    ,output logic                           udp_app_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_app_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_udp_app_out_rdy
    
    ,input                                  noc0_ctovr_rs_enc_stats_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rs_enc_stats_in_data
    ,output logic                           rs_enc_stats_in_noc0_ctovr_rdy
    
    ,output logic                           rs_enc_stats_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rs_enc_stats_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_rs_enc_stats_out_rdy
);
    logic                                   noc_in_stream_encoder_req_val;
    logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   noc_in_stream_encoder_req_num_blocks;
    logic                                   stream_encoder_noc_in_req_rdy;

    logic                               noc_in_stream_encoder_req_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_in_stream_encoder_req_data;
    logic                               stream_encoder_noc_in_req_data_rdy;

    logic                                   in_out_meta_val;
    logic   [`IP_ADDR_W-1:0]                in_out_src_ip;
    logic   [`IP_ADDR_W-1:0]                in_out_dst_ip;
    logic   [`PORT_NUM_W-1:0]               in_out_src_port;
    logic   [`PORT_NUM_W-1:0]               in_out_dst_port;
    logic   [`UDP_LENGTH_W-1:0]             in_out_data_len;
    logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   in_out_num_blocks;
    logic                                   out_in_meta_rdy;

    logic                                   in_ctrl_in_datap_store_hdr;
    logic                                   in_ctrl_in_datap_store_meta;
    logic                                   in_ctrl_in_datap_store_req;
    logic                                   in_ctrl_in_datap_incr_flits;

    logic                                   in_datap_in_ctrl_last_flit;
    
    logic                                   stream_encoder_noc_out_resp_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]           stream_encoder_noc_out_resp_data;
    logic                                   stream_encoder_noc_out_resp_last;
    logic                                   noc_out_stream_encoder_resp_data_rdy;

    logic                                   out_ctrl_out_datap_store_meta;
    udp_rs_tx_flit_e                        out_ctrl_out_datap_out_sel;
    logic                                   out_ctrl_out_datap_incr_data_flit;

    logic                                   out_datap_out_ctrl_last_data_flit;
    logic   [`UDP_LENGTH_W-1:0]             out_datap_out_ctrl_data_len;
    
    logic   [ENCODER_NUM_REQ_BLOCKS_W-1:0]  stream_encoder_req_num_blocks;

    logic                           noc_out_fifo_rdy;
    logic                           fifo_noc_out_val;
    
    logic                           output_queue_wr_req;
    logic                           output_queue_full;
    
    logic                           output_queue_rd_req;
    logic                           output_queue_empty;
    logic   [`NOC_DATA_WIDTH-1:0]   output_queue_rd_data;
    
    logic                           rs_enc_incr_bytes_sent;
    logic   [`NOC_DATA_BYTES_W:0]   rs_enc_num_bytes_sent;
    logic                           rs_enc_incr_reqs_done;

    udp_rs_encode_in_ctrl in_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_app_in_val             (noc0_ctovr_udp_app_in_val          )
        ,.udp_app_in_noc0_ctovr_rdy             (udp_app_in_noc0_ctovr_rdy          )
                                                                                    
        ,.noc_in_stream_encoder_req_val         (noc_in_stream_encoder_req_val      )
        ,.stream_encoder_noc_in_req_rdy         (stream_encoder_noc_in_req_rdy      )
                                                                                    
        ,.noc_in_stream_encoder_req_data_val    (noc_in_stream_encoder_req_data_val )
        ,.stream_encoder_noc_in_req_data_rdy    (stream_encoder_noc_in_req_data_rdy )
                                                                                    
        ,.in_out_meta_val                       (in_out_meta_val                    )
        ,.out_in_meta_rdy                       (out_in_meta_rdy                    )
                                                                                    
        ,.in_ctrl_in_datap_store_hdr            (in_ctrl_in_datap_store_hdr         )
        ,.in_ctrl_in_datap_store_meta           (in_ctrl_in_datap_store_meta        )
        ,.in_ctrl_in_datap_store_req            (in_ctrl_in_datap_store_req         )
        ,.in_ctrl_in_datap_incr_flits           (in_ctrl_in_datap_incr_flits        )
                                                                                    
        ,.in_datap_in_ctrl_last_flit            (in_datap_in_ctrl_last_flit         )
    );

    udp_rs_encode_in_datap in_datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_ctovr_udp_app_in_data            (noc0_ctovr_udp_app_in_data             )
                                                                                        
        ,.noc_in_stream_encoder_req_num_blocks  (noc_in_stream_encoder_req_num_blocks   )
        ,.noc_in_stream_encoder_req_data        (noc_in_stream_encoder_req_data         )
                                                                                        
        ,.in_out_src_ip                         (in_out_src_ip                          )
        ,.in_out_dst_ip                         (in_out_dst_ip                          )
        ,.in_out_src_port                       (in_out_src_port                        )
        ,.in_out_dst_port                       (in_out_dst_port                        )
        ,.in_out_data_len                       (in_out_data_len                        )
        ,.in_out_num_blocks                     (in_out_num_blocks                      )
                                                                                        
        ,.in_ctrl_in_datap_store_hdr            (in_ctrl_in_datap_store_hdr             )
        ,.in_ctrl_in_datap_store_meta           (in_ctrl_in_datap_store_meta            )
        ,.in_ctrl_in_datap_store_req            (in_ctrl_in_datap_store_req             )
        ,.in_ctrl_in_datap_incr_flits           (in_ctrl_in_datap_incr_flits            )
                                                                                        
        ,.in_datap_in_ctrl_last_flit            (in_datap_in_ctrl_last_flit             )
    );

    assign stream_encoder_req_num_blocks =
        noc_in_stream_encoder_req_num_blocks[ENCODER_NUM_REQ_BLOCKS_W-1:0];
    rs_encode_stream_wrap #(
         .NUM_REQ_BLOCKS    (ENCODER_NUM_REQ_BLOCKS     )
        ,.NUM_REQ_BLOCKS_W  (ENCODER_NUM_REQ_BLOCKS_W   )
        ,.DATA_W            (`NOC_DATA_WIDTH            )
        ,.NUM_RS_UNITS      (16                         )
    ) rs_encoder (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_stream_encoder_req_val        (noc_in_stream_encoder_req_val          )
        ,.src_stream_encoder_req_num_blocks (stream_encoder_req_num_blocks          )
        ,.stream_encoder_src_req_rdy        (stream_encoder_noc_in_req_rdy          )
    
        ,.src_stream_encoder_req_data_val   (noc_in_stream_encoder_req_data_val     )
        ,.src_stream_encoder_req_data       (noc_in_stream_encoder_req_data         )
        ,.stream_encoder_src_req_data_rdy   (stream_encoder_noc_in_req_data_rdy     )
    
        ,.stream_encoder_dst_resp_data_val  (stream_encoder_noc_out_resp_data_val   )
        ,.stream_encoder_dst_resp_data      (stream_encoder_noc_out_resp_data       )
        ,.stream_encoder_dst_resp_last      (stream_encoder_noc_out_resp_last       )
        ,.dst_stream_encoder_resp_data_rdy  (noc_out_stream_encoder_resp_data_rdy   )
    );

    assign output_queue_wr_req = stream_encoder_noc_out_resp_data_val 
                                 & ~output_queue_full;
    assign noc_out_stream_encoder_resp_data_rdy = ~output_queue_full;

    packet_queue #(
         .width_p       (`NOC_DATA_WIDTH    )
        ,.log2_els_p    (8                  )
    ) output_queue (
         .clk   (clk    )
        ,.rst   (rst    )
    
   
        ,.wr_req        (output_queue_wr_req                )
        ,.wr_data       (stream_encoder_noc_out_resp_data   )
        ,.full          (output_queue_full                  )

        ,.rd_req        (output_queue_rd_req                )
        ,.empty         (output_queue_empty                 )
        ,.rd_data       (output_queue_rd_data               )
    
        ,.dump_packet   (1'b0)
        ,.cmt_packet    (stream_encoder_noc_out_resp_last   )
    
        ,.curr_pkt_els  (/*unused*/)
    );

    assign output_queue_rd_req = ~output_queue_empty & noc_out_fifo_rdy;
    assign fifo_noc_out_val = ~output_queue_empty;

    udp_rs_encode_out_ctrl out_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.in_out_meta_val                       (in_out_meta_val                        )
        ,.out_in_meta_rdy                       (out_in_meta_rdy                        )
                                                                                        
        ,.udp_app_out_noc0_vrtoc_val            (udp_app_out_noc0_vrtoc_val             )
        ,.noc0_vrtoc_udp_app_out_rdy            (noc0_vrtoc_udp_app_out_rdy             )
                                                                                        
        ,.stream_encoder_noc_out_resp_data_val  (fifo_noc_out_val                       )
        ,.noc_out_stream_encoder_resp_data_rdy  (noc_out_fifo_rdy                       )
                                                                                        
        ,.out_ctrl_out_datap_store_meta         (out_ctrl_out_datap_store_meta          )
        ,.out_ctrl_out_datap_out_sel            (out_ctrl_out_datap_out_sel             )
        ,.out_ctrl_out_datap_incr_data_flit     (out_ctrl_out_datap_incr_data_flit      )
                                                                                        
        ,.out_datap_out_ctrl_last_data_flit     (out_datap_out_ctrl_last_data_flit      )
        ,.out_datap_out_ctrl_data_len           (out_datap_out_ctrl_data_len            )
                                                                                        
        ,.rs_enc_incr_bytes_sent                (rs_enc_incr_bytes_sent                 )
        ,.rs_enc_num_bytes_sent                 (rs_enc_num_bytes_sent                  )
        ,.rs_enc_incr_reqs_done                 (rs_enc_incr_reqs_done                  )
    );

    udp_rs_encode_out_datap #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) out_datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.in_out_src_ip                     (in_out_src_ip                      )
        ,.in_out_dst_ip                     (in_out_dst_ip                      )
        ,.in_out_src_port                   (in_out_src_port                    )
        ,.in_out_dst_port                   (in_out_dst_port                    )
        ,.in_out_data_len                   (in_out_data_len                    )
        ,.in_out_num_blocks                 (in_out_num_blocks                  )
                                                                                
        ,.udp_app_out_noc0_vrtoc_data       (udp_app_out_noc0_vrtoc_data        )
                                                                                
        ,.stream_encoder_noc_out_resp_data  (output_queue_rd_data               )
                                                                                
        ,.out_ctrl_out_datap_store_meta     (out_ctrl_out_datap_store_meta      )
        ,.out_ctrl_out_datap_out_sel        (out_ctrl_out_datap_out_sel         )
        ,.out_ctrl_out_datap_incr_data_flit (out_ctrl_out_datap_incr_data_flit  )
                                                                                
        ,.out_datap_out_ctrl_last_data_flit (out_datap_out_ctrl_last_data_flit  )
        ,.out_datap_out_ctrl_data_len       (out_datap_out_ctrl_data_len        )
    );

    rs_encode_stats #(
         .SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.NUM_BYTES_W   (`NOC_DATA_BYTES_W  )
    ) rs_encode_stats (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rs_enc_incr_bytes_sent            (rs_enc_incr_bytes_sent             )
        ,.rs_enc_num_bytes_sent             (rs_enc_num_bytes_sent              )
        ,.rs_enc_incr_reqs_done             (rs_enc_incr_reqs_done              )
                                                                                
        ,.noc0_ctovr_rs_enc_stats_in_val    (noc0_ctovr_rs_enc_stats_in_val     )
        ,.noc0_ctovr_rs_enc_stats_in_data   (noc0_ctovr_rs_enc_stats_in_data    )
        ,.rs_enc_stats_in_noc0_ctovr_rdy    (rs_enc_stats_in_noc0_ctovr_rdy     )
                                                                                
        ,.rs_enc_stats_out_noc0_vrtoc_val   (rs_enc_stats_out_noc0_vrtoc_val    )
        ,.rs_enc_stats_out_noc0_vrtoc_data  (rs_enc_stats_out_noc0_vrtoc_data   )
        ,.noc0_vrtoc_rs_enc_stats_out_rdy   (noc0_vrtoc_rs_enc_stats_out_rdy    )
    );
endmodule
