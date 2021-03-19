`include "tcp_tx_tile_defs.svh"
module tcp_tx_noc_out #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           tcp_tx_out_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_out_noc0_data    
    ,input  logic                           noc0_tcp_tx_out_rdy

    ,input  logic                           src_tcp_tx_out_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]        src_tcp_tx_out_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        src_tcp_tx_out_dst_ip
    ,input  logic   [`TOT_LEN_W-1:0]        src_tcp_tx_out_tcp_len
    ,input  logic   [`PROTOCOL_W-1:0]       src_tcp_tx_out_protocol
    ,output logic                           tcp_tx_out_src_hdr_rdy

    ,input  logic                           src_tcp_tx_out_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  src_tcp_tx_out_data
    ,input  logic                           src_tcp_tx_out_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   src_tcp_tx_out_padbytes
    ,output                                 tcp_tx_out_src_data_rdy
);
    
    noc_out_flit_mux_sel            ctrl_datap_flit_sel;
    logic                           ctrl_datap_store_inputs;

    logic                           datap_ctrl_last_output;

    tcp_tx_noc_out_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk)
        ,.rst   (rst)

        ,.tcp_tx_out_noc0_data      (tcp_tx_out_noc0_data       )
                                                                
        ,.src_tcp_tx_out_src_ip     (src_tcp_tx_out_src_ip      )
        ,.src_tcp_tx_out_dst_ip     (src_tcp_tx_out_dst_ip      )
        ,.src_tcp_tx_out_tcp_len    (src_tcp_tx_out_tcp_len     )
        ,.src_tcp_tx_out_protocol   (src_tcp_tx_out_protocol    )
                                                                
        ,.src_tcp_tx_out_data       (src_tcp_tx_out_data        )
        ,.src_tcp_tx_out_last       (src_tcp_tx_out_last        )
        ,.src_tcp_tx_out_padbytes   (src_tcp_tx_out_padbytes    )
                                                                
        ,.ctrl_datap_flit_sel       (ctrl_datap_flit_sel        )
        ,.ctrl_datap_store_inputs   (ctrl_datap_store_inputs    )
                                                                
        ,.datap_ctrl_last_output    (datap_ctrl_last_output     )
    );

    tcp_tx_noc_out_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.tcp_tx_out_noc0_val       (tcp_tx_out_noc0_val        )
        ,.noc0_tcp_tx_out_rdy       (noc0_tcp_tx_out_rdy        )
                                                                
        ,.src_tcp_tx_out_hdr_val    (src_tcp_tx_out_hdr_val     )
        ,.tcp_tx_out_src_hdr_rdy    (tcp_tx_out_src_hdr_rdy     )
                                                                
        ,.src_tcp_tx_out_data_val   (src_tcp_tx_out_data_val    )
        ,.tcp_tx_out_src_data_rdy   (tcp_tx_out_src_data_rdy    )
                                                                
        ,.ctrl_datap_flit_sel       (ctrl_datap_flit_sel        )
        ,.ctrl_datap_store_inputs   (ctrl_datap_store_inputs    )
                                                                
        ,.datap_ctrl_last_output    (datap_ctrl_last_output     )
    );

endmodule
