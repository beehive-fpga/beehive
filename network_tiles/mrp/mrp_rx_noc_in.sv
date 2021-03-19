`include "mrp_rx_defs.svh"
module mrp_rx_noc_in (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_mrp_rx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_mrp_rx_in_data
    ,output logic                           mrp_rx_in_noc0_ctovr_rdy
    
    ,output logic                           mrp_rx_in_mrp_engine_rx_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]        mrp_rx_in_mrp_engine_rx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]        mrp_rx_in_mrp_engine_rx_dst_ip
    ,output logic   [`PORT_NUM_W-1:0]       mrp_rx_in_mrp_engine_rx_src_port
    ,output logic   [`PORT_NUM_W-1:0]       mrp_rx_in_mrp_engine_rx_dst_port
    ,input  logic                           mrp_engine_mrp_rx_in_rx_hdr_rdy

    ,output logic                           mrp_rx_in_mrp_engine_rx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  mrp_rx_in_mrp_engine_rx_data
    ,output logic                           mrp_rx_in_mrp_engine_rx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   mrp_rx_in_mrp_engine_rx_padbytes
    ,input  logic                           mrp_engine_mrp_rx_in_rx_data_rdy
);
    logic   ctrl_datap_store_hdr_flit;
    logic   ctrl_datap_store_meta_flit;
    logic   ctrl_datap_init_num_flits;
    logic   ctrl_datap_decr_num_flits;

    logic   datap_ctrl_last_flit;

    mrp_rx_noc_in_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_mrp_rx_in_val          (noc0_ctovr_mrp_rx_in_val           )
        ,.mrp_rx_in_noc0_ctovr_rdy          (mrp_rx_in_noc0_ctovr_rdy           )
                                                                                
        ,.mrp_rx_in_mrp_engine_rx_hdr_val   (mrp_rx_in_mrp_engine_rx_hdr_val    )
        ,.mrp_engine_mrp_rx_in_rx_hdr_rdy   (mrp_engine_mrp_rx_in_rx_hdr_rdy    )
                                                                                
        ,.mrp_rx_in_mrp_engine_rx_data_val  (mrp_rx_in_mrp_engine_rx_data_val   )
        ,.mrp_engine_mrp_rx_in_rx_data_rdy  (mrp_engine_mrp_rx_in_rx_data_rdy   )
                                                                                
        ,.ctrl_datap_store_hdr_flit         (ctrl_datap_store_hdr_flit          )
        ,.ctrl_datap_store_meta_flit        (ctrl_datap_store_meta_flit         )
        ,.ctrl_datap_init_num_flits         (ctrl_datap_init_num_flits          )
        ,.ctrl_datap_decr_num_flits         (ctrl_datap_decr_num_flits          )
                                                                                
        ,.datap_ctrl_last_flit              (datap_ctrl_last_flit               )
    );

    mrp_rx_noc_in_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_mrp_rx_in_data         (noc0_ctovr_mrp_rx_in_data          )
                                                                                
        ,.mrp_rx_in_mrp_engine_rx_src_ip    (mrp_rx_in_mrp_engine_rx_src_ip     )
        ,.mrp_rx_in_mrp_engine_rx_dst_ip    (mrp_rx_in_mrp_engine_rx_dst_ip     )
        ,.mrp_rx_in_mrp_engine_rx_src_port  (mrp_rx_in_mrp_engine_rx_src_port   )
        ,.mrp_rx_in_mrp_engine_rx_dst_port  (mrp_rx_in_mrp_engine_rx_dst_port   )
                                                                                
        ,.mrp_rx_in_mrp_engine_rx_data      (mrp_rx_in_mrp_engine_rx_data       )
        ,.mrp_rx_in_mrp_engine_rx_last      (mrp_rx_in_mrp_engine_rx_last       )
        ,.mrp_rx_in_mrp_engine_rx_padbytes  (mrp_rx_in_mrp_engine_rx_padbytes   )
                                                                                
        ,.ctrl_datap_store_hdr_flit         (ctrl_datap_store_hdr_flit          )
        ,.ctrl_datap_store_meta_flit        (ctrl_datap_store_meta_flit         )
        ,.ctrl_datap_init_num_flits         (ctrl_datap_init_num_flits          )
        ,.ctrl_datap_decr_num_flits         (ctrl_datap_decr_num_flits          )
                                                                                
        ,.datap_ctrl_last_flit              (datap_ctrl_last_flit               )
    );
endmodule
