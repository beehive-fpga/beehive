`include "ip_tx_tile_defs.svh"
module ip_tx_noc_out_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           ip_tx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_tx_out_noc0_vrtoc_data    
    ,input  logic                           noc0_vrtoc_ip_tx_out_rdy
    
    ,input  logic                           ip_to_ethstream_ip_tx_out_hdr_val
    ,input  eth_hdr                         ip_to_ethstream_ip_tx_out_eth_hdr
    ,input  logic   [`TOT_LEN_W-1:0]        ip_to_ethstream_ip_tx_out_data_len
    ,input  logic   [MSG_TIMESTAMP_W-1:0]   ip_to_ethstream_ip_tx_out_timestamp
    ,output logic                           ip_tx_out_ip_to_ethstream_hdr_rdy

    ,input  logic                           ip_to_ethstream_ip_tx_out_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  ip_to_ethstream_ip_tx_out_data
    ,input  logic                           ip_to_ethstream_ip_tx_out_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   ip_to_ethstream_ip_tx_out_data_padbytes
    ,output                                 ip_tx_out_ip_to_ethstream_data_rdy
);


    localparam IP_TX_DST_X = (SRC_X == 1) && (SRC_Y == 1)
        ? ETH_TX_TILE_X
        : (SRC_X == 1) && (SRC_Y == 3)
        ? ETH_TX_TILE1_X
        : 0;
    localparam IP_TX_DST_Y = (SRC_X == 1) && (SRC_Y == 1)
        ? ETH_TX_TILE_Y
        : (SRC_X == 1) && (SRC_Y == 3)
        ? ETH_TX_TILE1_Y
        : 0;

    ip_tx_tile_pkg::noc_out_flit_mux_sel    ctrl_datap_flit_sel;
    logic                                   ctrl_datap_store_inputs;

    logic                                   datap_ctrl_last_output;

    ip_tx_noc_out_datap #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.ip_tx_out_noc0_vrtoc_data                 (ip_tx_out_noc0_vrtoc_data                  )
                                                                                                
        ,.ip_to_ethstream_ip_tx_out_eth_hdr         (ip_to_ethstream_ip_tx_out_eth_hdr          )
        ,.ip_to_ethstream_ip_tx_out_timestamp       (ip_to_ethstream_ip_tx_out_timestamp        )
        ,.ip_to_ethstream_ip_tx_out_data_len        (ip_to_ethstream_ip_tx_out_data_len         )
        
        ,.src_ip_tx_out_dst_x                       (IP_TX_DST_X[`XY_WIDTH-1:0]                 )
        ,.src_ip_tx_out_dst_y                       (IP_TX_DST_Y[`XY_WIDTH-1:0]                 )
                                                                                                
        ,.ip_to_ethstream_ip_tx_out_data            (ip_to_ethstream_ip_tx_out_data             )
        ,.ip_to_ethstream_ip_tx_out_data_last       (ip_to_ethstream_ip_tx_out_data_last        )
        ,.ip_to_ethstream_ip_tx_out_data_padbytes   (ip_to_ethstream_ip_tx_out_data_padbytes    )
                                                                                                
        ,.ctrl_datap_flit_sel                       (ctrl_datap_flit_sel                        )
        ,.ctrl_datap_store_inputs                   (ctrl_datap_store_inputs                    )
                                                                                                
        ,.datap_ctrl_last_output                    (datap_ctrl_last_output                     )
    );

    ip_tx_noc_out_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.ip_tx_out_noc0_vrtoc_val              (ip_tx_out_noc0_vrtoc_val           )
        ,.noc0_vrtoc_ip_tx_out_rdy              (noc0_vrtoc_ip_tx_out_rdy           )
                                                                                    
        ,.ip_to_ethstream_ip_tx_out_hdr_val     (ip_to_ethstream_ip_tx_out_hdr_val  )
        ,.ip_tx_out_ip_to_ethstream_hdr_rdy     (ip_tx_out_ip_to_ethstream_hdr_rdy  )
                                                                                    
        ,.ip_to_ethstream_ip_tx_out_data_val    (ip_to_ethstream_ip_tx_out_data_val )
        ,.ip_tx_out_ip_to_ethstream_data_rdy    (ip_tx_out_ip_to_ethstream_data_rdy )
                                                                                    
        ,.ctrl_datap_flit_sel                   (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs               (ctrl_datap_store_inputs            )
                                                                                    
        ,.datap_ctrl_last_output                (datap_ctrl_last_output             )
    );
endmodule
