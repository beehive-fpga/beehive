`include "echo_app_stats_defs.svh"
module echo_app_stats_log #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input                                  echo_app_incr_req_done
    
    ,input                                  ctovr_echo_app_stats_val
    ,input          [`NOC_DATA_WIDTH-1:0]   ctovr_echo_app_stats_data
    ,output logic                           echo_app_stats_ctovr_rdy

    ,output logic                           echo_app_stats_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   echo_app_stats_vrtoc_data
    ,input                                  vrtoc_echo_app_stats_rdy
);

    localparam ECHO_APP_LOG_ADDR_W = STATS_DEPTH_LOG2;
    
    logic                               log_wr_req_val;
    echo_app_stats_struct               log_wr_req_data;

    logic                               log_rd_req_val;
    logic   [ECHO_APP_LOG_ADDR_W-1:0]   log_rd_req_addr;

    logic                               log_rd_resp_val;
    echo_app_stats_struct               log_rd_resp_data;

    logic   [ECHO_APP_LOG_ADDR_W-1:0]   curr_wr_addr;
    logic                               log_has_wrapped;

    echo_app_stats_record recorder (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.echo_app_incr_req_done    (echo_app_incr_req_done )
                                                            
        ,.log_wr_req_val            (log_wr_req_val         )
        ,.log_wr_req_data           (log_wr_req_data        )
    );
    
    simple_log_udp_noc_read #(
         .SRC_X                 (SRC_X                      )
        ,.SRC_Y                 (SRC_Y                      )
        ,.ADDR_W                (ECHO_APP_LOG_ADDR_W        )
        ,.RESP_DATA_STRUCT_W    (ECHO_APP_STATS_STRUCT_W    )
        ,.CLIENT_ADDR_W         (CLIENT_ADDR_W              )
    ) reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.ctovr_reader_in_val   (ctovr_echo_app_stats_val  )
        ,.ctovr_reader_in_data  (ctovr_echo_app_stats_data )
        ,.reader_in_ctovr_rdy   (echo_app_stats_ctovr_rdy  )
        
        ,.reader_out_vrtoc_val  (echo_app_stats_vrtoc_val  )
        ,.reader_out_vrtoc_data (echo_app_stats_vrtoc_data )
        ,.vrtoc_reader_out_rdy  (vrtoc_echo_app_stats_rdy  )
    
        ,.log_rd_req_val        (log_rd_req_val            )
        ,.log_rd_req_addr       (log_rd_req_addr           )
                                                           
        ,.log_rd_resp_val       (log_rd_resp_val           )
        ,.log_rd_resp_data      (log_rd_resp_data          )
                                                           
        ,.curr_wr_addr          (curr_wr_addr              )
        ,.has_wrapped           (has_wrapped               )
    );

    
    simple_log #(
         .LOG_DATA_W        (ECHO_APP_STATS_STRUCT_W)
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
