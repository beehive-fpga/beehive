`include "noc_defs.vh"
`include "packet_defs.vh"

import beehive_topology::*;
import beehive_noc_msg::*;
import beehive_udp_msg::*;

// Cocotb-driven NoC sender used to exercise IP_TX's SRC_IP_POLICY
// substitution end-to-end. Lives only inside the dhcp_client harness;
// not a production tile.
//
// On a single-cycle `trigger`, latches src_ip/dst_ip/ports/payload_len/
// payload and walks IDLE -> SEND_META -> SEND_DATA -> IDLE through the
// `to_udp` adapter aimed at UDP_TX_TILE. From there the burst flows
// udp_tx -> ip_tx (where SRC_IP_POLICY=1 may substitute src_ip with the
// DHCP-bound yiaddr) -> eth_tx -> MAC.
//
// One data flit only -- enough for the test payload sizes we care about.
module udp_test_sender_core #(
    parameter int                              NOC_DATA_W = `NOC_DATA_WIDTH,
    parameter int                              SRC_X      = -1,
    parameter int                              SRC_Y      = -1,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0] SRC_FBITS  = PKT_IF_FBITS
) (
    input  logic clk,
    input  logic rst,

    // Cocotb-driven inputs (latched at trigger handshake).
    input  logic                          trigger,
    input  logic [`IP_ADDR_W-1:0]         in_src_ip,
    input  logic [`IP_ADDR_W-1:0]         in_dst_ip,
    input  logic [`PORT_NUM_W-1:0]        in_src_port,
    input  logic [`PORT_NUM_W-1:0]        in_dst_port,
    input  logic [`UDP_LENGTH_W-1:0]      in_payload_len,
    input  logic [NOC_DATA_W-1:0]         in_payload,
    output logic                          sender_done,

    // NoC interfaces (val/rdy after the wrapper's credit converters).
    input  logic                          noc_in_val,
    input  logic [NOC_DATA_W-1:0]         noc_in_data,
    output logic                          noc_in_rdy,

    output logic                          noc_out_val,
    output logic [NOC_DATA_W-1:0]         noc_out_data,
    input  logic                          noc_out_rdy
);
    // We never expect to receive anything; drain it.
    assign noc_in_rdy = 1'b1;

    // to_udp adapter -- handles NoC header + meta + data framing.
    logic                  to_udp_meta_val;
    udp_info               to_udp_meta_info;
    logic                  to_udp_meta_rdy;
    logic                  to_udp_data_val;
    logic [NOC_DATA_W-1:0] to_udp_data;
    logic                  to_udp_data_rdy;

    to_udp #(
         .NOC_DATA_W (NOC_DATA_W)
        ,.SRC_X      (SRC_X     )
        ,.SRC_Y      (SRC_Y     )
        ,.SRC_FBITS  (SRC_FBITS )
    ) to_udp_i (
         .clk(clk)
        ,.rst(rst)

        ,.src_to_udp_meta_val   (to_udp_meta_val            )
        ,.src_to_udp_meta_info  (to_udp_meta_info           )
        ,.to_udp_src_meta_rdy   (to_udp_meta_rdy            )

        ,.src_to_udp_data_val   (to_udp_data_val            )
        ,.src_to_udp_data       (to_udp_data                )
        ,.to_udp_src_data_rdy   (to_udp_data_rdy            )

        ,.to_udp_noc_vrtoc_val  (noc_out_val                )
        ,.to_udp_noc_vrtoc_data (noc_out_data               )
        ,.noc_vrtoc_to_udp_rdy  (noc_out_rdy                )

        ,.src_to_udp_dst_x      (UDP_TX_TILE_X[`XY_WIDTH-1:0]       )
        ,.src_to_udp_dst_y      (UDP_TX_TILE_Y[`XY_WIDTH-1:0]       )
        ,.src_to_udp_dst_fbits  (PKT_IF_FBITS[`NOC_FBITS_WIDTH-1:0] )
    );

    typedef enum logic [1:0] {
        IDLE      = 2'd0,
        SEND_META = 2'd1,
        SEND_DATA = 2'd2,
        UND       = 'X
    } state_e;

    state_e state_reg, state_next;

    // Latched inputs (stay stable across the burst).
    logic [`IP_ADDR_W-1:0]    src_ip_reg,      src_ip_next;
    logic [`IP_ADDR_W-1:0]    dst_ip_reg,      dst_ip_next;
    logic [`PORT_NUM_W-1:0]   src_port_reg,    src_port_next;
    logic [`PORT_NUM_W-1:0]   dst_port_reg,    dst_port_next;
    logic [`UDP_LENGTH_W-1:0] payload_len_reg, payload_len_next;
    logic [NOC_DATA_W-1:0]    payload_reg,     payload_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg       <= IDLE;
            src_ip_reg      <= '0;
            dst_ip_reg      <= '0;
            src_port_reg    <= '0;
            dst_port_reg    <= '0;
            payload_len_reg <= '0;
            payload_reg     <= '0;
        end else begin
            state_reg       <= state_next;
            src_ip_reg      <= src_ip_next;
            dst_ip_reg      <= dst_ip_next;
            src_port_reg    <= src_port_next;
            dst_port_reg    <= dst_port_next;
            payload_len_reg <= payload_len_next;
            payload_reg     <= payload_next;
        end
    end

    always_comb begin
        to_udp_meta_info             = '0;
        to_udp_meta_info.src_ip      = src_ip_reg;
        to_udp_meta_info.dst_ip      = dst_ip_reg;
        to_udp_meta_info.src_port    = src_port_reg;
        to_udp_meta_info.dst_port    = dst_port_reg;
        to_udp_meta_info.data_length = payload_len_reg;
    end

    assign to_udp_data = payload_reg;

    always_comb begin
        state_next       = state_reg;
        src_ip_next      = src_ip_reg;
        dst_ip_next      = dst_ip_reg;
        src_port_next    = src_port_reg;
        dst_port_next    = dst_port_reg;
        payload_len_next = payload_len_reg;
        payload_next     = payload_reg;

        to_udp_meta_val  = 1'b0;
        to_udp_data_val  = 1'b0;
        sender_done      = 1'b0;

        case (state_reg)
            IDLE: begin
                if (trigger) begin
                    src_ip_next      = in_src_ip;
                    dst_ip_next      = in_dst_ip;
                    src_port_next    = in_src_port;
                    dst_port_next    = in_dst_port;
                    payload_len_next = in_payload_len;
                    payload_next     = in_payload;
                    state_next       = SEND_META;
                end
            end
            SEND_META: begin
                to_udp_meta_val = 1'b1;
                if (to_udp_meta_rdy) state_next = SEND_DATA;
            end
            SEND_DATA: begin
                to_udp_data_val = 1'b1;
                if (to_udp_data_rdy) begin
                    sender_done = 1'b1;
                    state_next  = IDLE;
                end
            end
            default: state_next = UND;
        endcase
    end
endmodule
