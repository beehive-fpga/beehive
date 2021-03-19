`include "ip_tx_tile_defs.svh"
module ip_tx_tile_noc_in (
     input clk
    ,input rst
    
    ,input                                      noc0_ctovr_ip_tx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_ip_tx_in_data
    ,output logic                               ip_tx_in_noc0_ctovr_rdy

   
    ,output                                     ip_tx_in_assemble_meta_val
    ,output ip_tx_metadata_flit                 ip_tx_in_assemble_meta_flit
    ,input                                      assemble_ip_tx_in_meta_rdy 
    
    ,output logic                               ip_tx_in_assemble_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]      ip_tx_in_assemble_data
    ,output logic                               ip_tx_in_assemble_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       ip_tx_in_assemble_padbytes
    ,input                                      assemble_ip_tx_in_data_rdy
);
    
    logic   ctrl_datap_store_hdr_flit;
    logic   ctrl_datap_store_meta_flit;
    logic   ctrl_datap_init_num_flits;
    logic   ctrl_datap_decr_num_flits;

    logic   datap_ctrl_last_flit;

    ip_tx_tile_noc_in_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_tx_in_val       (noc0_ctovr_ip_tx_in_val    )
        ,.ip_tx_in_noc0_ctovr_rdy       (ip_tx_in_noc0_ctovr_rdy    )
                                                                    
        ,.ip_tx_in_assemble_meta_val    (ip_tx_in_assemble_meta_val )
        ,.assemble_ip_tx_in_meta_rdy    (assemble_ip_tx_in_meta_rdy )
                                                                    
        ,.ip_tx_in_assemble_data_val    (ip_tx_in_assemble_data_val )
        ,.assemble_ip_tx_in_data_rdy    (assemble_ip_tx_in_data_rdy )
                                                                    
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit  )
        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit )
        ,.ctrl_datap_init_num_flits     (ctrl_datap_init_num_flits  )
        ,.ctrl_datap_decr_num_flits     (ctrl_datap_decr_num_flits  )
                                                                    
        ,.datap_ctrl_last_flit          (datap_ctrl_last_flit       )
    );

    ip_tx_tile_noc_in_datap datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_tx_in_data      (noc0_ctovr_ip_tx_in_data       )
                                                                        
        ,.ip_tx_in_assemble_meta_flit   (ip_tx_in_assemble_meta_flit    )
                                                                        
        ,.ip_tx_in_assemble_data        (ip_tx_in_assemble_data         )
        ,.ip_tx_in_assemble_last        (ip_tx_in_assemble_last         )
        ,.ip_tx_in_assemble_padbytes    (ip_tx_in_assemble_padbytes     )
                                                                        
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit     )
        ,.ctrl_datap_init_num_flits     (ctrl_datap_init_num_flits      )
        ,.ctrl_datap_decr_num_flits     (ctrl_datap_decr_num_flits      )
                                                                        
        ,.datap_ctrl_last_flit          (datap_ctrl_last_flit           )
    );


endmodule
