`include "mrp_tx_defs.svh"
module mrp_tx_noc_out #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           mrp_tx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   mrp_tx_out_noc0_vrtoc_data    
    ,input  logic                           noc0_vrtoc_mrp_tx_out_rdy
    
    ,input  logic                           mrp_engine_mrp_tx_out_tx_meta_val
    ,input  logic   [`IP_ADDR_W-1:0]        mrp_engine_mrp_tx_out_tx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        mrp_engine_mrp_tx_out_tx_dst_ip
    ,input  logic   [`PORT_NUM_W-1:0]       mrp_engine_mrp_tx_out_tx_src_port
    ,input  logic   [`PORT_NUM_W-1:0]       mrp_engine_mrp_tx_out_tx_dst_port
    ,input  logic   [`UDP_LENGTH_W-1:0]     mrp_engine_mrp_tx_out_tx_len
    ,output logic                           mrp_tx_out_mrp_engine_tx_meta_rdy

    ,input  logic                           mrp_engine_mrp_tx_out_tx_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  mrp_engine_mrp_tx_out_tx_data
    ,input  logic                           mrp_engine_mrp_tx_out_tx_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   mrp_engine_mrp_tx_out_tx_data_padbytes
    ,output logic                           mrp_tx_out_mrp_engine_tx_data_rdy
);
    
    mrp_noc_out_flit_mux_sel        ctrl_datap_flit_sel;
    logic                           ctrl_datap_store_inputs;

    logic                           datap_ctrl_last_output;

    mrp_tx_noc_out_datap #(
         .SRC_X  (SRC_X  )
        ,.SRC_Y  (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.mrp_tx_out_noc0_vrtoc_data        (mrp_tx_out_noc0_vrtoc_data             )
                                                                                    
        ,.mrp_mrp_tx_out_tx_src_ip          (mrp_engine_mrp_tx_out_tx_src_ip        )
        ,.mrp_mrp_tx_out_tx_dst_ip          (mrp_engine_mrp_tx_out_tx_dst_ip        )
        ,.mrp_mrp_tx_out_tx_src_port        (mrp_engine_mrp_tx_out_tx_src_port      )
        ,.mrp_mrp_tx_out_tx_dst_port        (mrp_engine_mrp_tx_out_tx_dst_port      )
        ,.mrp_mrp_tx_out_tx_len             (mrp_engine_mrp_tx_out_tx_len           )
                                                                                
        ,.mrp_mrp_tx_out_tx_data            (mrp_engine_mrp_tx_out_tx_data          )
        ,.mrp_mrp_tx_out_tx_data_last       (mrp_engine_mrp_tx_out_tx_data_last     )
        ,.mrp_mrp_tx_out_tx_data_padbytes   (mrp_engine_mrp_tx_out_tx_data_padbytes )
                                                                                
        ,.ctrl_datap_flit_sel               (ctrl_datap_flit_sel                    )
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs                )
                                                                                    
        ,.datap_ctrl_last_output            (datap_ctrl_last_output                 )
    );

    mrp_tx_noc_out_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.mrp_tx_out_noc0_vrtoc_val     (mrp_tx_out_noc0_vrtoc_val          )
        ,.noc0_vrtoc_mrp_tx_out_rdy     (noc0_vrtoc_mrp_tx_out_rdy          )
                                                                    
        ,.mrp_mrp_tx_out_tx_meta_val    (mrp_engine_mrp_tx_out_tx_meta_val  )
        ,.mrp_tx_out_mrp_tx_meta_rdy    (mrp_tx_out_mrp_engine_tx_meta_rdy  )
                                                                    
        ,.mrp_mrp_tx_out_tx_data_val    (mrp_engine_mrp_tx_out_tx_data_val  )
        ,.mrp_tx_out_mrp_tx_data_rdy    (mrp_tx_out_mrp_engine_tx_data_rdy  )
                                                                    
        ,.ctrl_datap_flit_sel           (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs            )
                                                                            
        ,.datap_ctrl_last_output        (datap_ctrl_last_output             )
    );


endmodule
