`include "ip_rx_tile_defs.svh"

// Mirror of ip_tx_dhcp_listener but for ip_rx_tile. Sits between the
// tracker output and ip_rx_noc_in. Snoops incoming NoC msg headers:
// DHCP_IP_BIND / DHCP_IP_EXPIRE messages are consumed locally (2 flits
// each: hdr + data) and update the bound-IP cache. Every other msg
// (notably IP_RX_DATAGRAM from eth_rx_tile) passes straight through.
//
// Pass-through forwards the header, then forwards the next msg_len
// flits (covers IP_RX_DATAGRAM = 1 meta + N data, msg_len = 1 + N).
module ip_rx_dhcp_listener (
    input  logic clk,
    input  logic rst,

    // Upstream: from the tracker.
    input  logic                       src_val,
    input  logic [`NOC_DATA_WIDTH-1:0] src_data,
    output logic                       src_rdy,

    // Downstream: into ip_rx_noc_in.
    output logic                       dst_val,
    output logic [`NOC_DATA_WIDTH-1:0] dst_data,
    input  logic                       dst_rdy,

    // Cached lease state, exported for the dst filter / observation.
    output logic [`IP_ADDR_W-1:0]      dhcp_bound_ip,
    output logic                       dhcp_bound_valid
);
    typedef enum logic [1:0] {
        IDLE        = 2'd0,
        FWD_REST    = 2'd1,
        CAPTURE_DAT = 2'd2,
        UND         = 'X
    } state_e;

    state_e state_reg, state_next;

    logic [`MSG_LENGTH_WIDTH-1:0] remaining_reg, remaining_next;
    logic                         latching_expire_reg, latching_expire_next;
    logic [`IP_ADDR_W-1:0]        bound_ip_reg, bound_ip_next;
    logic                         bound_valid_reg, bound_valid_next;

    assign dhcp_bound_ip    = bound_ip_reg;
    assign dhcp_bound_valid = bound_valid_reg;

    beehive_noc_hdr_flit hdr_cast;
    assign hdr_cast = src_data;

    logic is_bind_hdr, is_expire_hdr, is_dhcp_hdr;
    assign is_bind_hdr   = (hdr_cast.core.core.msg_type == DHCP_IP_BIND);
    assign is_expire_hdr = (hdr_cast.core.core.msg_type == DHCP_IP_EXPIRE);
    assign is_dhcp_hdr   = is_bind_hdr || is_expire_hdr;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg           <= IDLE;
            remaining_reg       <= '0;
            latching_expire_reg <= 1'b0;
            bound_ip_reg        <= '0;
            bound_valid_reg     <= 1'b0;
        end else begin
            state_reg           <= state_next;
            remaining_reg       <= remaining_next;
            latching_expire_reg <= latching_expire_next;
            bound_ip_reg        <= bound_ip_next;
            bound_valid_reg     <= bound_valid_next;
        end
    end

    always_comb begin
        state_next           = state_reg;
        remaining_next       = remaining_reg;
        latching_expire_next = latching_expire_reg;
        bound_ip_next        = bound_ip_reg;
        bound_valid_next     = bound_valid_reg;

        src_rdy  = 1'b0;
        dst_val  = 1'b0;
        dst_data = src_data;

        case (state_reg)
            IDLE: begin
                if (src_val) begin
                    if (is_dhcp_hdr) begin
                        // Swallow the header without telling noc_in.
                        src_rdy              = 1'b1;
                        latching_expire_next = is_expire_hdr;
                        state_next           = CAPTURE_DAT;
                    end else begin
                        // Forward header; queue up the remaining flits.
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
            CAPTURE_DAT: begin
                src_rdy = 1'b1;
                if (src_val) begin
                    if (latching_expire_reg) begin
                        bound_valid_next = 1'b0;
                        bound_ip_next    = '0;
                    end else begin
                        bound_valid_next = 1'b1;
                        bound_ip_next    = src_data[`NOC_DATA_WIDTH-1 -: `IP_ADDR_W];
                    end
                    state_next = IDLE;
                end
            end
            default: begin
                state_next = UND;
            end
        endcase
    end
endmodule
