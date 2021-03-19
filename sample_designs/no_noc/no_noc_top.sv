`include "soc_defs.vh"
`include "packet_defs.vh"
module no_noc_top (
     input clk
    ,input rst
    
    ,input                                      mac_engine_rx_val
    ,input          [`MAC_INTERFACE_W-1:0]      mac_engine_rx_data
    ,input                                      mac_engine_rx_startframe
    ,input          [`MTU_SIZE_W-1:0]           mac_engine_rx_frame_size
    ,input                                      mac_engine_rx_endframe
    ,input          [`MAC_PADBYTES_W-1:0]       mac_engine_rx_padbytes
    ,output logic                               engine_mac_rx_rdy
    
    ,output logic                               engine_mac_tx_val
    ,input                                      mac_engine_tx_rdy
    ,output logic                               engine_mac_tx_startframe
    ,output logic   [`MTU_SIZE_W-1:0]           engine_mac_tx_frame_size 
    ,output logic                               engine_mac_tx_endframe
    ,output logic   [`MAC_INTERFACE_W-1:0]      engine_mac_tx_data
    ,output logic   [`MAC_PADBYTES_W-1:0]       engine_mac_tx_padbytes
);
    
    typedef struct packed {
        logic   [`NOC_DATA_WIDTH-1:0]       data;
        logic                               last;
        logic   [`NOC_PADBYTES_WIDTH-1:0]   padbytes;
    } data_buf_q_struct;
    localparam DATA_BUF_Q_STRUCT_W = $bits(data_buf_q_struct);

    localparam UDP_APP_ID = 0;
    localparam UDP_LOG_ID = 1;
    localparam ETH_LAT_LOG_ID = 2;
    localparam UDP_SRCS = 3;
    localparam UDP_DSTS = 3;

    eth_hdr                         eth_format_eth_filter_eth_hdr;
    logic   [`MTU_SIZE_W-1:0]       eth_format_eth_filter_data_size;
    logic   [`PKT_TIMESTAMP_W-1:0]  eth_format_eth_filter_timestamp;
    logic                           eth_format_eth_filter_hdr_val;
    logic                           eth_filter_eth_format_hdr_rdy;

    logic                           eth_format_eth_filter_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  eth_format_eth_filter_data;
    logic                           eth_filter_eth_format_data_rdy;
    logic                           eth_format_eth_filter_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   eth_format_eth_filter_data_padbytes;
    
    eth_hdr                         eth_filter_ip_format_eth_hdr;
    logic   [`MTU_SIZE_W-1:0]       eth_filter_ip_format_data_size;
    logic   [`PKT_TIMESTAMP_W-1:0]  eth_filter_ip_format_timestamp;
    logic                           eth_filter_ip_format_hdr_val;
    logic                           ip_format_eth_filter_hdr_rdy;

    logic                           eth_filter_ip_format_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  eth_filter_ip_format_data;
    logic                           ip_format_eth_filter_data_rdy;
    logic                           eth_filter_ip_format_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   eth_filter_ip_format_data_padbytes;
    
    logic                           ip_format_ip_filter_rx_hdr_val;
    ip_pkt_hdr                      ip_format_ip_filter_rx_ip_hdr;
    logic   [`PKT_TIMESTAMP_W-1:0]  ip_format_ip_filter_rx_timestamp;
    logic                           ip_filter_ip_format_rx_hdr_rdy;

    logic                           ip_format_ip_filter_rx_data_val;
    logic                           ip_filter_ip_format_rx_data_rdy;
    logic   [`MAC_INTERFACE_W-1:0]  ip_format_ip_filter_rx_data;
    logic                           ip_format_ip_filter_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   ip_format_ip_filter_rx_padbytes;
    
    logic                           ip_filter_udp_formatter_rx_hdr_val;
    ip_pkt_hdr                      ip_filter_udp_formatter_rx_ip_hdr;
    logic   [`TOT_LEN_W-1:0]        ip_filter_udp_formatter_rx_udp_len;
    logic   [`IP_ADDR_W-1:0]        ip_filter_udp_formatter_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        ip_filter_udp_formatter_rx_dst_ip;
    logic   [`PKT_TIMESTAMP_W-1:0]  ip_filter_udp_formatter_rx_timestamp;
    logic                           udp_formatter_ip_filter_rx_hdr_rdy;

    logic                           ip_filter_udp_formatter_rx_data_val;
    logic                           udp_formatter_ip_filter_rx_data_rdy;
    logic   [`MAC_INTERFACE_W-1:0]  ip_filter_udp_formatter_rx_data;
    logic                           ip_filter_udp_formatter_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   ip_filter_udp_formatter_rx_padbytes;
    
    logic                           udp_formatter_udp_splitter_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_formatter_udp_splitter_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_formatter_udp_splitter_rx_dst_ip;
    udp_pkt_hdr                     udp_formatter_udp_splitter_rx_udp_hdr;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_formatter_udp_splitter_rx_timestamp;
    logic                           udp_splitter_udp_formatter_rx_hdr_rdy;

    logic                           udp_formatter_udp_splitter_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_formatter_udp_splitter_rx_data;
    logic                           udp_formatter_udp_splitter_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_formatter_udp_splitter_rx_padbytes;
    logic                           udp_splitter_udp_formatter_rx_data_rdy;
    
    logic   [UDP_DSTS-1:0]                          udp_splitter_dsts_rx_hdr_val;
    logic                 [`IP_ADDR_W-1:0]          udp_splitter_dsts_rx_src_ip;
    logic                 [`IP_ADDR_W-1:0]          udp_splitter_dsts_rx_dst_ip;
    logic                 [UDP_HDR_W-1:0]           udp_splitter_dsts_rx_udp_hdr;
    logic                 [`PKT_TIMESTAMP_W-1:0]    udp_splitter_dsts_rx_timestamp;
    logic   [UDP_DSTS-1:0]                          dsts_udp_splitter_rx_hdr_rdy;

    logic   [UDP_DSTS-1:0]                          udp_splitter_dsts_rx_data_val;
    logic                 [`MAC_INTERFACE_W-1:0]    udp_splitter_dsts_rx_data;
    logic                                           udp_splitter_dsts_rx_last;
    logic                 [`MAC_PADBYTES_W-1:0]     udp_splitter_dsts_rx_padbytes;
    logic   [UDP_DSTS-1:0]                          dsts_udp_splitter_rx_data_rdy;
    
    logic                                           src_data_buf_q_wr_req;
    data_buf_q_struct                               src_data_buf_q_wr_data;
    logic                                           data_buf_q_src_full;

    logic                                           dst_data_buf_q_rd_req;
    data_buf_q_struct                               data_buf_q_dst_rd_data;
    logic                                           data_buf_q_dst_empty;
    
    
    logic                           udp_to_stream_ip_assemble_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_to_stream_ip_assemble_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_to_stream_ip_assemble_dst_ip;
    logic   [`TOT_LEN_W-1:0]        udp_to_stream_ip_assemble_udp_len;
    logic   [`PROTOCOL_W-1:0]       udp_to_stream_ip_assemble_protocol;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_to_stream_ip_assemble_timestamp;
    logic                           ip_assemble_udp_to_stream_hdr_rdy;
    
    logic                           udp_to_stream_ip_stream_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_to_stream_ip_stream_data;
    logic                           udp_to_stream_ip_stream_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_to_stream_ip_stream_padbytes;
    logic                           ip_stream_udp_to_stream_rdy;
    
    logic                               ip_assemble_ip_to_ethstream_hdr_val;
    ip_pkt_hdr                          ip_assemble_ip_to_ethstream_ip_hdr;
    logic       [`PKT_TIMESTAMP_W-1:0]  ip_assemble_ip_to_ethstream_timestamp;
    logic                               ip_to_ethstream_ip_assemble_hdr_rdy;
    
    logic                               ip_assemble_ip_to_ethstream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]      ip_assemble_ip_to_ethstream_data;
    logic                               ip_assemble_ip_to_ethstream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]       ip_assemble_ip_to_ethstream_data_padbytes;
    logic                               ip_to_ethstream_ip_assemble_data_rdy;
    
    logic                               ip_to_ethstream_eth_stream_hdr_val;
    eth_hdr                             ip_to_ethstream_eth_stream_eth_hdr;
    logic   [`TOT_LEN_W-1:0]            ip_to_ethstream_eth_stream_data_len;
    logic   [`PKT_TIMESTAMP_W-1:0]      ip_to_ethstream_eth_stream_timestamp;
    logic                               eth_stream_ip_to_ethstream_hdr_rdy;

    logic                               ip_to_ethstream_eth_stream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]      ip_to_ethstream_eth_stream_data;
    logic                               ip_to_ethstream_eth_stream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]       ip_to_ethstream_eth_stream_data_padbytes;
    logic                               eth_stream_ip_to_ethstream_data_rdy;
    
    logic                               eth_lat_wr_val;
    logic   [`PKT_TIMESTAMP_W-1:0]      eth_lat_wr_timestamp;
   
    logic                               app_stats_do_log;
    logic                               app_stats_incr_bytes_sent;
    logic   [`MAC_INTERFACE_BYTES_W:0]  app_stats_num_bytes_sent;
    
    logic   [UDP_SRCS-1:0]                          srcs_udp_merger_tx_hdr_val;
    logic   [UDP_SRCS-1:0][`IP_ADDR_W-1:0]          srcs_udp_merger_tx_src_ip;
    logic   [UDP_SRCS-1:0][`IP_ADDR_W-1:0]          srcs_udp_merger_tx_dst_ip;
    logic   [UDP_SRCS-1:0][UDP_HDR_W-1:0]           srcs_udp_merger_tx_udp_hdr;
    logic   [UDP_SRCS-1:0][`PKT_TIMESTAMP_W-1:0]    srcs_udp_merger_tx_timestamp;
    logic   [UDP_SRCS-1:0]                          udp_merger_srcs_tx_hdr_rdy;

    logic   [UDP_SRCS-1:0]                          srcs_udp_merger_tx_data_val;
    logic   [UDP_SRCS-1:0][`MAC_INTERFACE_W-1:0]    srcs_udp_merger_tx_data;
    logic   [UDP_SRCS-1:0]                          srcs_udp_merger_tx_last;
    logic   [UDP_SRCS-1:0][`MAC_PADBYTES_W-1:0]     srcs_udp_merger_tx_padbytes;
    logic   [UDP_SRCS-1:0]                          udp_merger_srcs_tx_data_rdy;
    
    logic                           udp_merger_udp_stream_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_merger_udp_stream_src_ip_addr;
    logic   [`IP_ADDR_W-1:0]        udp_merger_udp_stream_dst_ip_addr;
    udp_pkt_hdr                     udp_merger_udp_stream_udp_hdr;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_merger_udp_stream_timestamp;
    logic                           udp_stream_udp_merger_hdr_rdy;
    
    logic                           udp_merger_udp_stream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_merger_udp_stream_data;
    logic                           udp_merger_udp_stream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_merger_udp_stream_data_padbytes;
    logic                           udp_stream_udp_merger_data_rdy;

    /* 
     *
     * Rx chain
     *
     */
    eth_frame_format rx_eth_format (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_eth_format_val            (mac_engine_rx_val                  )
        ,.src_eth_format_data           (mac_engine_rx_data                 )
        ,.src_eth_format_frame_size     (mac_engine_rx_frame_size           )
        ,.src_eth_format_data_last      (mac_engine_rx_endframe             )
        ,.src_eth_format_data_padbytes  (mac_engine_rx_padbytes             )
        ,.eth_format_src_rdy            (engine_mac_rx_rdy                  )
    
        ,.eth_format_dst_eth_hdr        (eth_format_eth_filter_eth_hdr       )
        ,.eth_format_dst_data_size      (eth_format_eth_filter_data_size     )
        ,.eth_format_dst_timestamp      (eth_format_eth_filter_timestamp     )
        ,.eth_format_dst_hdr_val        (eth_format_eth_filter_hdr_val       )
        ,.dst_eth_format_hdr_rdy        (eth_filter_eth_format_hdr_rdy       )
    
        ,.eth_format_dst_data_val       (eth_format_eth_filter_data_val      )
        ,.eth_format_dst_data           (eth_format_eth_filter_data          )
        ,.dst_eth_format_data_rdy       (eth_filter_eth_format_data_rdy      )
        ,.eth_format_dst_data_last      (eth_format_eth_filter_data_last     )
        ,.eth_format_dst_data_padbytes  (eth_format_eth_filter_data_padbytes )
    );

    eth_filter rx_eth_filter (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_eth_filter_eth_hdr        (eth_format_eth_filter_eth_hdr          )
        ,.src_eth_filter_data_size      (eth_format_eth_filter_data_size        )
        ,.src_eth_filter_hdr_val        (eth_format_eth_filter_hdr_val          )
        ,.eth_filter_src_hdr_rdy        (eth_filter_eth_format_hdr_rdy          )
    
        ,.src_eth_filter_data_val       (eth_format_eth_filter_data_val         )
        ,.src_eth_filter_timestamp      (eth_format_eth_filter_timestamp        )
        ,.src_eth_filter_data           (eth_format_eth_filter_data             )
        ,.src_eth_filter_data_last      (eth_format_eth_filter_data_last        )
        ,.src_eth_filter_data_padbytes  (eth_format_eth_filter_data_padbytes    )
        ,.eth_filter_src_data_rdy       (eth_filter_eth_format_data_rdy         )
        
        ,.eth_filter_dst_eth_hdr        (eth_filter_ip_format_eth_hdr           )
        ,.eth_filter_dst_data_size      (eth_filter_ip_format_data_size         )
        ,.eth_filter_dst_hdr_val        (eth_filter_ip_format_hdr_val           )
        ,.eth_filter_dst_timestamp      (eth_filter_ip_format_timestamp         )
        ,.dst_eth_filter_hdr_rdy        (ip_format_eth_filter_hdr_rdy           )
    
        ,.eth_filter_dst_data_val       (eth_filter_ip_format_data_val          )
        ,.eth_filter_dst_data           (eth_filter_ip_format_data              )
        ,.eth_filter_dst_data_last      (eth_filter_ip_format_data_last         )
        ,.eth_filter_dst_data_padbytes  (eth_filter_ip_format_data_padbytes     )
        ,.dst_eth_filter_data_rdy       (ip_format_eth_filter_data_rdy          )
    );

    assign ip_format_eth_filter_hdr_rdy = 1'b1;

    ip_stream_format_pipe #(
         .DATA_WIDTH    (`MAC_INTERFACE_W)
    ) rx_ip_format (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_ip_format_rx_val          (eth_filter_ip_format_data_val      )
        ,.src_ip_format_rx_timestamp    (eth_filter_ip_format_timestamp     )
        ,.src_ip_format_rx_data         (eth_filter_ip_format_data          )
        ,.src_ip_format_rx_last         (eth_filter_ip_format_data_last     )
        ,.src_ip_format_rx_padbytes     (eth_filter_ip_format_data_padbytes )
        ,.ip_format_src_rx_rdy          (ip_format_eth_filter_data_rdy      )
    
        ,.ip_format_dst_rx_hdr_val      (ip_format_ip_filter_rx_hdr_val     )
        ,.ip_format_dst_rx_ip_hdr       (ip_format_ip_filter_rx_ip_hdr      )
        ,.ip_format_dst_rx_timestamp    (ip_format_ip_filter_rx_timestamp   )
        ,.dst_ip_format_rx_hdr_rdy      (ip_filter_ip_format_rx_hdr_rdy     )
    
        ,.ip_format_dst_rx_data_val     (ip_format_ip_filter_rx_data_val    )
        ,.ip_format_dst_rx_data         (ip_format_ip_filter_rx_data        )
        ,.ip_format_dst_rx_last         (ip_format_ip_filter_rx_last        )
        ,.ip_format_dst_rx_padbytes     (ip_format_ip_filter_rx_padbytes    )
        ,.dst_ip_format_rx_data_rdy     (ip_filter_ip_format_rx_data_rdy    )
    );

    ip_filter rx_ip_filter (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_ip_filter_rx_hdr_val      (ip_format_ip_filter_rx_hdr_val         )
        ,.src_ip_filter_rx_ip_hdr       (ip_format_ip_filter_rx_ip_hdr          )
        ,.src_ip_filter_rx_timestamp    (ip_format_ip_filter_rx_timestamp       )
        ,.ip_filter_src_rx_hdr_rdy      (ip_filter_ip_format_rx_hdr_rdy         )
    
        ,.src_ip_filter_rx_data_val     (ip_format_ip_filter_rx_data_val        )
        ,.src_ip_filter_rx_data         (ip_format_ip_filter_rx_data            )
        ,.src_ip_filter_rx_last         (ip_format_ip_filter_rx_last            )
        ,.src_ip_filter_rx_padbytes     (ip_format_ip_filter_rx_padbytes        )
        ,.ip_filter_src_rx_data_rdy     (ip_filter_ip_format_rx_data_rdy        )
        
        ,.ip_filter_dst_rx_hdr_val      (ip_filter_udp_formatter_rx_hdr_val     )
        ,.ip_filter_dst_rx_ip_hdr       (ip_filter_udp_formatter_rx_ip_hdr      )
        ,.ip_filter_dst_rx_timestamp    (ip_filter_udp_formatter_rx_timestamp   )
        ,.dst_ip_filter_rx_hdr_rdy      (udp_formatter_ip_filter_rx_hdr_rdy     )
    
        ,.ip_filter_dst_rx_data_val     (ip_filter_udp_formatter_rx_data_val    )
        ,.ip_filter_dst_rx_data         (ip_filter_udp_formatter_rx_data        )
        ,.ip_filter_dst_rx_last         (ip_filter_udp_formatter_rx_last        )
        ,.ip_filter_dst_rx_padbytes     (ip_filter_udp_formatter_rx_padbytes    )
        ,.dst_ip_filter_rx_data_rdy     (udp_formatter_ip_filter_rx_data_rdy    )
    );

    assign ip_filter_udp_formatter_rx_udp_len = ip_filter_udp_formatter_rx_ip_hdr.tot_len
                                    - (ip_filter_udp_formatter_rx_ip_hdr.ip_hdr_len << 2);
    assign ip_filter_udp_formatter_rx_src_ip = 
                                            ip_filter_udp_formatter_rx_ip_hdr.source_addr;
    assign ip_filter_udp_formatter_rx_dst_ip =
                                            ip_filter_udp_formatter_rx_ip_hdr.dest_addr;

    udp_stream_format #(
         .DATA_WIDTH   (`MAC_INTERFACE_W   )
        ,.USER_WIDTH   (`PKT_TIMESTAMP_W   )
    ) rx_udp_format (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_udp_formatter_rx_hdr_val      (ip_filter_udp_formatter_rx_hdr_val     )
        ,.src_udp_formatter_rx_src_ip       (ip_filter_udp_formatter_rx_src_ip      )
        ,.src_udp_formatter_rx_dst_ip       (ip_filter_udp_formatter_rx_dst_ip      )
        ,.src_udp_formatter_rx_udp_len      (ip_filter_udp_formatter_rx_udp_len     )
        ,.src_udp_formatter_rx_timestamp    (ip_filter_udp_formatter_rx_timestamp   )
        ,.udp_formatter_src_rx_hdr_rdy      (udp_formatter_ip_filter_rx_hdr_rdy     )
    
        ,.src_udp_formatter_rx_data_val     (ip_filter_udp_formatter_rx_data_val    )
        ,.src_udp_formatter_rx_data         (ip_filter_udp_formatter_rx_data        )
        ,.src_udp_formatter_rx_last         (ip_filter_udp_formatter_rx_last        )
        ,.src_udp_formatter_rx_padbytes     (ip_filter_udp_formatter_rx_padbytes    )
        ,.udp_formatter_src_rx_data_rdy     (udp_formatter_ip_filter_rx_data_rdy    )
        
        ,.udp_formatter_dst_rx_hdr_val      (udp_formatter_udp_splitter_rx_hdr_val  )
        ,.udp_formatter_dst_rx_src_ip       (udp_formatter_udp_splitter_rx_src_ip   )
        ,.udp_formatter_dst_rx_dst_ip       (udp_formatter_udp_splitter_rx_dst_ip   )
        ,.udp_formatter_dst_rx_udp_hdr      (udp_formatter_udp_splitter_rx_udp_hdr  )
        ,.udp_formatter_dst_rx_timestamp    (udp_formatter_udp_splitter_rx_timestamp)
        ,.dst_udp_formatter_rx_hdr_rdy      (udp_splitter_udp_formatter_rx_hdr_rdy  )
    
        ,.udp_formatter_dst_rx_data_val     (udp_formatter_udp_splitter_rx_data_val )
        ,.udp_formatter_dst_rx_data         (udp_formatter_udp_splitter_rx_data     )
        ,.udp_formatter_dst_rx_last         (udp_formatter_udp_splitter_rx_last     )
        ,.udp_formatter_dst_rx_padbytes     (udp_formatter_udp_splitter_rx_padbytes )
        ,.dst_udp_formatter_rx_data_rdy     (udp_splitter_udp_formatter_rx_data_rdy )
    );

    udp_splitter #(
         .UDP_DSTS          (UDP_DSTS       )
        ,.UDP_APP_ID        (UDP_APP_ID     )
        ,.UDP_LOG_ID        (UDP_LOG_ID     )
        ,.ETH_LAT_LOG_ID    (ETH_LAT_LOG_ID )
        ,.UDP_APP_PORT      (65432          )
        ,.UDP_LOG_PORT      (60000          )
        ,.ETH_LAT_LOG_PORT  (60001          )
    ) rx_udp_splitter (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_udp_splitter_rx_hdr_val   (udp_formatter_udp_splitter_rx_hdr_val  )
        ,.src_udp_splitter_rx_src_ip    (udp_formatter_udp_splitter_rx_src_ip   )
        ,.src_udp_splitter_rx_dst_ip    (udp_formatter_udp_splitter_rx_dst_ip   )
        ,.src_udp_splitter_rx_udp_hdr   (udp_formatter_udp_splitter_rx_udp_hdr  )
        ,.src_udp_splitter_rx_timestamp (udp_formatter_udp_splitter_rx_timestamp)
        ,.udp_splitter_src_rx_hdr_rdy   (udp_splitter_udp_formatter_rx_hdr_rdy  )
    
        ,.src_udp_splitter_rx_data_val  (udp_formatter_udp_splitter_rx_data_val )
        ,.src_udp_splitter_rx_data      (udp_formatter_udp_splitter_rx_data     )
        ,.src_udp_splitter_rx_last      (udp_formatter_udp_splitter_rx_last     )
        ,.src_udp_splitter_rx_padbytes  (udp_formatter_udp_splitter_rx_padbytes )
        ,.udp_splitter_src_rx_data_rdy  (udp_splitter_udp_formatter_rx_data_rdy )
        
        ,.udp_splitter_dst_rx_hdr_val   (udp_splitter_dsts_rx_hdr_val           )
        ,.udp_splitter_dst_rx_src_ip    (udp_splitter_dsts_rx_src_ip            )
        ,.udp_splitter_dst_rx_dst_ip    (udp_splitter_dsts_rx_dst_ip            )
        ,.udp_splitter_dst_rx_udp_hdr   (udp_splitter_dsts_rx_udp_hdr           )
        ,.udp_splitter_dst_rx_timestamp (udp_splitter_dsts_rx_timestamp         )
        ,.dst_udp_splitter_rx_hdr_rdy   (dsts_udp_splitter_rx_hdr_rdy           )

        ,.udp_splitter_dst_rx_data_val  (udp_splitter_dsts_rx_data_val          )
        ,.udp_splitter_dst_rx_data      (udp_splitter_dsts_rx_data              )
        ,.udp_splitter_dst_rx_last      (udp_splitter_dsts_rx_last              )
        ,.udp_splitter_dst_rx_padbytes  (udp_splitter_dsts_rx_padbytes          )
        ,.dst_udp_splitter_rx_data_rdy  (dsts_udp_splitter_rx_data_rdy          )
    );


    assign srcs_udp_merger_tx_timestamp[UDP_LOG_ID] = '0;
    udp_app_no_noc_log udp_app_log (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_udp_app_log_rx_hdr_val    (udp_splitter_dsts_rx_hdr_val[UDP_LOG_ID]   )
        ,.udp_udp_app_log_rx_src_ip     (udp_splitter_dsts_rx_src_ip                )
        ,.udp_udp_app_log_rx_dst_ip     (udp_splitter_dsts_rx_dst_ip                )
        ,.udp_udp_app_log_rx_udp_hdr    (udp_splitter_dsts_rx_udp_hdr               )
        ,.udp_app_log_udp_rx_hdr_rdy    (dsts_udp_splitter_rx_hdr_rdy[UDP_LOG_ID]   )
    
        ,.udp_udp_app_log_rx_data_val   (udp_splitter_dsts_rx_data_val[UDP_LOG_ID]  )
        ,.udp_udp_app_log_rx_data       (udp_splitter_dsts_rx_data                  )
        ,.udp_udp_app_log_rx_last       (udp_splitter_dsts_rx_last                  )
        ,.udp_udp_app_log_rx_padbytes   (udp_splitter_dsts_rx_padbytes              )
        ,.udp_app_log_udp_rx_data_rdy   (dsts_udp_splitter_rx_data_rdy[UDP_LOG_ID]  )
    
        ,.udp_app_log_udp_tx_hdr_val    (srcs_udp_merger_tx_hdr_val[UDP_LOG_ID]     )
        ,.udp_app_log_udp_tx_src_ip     (srcs_udp_merger_tx_src_ip[UDP_LOG_ID]      )
        ,.udp_app_log_udp_tx_dst_ip     (srcs_udp_merger_tx_dst_ip[UDP_LOG_ID]      )
        ,.udp_app_log_udp_tx_udp_hdr    (srcs_udp_merger_tx_udp_hdr[UDP_LOG_ID]     )
        ,.udp_udp_app_log_tx_hdr_rdy    (udp_merger_srcs_tx_hdr_rdy[UDP_LOG_ID]     )
    
        ,.udp_app_log_udp_tx_data_val   (srcs_udp_merger_tx_data_val[UDP_LOG_ID]    )
        ,.udp_app_log_udp_tx_data       (srcs_udp_merger_tx_data[UDP_LOG_ID]        )
        ,.udp_app_log_udp_tx_last       (srcs_udp_merger_tx_last[UDP_LOG_ID]        )
        ,.udp_app_log_udp_tx_padbytes   (srcs_udp_merger_tx_padbytes[UDP_LOG_ID]    )
        ,.udp_udp_app_log_tx_data_rdy   (udp_merger_srcs_tx_data_rdy[UDP_LOG_ID]    )
       
        ,.app_stats_do_log              (app_stats_do_log                           )
        ,.app_stats_incr_bytes_sent     (app_stats_incr_bytes_sent                  )
        ,.app_stats_num_bytes_sent      (app_stats_num_bytes_sent                   )
    );

    udp_echo_app_top app (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_echo_app_rx_hdr_val       (udp_splitter_dsts_rx_hdr_val[UDP_APP_ID]   )
        ,.src_udp_echo_app_rx_src_ip        (udp_splitter_dsts_rx_src_ip                )
        ,.src_udp_echo_app_rx_dst_ip        (udp_splitter_dsts_rx_dst_ip                )
        ,.src_udp_echo_app_rx_udp_hdr       (udp_splitter_dsts_rx_udp_hdr               )
        ,.src_udp_echo_app_rx_timestamp     (udp_splitter_dsts_rx_timestamp             )
        ,.udp_echo_app_src_rx_hdr_rdy       (dsts_udp_splitter_rx_hdr_rdy[UDP_APP_ID]   )
    
        ,.src_udp_echo_app_rx_data_val      (udp_splitter_dsts_rx_data_val[UDP_APP_ID]  )
        ,.src_udp_echo_app_rx_data          (udp_splitter_dsts_rx_data                  )
        ,.src_udp_echo_app_rx_last          (udp_splitter_dsts_rx_last                  )
        ,.src_udp_echo_app_rx_padbytes      (udp_splitter_dsts_rx_padbytes              )
        ,.udp_echo_app_src_rx_data_rdy      (dsts_udp_splitter_rx_data_rdy[UDP_APP_ID]  )
        
        ,.udp_echo_app_dst_hdr_val          (srcs_udp_merger_tx_hdr_val[UDP_APP_ID]     )
        ,.udp_echo_app_dst_src_ip_addr      (srcs_udp_merger_tx_src_ip[UDP_APP_ID]      )
        ,.udp_echo_app_dst_dst_ip_addr      (srcs_udp_merger_tx_dst_ip[UDP_APP_ID]      )
        ,.udp_echo_app_dst_udp_hdr          (srcs_udp_merger_tx_udp_hdr[UDP_APP_ID]     )
        ,.udp_echo_app_dst_timestamp        (srcs_udp_merger_tx_timestamp[UDP_APP_ID]   )
        ,.dst_udp_echo_app_hdr_rdy          (udp_merger_srcs_tx_hdr_rdy[UDP_APP_ID]     )
        
        ,.udp_echo_app_dst_data_val         (srcs_udp_merger_tx_data_val[UDP_APP_ID]    )
        ,.udp_echo_app_dst_data             (srcs_udp_merger_tx_data[UDP_APP_ID]        )
        ,.udp_echo_app_dst_data_last        (srcs_udp_merger_tx_last[UDP_APP_ID]        )
        ,.udp_echo_app_dst_data_padbytes    (srcs_udp_merger_tx_padbytes[UDP_APP_ID]    )
        ,.dst_udp_echo_app_data_rdy         (udp_merger_srcs_tx_data_rdy[UDP_APP_ID]    )

        ,.app_stats_do_log                  (app_stats_do_log                           )
        ,.app_stats_incr_bytes_sent         (app_stats_incr_bytes_sent                  )
        ,.app_stats_num_bytes_sent          (app_stats_num_bytes_sent                   )
    );
    
    udp_merger #(
         .NUM_SRCS  (UDP_SRCS   )
    ) tx_udp_merger (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.srcs_udp_merger_tx_hdr_val    (srcs_udp_merger_tx_hdr_val         )
        ,.srcs_udp_merger_tx_src_ip     (srcs_udp_merger_tx_src_ip          )
        ,.srcs_udp_merger_tx_dst_ip     (srcs_udp_merger_tx_dst_ip          )
        ,.srcs_udp_merger_tx_udp_hdr    (srcs_udp_merger_tx_udp_hdr         )
        ,.srcs_udp_merger_tx_timestamp  (srcs_udp_merger_tx_timestamp       )
        ,.udp_merger_srcs_tx_hdr_rdy    (udp_merger_srcs_tx_hdr_rdy         )
                                                                            
        ,.srcs_udp_merger_tx_data_val   (srcs_udp_merger_tx_data_val        )
        ,.srcs_udp_merger_tx_data       (srcs_udp_merger_tx_data            )
        ,.srcs_udp_merger_tx_last       (srcs_udp_merger_tx_last            )
        ,.srcs_udp_merger_tx_padbytes   (srcs_udp_merger_tx_padbytes        )
        ,.udp_merger_srcs_tx_data_rdy   (udp_merger_srcs_tx_data_rdy        )
        
        ,.udp_merger_dst_tx_hdr_val     (udp_merger_udp_stream_hdr_val      )
        ,.udp_merger_dst_tx_src_ip      (udp_merger_udp_stream_src_ip_addr  )
        ,.udp_merger_dst_tx_dst_ip      (udp_merger_udp_stream_dst_ip_addr  )
        ,.udp_merger_dst_tx_udp_hdr     (udp_merger_udp_stream_udp_hdr      )
        ,.udp_merger_dst_tx_timestamp   (udp_merger_udp_stream_timestamp    )
        ,.dst_udp_merger_tx_hdr_rdy     (udp_stream_udp_merger_hdr_rdy      )
    
        ,.udp_merger_dst_tx_data_val    (udp_merger_udp_stream_data_val     )
        ,.udp_merger_dst_tx_data        (udp_merger_udp_stream_data         )
        ,.udp_merger_dst_tx_last        (udp_merger_udp_stream_data_last    )
        ,.udp_merger_dst_tx_padbytes    (udp_merger_udp_stream_data_padbytes)
        ,.dst_udp_merger_tx_data_rdy    (udp_stream_udp_merger_data_rdy     )
    );

    udp_to_stream #(
         .DATA_WIDTH    (`MAC_INTERFACE_W   )
    ) tx_udp_to_stream (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_to_stream_hdr_val         (udp_merger_udp_stream_hdr_val      )
        ,.src_udp_to_stream_src_ip_addr     (udp_merger_udp_stream_src_ip_addr  )
        ,.src_udp_to_stream_dst_ip_addr     (udp_merger_udp_stream_dst_ip_addr  )
        ,.src_udp_to_stream_udp_hdr         (udp_merger_udp_stream_udp_hdr      )
        ,.src_udp_to_stream_timestamp       (udp_merger_udp_stream_timestamp    )
        ,.udp_to_stream_src_hdr_rdy         (udp_stream_udp_merger_hdr_rdy      )
        
        ,.src_udp_to_stream_data_val        (udp_merger_udp_stream_data_val     )
        ,.src_udp_to_stream_data            (udp_merger_udp_stream_data         )
        ,.src_udp_to_stream_data_last       (udp_merger_udp_stream_data_last    )
        ,.src_udp_to_stream_data_padbytes   (udp_merger_udp_stream_data_padbytes)
        ,.udp_to_stream_src_data_rdy        (udp_stream_udp_merger_data_rdy     )
    
        ,.udp_to_stream_dst_hdr_val         (udp_to_stream_ip_assemble_hdr_val      )
        ,.udp_to_stream_dst_src_ip          (udp_to_stream_ip_assemble_src_ip       )
        ,.udp_to_stream_dst_dst_ip          (udp_to_stream_ip_assemble_dst_ip       )
        ,.udp_to_stream_dst_udp_len         (udp_to_stream_ip_assemble_udp_len      )
        ,.udp_to_stream_dst_protocol        (udp_to_stream_ip_assemble_protocol     )
        ,.udp_to_stream_dst_timestamp       (udp_to_stream_ip_assemble_timestamp    )
        ,.dst_udp_to_stream_hdr_rdy         (ip_assemble_udp_to_stream_hdr_rdy      )
        
        ,.udp_to_stream_dst_val             (udp_to_stream_ip_stream_val            )
        ,.udp_to_stream_dst_data            (udp_to_stream_ip_stream_data           )
        ,.udp_to_stream_dst_last            (udp_to_stream_ip_stream_last           )
        ,.udp_to_stream_dst_padbytes        (udp_to_stream_ip_stream_padbytes       )
        ,.dst_udp_to_stream_rdy             (ip_stream_udp_to_stream_rdy            )
    );

    ip_hdr_assembler_pipe #(
         .DATA_W         (`MAC_INTERFACE_W)
    ) hdr_assembler (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_assembler_req_val             (udp_to_stream_ip_assemble_hdr_val      )
        ,.src_assembler_src_ip_addr         (udp_to_stream_ip_assemble_src_ip       )
        ,.src_assembler_dst_ip_addr         (udp_to_stream_ip_assemble_dst_ip       )
        ,.src_assembler_data_payload_len    (udp_to_stream_ip_assemble_udp_len      )
        ,.src_assembler_protocol            (udp_to_stream_ip_assemble_protocol     )    
        ,.src_assembler_timestamp           (udp_to_stream_ip_assemble_timestamp    )
        ,.assembler_src_req_rdy             (ip_assemble_udp_to_stream_hdr_rdy      )
    
        ,.src_assembler_data_val            (udp_to_stream_ip_stream_val            )
        ,.src_assembler_data                (udp_to_stream_ip_stream_data           )
        ,.src_assembler_data_last           (udp_to_stream_ip_stream_last           )
        ,.src_assembler_data_padbytes       (udp_to_stream_ip_stream_padbytes       )
        ,.assembler_src_data_rdy            (ip_stream_udp_to_stream_rdy            )
    
        ,.assembler_dst_hdr_val             (ip_assemble_ip_to_ethstream_hdr_val    )
        ,.assembler_dst_timestamp           (ip_assemble_ip_to_ethstream_timestamp  )
        ,.assembler_dst_ip_hdr              (ip_assemble_ip_to_ethstream_ip_hdr     )
        ,.dst_assembler_hdr_rdy             (ip_to_ethstream_ip_assemble_hdr_rdy    )
    
        ,.assembler_dst_data_val            (ip_assemble_ip_to_ethstream_data_val   )
        ,.assembler_dst_data                (ip_assemble_ip_to_ethstream_data       )
        ,.assembler_dst_data_padbytes       (ip_assemble_ip_to_ethstream_data_padbytes  )
        ,.assembler_dst_data_last           (ip_assemble_ip_to_ethstream_data_last  )
        ,.dst_assembler_data_rdy            (ip_to_ethstream_ip_assemble_data_rdy   )
    );


    ip_to_ethstream tx_ip_to_stream (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_ip_to_ethstream_hdr_val       (ip_assemble_ip_to_ethstream_hdr_val        )
        ,.src_ip_to_ethstream_ip_hdr        (ip_assemble_ip_to_ethstream_ip_hdr         )
        ,.src_ip_to_ethstream_timestamp     (ip_assemble_ip_to_ethstream_timestamp      )
        ,.ip_to_ethstream_src_hdr_rdy       (ip_to_ethstream_ip_assemble_hdr_rdy        )
    
        ,.src_ip_to_ethstream_data_val      (ip_assemble_ip_to_ethstream_data_val       )
        ,.src_ip_to_ethstream_data          (ip_assemble_ip_to_ethstream_data           )
        ,.src_ip_to_ethstream_data_last     (ip_assemble_ip_to_ethstream_data_last      )
        ,.src_ip_to_ethstream_data_padbytes (ip_assemble_ip_to_ethstream_data_padbytes  )
        ,.ip_to_ethstream_src_data_rdy      (ip_to_ethstream_ip_assemble_data_rdy       )
    
        ,.ip_to_ethstream_dst_hdr_val       (ip_to_ethstream_eth_stream_hdr_val         )
        ,.ip_to_ethstream_dst_eth_hdr       (ip_to_ethstream_eth_stream_eth_hdr         )
        ,.ip_to_ethstream_dst_data_len      (ip_to_ethstream_eth_stream_data_len        )
        ,.ip_to_ethstream_dst_timestamp     (ip_to_ethstream_eth_stream_timestamp       )
        ,.dst_ip_to_ethstream_hdr_rdy       (eth_stream_ip_to_ethstream_hdr_rdy         )
    
        ,.ip_to_ethstream_dst_data_val      (ip_to_ethstream_eth_stream_data_val        )
        ,.ip_to_ethstream_dst_data          (ip_to_ethstream_eth_stream_data            )
        ,.ip_to_ethstream_dst_data_last     (ip_to_ethstream_eth_stream_data_last       )
        ,.ip_to_ethstream_dst_data_padbytes (ip_to_ethstream_eth_stream_data_padbytes   )
        ,.dst_ip_to_ethstream_data_rdy      (eth_stream_ip_to_ethstream_data_rdy        )
    );

    eth_hdrtostream tx_eth_to_stream (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_eth_hdrtostream_eth_hdr_val   (ip_to_ethstream_eth_stream_hdr_val         )
        ,.src_eth_hdrtostream_eth_hdr       (ip_to_ethstream_eth_stream_eth_hdr         )
        ,.src_eth_hdrtostream_timestamp     (ip_to_ethstream_eth_stream_timestamp       )
        ,.src_eth_hdrtostream_payload_len   (ip_to_ethstream_eth_stream_data_len[`MTU_SIZE_W-1:0])
        ,.eth_hdrtostream_src_eth_hdr_rdy   (eth_stream_ip_to_ethstream_hdr_rdy         )

        ,.src_eth_hdrtostream_data_val      (ip_to_ethstream_eth_stream_data_val        )
        ,.src_eth_hdrtostream_data          (ip_to_ethstream_eth_stream_data            )
        ,.src_eth_hdrtostream_data_last     (ip_to_ethstream_eth_stream_data_last       )
        ,.src_eth_hdrtostream_data_padbytes (ip_to_ethstream_eth_stream_data_padbytes   )
        ,.eth_hdrtostream_src_data_rdy      (eth_stream_ip_to_ethstream_data_rdy        )

        ,.eth_hdrtostream_dst_data_val      (engine_mac_tx_val                          )
        ,.eth_hdrtostream_dst_startframe    (engine_mac_tx_startframe                   )
        ,.eth_hdrtostream_dst_data          (engine_mac_tx_data                         )
        ,.eth_hdrtostream_dst_frame_size    (engine_mac_tx_frame_size                   )
        ,.eth_hdrtostream_dst_endframe      (engine_mac_tx_endframe                     )
        ,.eth_hdrtostream_dst_data_padbytes (engine_mac_tx_padbytes                     )
        ,.dst_eth_hdrtostream_data_rdy      (mac_engine_tx_rdy                          )

        ,.eth_lat_wr_val                    (eth_lat_wr_val                             )
        ,.eth_lat_wr_timestamp              (eth_lat_wr_timestamp                       )
    );

    assign srcs_udp_merger_tx_timestamp[ETH_LAT_LOG_ID] = '0;
    eth_no_noc_log tx_eth_lat_log (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.eth_lat_wr_val            (eth_lat_wr_val                                 )
        ,.eth_lat_wr_timestamp      (eth_lat_wr_timestamp                           )
    
        ,.udp_eth_lat_rx_hdr_val    (udp_splitter_dsts_rx_hdr_val[ETH_LAT_LOG_ID]   )
        ,.udp_eth_lat_rx_udp_hdr    (udp_splitter_dsts_rx_udp_hdr                   )
        ,.udp_eth_lat_rx_src_ip     (udp_splitter_dsts_rx_src_ip                    )
        ,.udp_eth_lat_rx_dst_ip     (udp_splitter_dsts_rx_dst_ip                    )
        ,.eth_lat_udp_rx_hdr_rdy    (dsts_udp_splitter_rx_hdr_rdy[ETH_LAT_LOG_ID]   )
    
        ,.udp_eth_lat_rx_data_val   (udp_splitter_dsts_rx_data_val[ETH_LAT_LOG_ID]  )
        ,.udp_eth_lat_rx_data       (udp_splitter_dsts_rx_data                      )
        ,.udp_eth_lat_rx_last       (udp_splitter_dsts_rx_last                      )
        ,.udp_eth_lat_rx_padbytes   (udp_splitter_dsts_rx_padbytes                  )
        ,.eth_lat_udp_rx_data_rdy   (dsts_udp_splitter_rx_data_rdy[ETH_LAT_LOG_ID]  )
    
        ,.eth_lat_udp_tx_hdr_val    (srcs_udp_merger_tx_hdr_val[ETH_LAT_LOG_ID]     )
        ,.eth_lat_udp_tx_src_ip     (srcs_udp_merger_tx_src_ip[ETH_LAT_LOG_ID]      )
        ,.eth_lat_udp_tx_dst_ip     (srcs_udp_merger_tx_dst_ip[ETH_LAT_LOG_ID]      )
        ,.eth_lat_udp_tx_udp_hdr    (srcs_udp_merger_tx_udp_hdr[ETH_LAT_LOG_ID]     )
        ,.udp_eth_lat_tx_hdr_rdy    (udp_merger_srcs_tx_hdr_rdy[ETH_LAT_LOG_ID]     )
    
        ,.eth_lat_udp_tx_data_val   (srcs_udp_merger_tx_data_val[ETH_LAT_LOG_ID]    )
        ,.eth_lat_udp_tx_data       (srcs_udp_merger_tx_data[ETH_LAT_LOG_ID]        )
        ,.eth_lat_udp_tx_last       (srcs_udp_merger_tx_last[ETH_LAT_LOG_ID]        )
        ,.eth_lat_udp_tx_padbytes   (srcs_udp_merger_tx_padbytes[ETH_LAT_LOG_ID]    )
        ,.udp_eth_lat_tx_data_rdy   (udp_merger_srcs_tx_data_rdy[ETH_LAT_LOG_ID]    )
    );

endmodule
