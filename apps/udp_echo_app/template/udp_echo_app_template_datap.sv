`include "udp_echo_app_defs.svh"
module udp_echo_app_datap_temp #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_app_in_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_app_out_noc0_vrtoc_data

    ,input          [`XY_WIDTH-1:0]         src_udp_app_out_dst_x
    ,input          [`XY_WIDTH-1:0]         src_udp_app_out_dst_y

    /* TODO: Add more wires here as necessary */
);
    


endmodule
