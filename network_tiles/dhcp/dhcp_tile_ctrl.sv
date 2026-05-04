`include "dhcp_tile_defs.svh"

// Tile-level RX control. Drains every UDP packet that lands on the DHCP tile
// so the observe-only parser can register the fields. The lease FSM lands
// here in step 6 and starts gating tx_start / consuming parsed lease info.
module dhcp_tile_ctrl (
    input  logic clk,
    input  logic rst,

    input  logic fr_udp_meta_val,
    output logic fr_udp_meta_rdy,
    input  logic fr_udp_data_val,
    input  logic fr_udp_data_last,
    output logic fr_udp_data_rdy
);
    assign fr_udp_meta_rdy = 1'b1;
    assign fr_udp_data_rdy = 1'b1;
endmodule
