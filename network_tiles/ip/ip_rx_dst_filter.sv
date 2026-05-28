`include "ip_rx_tile_defs.svh"

// Sits between ip_stream_format_pipe (which parses the IP header and
// emits hdr + data streams) and ip_rx_noc_out_copy (which rewraps and
// forwards to L4 tiles). When FILTER_ENABLE=1 + dhcp_bound_valid AND
// the incoming packet's `dest_addr` is neither the bound IP nor the
// IPv4 broadcast (255.255.255.255), the entire burst is silently
// dropped: the header is consumed locally, every data flit is drained,
// and nothing reaches the downstream NoC out path.
//
// Drop decision is latched at the header handshake so a `bound_valid`
// or `bound_ip` change mid-burst can't corrupt the in-flight packet.
// FSM: IDLE -> FWD or DRAIN -> IDLE.
module ip_rx_dst_filter
    import tracker_pkg::*;
#(
    parameter int FILTER_ENABLE = 1
) (
    input  logic clk,
    input  logic rst,

    // From ip_stream_format_pipe
    input  logic                            src_hdr_val,
    input  ip_pkt_hdr                       src_ip_hdr,
    input  tracker_stats_struct             src_timestamp,
    output logic                            src_hdr_rdy,

    input  logic                            src_data_val,
    input  logic [`NOC_DATA_WIDTH-1:0]      src_data,
    input  logic                            src_last,
    input  logic [`NOC_PADBYTES_WIDTH-1:0]  src_padbytes,
    output logic                            src_data_rdy,

    // To ip_rx_noc_out_copy
    output logic                            dst_hdr_val,
    output ip_pkt_hdr                       dst_ip_hdr,
    output tracker_stats_struct             dst_timestamp,
    input  logic                            dst_hdr_rdy,

    output logic                            dst_data_val,
    output logic [`NOC_DATA_WIDTH-1:0]      dst_data,
    output logic                            dst_last,
    output logic [`NOC_PADBYTES_WIDTH-1:0]  dst_padbytes,
    input  logic                            dst_data_rdy,

    // Cached lease state from ip_rx_dhcp_listener.
    input  logic [`IP_ADDR_W-1:0]           dhcp_bound_ip,
    input  logic                            dhcp_bound_valid,

    // Observability hook for cocotb. Combinational, no behavior impact.
    output logic                            dbg_would_drop
);
    localparam logic [`IP_ADDR_W-1:0] BROADCAST_IP = {`IP_ADDR_W{1'b1}};

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        FWD   = 2'd1,
        DRAIN = 2'd2,
        UND   = 'X
    } state_e;

    state_e state_reg, state_next;

    always_ff @(posedge clk) begin
        if (rst) state_reg <= IDLE;
        else     state_reg <= state_next;
    end

    // Drop iff filter enabled + bound + dest is neither bound IP nor broadcast.
    logic would_drop;
    assign would_drop = (FILTER_ENABLE == 1)
                     && dhcp_bound_valid
                     && (src_ip_hdr.dest_addr != dhcp_bound_ip)
                     && (src_ip_hdr.dest_addr != BROADCAST_IP);

    assign dbg_would_drop = would_drop;

    always_comb begin
        // Defaults: payload mirrors, but val/rdy are gated by state.
        dst_hdr_val   = 1'b0;
        dst_ip_hdr    = src_ip_hdr;
        dst_timestamp = src_timestamp;
        src_hdr_rdy   = 1'b0;

        dst_data_val  = 1'b0;
        dst_data      = src_data;
        dst_last      = src_last;
        dst_padbytes  = src_padbytes;
        src_data_rdy  = 1'b0;

        state_next = state_reg;

        case (state_reg)
            IDLE: begin
                // Hold the data channel until we've decided on the hdr.
                if (src_hdr_val) begin
                    if (would_drop) begin
                        // Consume hdr locally.
                        src_hdr_rdy = 1'b1;
                        state_next  = DRAIN;
                    end else begin
                        // Forward hdr; transition to FWD on handshake.
                        dst_hdr_val = 1'b1;
                        src_hdr_rdy = dst_hdr_rdy;
                        if (dst_hdr_rdy) state_next = FWD;
                    end
                end
            end
            FWD: begin
                // Pass data flits through.
                dst_data_val = src_data_val;
                src_data_rdy = dst_data_rdy;
                if (src_data_val && dst_data_rdy && src_last) begin
                    state_next = IDLE;
                end
            end
            DRAIN: begin
                // Drain data flits; never raise dst_data_val.
                src_data_rdy = 1'b1;
                if (src_data_val && src_last) begin
                    state_next = IDLE;
                end
            end
            default: state_next = UND;
        endcase
    end
endmodule
