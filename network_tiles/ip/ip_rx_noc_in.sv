`include "ip_rx_tile_defs.svh"
module ip_rx_noc_in (
     input clk
    ,input rst
    
    ,input                                      noc0_ctovr_ip_rx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_ip_rx_in_data
    ,output logic                               ip_rx_in_noc0_ctovr_rdy

    ,output logic                               ip_rx_in_ip_format_rx_val
    ,output logic   [MSG_TIMESTAMP_W-1:0]       ip_rx_in_ip_format_rx_timestamp
    ,output logic   [`MAC_INTERFACE_W-1:0]      ip_rx_in_ip_format_rx_data
    ,output logic                               ip_rx_in_ip_format_rx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       ip_rx_in_ip_format_rx_padbytes
    ,input  logic                               ip_format_ip_rx_in_rx_rdy
);
    
    logic                               datap_ctrl_last_flit;
    logic                               datap_ctrl_last_meta_flit;
    
    logic                               ctrl_datap_init_data;
    logic                               ctrl_datap_store_meta_flit;
    logic                               ctrl_datap_decr_meta_flits;
    logic                               ctrl_datap_decr_data_flits;

    ip_rx_noc_in_datap datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_rx_in_data          (noc0_ctovr_ip_rx_in_data       )

        ,.ip_rx_in_ip_format_rx_data        (ip_rx_in_ip_format_rx_data     )
        ,.ip_rx_in_ip_format_rx_last        (ip_rx_in_ip_format_rx_last     )
        ,.ip_rx_in_ip_format_rx_padbytes    (ip_rx_in_ip_format_rx_padbytes )
        ,.ip_rx_in_ip_format_rx_timestamp   (ip_rx_in_ip_format_rx_timestamp)
        
        ,.datap_ctrl_last_flit              (datap_ctrl_last_flit           )
        ,.datap_ctrl_last_meta_flit         (datap_ctrl_last_meta_flit      )
                                                                            
        ,.ctrl_datap_init_data              (ctrl_datap_init_data           )
        ,.ctrl_datap_store_meta_flit        (ctrl_datap_store_meta_flit     )
        ,.ctrl_datap_decr_meta_flits        (ctrl_datap_decr_meta_flits     )
        ,.ctrl_datap_decr_data_flits        (ctrl_datap_decr_data_flits     )
    );

    ip_rx_noc_in_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_rx_in_val       (noc0_ctovr_ip_rx_in_val    )
        ,.noc0_ctovr_ip_rx_in_data      (noc0_ctovr_ip_rx_in_data   )
        ,.ip_rx_in_noc0_ctovr_rdy       (ip_rx_in_noc0_ctovr_rdy    )

        ,.ip_rx_in_ip_format_rx_val     (ip_rx_in_ip_format_rx_val  )
        ,.ip_format_ip_rx_in_rx_rdy     (ip_format_ip_rx_in_rx_rdy  )

        ,.datap_ctrl_last_flit          (datap_ctrl_last_flit       )
        ,.datap_ctrl_last_meta_flit     (datap_ctrl_last_meta_flit  )

        ,.ctrl_datap_init_data          (ctrl_datap_init_data       )
        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit )
        ,.ctrl_datap_decr_meta_flits    (ctrl_datap_decr_meta_flits )
        ,.ctrl_datap_decr_data_flits    (ctrl_datap_decr_data_flits )
    );
endmodule
