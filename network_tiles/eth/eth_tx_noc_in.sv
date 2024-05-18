`include "eth_tx_tile_defs.svh"

module eth_tx_noc_in 
    import tracker_pkg::*;
(
     input clk
    ,input rst 
    
    ,input                                      noc0_ctovr_eth_tx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_eth_tx_in_data
    ,output logic                               eth_tx_in_noc0_ctovr_rdy
    
    ,output logic                               eth_tx_in_eth_tostream_eth_hdr_val
    ,output eth_hdr                             eth_tx_in_eth_tostream_eth_hdr
    ,output logic   [`MTU_SIZE_W-1:0]           eth_tx_in_eth_tostream_payload_len
    ,input                                      eth_tostream_eth_tx_in_eth_hdr_rdy

    ,output logic                               eth_tx_in_eth_tostream_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]      eth_tx_in_eth_tostream_data
    ,output logic                               eth_tx_in_eth_tostream_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       eth_tx_in_eth_tostream_data_padbytes
    ,input                                      eth_tostream_eth_tx_in_data_rdy
    
    ,output                                     eth_wr_log
    ,output tracker_stats_struct                eth_wr_log_start_timestamp
);
    logic                               ctrl_datap_store_hdr_flit;
    logic                               ctrl_datap_store_meta_flit;
    logic                               ctrl_datap_init_num_flits;
    logic                               ctrl_datap_decr_num_flits;

    logic                               datap_ctrl_last_flit;


    eth_tx_noc_in_datap datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_eth_tx_in_data             (noc0_ctovr_eth_tx_in_data              )
                                                                                        
        ,.eth_tx_in_eth_tostream_eth_hdr        (eth_tx_in_eth_tostream_eth_hdr         )
        ,.eth_tx_in_eth_tostream_payload_len    (eth_tx_in_eth_tostream_payload_len     )
        ,.eth_tx_in_eth_tostream_timestamp      (eth_wr_log_start_timestamp             )
                                                                                        
        ,.eth_tx_in_eth_tostream_data           (eth_tx_in_eth_tostream_data            )
        ,.eth_tx_in_eth_tostream_data_last      (eth_tx_in_eth_tostream_data_last       )
        ,.eth_tx_in_eth_tostream_data_padbytes  (eth_tx_in_eth_tostream_data_padbytes   )
                                                                                        
        ,.ctrl_datap_store_hdr_flit             (ctrl_datap_store_hdr_flit              )
        ,.ctrl_datap_store_meta_flit            (ctrl_datap_store_meta_flit             )
        ,.ctrl_datap_init_num_flits             (ctrl_datap_init_num_flits              )
        ,.ctrl_datap_decr_num_flits             (ctrl_datap_decr_num_flits              )
                                                                                        
        ,.datap_ctrl_last_flit                  (datap_ctrl_last_flit                   )
    );

    eth_tx_noc_in_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_eth_tx_in_val              (noc0_ctovr_eth_tx_in_val           )
        ,.eth_tx_in_noc0_ctovr_rdy              (eth_tx_in_noc0_ctovr_rdy           )
                                                                                    
        ,.eth_tx_in_eth_tostream_eth_hdr_val    (eth_tx_in_eth_tostream_eth_hdr_val )
        ,.eth_tostream_eth_tx_in_eth_hdr_rdy    (eth_tostream_eth_tx_in_eth_hdr_rdy )
                                                                                    
        ,.eth_tx_in_eth_tostream_data_val       (eth_tx_in_eth_tostream_data_val    )
        ,.eth_tostream_eth_tx_in_data_rdy       (eth_tostream_eth_tx_in_data_rdy    )
                                                                                    
        ,.ctrl_datap_store_hdr_flit             (ctrl_datap_store_hdr_flit          )
        ,.ctrl_datap_store_meta_flit            (ctrl_datap_store_meta_flit         )
        ,.ctrl_datap_init_num_flits             (ctrl_datap_init_num_flits          )
        ,.ctrl_datap_decr_num_flits             (ctrl_datap_decr_num_flits          )
                                                                                    
        ,.datap_ctrl_last_flit                  (datap_ctrl_last_flit               )
        ,.eth_wr_log                            (eth_wr_log                         )
    );

endmodule
