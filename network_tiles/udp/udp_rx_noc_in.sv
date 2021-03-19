`include "udp_rx_tile_defs.svh"

module udp_rx_noc_in (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_rx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_rx_in_data
    ,output logic                           udp_rx_in_noc0_ctovr_rdy
    
    ,output logic                           udp_rx_in_udp_formatter_rx_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]        udp_rx_in_udp_formatter_rx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]        udp_rx_in_udp_formatter_rx_dst_ip
    ,output logic   [`TOT_LEN_W-1:0]        udp_rx_in_udp_formatter_rx_udp_len
    ,output logic   [MSG_TIMESTAMP_W-1:0]   udp_rx_in_udp_formatter_rx_timestamp
    ,input  logic                           udp_formatter_udp_rx_in_rx_hdr_rdy

    ,output logic                           udp_rx_in_udp_formatter_rx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  udp_rx_in_udp_formatter_rx_data
    ,output logic                           udp_rx_in_udp_formatter_rx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   udp_rx_in_udp_formatter_rx_padbytes
    ,input  logic                           udp_formatter_udp_rx_in_rx_data_rdy
);

    logic                   ctrl_datap_store_hdr_flit;
    logic                   ctrl_datap_store_meta_flit;
    logic                   ctrl_datap_init_num_flits;
    logic                   ctrl_datap_decr_num_flits;

    logic                   datap_ctrl_last_flit;

    udp_rx_noc_in_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_rx_in_data             (noc0_ctovr_udp_rx_in_data              )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_src_ip     (udp_rx_in_udp_formatter_rx_src_ip      )
        ,.udp_rx_in_udp_formatter_rx_dst_ip     (udp_rx_in_udp_formatter_rx_dst_ip      )
        ,.udp_rx_in_udp_formatter_rx_udp_len    (udp_rx_in_udp_formatter_rx_udp_len     )
        ,.udp_rx_in_udp_formatter_rx_timestamp  (udp_rx_in_udp_formatter_rx_timestamp   )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_data       (udp_rx_in_udp_formatter_rx_data        )
        ,.udp_rx_in_udp_formatter_rx_last       (udp_rx_in_udp_formatter_rx_last        )
        ,.udp_rx_in_udp_formatter_rx_padbytes   (udp_rx_in_udp_formatter_rx_padbytes    )
                                                                                        
        ,.ctrl_datap_store_hdr_flit             (ctrl_datap_store_hdr_flit              )
        ,.ctrl_datap_store_meta_flit            (ctrl_datap_store_meta_flit             )
        ,.ctrl_datap_init_num_flits             (ctrl_datap_init_num_flits              )
        ,.ctrl_datap_decr_num_flits             (ctrl_datap_decr_num_flits              )
                                                                                        
        ,.datap_ctrl_last_flit                  (datap_ctrl_last_flit                   )
    );

    udp_rx_noc_in_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.noc0_ctovr_udp_rx_in_val              (noc0_ctovr_udp_rx_in_val               )
        ,.udp_rx_in_noc0_ctovr_rdy              (udp_rx_in_noc0_ctovr_rdy               )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_hdr_val    (udp_rx_in_udp_formatter_rx_hdr_val     )
        ,.udp_formatter_udp_rx_in_rx_hdr_rdy    (udp_formatter_udp_rx_in_rx_hdr_rdy     )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_data_val   (udp_rx_in_udp_formatter_rx_data_val    )
        ,.udp_formatter_udp_rx_in_rx_data_rdy   (udp_formatter_udp_rx_in_rx_data_rdy    )
                                                                                        
        ,.ctrl_datap_store_hdr_flit             (ctrl_datap_store_hdr_flit              )
        ,.ctrl_datap_store_meta_flit            (ctrl_datap_store_meta_flit             )
        ,.ctrl_datap_init_num_flits             (ctrl_datap_init_num_flits              )
        ,.ctrl_datap_decr_num_flits             (ctrl_datap_decr_num_flits              )
                                                                                        
        ,.datap_ctrl_last_flit                  (datap_ctrl_last_flit                   )
    );

endmodule
