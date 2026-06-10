`include "dhcp_tile_defs.svh"

// Tile-level control: drains the RX UDP stream so the parser can observe
// inbound replies, and runs the DHCP lease FSM.
//
// Step 8c scope (full 6-state DHCP client): cooperative-server DORA +
// auto-retransmit + NAK/xid filtering + push-on-bind + the BOUND ->
// RENEWING -> BOUND lease renewal loop driven by T1 (lease_secs/2) +
// the RENEWING -> REBINDING -> BOUND broadcast-renew fallback driven
// by T2 (lease_secs * 7/8) + lease EXPIRY in REBINDING which pushes
// DHCP_IP_EXPIRE and restarts DORA with a fresh xid.
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

    // Notify boundary toward dhcp_notify_tx. `notify_yiaddr` is driven
    // combinationally from `yiaddr_next` so that the bind that fires on
    // an ACK cycle latches the just-parsed yiaddr, not the stale
    // `yiaddr_reg` (which only updates on the next posedge). Critical
    // when a REBIND ACK arrives from a different server with a new IP.
    output logic                          notify_start,
    output logic [`MSG_TYPE_WIDTH-1:0]    notify_msg_type,
    output logic [`IP_ADDR_W-1:0]         notify_yiaddr,
    input  logic                          notify_done,

    // Override dst inputs to dhcp_notify_tx, driven on query responses
    // so a single-subscriber burst targets the querier's coords.
    output logic                                  notify_override_en,
    output logic [`MSG_DST_X_WIDTH-1:0]           notify_override_x,
    output logic [`MSG_DST_Y_WIDTH-1:0]           notify_override_y,
    output logic [`MSG_DST_FBITS_WIDTH-1:0]       notify_override_fbits,

    // DHCP_IP_QUERY arrived on the NoC RX side. Pulses for one cycle
    // with the querier's coords; ctrl latches them and fires a single
    // bind/expire response when the notify FSM is free.
    input  logic                                  query_received,
    input  logic [`MSG_DST_X_WIDTH-1:0]           query_src_x,
    input  logic [`MSG_DST_Y_WIDTH-1:0]           query_src_y,

    // Cocotb peek for tests.
    output dhcp_client_state_e     lease_state_dbg
);
    assign fr_udp_meta_rdy = 1'b1;
    assign fr_udp_data_rdy = 1'b1;

    typedef enum logic [3:0] {
        ST_INIT           = 4'd0,
        ST_INIT_WAIT_TX   = 4'd1,
        ST_SELECTING      = 4'd2,
        ST_REQ_WAIT_TX    = 4'd3,
        ST_REQUESTING     = 4'd4,
        ST_BOUND          = 4'd5,
        ST_RENEW_WAIT_TX  = 4'd6,
        ST_RENEWING       = 4'd7,
        ST_REBIND_WAIT_TX = 4'd8,
        ST_REBINDING      = 4'd9
    } lease_internal_e;

    lease_internal_e state_reg, state_next;

    logic [`IP_ADDR_W-1:0]        yiaddr_reg, yiaddr_next;
    logic [`IP_ADDR_W-1:0]        siaddr_reg, siaddr_next;
    logic [DHCP_LEASE_SECS_W-1:0] lease_secs_reg, lease_secs_next;

    // Query-response bookkeeping. `query_pending_reg` is set on a
    // DHCP_IP_QUERY arrival and stays set until the response notify
    // burst is dispatched (notify_start && override_en in the same
    // cycle). `notify_inflight_reg` tracks notify_tx busy so the
    // response waits for any in-flight broadcast.
    logic                                query_pending_reg, query_pending_next;
    logic [`MSG_DST_X_WIDTH-1:0]         query_src_x_reg,   query_src_x_next;
    logic [`MSG_DST_Y_WIDTH-1:0]         query_src_y_reg,   query_src_y_next;
    logic                                notify_inflight_reg, notify_inflight_next;

    // XID is held across the whole lease cycle (DISCOVER + REQUEST share
    // it). Re-rolled on NAK -> INIT via a 32-bit Fibonacci LFSR step
    // (taps at 31, 21, 1, 0). Seed kept as 0xDEAD_BEEF so existing tests
    // -- which assert the first DISCOVER carries that xid -- still pass.
    localparam logic [`DHCP_XID_W-1:0] XID_SEED = 32'hDEAD_BEEF;
    logic [`DHCP_XID_W-1:0] xid_reg, xid_next;
    logic                   xid_step;

    assign current_xid   = xid_reg;
    assign lease_yiaddr  = yiaddr_reg;
    assign lease_siaddr  = siaddr_reg;
    assign notify_yiaddr = yiaddr_next;

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
                        || (state_reg == ST_RENEWING)
                        || (state_reg == ST_REBINDING);
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
    // Counts continuously across BOUND -> RENEWING -> REBINDING (and the
    // *_WAIT_TX transitions between them). Resets on every fresh lease
    // (REQUESTING -> BOUND, RENEWING -> BOUND, REBINDING -> BOUND).
    // T1 = lease_secs * CLK_HZ / 2.
    // T2 = lease_secs * CLK_HZ * 7 / 8.
    localparam longint MAX_LEASE_CYCLES_LL = longint'(MAX_LEASE_SEC) * longint'(CLK_HZ);
    localparam int LEASE_CNT_W = $clog2(MAX_LEASE_CYCLES_LL + 1);

    logic [LEASE_CNT_W-1:0] lease_cnt_reg, lease_cnt_next;
    logic lease_cnt_active;
    logic lease_cnt_reset;

    // 64-bit intermediate so the multiplication never narrows for any
    // sane (lease_secs, CLK_HZ) pair. Then truncate to the counter width.
    logic [63:0] lease_cycles_full;
    assign lease_cycles_full = {32'd0, lease_secs_reg} * 64'(CLK_HZ);

    // Clamp > MAX to the max trackable duration instead
    localparam logic [63:0] MAX_LEASE_CYCLES_64 = 64'(MAX_LEASE_CYCLES_LL);
    logic lease_overflow;
    assign lease_overflow = (lease_cycles_full > MAX_LEASE_CYCLES_64);

    logic [LEASE_CNT_W-1:0] lease_cycles_eff;
    assign lease_cycles_eff = lease_overflow ? MAX_LEASE_CYCLES_64[LEASE_CNT_W-1:0]
                                             : lease_cycles_full[LEASE_CNT_W-1:0];

    logic [LEASE_CNT_W-1:0] t1_threshold;
    logic [LEASE_CNT_W-1:0] t2_threshold;
    assign t1_threshold = lease_cycles_eff >> 1;                       // lease / 2
    assign t2_threshold = lease_cycles_eff - (lease_cycles_eff >> 3);  // lease * 7/8

    // a lease time of 0xFFFFFFFF is "infinite": holds BOUND indefinitely.
    logic infinite_lease;
    assign infinite_lease = (lease_secs_reg == '1);

    logic t1_expired;
    logic t2_expired;
    logic lease_expired;
    assign t1_expired    = !infinite_lease && (state_reg == ST_BOUND)     && (lease_cnt_reg >= t1_threshold);
    assign t2_expired    = !infinite_lease && (state_reg == ST_RENEWING)  && (lease_cnt_reg >= t2_threshold);
    assign lease_expired = !infinite_lease && (state_reg == ST_REBINDING) && (lease_cnt_reg >= lease_cycles_eff);

    assign lease_cnt_active = (state_reg == ST_BOUND)
                           || (state_reg == ST_RENEW_WAIT_TX)
                           || (state_reg == ST_RENEWING)
                           || (state_reg == ST_REBIND_WAIT_TX)
                           || (state_reg == ST_REBINDING);

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
            ST_REBIND_WAIT_TX, ST_REBINDING:    lease_state_dbg = REBINDING;
            default:                            lease_state_dbg = INIT;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg            <= ST_INIT;
            yiaddr_reg           <= '0;
            siaddr_reg           <= '0;
            lease_secs_reg       <= '0;
            timeout_cnt_reg      <= '0;
            lease_cnt_reg        <= '0;
            xid_reg              <= XID_SEED;
            query_pending_reg    <= 1'b0;
            query_src_x_reg      <= '0;
            query_src_y_reg      <= '0;
            notify_inflight_reg  <= 1'b0;
        end else begin
            state_reg            <= state_next;
            yiaddr_reg           <= yiaddr_next;
            siaddr_reg           <= siaddr_next;
            lease_secs_reg       <= lease_secs_next;
            timeout_cnt_reg      <= timeout_cnt_next;
            lease_cnt_reg        <= lease_cnt_next;
            xid_reg              <= xid_next;
            query_pending_reg    <= query_pending_next;
            query_src_x_reg      <= query_src_x_next;
            query_src_y_reg      <= query_src_y_next;
            notify_inflight_reg  <= notify_inflight_next;
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

    // Defaults for the override path -- the lease-event notifies below
    // always broadcast to SUB_0/SUB_1, so the override is only asserted
    // when the query-response arbiter fires (after the case).
    always_comb begin
        state_next            = state_reg;
        yiaddr_next           = yiaddr_reg;
        siaddr_next           = siaddr_reg;
        lease_secs_next       = lease_secs_reg;
        tx_start              = 1'b0;
        tx_msg_type           = DISCOVER;
        xid_step              = 1'b0;
        notify_start          = 1'b0;
        notify_msg_type       = DHCP_IP_BIND;
        lease_cnt_reset       = 1'b0;
        notify_override_en    = 1'b0;
        notify_override_x     = '0;
        notify_override_y     = '0;
        notify_override_fbits = PKT_IF_FBITS;

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
                end else if (t2_expired) begin
                    // T2: silence from siaddr long enough -- broadcast.
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_REBIND;
                    state_next  = ST_REBIND_WAIT_TX;
                end else if (timer_expired) begin
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_RENEW;
                    state_next  = ST_RENEW_WAIT_TX;
                end
                // Step 8c: EXPIRY -> ST_INIT (+ DHCP_IP_EXPIRE).
            end
            ST_REBIND_WAIT_TX: begin
                if (tx_done) state_next = ST_REBINDING;
            end
            ST_REBINDING: begin
                if (parsed_match
                    && parser_parsed_msg_type_53 == 3'd5 /* ACK */) begin
                    // Any cooperative server may answer the broadcast;
                    // re-capture the lease info it advertises.
                    yiaddr_next     = parser_parsed_yiaddr;
                    siaddr_next     = parser_parsed_siaddr;
                    lease_secs_next = parser_parsed_lease_secs;
                    notify_start    = 1'b1;
                    notify_msg_type = DHCP_IP_BIND;
                    lease_cnt_reset = 1'b1;
                    state_next      = ST_BOUND;
                end else if (lease_expired) begin
                    // Full lease elapsed: push DHCP_IP_EXPIRE (carrying
                    // the expiring yiaddr via notify_yiaddr = yiaddr_next
                    // = yiaddr_reg since we don't update it here), roll
                    // the xid, and restart DORA from ST_INIT.
                    notify_start    = 1'b1;
                    notify_msg_type = DHCP_IP_EXPIRE;
                    xid_step        = 1'b1;
                    lease_cnt_reset = 1'b1;
                    state_next      = ST_INIT;
                end else if (timer_expired) begin
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_REBIND;
                    state_next  = ST_REBIND_WAIT_TX;
                end
            end
            default: begin
                state_next = ST_INIT;
            end
        endcase

        // ---- Query response arbiter --------------------------------------
        // Latch incoming QUERY coords; service when notify is idle and no
        // lease-event notify fired this cycle. Sticky until serviced.
        query_pending_next   = query_pending_reg;
        query_src_x_next     = query_src_x_reg;
        query_src_y_next     = query_src_y_reg;
        notify_inflight_next = notify_inflight_reg;

        if (query_received) begin
            query_pending_next = 1'b1;
            query_src_x_next   = query_src_x;
            query_src_y_next   = query_src_y;
        end

        // notify_inflight tracks notify_tx state (set on start, clear on done).
        if (notify_start)     notify_inflight_next = 1'b1;
        else if (notify_done) notify_inflight_next = 1'b0;

        // If no lease-event notify is firing this cycle AND notify_tx is
        // idle, service the pending query (if any).
        if (query_pending_reg && !notify_start && !notify_inflight_reg) begin
            notify_start          = 1'b1;
            notify_msg_type       = (state_reg == ST_BOUND)
                                 || (state_reg == ST_RENEW_WAIT_TX)
                                 || (state_reg == ST_RENEWING)
                                 || (state_reg == ST_REBIND_WAIT_TX)
                                 || (state_reg == ST_REBINDING)
                                 ? DHCP_IP_BIND
                                 : DHCP_IP_EXPIRE;
            notify_override_en    = 1'b1;
            notify_override_x     = query_src_x_reg;
            notify_override_y     = query_src_y_reg;
            notify_override_fbits = PKT_IF_FBITS;
            query_pending_next    = 1'b0;
        end
    end
endmodule
