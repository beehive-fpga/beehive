`include "udp_echo_app_defs.svh"
module udp_echo_app_ctrl_temp (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_app_in_val
    ,output logic                           udp_app_in_noc0_ctovr_rdy
    
    ,output logic                           udp_app_out_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_udp_app_out_rdy

    /* TODO: add more wires here as necessary */
    
);

endmodule
