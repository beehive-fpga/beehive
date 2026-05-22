`include "dhcp_tile_defs.svh"

// Tile-level control: drains the RX UDP stream so the parser can observe
// inbound replies, and runs the DHCP lease FSM.
//
// Step 8a scope: cooperative-server DORA + auto-retransmit + NAK/xid
// filtering + push-on-bind, plus the BOUND -> RENEWING -> BOUND lease
// renewal loop driven by T1 (lease_secs/2). REBINDING (step 8b) and
// EXPIRY (step 8c) land on top of the lease counter machinery added
// here.
module dhcp_tile_ctrl #(
    parameter int CLK_HZ        = 100_000_000,
    parameter int MAX_LEASE_SEC = 86_400
) (
    input  logic clk,
    input  logic rst,

    // RX (drained always so the parser observes everything).
    input  logic fr_udp_meta_val,
    output logic fr_udp_meta_rdy,
    input  logic fr_udp_data_val,
    input  logic fr_udp_data_last,
    output logic fr_udp_data_rdy,

    // Parser observations (registered, one-cycle parsed_val pulse).
    input  logic                          parser_parsed_val,
    input  logic                          parser_parsed_cookie_valid,
    input  logic [2:0]                    parser_parsed_msg_type_53,
    input  logic [`DHCP_XID_W-1:0]        parser_parsed_xid,
    input  logic [`IP_ADDR_W-1:0]         parser_parsed_yiaddr,
    input  logic [`IP_ADDR_W-1:0]         parser_parsed_siaddr,
    input  logic [DHCP_LEASE_SECS_W-1:0]  parser_parsed_lease_secs,

    // TX boundary toward dhcp_tx_ctrl + dhcp_tx_datap.
    input  logic                   tx_done,
    output logic                   tx_start,
    output dhcp_tx_msg_type_e      tx_msg_type,
    output logic [`DHCP_XID_W-1:0] current_xid,
    output logic [`IP_ADDR_W-1:0]  lease_yiaddr,
    output logic [`IP_ADDR_W-1:0]  lease_siaddr,

    // Notify boundary toward dhcp_notify_tx.
    output logic                          notify_start,
    output logic [`MSG_TYPE_WIDTH-1:0]    notify_msg_type,
    input  logic                          notify_done,

    // Cocotb peek for tests.
    output dhcp_client_state_e     lease_state_dbg
);
    assign fr_udp_meta_rdy = 1'b1;
    assign fr_udp_data_rdy = 1'b1;

    typedef enum logic [2:0] {
        ST_INIT          = 3'd0,
        ST_INIT_WAIT_TX  = 3'd1,
        ST_SELECTING     = 3'd2,
        ST_REQ_WAIT_TX   = 3'd3,
        ST_REQUESTING    = 3'd4,
        ST_BOUND         = 3'd5,
        ST_RENEW_WAIT_TX = 3'd6,
        ST_RENEWING      = 3'd7
    } lease_internal_e;

    lease_internal_e state_reg, state_next;

    logic [`IP_ADDR_W-1:0]        yiaddr_reg, yiaddr_next;
    logic [`IP_ADDR_W-1:0]        siaddr_reg, siaddr_next;
    logic [DHCP_LEASE_SECS_W-1:0] lease_secs_reg, lease_secs_next;

    // XID is held across the whole lease cycle (DISCOVER + REQUEST share
    // it). Re-rolled on NAK -> INIT via a 32-bit Fibonacci LFSR step
    // (taps at 31, 21, 1, 0). Seed kept as 0xDEAD_BEEF so existing tests
    // -- which assert the first DISCOVER carries that xid -- still pass.
    localparam logic [`DHCP_XID_W-1:0] XID_SEED = 32'hDEAD_BEEF;
    logic [`DHCP_XID_W-1:0] xid_reg, xid_next;
    logic                   xid_step;

    assign current_xid  = xid_reg;
    assign lease_yiaddr = yiaddr_reg;
    assign lease_siaddr = siaddr_reg;

    always_comb begin
        if (xid_step) begin
            xid_next = {xid_reg[30:0],
                        xid_reg[31] ^ xid_reg[21] ^ xid_reg[1] ^ xid_reg[0]};
        end else begin
            xid_next = xid_reg;
        end
    end

    // -- Retransmit timer ----------------------------------------------------
    // Counts only while the FSM is waiting for an OFFER (SELECTING), an
    // ACK after the initial REQUEST (REQUESTING), or an ACK after a
    // REQUEST_RENEW (RENEWING). Threshold is `DHCP_RETRANSMIT_SEC`
    // seconds at the configured CLK_HZ.
    localparam int RETRANSMIT_CYCLES = CLK_HZ * DHCP_RETRANSMIT_SEC;
    localparam int CYC_W = (RETRANSMIT_CYCLES <= 1) ? 1 : $clog2(RETRANSMIT_CYCLES);

    logic [CYC_W-1:0] timeout_cnt_reg, timeout_cnt_next;
    logic timer_active;
    logic timer_expired;

    assign timer_active  = (state_reg == ST_SELECTING)
                        || (state_reg == ST_REQUESTING)
                        || (state_reg == ST_RENEWING);
    assign timer_expired = timer_active &&
                           (timeout_cnt_reg == CYC_W'(RETRANSMIT_CYCLES - 1));

    always_comb begin
        if (!timer_active || timer_expired) begin
            timeout_cnt_next = '0;
        end else begin
            timeout_cnt_next = timeout_cnt_reg + 1'b1;
        end
    end
    // ------------------------------------------------------------------------

    // -- Lease counter (T1 / T2 / EXPIRY) ------------------------------------
    // Counts continuously across BOUND -> RENEWING (-> REBINDING in 8b).
    // Resets on every fresh lease (REQUESTING -> BOUND, RENEWING -> BOUND).
    // T1 = lease_secs * CLK_HZ / 2.
    localparam longint MAX_LEASE_CYCLES_LL = longint'(MAX_LEASE_SEC) * longint'(CLK_HZ);
    localparam int LEASE_CNT_W = $clog2(MAX_LEASE_CYCLES_LL + 1);

    logic [LEASE_CNT_W-1:0] lease_cnt_reg, lease_cnt_next;
    logic lease_cnt_active;
    logic lease_cnt_reset;

    // 64-bit intermediate so the multiplication never narrows for any
    // sane (lease_secs, CLK_HZ) pair. Then truncate to the counter width.
    logic [63:0] lease_cycles_full;
    assign lease_cycles_full = {32'd0, lease_secs_reg} * 64'(CLK_HZ);

    logic [LEASE_CNT_W-1:0] t1_threshold;
    assign t1_threshold = lease_cycles_full[LEASE_CNT_W:1];  // = full / 2

    logic t1_expired;
    assign t1_expired = (state_reg == ST_BOUND) && (lease_cnt_reg >= t1_threshold);

    assign lease_cnt_active = (state_reg == ST_BOUND)
                           || (state_reg == ST_RENEW_WAIT_TX)
                           || (state_reg == ST_RENEWING);

    always_comb begin
        if (lease_cnt_reset)       lease_cnt_next = '0;
        else if (lease_cnt_active) lease_cnt_next = lease_cnt_reg + 1'b1;
        else                       lease_cnt_next = lease_cnt_reg;
    end
    // ------------------------------------------------------------------------

    // Map internal sub-states onto the public lease enum cocotb peeks.
    always_comb begin
        case (state_reg)
            ST_INIT, ST_INIT_WAIT_TX:           lease_state_dbg = INIT;
            ST_SELECTING:                       lease_state_dbg = SELECTING;
            ST_REQ_WAIT_TX, ST_REQUESTING:      lease_state_dbg = REQUESTING;
            ST_BOUND:                           lease_state_dbg = BOUND;
            ST_RENEW_WAIT_TX, ST_RENEWING:      lease_state_dbg = RENEWING;
            default:                            lease_state_dbg = INIT;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg       <= ST_INIT;
            yiaddr_reg      <= '0;
            siaddr_reg      <= '0;
            lease_secs_reg  <= '0;
            timeout_cnt_reg <= '0;
            lease_cnt_reg   <= '0;
            xid_reg         <= XID_SEED;
        end else begin
            state_reg       <= state_next;
            yiaddr_reg      <= yiaddr_next;
            siaddr_reg      <= siaddr_next;
            lease_secs_reg  <= lease_secs_next;
            timeout_cnt_reg <= timeout_cnt_next;
            lease_cnt_reg   <= lease_cnt_next;
            xid_reg         <= xid_next;
        end
    end

    // True only when the parser just registered a valid DHCP reply whose
    // xid matches the one we sent. Cookie check guards against random
    // UDP/68 traffic; xid check guards against stale replies for a
    // previous lease cycle.
    logic parsed_match;
    assign parsed_match = parser_parsed_val
                       && parser_parsed_cookie_valid
                       && (parser_parsed_xid == xid_reg);

    always_comb begin
        state_next      = state_reg;
        yiaddr_next     = yiaddr_reg;
        siaddr_next     = siaddr_reg;
        lease_secs_next = lease_secs_reg;
        tx_start        = 1'b0;
        tx_msg_type     = DISCOVER;
        xid_step        = 1'b0;
        notify_start    = 1'b0;
        notify_msg_type = DHCP_IP_BIND;
        lease_cnt_reset = 1'b0;

        case (state_reg)
            ST_INIT: begin
                tx_start    = 1'b1;
                tx_msg_type = DISCOVER;
                state_next  = ST_INIT_WAIT_TX;
            end
            ST_INIT_WAIT_TX: begin
                if (tx_done) state_next = ST_SELECTING;
            end
            ST_SELECTING: begin
                if (parsed_match
                    && parser_parsed_msg_type_53 == 3'd2 /* OFFER */) begin
                    yiaddr_next = parser_parsed_yiaddr;
                    siaddr_next = parser_parsed_siaddr;
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_INIT;
                    state_next  = ST_REQ_WAIT_TX;
                end else if (timer_expired) begin
                    tx_start    = 1'b1;
                    tx_msg_type = DISCOVER;
                    state_next  = ST_INIT_WAIT_TX;
                end
            end
            ST_REQ_WAIT_TX: begin
                if (tx_done) state_next = ST_REQUESTING;
            end
            ST_REQUESTING: begin
                if (parsed_match
                    && parser_parsed_msg_type_53 == 3'd5 /* ACK */) begin
                    // Capture the authoritative lease info from the ACK.
                    yiaddr_next     = parser_parsed_yiaddr;
                    siaddr_next     = parser_parsed_siaddr;
                    lease_secs_next = parser_parsed_lease_secs;
                    notify_start    = 1'b1;
                    notify_msg_type = DHCP_IP_BIND;
                    lease_cnt_reset = 1'b1;
                    state_next      = ST_BOUND;
                end else if (parsed_match
                    && parser_parsed_msg_type_53 == 3'd6 /* NAK */) begin
                    xid_step   = 1'b1;
                    state_next = ST_INIT;
                end else if (timer_expired) begin
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_INIT;
                    state_next  = ST_REQ_WAIT_TX;
                end
            end
            ST_BOUND: begin
                if (t1_expired) begin
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_RENEW;
                    state_next  = ST_RENEW_WAIT_TX;
                end
            end
            ST_RENEW_WAIT_TX: begin
                if (tx_done) state_next = ST_RENEWING;
            end
            ST_RENEWING: begin
                if (parsed_match
                    && parser_parsed_msg_type_53 == 3'd5 /* ACK */) begin
                    yiaddr_next     = parser_parsed_yiaddr;
                    siaddr_next     = parser_parsed_siaddr;
                    lease_secs_next = parser_parsed_lease_secs;
                    notify_start    = 1'b1;
                    notify_msg_type = DHCP_IP_BIND;
                    lease_cnt_reset = 1'b1;
                    state_next      = ST_BOUND;
                end else if (timer_expired) begin
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_RENEW;
                    state_next  = ST_RENEW_WAIT_TX;
                end
                // Step 8b: T2 -> ST_REBINDING.
                // Step 8c: EXPIRY -> ST_INIT (+ DHCP_IP_EXPIRE).
            end
            default: begin
                state_next = ST_INIT;
            end
        endcase
    end
endmodule
