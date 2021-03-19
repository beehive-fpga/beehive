`include "soc_defs.vh"
`include "eth_latency_stats_defs.svh"
module eth_no_noc_log (
     input clk
    ,input rst
    
    ,input  logic                           eth_lat_wr_val
    ,input  logic   [`PKT_TIMESTAMP_W-1:0]  eth_lat_wr_timestamp

    ,input  logic                           udp_eth_lat_rx_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]        udp_eth_lat_rx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        udp_eth_lat_rx_dst_ip
    ,input  udp_pkt_hdr                     udp_eth_lat_rx_udp_hdr
    ,output logic                           eth_lat_udp_rx_hdr_rdy

    ,input  logic                           udp_eth_lat_rx_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  udp_eth_lat_rx_data
    ,input  logic                           udp_eth_lat_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   udp_eth_lat_rx_padbytes
    ,output logic                           eth_lat_udp_rx_data_rdy

    ,output logic                           eth_lat_udp_tx_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]        eth_lat_udp_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]        eth_lat_udp_tx_dst_ip
    ,output udp_pkt_hdr                     eth_lat_udp_tx_udp_hdr
    ,input                                  udp_eth_lat_tx_hdr_rdy

    ,output logic                           eth_lat_udp_tx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  eth_lat_udp_tx_data
    ,output logic                           eth_lat_udp_tx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   eth_lat_udp_tx_padbytes
    ,input  logic                           udp_eth_lat_tx_data_rdy
);
    
    logic                               log_wr_req_val;
    eth_latency_stats_struct            log_wr_req_data;
    
    logic                               log_rd_req_val;
    logic   [ETH_STATS_DEPTH_LOG2-1:0]  log_rd_req_addr;

    logic                               log_rd_resp_val;
    eth_latency_stats_struct            log_rd_resp_data;

    logic   [ETH_STATS_DEPTH_LOG2-1:0]  curr_wr_addr;
    logic                               has_wrapped;

    eth_latency_stats_record record (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.eth_wr_log                    (eth_lat_wr_val         )
        ,.eth_wr_log_start_timestamp    (eth_lat_wr_timestamp   )
    
        ,.log_wr_req_val                (log_wr_req_val         )
        ,.log_wr_req_data               (log_wr_req_data        )
    );

    simple_no_noc_reader #(
         .ADDR_W                (ETH_STATS_DEPTH_LOG2       )
        ,.RESP_DATA_STRUCT_W    (ETH_LATENCY_STATS_STRUCT_W )
        ,.CLIENT_ADDR_W         (ETH_CLIENT_ADDR_W          )
    ) reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_log_rx_hdr_val    (udp_eth_lat_rx_hdr_val     )
        ,.udp_log_rx_src_ip     (udp_eth_lat_rx_src_ip      )
        ,.udp_log_rx_dst_ip     (udp_eth_lat_rx_dst_ip      )
        ,.udp_log_rx_udp_hdr    (udp_eth_lat_rx_udp_hdr     )
        ,.log_udp_rx_hdr_rdy    (eth_lat_udp_rx_hdr_rdy     )
    
        ,.udp_log_rx_data_val   (udp_eth_lat_rx_data_val    )
        ,.udp_log_rx_data       (udp_eth_lat_rx_data        )
        ,.udp_log_rx_last       (udp_eth_lat_rx_last        )
        ,.udp_log_rx_padbytes   (udp_eth_lat_rx_padbytes    )
        ,.log_udp_rx_data_rdy   (eth_lat_udp_rx_data_rdy    )
        
        ,.log_udp_tx_hdr_val    (eth_lat_udp_tx_hdr_val     )
        ,.log_udp_tx_src_ip     (eth_lat_udp_tx_src_ip      )
        ,.log_udp_tx_dst_ip     (eth_lat_udp_tx_dst_ip      )
        ,.log_udp_tx_udp_hdr    (eth_lat_udp_tx_udp_hdr     )
        ,.udp_log_tx_hdr_rdy    (udp_eth_lat_tx_hdr_rdy     )
    
        ,.log_udp_tx_data_val   (eth_lat_udp_tx_data_val    )
        ,.log_udp_tx_data       (eth_lat_udp_tx_data        )
        ,.log_udp_tx_last       (eth_lat_udp_tx_last        )
        ,.log_udp_tx_padbytes   (eth_lat_udp_tx_padbytes    )
        ,.udp_log_tx_data_rdy   (udp_eth_lat_tx_data_rdy    )
    
        ,.log_rd_req_val        (log_rd_req_val             )
        ,.log_rd_req_addr       (log_rd_req_addr            )
                                                            
        ,.log_rd_resp_val       (log_rd_resp_val            )
        ,.log_rd_resp_data      (log_rd_resp_data           )
                                                            
        ,.curr_wr_addr          (curr_wr_addr               )
        ,.has_wrapped           (has_wrapped                )
    );
    
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
