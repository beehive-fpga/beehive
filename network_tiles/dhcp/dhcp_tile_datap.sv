`include "dhcp_tile_defs.svh"

module dhcp_tile_datap #(
    parameter NOC_DATA_W = `NOC_DATA_WIDTH
) (
    input  udp_info               fr_udp_meta_info,
    input  logic [NOC_DATA_W-1:0] fr_udp_data,

    output udp_info               to_udp_meta_info,
    output logic [NOC_DATA_W-1:0] to_udp_data,

    output logic                  datap_ctrl_dst_port_is_client
);
    assign to_udp_meta_info              = fr_udp_meta_info;
    assign to_udp_data                   = fr_udp_data;
    assign datap_ctrl_dst_port_is_client = (fr_udp_meta_info.dst_port == DHCP_CLIENT_PORT);
endmodule
