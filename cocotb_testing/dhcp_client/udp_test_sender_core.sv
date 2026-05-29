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

    // Query-mode trigger: emit a 1-flit DHCP_IP_QUERY directly on the
    // NoC TX, bypassing the to_udp UDP envelope. Used by cocotb to
    // pull-test the dhcp_tile QUERY response path.
    input  logic                          query_trigger,
    input  logic [`MSG_DST_X_WIDTH-1:0]   query_dst_x,
    input  logic [`MSG_DST_Y_WIDTH-1:0]   query_dst_y,
    input  logic [`MSG_DST_FBITS_WIDTH-1:0] query_dst_fbits,
    output logic                          query_sender_done,

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

    // to_udp's NoC TX goes into a mux below alongside the query-emit path.
    logic                  udp_path_val;
    logic [NOC_DATA_W-1:0] udp_path_data;
    logic                  udp_path_rdy;

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

        ,.to_udp_noc_vrtoc_val  (udp_path_val               )
        ,.to_udp_noc_vrtoc_data (udp_path_data              )
        ,.noc_vrtoc_to_udp_rdy  (udp_path_rdy               )

        ,.src_to_udp_dst_x      (UDP_TX_TILE_X[`XY_WIDTH-1:0]       )
        ,.src_to_udp_dst_y      (UDP_TX_TILE_Y[`XY_WIDTH-1:0]       )
        ,.src_to_udp_dst_fbits  (PKT_IF_FBITS[`NOC_FBITS_WIDTH-1:0] )
    );

    // Query-emit FSM: on query_trigger, drive one DHCP_IP_QUERY header
    // (msg_len=0, metadata_flits=0) at (query_dst_x, query_dst_y).
    typedef enum logic [0:0] {
        Q_IDLE      = 1'd0,
        Q_SEND_HDR  = 1'd1
    } q_state_e;

    q_state_e q_state_reg, q_state_next;

    logic [`MSG_DST_X_WIDTH-1:0]     q_dst_x_reg, q_dst_x_next;
    logic [`MSG_DST_Y_WIDTH-1:0]     q_dst_y_reg, q_dst_y_next;
    logic [`MSG_DST_FBITS_WIDTH-1:0] q_dst_fbits_reg, q_dst_fbits_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            q_state_reg     <= Q_IDLE;
            q_dst_x_reg     <= '0;
            q_dst_y_reg     <= '0;
            q_dst_fbits_reg <= '0;
        end else begin
            q_state_reg     <= q_state_next;
            q_dst_x_reg     <= q_dst_x_next;
            q_dst_y_reg     <= q_dst_y_next;
            q_dst_fbits_reg <= q_dst_fbits_next;
        end
    end

    beehive_noc_hdr_flit query_hdr;
    always_comb begin
        query_hdr                       = '0;
        query_hdr.core.core.dst_chip_id = '0;
        query_hdr.core.core.dst_x_coord = q_dst_x_reg;
        query_hdr.core.core.dst_y_coord = q_dst_y_reg;
        query_hdr.core.core.dst_fbits   = q_dst_fbits_reg;
        query_hdr.core.core.msg_len     = '0;
        query_hdr.core.core.msg_type    = DHCP_IP_QUERY;
        query_hdr.core.core.src_chip_id = '0;
        query_hdr.core.core.src_x_coord = SRC_X[`MSG_DST_X_WIDTH-1:0];
        query_hdr.core.core.src_y_coord = SRC_Y[`MSG_DST_Y_WIDTH-1:0];
        query_hdr.core.core.src_fbits   = SRC_FBITS;
        query_hdr.core.metadata_flits   = '0;
    end

    // Query path NoC output (single-flit emit).
    logic                  q_path_val;
    logic [NOC_DATA_W-1:0] q_path_data;
    logic                  q_path_rdy;

    always_comb begin
        q_state_next     = q_state_reg;
        q_dst_x_next     = q_dst_x_reg;
        q_dst_y_next     = q_dst_y_reg;
        q_dst_fbits_next = q_dst_fbits_reg;
        q_path_val       = 1'b0;
        q_path_data      = query_hdr;
        query_sender_done = 1'b0;

        case (q_state_reg)
            Q_IDLE: begin
                if (query_trigger) begin
                    q_dst_x_next     = query_dst_x;
                    q_dst_y_next     = query_dst_y;
                    q_dst_fbits_next = query_dst_fbits;
                    q_state_next     = Q_SEND_HDR;
                end
            end
            Q_SEND_HDR: begin
                q_path_val = 1'b1;
                if (q_path_rdy) begin
                    query_sender_done = 1'b1;
                    q_state_next      = Q_IDLE;
                end
            end
        endcase
    end

    // Priority mux: query-emit wins when active (query is rare; UDP path
    // is the steady-state user). Mirrors dhcp_tile's notify-vs-to_udp mux.
    always_comb begin
        if (q_path_val) begin
            noc_out_val  = 1'b1;
            noc_out_data = q_path_data;
            q_path_rdy   = noc_out_rdy;
            udp_path_rdy = 1'b0;
        end else begin
            noc_out_val  = udp_path_val;
            noc_out_data = udp_path_data;
            udp_path_rdy = noc_out_rdy;
            q_path_rdy   = 1'b0;
        end
    end

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
