`include "rs_encode_stats_defs.svh"
module rs_encode_stats #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NUM_BYTES_W = `NOC_DATA_BYTES_W
)(
     input clk
    ,input rst

    ,input                                  rs_enc_incr_bytes_sent
    ,input          [NUM_BYTES_W:0]         rs_enc_num_bytes_sent
    ,input                                  rs_enc_incr_reqs_done
    
    ,input                                  noc0_ctovr_rs_enc_stats_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rs_enc_stats_in_data
    ,output logic                           rs_enc_stats_in_noc0_ctovr_rdy
    
    ,output logic                           rs_enc_stats_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rs_enc_stats_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_rs_enc_stats_out_rdy
);

    localparam RS_LOG_ADDR_W = STATS_DEPTH_LOG2;
    logic                           log_wr_req_val;
    rs_enc_stats_struct             log_wr_req_data;
    
    logic                           log_rd_req_val;
    logic   [RS_LOG_ADDR_W-1:0]     log_rd_req_addr;

    logic                           log_rd_resp_val;
    rs_enc_stats_struct             log_rd_resp_data;

    logic   [RS_LOG_ADDR_W-1:0]     curr_wr_addr;
    logic                           log_has_wrapped;

    rs_encode_stats_record #(
        .NUM_BYTES_W    (`NOC_DATA_BYTES_W  )
    ) recorder (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rs_enc_incr_bytes_sent    (rs_enc_incr_bytes_sent )
        ,.rs_enc_num_bytes_sent     (rs_enc_num_bytes_sent  )
        ,.rs_enc_incr_reqs_done     (rs_enc_incr_reqs_done  )
        
        ,.log_wr_req_val            (log_wr_req_val         )
        ,.log_wr_req_data           (log_wr_req_data        )
    );

    simple_log_udp_noc_read #(
         .SRC_X                 (SRC_X                      )
        ,.SRC_Y                 (SRC_Y                      )
        ,.ADDR_W                (RS_LOG_ADDR_W              )
        ,.RESP_DATA_STRUCT_W    (RS_ENC_STATS_STRUCT_W      )
        ,.CLIENT_ADDR_W         (CLIENT_ADDR_W              )
        ,.UDP_DST_X             (UDP_TX_TILE_X              )
        ,.UDP_DST_Y             (UDP_TX_TILE_Y              )
    ) reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.ctovr_reader_in_val   (noc0_ctovr_rs_enc_stats_in_val     )
        ,.ctovr_reader_in_data  (noc0_ctovr_rs_enc_stats_in_data    )
        ,.reader_in_ctovr_rdy   (rs_enc_stats_in_noc0_ctovr_rdy     )
        
        ,.reader_out_vrtoc_val  (rs_enc_stats_out_noc0_vrtoc_val    )
        ,.reader_out_vrtoc_data (rs_enc_stats_out_noc0_vrtoc_data   )
        ,.vrtoc_reader_out_rdy  (noc0_vrtoc_rs_enc_stats_out_rdy    )
    
        ,.log_rd_req_val        (log_rd_req_val                     )
        ,.log_rd_req_addr       (log_rd_req_addr                    )
                                                                    
        ,.log_rd_resp_val       (log_rd_resp_val                    )
        ,.log_rd_resp_data      (log_rd_resp_data                   )
                                                                    
        ,.curr_wr_addr          (curr_wr_addr                       )
        ,.has_wrapped           (has_wrapped                        )
    );

    
    simple_log #(
         .LOG_DATA_W        (RS_ENC_STATS_STRUCT_W  )
        ,.MEM_DEPTH_LOG2    (STATS_DEPTH_LOG2       )
    ) stats_log (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val        (log_wr_req_val     )
        ,.wr_req_data       (log_wr_req_data    )
    
        ,.rd_req_val        (log_rd_req_val     )
        ,.rd_req_addr       (log_rd_req_addr    )
    
        ,.rd_resp_val       (log_rd_resp_val    )
        ,.rd_resp_data      (log_rd_resp_data   )
    
        ,.curr_wr_addr      (curr_wr_addr       )
        ,.log_has_wrapped   (has_wrapped        )
    );

endmodule
