`include "dhcp_tile_defs.svh"

// Sits between dhcp_tile's raw NoC RX (noc_dhcp_rx_*) and the from_udp
// adapter. Snoops incoming headers: DHCP_IP_QUERY messages are consumed
// locally (1 flit, header only -- no metadata, no data) and the
// requester's NoC coords are pulsed out for one cycle on `query_*`.
// Everything else (notably UDP_RX_SEGMENT from udp_rx_tile) is forwarded
// to from_udp unchanged.
//
// Same shape as ip_tx_dhcp_listener but the demux'd traffic flows in
// the opposite direction (RX-side instead of TX-side).
module dhcp_query_rx (
    input  logic clk,
    input  logic rst,

    // Upstream: raw NoC RX from the credit converter.
    input  logic                       src_val,
    input  logic [`NOC_DATA_WIDTH-1:0] src_data,
    output logic                       src_rdy,

    // Downstream: into from_udp.
    output logic                       dst_val,
    output logic [`NOC_DATA_WIDTH-1:0] dst_data,
    input  logic                       dst_rdy,

    // Query notification to dhcp_tile_ctrl. One-cycle pulse on the
    // handshake cycle of a DHCP_IP_QUERY header.
    output logic                          query_received,
    output logic [`MSG_DST_X_WIDTH-1:0]   query_src_x,
    output logic [`MSG_DST_Y_WIDTH-1:0]   query_src_y
);
    typedef enum logic [1:0] {
        IDLE     = 2'd0,
        FWD_REST = 2'd1,
        UND      = 'X
    } state_e;

    state_e state_reg, state_next;

    logic [`MSG_LENGTH_WIDTH-1:0] remaining_reg, remaining_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg     <= IDLE;
            remaining_reg <= '0;
        end else begin
            state_reg     <= state_next;
            remaining_reg <= remaining_next;
        end
    end

    beehive_noc_hdr_flit hdr_cast;
    assign hdr_cast = src_data;

    logic is_query_hdr;
    assign is_query_hdr = (hdr_cast.core.core.msg_type == DHCP_IP_QUERY);

    always_comb begin
        state_next     = state_reg;
        remaining_next = remaining_reg;

        src_rdy = 1'b0;
        dst_val = 1'b0;
        dst_data = src_data;

        query_received = 1'b0;
        query_src_x    = hdr_cast.core.core.src_x_coord;
        query_src_y    = hdr_cast.core.core.src_y_coord;

        case (state_reg)
            IDLE: begin
                if (src_val) begin
                    if (is_query_hdr) begin
                        // Header-only msg (msg_len=0). Consume + signal.
                        src_rdy        = 1'b1;
                        query_received = 1'b1;
                        // Stay in IDLE for the next header.
                    end else begin
                        // Forward header; queue remaining msg_len flits.
                        dst_val = 1'b1;
                        src_rdy = dst_rdy;
                        if (dst_rdy) begin
                            remaining_next = hdr_cast.core.core.msg_len;
                            if (hdr_cast.core.core.msg_len != '0) begin
                                state_next = FWD_REST;
                            end
                        end
                    end
                end
            end
            FWD_REST: begin
                dst_val = src_val;
                src_rdy = dst_rdy;
                if (src_val && dst_rdy) begin
                    if (remaining_reg == `MSG_LENGTH_WIDTH'd1) begin
                        state_next = IDLE;
                    end else begin
                        remaining_next = remaining_reg - 1'b1;
                    end
                end
            end
            default: state_next = UND;
        endcase
    end
endmodule
