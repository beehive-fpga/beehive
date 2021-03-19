`include "packet_defs.vh"
`include "soc_defs.vh"

import packet_struct_pkg::*;
module simple_no_noc_reader #(
     parameter ADDR_W = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter CLIENT_ADDR_W = -1
)(
     input clk
    ,input rst
    
    ,input  logic                               udp_log_rx_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]            udp_log_rx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]            udp_log_rx_dst_ip
    ,input  udp_pkt_hdr                         udp_log_rx_udp_hdr
    ,output logic                               log_udp_rx_hdr_rdy

    ,input  logic                               udp_log_rx_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]      udp_log_rx_data
    ,input  logic                               udp_log_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]       udp_log_rx_padbytes
    ,output logic                               log_udp_rx_data_rdy
    
    ,output logic                               log_udp_tx_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]            log_udp_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            log_udp_tx_dst_ip
    ,output udp_pkt_hdr                         log_udp_tx_udp_hdr
    ,input                                      udp_log_tx_hdr_rdy

    ,output logic                               log_udp_tx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]      log_udp_tx_data
    ,output logic                               log_udp_tx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       log_udp_tx_padbytes
    ,input  logic                               udp_log_tx_data_rdy

    ,output logic                               log_rd_req_val
    ,output logic   [ADDR_W-1:0]                log_rd_req_addr

    ,input  logic                               log_rd_resp_val
    ,input  logic   [RESP_DATA_STRUCT_W-1:0]    log_rd_resp_data

    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped
);
    
    logic                               ctrl_datap_store_hdr;
    logic                               ctrl_datap_store_req;
    logic                               ctrl_datap_store_log_resp;

    logic                               datap_ctrl_rd_meta;

    simple_log_no_noc_reader_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_log_rx_hdr_val        (udp_log_rx_hdr_val         )
        ,.log_udp_rx_hdr_rdy        (log_udp_rx_hdr_rdy         )
                                                                
        ,.udp_log_rx_data_val       (udp_log_rx_data_val        )
        ,.log_udp_rx_data_rdy       (log_udp_rx_data_rdy        )
                                                                
        ,.log_udp_tx_hdr_val        (log_udp_tx_hdr_val         )
        ,.udp_log_tx_hdr_rdy        (udp_log_tx_hdr_rdy         )
                                                                
        ,.log_udp_tx_data_val       (log_udp_tx_data_val        )
        ,.log_udp_tx_last           (log_udp_tx_last            )
        ,.udp_log_tx_data_rdy       (udp_log_tx_data_rdy        )
                                                                
        ,.log_rd_req_val            (log_rd_req_val             )
                                                                
        ,.log_rd_resp_val           (log_rd_resp_val            )
                                                                
        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_store_req      (ctrl_datap_store_req       )
        ,.ctrl_datap_store_log_resp (ctrl_datap_store_log_resp  )
                                                                
        ,.datap_ctrl_rd_meta        (datap_ctrl_rd_meta         )
    );

    simple_log_no_noc_reader_datap #(
         .ADDR_W                (ADDR_W             )
        ,.RESP_DATA_STRUCT_W    (RESP_DATA_STRUCT_W )
        ,.CLIENT_ADDR_W         (CLIENT_ADDR_W      )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.udp_log_rx_src_ip         (udp_log_rx_src_ip          )
        ,.udp_log_rx_dst_ip         (udp_log_rx_dst_ip          )
        ,.udp_log_rx_udp_hdr        (udp_log_rx_udp_hdr         )

        ,.udp_log_rx_data           (udp_log_rx_data            )
        ,.udp_log_rx_last           (udp_log_rx_last            )
        ,.udp_log_rx_padbytes       (udp_log_rx_padbytes        )

        ,.log_udp_tx_src_ip         (log_udp_tx_src_ip          )
        ,.log_udp_tx_dst_ip         (log_udp_tx_dst_ip          )
        ,.log_udp_tx_udp_hdr        (log_udp_tx_udp_hdr         )

        ,.log_udp_tx_data           (log_udp_tx_data            )
        ,.log_udp_tx_padbytes       (log_udp_tx_padbytes        )

        ,.log_rd_req_addr           (log_rd_req_addr            )

        ,.log_rd_resp_data          (log_rd_resp_data           )

        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_store_req      (ctrl_datap_store_req       )
        ,.ctrl_datap_store_log_resp (ctrl_datap_store_log_resp  )

        ,.datap_ctrl_rd_meta        (datap_ctrl_rd_meta         )
    
        ,.curr_wr_addr              (curr_wr_addr               )
        ,.has_wrapped               (has_wrapped                )
    );

endmodule
