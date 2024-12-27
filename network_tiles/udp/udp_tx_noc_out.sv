`include "udp_tx_tile_defs.svh"
`include "soc_defs.vh"
module udp_tx_noc_out #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           udp_tx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_tx_out_noc0_vrtoc_data    
    ,input  logic                           noc0_vrtoc_udp_tx_out_rdy
    
    ,input  logic                           udp_to_stream_udp_tx_out_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]        udp_to_stream_udp_tx_out_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        udp_to_stream_udp_tx_out_dst_ip
    ,input  logic   [`TOT_LEN_W-1:0]        udp_to_stream_udp_tx_out_udp_len
    ,input  logic   [`PROTOCOL_W-1:0]       udp_to_stream_udp_tx_out_protocol
    ,input  logic   [MSG_TIMESTAMP_W-1:0]   udp_to_stream_udp_tx_out_timestamp
    ,output                                 udp_tx_out_udp_to_stream_hdr_rdy
    
    ,input  logic                           udp_to_stream_udp_tx_out_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  udp_to_stream_udp_tx_out_data
    ,input  logic                           udp_to_stream_udp_tx_out_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   udp_to_stream_udp_tx_out_padbytes
    ,output                                 udp_tx_out_udp_to_stream_rdy
);
    
    udp_tx_tile_pkg::noc_out_flit_mux_sel   ctrl_datap_flit_sel;
    logic                                   ctrl_datap_store_inputs;

    logic                                   datap_ctrl_last_output;

    udp_tx_noc_out_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_tx_out_noc0_vrtoc_data        (udp_tx_out_noc0_vrtoc_data         )
                                                                                
        ,.udp_to_stream_udp_tx_out_src_ip   (udp_to_stream_udp_tx_out_src_ip    )
        ,.udp_to_stream_udp_tx_out_dst_ip   (udp_to_stream_udp_tx_out_dst_ip    )
        ,.udp_to_stream_udp_tx_out_udp_len  (udp_to_stream_udp_tx_out_udp_len   )
        ,.udp_to_stream_udp_tx_out_protocol (udp_to_stream_udp_tx_out_protocol  )
        ,.udp_to_stream_udp_tx_out_timestamp(udp_to_stream_udp_tx_out_timestamp )

        ,.src_udp_tx_out_dst_x              (IP_TX_TILE_X                       )
        ,.src_udp_tx_out_dst_y              (IP_TX_TILE_Y                       )
                                                                                
        ,.udp_to_stream_udp_tx_out_data     (udp_to_stream_udp_tx_out_data      )
        ,.udp_to_stream_udp_tx_out_last     (udp_to_stream_udp_tx_out_last      )
        ,.udp_to_stream_udp_tx_out_padbytes (udp_to_stream_udp_tx_out_padbytes  )
                                                                                
        ,.ctrl_datap_flit_sel               (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
                                                                                
        ,.datap_ctrl_last_output            (datap_ctrl_last_output             )
    );

    udp_tx_noc_out_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_tx_out_noc0_vrtoc_val         (udp_tx_out_noc0_vrtoc_val          )
        ,.noc0_vrtoc_udp_tx_out_rdy         (noc0_vrtoc_udp_tx_out_rdy          )
                                                                                
        ,.udp_to_stream_udp_tx_out_hdr_val  (udp_to_stream_udp_tx_out_hdr_val   )
        ,.udp_tx_out_udp_to_stream_hdr_rdy  (udp_tx_out_udp_to_stream_hdr_rdy   )
                                                                                
        ,.udp_to_stream_udp_tx_out_val      (udp_to_stream_udp_tx_out_val       )
        ,.udp_tx_out_udp_to_stream_rdy      (udp_tx_out_udp_to_stream_rdy       )
                                                                                
        ,.ctrl_datap_flit_sel               (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
                                                                                
        ,.datap_ctrl_last_output            (datap_ctrl_last_output             )
    );

endmodule
