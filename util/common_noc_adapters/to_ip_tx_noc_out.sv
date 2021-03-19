`include "to_ip_tx_defs.svh"
module to_ip_tx_noc_out #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           to_ip_tx_out_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   to_ip_tx_out_noc0_data    
    ,input  logic                           noc0_to_ip_tx_out_rdy

    ,input  logic                           src_to_ip_tx_out_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]        src_to_ip_tx_out_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        src_to_ip_tx_out_dst_ip
    ,input  logic   [`TOT_LEN_W-1:0]        src_to_ip_tx_out_payload_len
    ,input  logic   [`PROTOCOL_W-1:0]       src_to_ip_tx_out_protocol
    ,input  logic   [`XY_WIDTH-1:0]         src_to_ip_tx_out_dst_x
    ,input  logic   [`XY_WIDTH-1:0]         src_to_ip_tx_out_dst_y
    ,output logic                           to_ip_tx_out_src_hdr_rdy

    ,input  logic                           src_to_ip_tx_out_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  src_to_ip_tx_out_data
    ,input  logic                           src_to_ip_tx_out_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   src_to_ip_tx_out_padbytes
    ,output                                 to_ip_tx_out_src_data_rdy
);
    
    to_ip_tx_pkg::noc_flit_mux_sel  ctrl_datap_flit_sel;
    logic                           ctrl_datap_store_inputs;

    logic                           datap_ctrl_last_output;

    to_ip_tx_noc_out_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.to_ip_tx_out_noc0_val     (to_ip_tx_out_noc0_val      )
        ,.noc0_to_ip_tx_out_rdy     (noc0_to_ip_tx_out_rdy      )
                                                                
        ,.src_to_ip_tx_out_hdr_val  (src_to_ip_tx_out_hdr_val   )
        ,.to_ip_tx_out_src_hdr_rdy  (to_ip_tx_out_src_hdr_rdy   )
                                                                
        ,.src_to_ip_tx_out_data_val (src_to_ip_tx_out_data_val  )
        ,.to_ip_tx_out_src_data_rdy (to_ip_tx_out_src_data_rdy  )
                                                                
        ,.ctrl_datap_flit_sel       (ctrl_datap_flit_sel        )
        ,.ctrl_datap_store_inputs   (ctrl_datap_store_inputs    )
                                                                
        ,.datap_ctrl_last_output    (datap_ctrl_last_output     )
    );

    to_ip_tx_noc_out_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.to_ip_tx_out_noc0_data        (to_ip_tx_out_noc0_data         )
                                                                        
        ,.src_to_ip_tx_out_src_ip       (src_to_ip_tx_out_src_ip        )
        ,.src_to_ip_tx_out_dst_ip       (src_to_ip_tx_out_dst_ip        )
        ,.src_to_ip_tx_out_payload_len  (src_to_ip_tx_out_payload_len   )
        ,.src_to_ip_tx_out_protocol     (src_to_ip_tx_out_protocol      )
        ,.src_to_ip_tx_out_dst_x        (src_to_ip_tx_out_dst_x         )
        ,.src_to_ip_tx_out_dst_y        (src_to_ip_tx_out_dst_y         )
                                                                        
        ,.src_to_ip_tx_out_data         (src_to_ip_tx_out_data          )
        ,.src_to_ip_tx_out_last         (src_to_ip_tx_out_last          )
        ,.src_to_ip_tx_out_padbytes     (src_to_ip_tx_out_padbytes      )
                                                                        
        ,.ctrl_datap_flit_sel           (ctrl_datap_flit_sel            )
        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs        )
                                                                        
        ,.datap_ctrl_last_output        (datap_ctrl_last_output         )
    );

endmodule
