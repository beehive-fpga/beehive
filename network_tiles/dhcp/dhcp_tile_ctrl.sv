`include "dhcp_tile_defs.svh"

// Tile-level control: drains the RX UDP stream so the parser can observe
// inbound replies, and runs the DHCP lease FSM.
//
// Step 6a scope: cooperative-server DORA happy path. INIT -> SELECTING ->
// REQUESTING -> BOUND with no timer and no NAK / wrong-xid handling. The
// internal `*_WAIT_TX` micro-states park while a previously-strobed
// `tx_start` walks through dhcp_tx_ctrl, so `tx_start` stays a clean
// one-cycle pulse.
module dhcp_tile_ctrl (
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

    // TX boundary toward dhcp_tx_ctrl + dhcp_tx_datap.
    input  logic                   tx_done,
    output logic                   tx_start,
    output dhcp_tx_msg_type_e      tx_msg_type,
    output logic [`DHCP_XID_W-1:0] current_xid,
    output logic [`IP_ADDR_W-1:0]  lease_yiaddr,
    output logic [`IP_ADDR_W-1:0]  lease_siaddr,

    // Cocotb peek for tests.
    output dhcp_client_state_e     lease_state_dbg
);
    assign fr_udp_meta_rdy = 1'b1;
    assign fr_udp_data_rdy = 1'b1;

    typedef enum logic [2:0] {
        ST_INIT         = 3'd0,
        ST_INIT_WAIT_TX = 3'd1,
        ST_SELECTING    = 3'd2,
        ST_REQ_WAIT_TX  = 3'd3,
        ST_REQUESTING   = 3'd4,
        ST_BOUND        = 3'd5
    } lease_internal_e;

    lease_internal_e state_reg, state_next;

    logic [`IP_ADDR_W-1:0] yiaddr_reg, yiaddr_next;
    logic [`IP_ADDR_W-1:0] siaddr_reg, siaddr_next;

    // Hardcoded XID for 6a; step 6c swaps to a re-rolling LFSR.
    localparam logic [`DHCP_XID_W-1:0] FIXED_XID = 32'hDEAD_BEEF;
    assign current_xid  = FIXED_XID;
    assign lease_yiaddr = yiaddr_reg;
    assign lease_siaddr = siaddr_reg;

    // Map internal sub-states onto the public lease enum cocotb peeks.
    always_comb begin
        case (state_reg)
            ST_INIT, ST_INIT_WAIT_TX:        lease_state_dbg = INIT;
            ST_SELECTING:                    lease_state_dbg = SELECTING;
            ST_REQ_WAIT_TX, ST_REQUESTING:   lease_state_dbg = REQUESTING;
            ST_BOUND:                        lease_state_dbg = BOUND;
            default:                         lease_state_dbg = INIT;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg  <= ST_INIT;
            yiaddr_reg <= '0;
            siaddr_reg <= '0;
        end else begin
            state_reg  <= state_next;
            yiaddr_reg <= yiaddr_next;
            siaddr_reg <= siaddr_next;
        end
    end

    always_comb begin
        state_next  = state_reg;
        yiaddr_next = yiaddr_reg;
        siaddr_next = siaddr_reg;
        tx_start    = 1'b0;
        tx_msg_type = DISCOVER;

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
                if (parser_parsed_val
                    && parser_parsed_cookie_valid
                    && parser_parsed_msg_type_53 == 3'd2 /* OFFER */) begin
                    yiaddr_next = parser_parsed_yiaddr;
                    siaddr_next = parser_parsed_siaddr;
                    tx_start    = 1'b1;
                    tx_msg_type = REQUEST_INIT;
                    state_next  = ST_REQ_WAIT_TX;
                end
            end
            ST_REQ_WAIT_TX: begin
                if (tx_done) state_next = ST_REQUESTING;
            end
            ST_REQUESTING: begin
                if (parser_parsed_val
                    && parser_parsed_cookie_valid
                    && parser_parsed_msg_type_53 == 3'd5 /* ACK */) begin
                    state_next = ST_BOUND;
                end
            end
            ST_BOUND: begin
                // Step 8 re-arms transitions on T1/T2.
            end
            default: begin
                state_next = ST_INIT;
            end
        endcase
    end
endmodule
