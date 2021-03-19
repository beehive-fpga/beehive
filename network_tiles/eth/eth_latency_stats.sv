`include "eth_latency_stats_defs.svh"
module eth_latency_stats #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NOC1_DATA_W=-1
    ,parameter NOC2_DATA_W=-1
)(
     input clk
    ,input rst

    ,input                                  eth_wr_log
    ,input  logic   [MSG_TIMESTAMP_W-1:0]   eth_wr_log_start_timestamp
    
    ,input                                  ctovr_eth_stats_in_val
    ,input          [NOC1_DATA_W-1:0]       ctovr_eth_stats_in_data
    ,output logic                           eth_stats_in_ctovr_rdy
    
    ,output logic                           eth_stats_out_vrtoc_val
    ,output logic   [NOC2_DATA_W-1:0]       eth_stats_out_vrtoc_data
    ,input                                  vrtoc_eth_stats_out_rdy
);
    logic                               log_wr_req_val;
    eth_latency_stats_struct            log_wr_req_data;
    
    logic                               log_rd_req_val;
    logic   [ETH_STATS_DEPTH_LOG2-1:0]  log_rd_req_addr;
    
    logic                               log_rd_resp_val;
    eth_latency_stats_struct            log_rd_resp_data;

    logic   [ETH_STATS_DEPTH_LOG2-1:0]  curr_wr_addr;
    logic                               has_wrapped;
    
    logic                           noc_ctd_eth_stats_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc_ctd_eth_stats_data;
    logic                           eth_stats_noc_ctd_rdy;
    
    logic                           eth_stats_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   eth_stats_noc_dtc_data;
    logic                           noc_dtc_eth_stats_rdy;

    eth_latency_stats_record recorder (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.eth_wr_log                    (eth_wr_log                 )
        ,.eth_wr_log_start_timestamp    (eth_wr_log_start_timestamp )
                                                                    
        ,.log_wr_req_val                (log_wr_req_val             )
        ,.log_wr_req_data               (log_wr_req_data            )
    );

// generate the width converters if necessary
generate
    if (NOC1_DATA_W != `NOC_DATA_WIDTH) begin
        // noc narrow to wide
        noc_ctrl_to_data ctd (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_noc_ctd_val   (ctovr_eth_stats_in_val     )
            ,.src_noc_ctd_data  (ctovr_eth_stats_in_data    )
            ,.noc_ctd_src_rdy   (eth_stats_in_ctovr_rdy     )
        
            ,.noc_ctd_dst_val   (noc_ctd_eth_stats_val      )
            ,.noc_ctd_dst_data  (noc_ctd_eth_stats_data     )
            ,.dst_noc_ctd_rdy   (eth_stats_noc_ctd_rdy      )
        );
    end
    else begin
        assign noc_ctd_eth_stats_val = ctovr_eth_stats_in_val;
        assign noc_ctd_eth_stats_data = ctovr_eth_stats_in_data;
        assign eth_stats_in_ctovr_rdy = eth_stats_noc_ctd_rdy;
    end
endgenerate

    simple_log_udp_noc_read #(
         .SRC_X                 (SRC_X                      )
        ,.SRC_Y                 (SRC_Y                      )
        ,.ADDR_W                (ETH_STATS_DEPTH_LOG2       )
        ,.RESP_DATA_STRUCT_W    (ETH_LATENCY_STATS_STRUCT_W )
        ,.CLIENT_ADDR_W         (ETH_CLIENT_ADDR_W          )
    ) reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.ctovr_reader_in_val   (noc_ctd_eth_stats_val      )
        ,.ctovr_reader_in_data  (noc_ctd_eth_stats_data     )
        ,.reader_in_ctovr_rdy   (eth_stats_noc_ctd_rdy      )
        
        ,.reader_out_vrtoc_val  (eth_stats_noc_dtc_val      )
        ,.reader_out_vrtoc_data (eth_stats_noc_dtc_data     )
        ,.vrtoc_reader_out_rdy  (noc_dtc_eth_stats_rdy      )
    
        ,.log_rd_req_val        (log_rd_req_val            )
        ,.log_rd_req_addr       (log_rd_req_addr           )
                                                           
        ,.log_rd_resp_val       (log_rd_resp_val           )
        ,.log_rd_resp_data      (log_rd_resp_data          )
                                                           
        ,.curr_wr_addr          (curr_wr_addr              )
        ,.has_wrapped           (has_wrapped               )
    );

generate
    if (NOC2_DATA_W != `NOC_DATA_WIDTH) begin
        // wide back to narrow
        noc_data_to_ctrl dtc (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_noc_dtc_val   (eth_stats_noc_dtc_val      )
            ,.src_noc_dtc_data  (eth_stats_noc_dtc_data     )
            ,.noc_dtc_src_rdy   (noc_dtc_eth_stats_rdy      )
        
            ,.noc_dtc_dst_val   (eth_stats_out_vrtoc_val    )
            ,.noc_dtc_dst_data  (eth_stats_out_vrtoc_data   )
            ,.dst_noc_dtc_rdy   (vrtoc_eth_stats_out_rdy    )
        );
    end
    else begin
        assign eth_stats_out_vrtoc_val = eth_stats_noc_dtc_val;
        assign eth_stats_out_vrtoc_data = eth_stats_noc_dtc_data;
        assign noc_dtc_eth_stats_rdy = vrtoc_eth_stats_out_rdy;
    end
endgenerate

    
    simple_log #(
         .LOG_DATA_W        (ETH_LATENCY_STATS_STRUCT_W )
        ,.MEM_DEPTH_LOG2    (ETH_STATS_DEPTH_LOG2       )
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
