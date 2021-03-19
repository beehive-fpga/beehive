`ifndef UDP_RX_TILE_DEFS
`define UDP_RX_TILE_DEFS
    `include "noc_defs.vh"
    `include "packet_defs.vh"

    import packet_struct_pkg::*;

    import beehive_ip_msg::*;
    import beehive_udp_msg::*;
    import beehive_noc_msg::*;
    import beehive_tcp_logger_msg::*;
    import beehive_udp_app_logger_msg::*;
    import beehive_echo_app_logger_msg::*;
    import beehive_topology::*;

    import udp_rx_tile_pkg::*;
`endif
