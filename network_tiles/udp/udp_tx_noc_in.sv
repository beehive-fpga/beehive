`include "udp_tx_tile_defs.svh"
module udp_tx_noc_in 
    import tracker_pkg::*;
(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_tx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_tx_in_data
    ,output logic                           udp_tx_in_noc0_ctovr_rdy
    
    ,output logic                           udp_tx_in_udp_to_stream_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_src_ip_addr
    ,output logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_dst_ip_addr
    ,output udp_pkt_hdr                     udp_tx_in_udp_to_stream_udp_hdr
    ,output tracker_stats_struct            udp_tx_in_udp_to_stream_timestamp
    ,input  logic                           udp_to_stream_udp_tx_in_hdr_rdy
    
    ,output logic                           udp_tx_in_udp_to_stream_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  udp_tx_in_udp_to_stream_data
    ,output logic                           udp_tx_in_udp_to_stream_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   udp_tx_in_udp_to_stream_data_padbytes
    ,input  logic                           udp_to_stream_udp_tx_in_data_rdy

);
    
    logic   ctrl_datap_store_hdr_flit;
    logic   ctrl_datap_store_meta_flit;
    logic   ctrl_datap_init_num_flits;
    logic   ctrl_datap_decr_num_flits;

    logic   datap_ctrl_last_flit;

    udp_tx_noc_in_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_tx_in_val          (noc0_ctovr_udp_tx_in_val           )
        ,.udp_tx_in_noc0_ctovr_rdy          (udp_tx_in_noc0_ctovr_rdy           )
                                                                                
        ,.udp_tx_in_udp_to_stream_hdr_val   (udp_tx_in_udp_to_stream_hdr_val    )
        ,.udp_to_stream_udp_tx_in_hdr_rdy   (udp_to_stream_udp_tx_in_hdr_rdy    )
                                                                                
        ,.udp_tx_in_udp_to_stream_data_val  (udp_tx_in_udp_to_stream_data_val   )
        ,.udp_to_stream_udp_tx_in_data_rdy  (udp_to_stream_udp_tx_in_data_rdy   )
                                                                                
        ,.ctrl_datap_store_hdr_flit         (ctrl_datap_store_hdr_flit          )
        ,.ctrl_datap_store_meta_flit        (ctrl_datap_store_meta_flit         )
        ,.ctrl_datap_init_num_flits         (ctrl_datap_init_num_flits          )
        ,.ctrl_datap_decr_num_flits         (ctrl_datap_decr_num_flits          )
                                                                                
        ,.datap_ctrl_last_flit              (datap_ctrl_last_flit               )
    );

    udp_tx_noc_in_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_tx_in_data             (noc0_ctovr_udp_tx_in_data              )
                                                                                        
        ,.udp_tx_in_udp_to_stream_src_ip_addr   (udp_tx_in_udp_to_stream_src_ip_addr    )
        ,.udp_tx_in_udp_to_stream_dst_ip_addr   (udp_tx_in_udp_to_stream_dst_ip_addr    )
        ,.udp_tx_in_udp_to_stream_udp_hdr       (udp_tx_in_udp_to_stream_udp_hdr        )
        ,.udp_tx_in_udp_to_stream_timestamp     (udp_tx_in_udp_to_stream_timestamp      )
                                                                                        
        ,.udp_tx_in_udp_to_stream_data          (udp_tx_in_udp_to_stream_data           )
        ,.udp_tx_in_udp_to_stream_data_last     (udp_tx_in_udp_to_stream_data_last      )
        ,.udp_tx_in_udp_to_stream_data_padbytes (udp_tx_in_udp_to_stream_data_padbytes  )
                                                                                        
        ,.ctrl_datap_store_hdr_flit             (ctrl_datap_store_hdr_flit              )
        ,.ctrl_datap_store_meta_flit            (ctrl_datap_store_meta_flit             )
        ,.ctrl_datap_init_num_flits             (ctrl_datap_init_num_flits              )
        ,.ctrl_datap_decr_num_flits             (ctrl_datap_decr_num_flits              )
                                                                                        
        ,.datap_ctrl_last_flit                  (datap_ctrl_last_flit                   )
    );
endmodule
