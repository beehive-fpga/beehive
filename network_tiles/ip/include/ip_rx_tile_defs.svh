`ifndef IP_RX_TILE_DEFS
`define IP_RX_TILE_DEFS
    `include "noc_defs.vh"
    `include "soc_defs.vh"
    `include "packet_defs.vh"

    import packet_struct_pkg::*;

    import beehive_eth_msg::*;
    import beehive_ip_msg::*;
    import beehive_noc_msg::*;
    import beehive_topology::*;

    import ip_rx_tile_pkg::*;
`endif
