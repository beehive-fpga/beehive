`ifndef TCP_RX_TILE_DEFS
`define TCP_RX_TILE_DEFS
    `include "noc_defs.vh"
    `include "soc_defs.vh"
    `include "packet_defs.vh"

    import packet_struct_pkg::*;
    import tcp_pkg::*;

    import beehive_tcp_msg::*; 
    import beehive_ip_msg::*;
    import beehive_noc_msg::*;
    import beehive_topology::*;

    import tcp_rx_tile_pkg::*;
`endif
