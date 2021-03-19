`include "udp_echo_app_stats_defs.svh"
module udp_echo_app_stats #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NOC1_DATA_W=-1
    ,parameter NOC2_DATA_W=-1
)(
     input clk
    ,input rst

    ,input                                  app_stats_do_log
    ,input                                  app_stats_incr_bytes_sent
    ,input          [`NOC_DATA_BYTES_W:0]   app_stats_num_bytes_sent
    
    ,input                                  ctovr_udp_stats_in_val
    ,input          [NOC1_DATA_W-1:0]       ctovr_udp_stats_in_data
    ,output logic                           udp_stats_in_ctovr_rdy
    
    ,output logic                           udp_stats_out_vrtoc_val
    ,output logic   [NOC2_DATA_W-1:0]       udp_stats_out_vrtoc_data
    ,input                                  vrtoc_udp_stats_out_rdy
);

    logic                   log_wr_req_val;
    udp_app_stats_struct    log_wr_req_data;

    logic                           log_rd_req_val;
    logic   [STATS_DEPTH_LOG2-1:0]  log_rd_req_addr;

    logic                           log_rd_resp_val;
    udp_app_stats_struct            log_rd_resp_data;

    logic   [STATS_DEPTH_LOG2-1:0]  curr_wr_addr;
    logic                           has_wrapped;

    udp_echo_app_stats_record recorder (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.app_stats_do_log          (app_stats_do_log           )
        ,.app_stats_incr_bytes_sent (app_stats_incr_bytes_sent  )
        ,.app_stats_num_bytes_sent  (app_stats_num_bytes_sent   )
                                                                
        ,.log_wr_req_val            (log_wr_req_val             )
        ,.log_wr_req_data           (log_wr_req_data            )
    );

    simple_log_udp_noc_read #(
         .SRC_X                 (SRC_X                  )
        ,.SRC_Y                 (SRC_Y                  )
        ,.ADDR_W                (STATS_DEPTH_LOG2       )
        ,.RESP_DATA_STRUCT_W    (UDP_APP_STATS_STRUCT_W )
        ,.CLIENT_ADDR_W         (CLIENT_ADDR_W          )
    ) reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.ctovr_reader_in_val   (ctovr_udp_stats_in_val     )
        ,.ctovr_reader_in_data  (ctovr_udp_stats_in_data    )
        ,.reader_in_ctovr_rdy   (udp_stats_in_ctovr_rdy     )
        
        ,.reader_out_vrtoc_val  (udp_stats_out_vrtoc_val    )
        ,.reader_out_vrtoc_data (udp_stats_out_vrtoc_data   )
        ,.vrtoc_reader_out_rdy  (vrtoc_udp_stats_out_rdy    )
    
        ,.log_rd_req_val        (log_rd_req_val             )
        ,.log_rd_req_addr       (log_rd_req_addr            )
                                                            
        ,.log_rd_resp_val       (log_rd_resp_val            )
        ,.log_rd_resp_data      (log_rd_resp_data           )
                                                            
        ,.curr_wr_addr          (curr_wr_addr               )
        ,.has_wrapped           (has_wrapped                )
    );

    simple_log #(
         .LOG_DATA_W        (UDP_APP_STATS_STRUCT_W )
        ,.MEM_DEPTH_LOG2    (STATS_DEPTH_LOG2       )
    ) udp_stats_log (
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
