`include "ip_tx_tile_defs.svh"

// Sits between ip_tx_tile_noc_in's meta + data outputs and
// ip_hdr_assembler_pipe's meta + data inputs. Implements SRC_IP_POLICY
// for outgoing IP packets:
//
//   0  passthrough -- meta + data forwarded unchanged. No substitution.
//      (This module isn't instantiated when DHCP_BIND_LISTEN=0, so this
//      branch only fires for policy=0 with the listener on.)
//   1  substitute when bound; otherwise fall back to the operator's
//      udp_info.src_ip. The DHCP-aware mode for any tile that wants the
//      bound IP without caring about pre-bind. The "fallback" path
//      means src_ip flows through verbatim when unbound -- the sender
//      remains responsible for picking a sane src (0.0.0.0, a static
//      fallback IP, or its own gate on "should I send pre-bind").
//
// The substitute decision is latched at the meta-flit handshake so
// dhcp_bound_valid flipping mid-burst can't corrupt a burst that's
// already started forwarding.
module ip_tx_policy_mux
    import tracker_pkg::*;
#(
    parameter int SRC_IP_POLICY = 0
) (
    input  logic clk,
    input  logic rst,

    // From ip_tx_tile_noc_in
    input  logic                            src_meta_val,
    input  ip_tx_metadata_flit              src_meta_flit,
    input  tracker_stats_struct             src_meta_timestamp,
    output logic                            src_meta_rdy,

    input  logic                            src_data_val,
    input  logic [`MAC_INTERFACE_W-1:0]     src_data,
    input  logic                            src_data_last,
    input  logic [`MAC_PADBYTES_W-1:0]      src_data_padbytes,
    output logic                            src_data_rdy,

    // To ip_hdr_assembler_pipe
    output logic                            dst_meta_val,
    output ip_tx_metadata_flit              dst_meta_flit,
    output tracker_stats_struct             dst_meta_timestamp,
    input  logic                            dst_meta_rdy,

    output logic                            dst_data_val,
    output logic [`MAC_INTERFACE_W-1:0]     dst_data,
    output logic                            dst_data_last,
    output logic [`MAC_PADBYTES_W-1:0]      dst_data_padbytes,
    input  logic                            dst_data_rdy,

    // Cached DHCP lease state from ip_tx_dhcp_listener.
    input  logic [`IP_ADDR_W-1:0]           dhcp_bound_ip,
    input  logic                            dhcp_bound_valid,

    // Observability hooks for cocotb. Combinational, no behavior impact.
    output logic                            dbg_substitute_now,
    output logic [`IP_ADDR_W-1:0]           dbg_substituted_src_ip
);
    typedef enum logic [0:0] {
        IDLE    = 1'd0,
        FORWARD = 1'd1
    } state_e;

    state_e state_reg, state_next;

    always_ff @(posedge clk) begin
        if (rst) state_reg <= IDLE;
        else     state_reg <= state_next;
    end

    // Substitution logic: pull from cache when policy=1 AND bound.
    logic substitute_now;
    assign substitute_now = (SRC_IP_POLICY == 1) && dhcp_bound_valid;

    logic [`IP_ADDR_W-1:0] substituted_src_ip;
    assign substituted_src_ip = substitute_now
                              ? dhcp_bound_ip
                              : src_meta_flit.src_ip;

    assign dbg_substitute_now     = substitute_now;
    assign dbg_substituted_src_ip = substituted_src_ip;

    // Rebuild the meta_flit struct with the (possibly substituted) src.
    ip_tx_metadata_flit modified_meta;
    always_comb begin
        modified_meta        = src_meta_flit;
        modified_meta.src_ip = substituted_src_ip;
    end

    always_comb begin
        state_next         = state_reg;

        // Defaults: not forwarding.
        dst_meta_val       = 1'b0;
        dst_meta_flit      = modified_meta;
        dst_meta_timestamp = src_meta_timestamp;
        src_meta_rdy       = 1'b0;

        dst_data_val       = 1'b0;
        dst_data           = src_data;
        dst_data_last      = src_data_last;
        dst_data_padbytes  = src_data_padbytes;
        src_data_rdy       = 1'b0;

        case (state_reg)
            IDLE: begin
                // Drive src_meta_rdy unconditionally so upstream
                // ip_tx_tile_noc_in (which only asserts meta_val on a
                // cycle when meta_rdy is already high) can fire.
                src_meta_rdy = dst_meta_rdy;

                if (src_meta_val) begin
                    dst_meta_val = 1'b1;
                    if (dst_meta_rdy) state_next = FORWARD;
                end
            end
            FORWARD: begin
                dst_data_val = src_data_val;
                src_data_rdy = dst_data_rdy;
                if (src_data_val && dst_data_rdy && src_data_last) begin
                    state_next = IDLE;
                end
            end
            default: state_next = IDLE;
        endcase
    end
endmodule
