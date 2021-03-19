`include "soc_defs.vh"
`include "udp_echo_app_stats_defs.svh"
module udp_app_no_noc_log (
     input clk
    ,input rst
    
    ,input  logic                               udp_udp_app_log_rx_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]            udp_udp_app_log_rx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]            udp_udp_app_log_rx_dst_ip
    ,input  udp_pkt_hdr                         udp_udp_app_log_rx_udp_hdr
    ,output logic                               udp_app_log_udp_rx_hdr_rdy

    ,input  logic                               udp_udp_app_log_rx_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]      udp_udp_app_log_rx_data
    ,input  logic                               udp_udp_app_log_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]       udp_udp_app_log_rx_padbytes
    ,output logic                               udp_app_log_udp_rx_data_rdy

    ,output logic                               udp_app_log_udp_tx_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]            udp_app_log_udp_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            udp_app_log_udp_tx_dst_ip
    ,output udp_pkt_hdr                         udp_app_log_udp_tx_udp_hdr
    ,input                                      udp_udp_app_log_tx_hdr_rdy

    ,output logic                               udp_app_log_udp_tx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]      udp_app_log_udp_tx_data
    ,output logic                               udp_app_log_udp_tx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       udp_app_log_udp_tx_padbytes
    ,input  logic                               udp_udp_app_log_tx_data_rdy
   
    ,input  logic                               app_stats_do_log
    ,input  logic                               app_stats_incr_bytes_sent
    ,input  logic   [`MAC_INTERFACE_BYTES_W:0]  app_stats_num_bytes_sent
);
    
    logic                               log_wr_req_val;
    udp_app_stats_struct                log_wr_req_data;
    
    logic                               log_rd_req_val;
    logic   [STATS_DEPTH_LOG2-1:0]      log_rd_req_addr;

    logic                               log_rd_resp_val;
    eth_latency_stats_struct            log_rd_resp_data;

    logic   [STATS_DEPTH_LOG2-1:0]      curr_wr_addr;
    logic                               has_wrapped;

    udp_echo_app_stats_record #(
        .NUM_BYTES_W    (`MAC_INTERFACE_BYTES_W)
    ) recorder (
         .clk   (clk    )
        ,.rst   (rst    )
   
        ,.app_stats_do_log          (app_stats_do_log           )
        ,.app_stats_incr_bytes_sent (app_stats_incr_bytes_sent  )
        ,.app_stats_num_bytes_sent  (app_stats_num_bytes_sent   )

        ,.log_wr_req_val            (log_wr_req_val             )
        ,.log_wr_req_data           (log_wr_req_data            )
    );

    simple_no_noc_reader #(
         .ADDR_W                (STATS_DEPTH_LOG2       )
        ,.RESP_DATA_STRUCT_W    (UDP_APP_STATS_STRUCT_W )
        ,.CLIENT_ADDR_W         (CLIENT_ADDR_W          )
    ) reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_log_rx_hdr_val    (udp_udp_app_log_rx_hdr_val )
        ,.udp_log_rx_src_ip     (udp_udp_app_log_rx_src_ip  )
        ,.udp_log_rx_dst_ip     (udp_udp_app_log_rx_dst_ip  )
        ,.udp_log_rx_udp_hdr    (udp_udp_app_log_rx_udp_hdr )
        ,.log_udp_rx_hdr_rdy    (udp_app_log_udp_rx_hdr_rdy )
    
        ,.udp_log_rx_data_val   (udp_udp_app_log_rx_data_val)
        ,.udp_log_rx_data       (udp_udp_app_log_rx_data    )
        ,.udp_log_rx_last       (udp_udp_app_log_rx_last    )
        ,.udp_log_rx_padbytes   (udp_udp_app_log_rx_padbytes)
        ,.log_udp_rx_data_rdy   (udp_app_log_udp_rx_data_rdy)
        
        ,.log_udp_tx_hdr_val    (udp_app_log_udp_tx_hdr_val )
        ,.log_udp_tx_src_ip     (udp_app_log_udp_tx_src_ip  )
        ,.log_udp_tx_dst_ip     (udp_app_log_udp_tx_dst_ip  )
        ,.log_udp_tx_udp_hdr    (udp_app_log_udp_tx_udp_hdr )
        ,.udp_log_tx_hdr_rdy    (udp_udp_app_log_tx_hdr_rdy )
    
        ,.log_udp_tx_data_val   (udp_app_log_udp_tx_data_val)
        ,.log_udp_tx_data       (udp_app_log_udp_tx_data    )
        ,.log_udp_tx_last       (udp_app_log_udp_tx_last    )
        ,.log_udp_tx_padbytes   (udp_app_log_udp_tx_padbytes)
        ,.udp_log_tx_data_rdy   (udp_udp_app_log_tx_data_rdy)
    
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
