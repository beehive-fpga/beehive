`ifndef TCP_TX_TILE_DEFS
`define TCP_TX_TILE_DEFS
    `include "noc_defs.vh"
    `include "soc_defs.vh"
    `include "packet_defs.vh"

    import packet_struct_pkg::*;
    import tcp_pkg::*;

    import beehive_tcp_msg::*; 
    import beehive_ip_msg::*;
    import beehive_noc_msg::*;
    import tcp_tx_tile_pkg::*;
    import beehive_topology::*;
`endif
