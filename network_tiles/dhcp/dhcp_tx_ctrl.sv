`include "dhcp_tile_defs.svh"

// DHCP TX framing FSM. Triggered by a one-cycle `tx_start` from the lease
// FSM (in dhcp_tile_ctrl) with the message type to send. Latches msg_type
// at the IDLE -> SEND_META edge so the datapath sees a stable selector
// across the whole burst, then walks through SEND_META + N data flits and
// pulses `tx_done` for one cycle as the last data flit handshakes.
module dhcp_tx_ctrl (
    input  logic clk,
    input  logic rst,

    input  logic              tx_start,
    input  dhcp_tx_msg_type_e tx_msg_type,
    output dhcp_tx_msg_type_e tx_msg_type_reg,

    output logic       to_udp_meta_val,
    input  logic       to_udp_meta_rdy,
    output logic       to_udp_data_val,
    input  logic       to_udp_data_rdy,

    output logic [2:0] curr_flit_index,
    output logic       tx_done
);
    typedef enum logic [1:0] {
        IDLE      = 2'd0,
        SEND_META = 2'd1,
        SEND_DATA = 2'd2,
        UND       = 'X
    } tx_state_e;

    tx_state_e state_reg, state_next;
    logic [2:0] flit_idx_reg, flit_idx_next;
    dhcp_tx_msg_type_e msg_type_reg, msg_type_next;
    logic [2:0] num_data_flits;

    assign tx_msg_type_reg = msg_type_reg;

    // DISCOVER = REQUEST_RENEW = 253 B = 4 flits (no opt 50/54 in either).
    // REQUEST_INIT = 265 B = 5 flits (carries opt 50 + opt 54).
    always_comb begin
        case (msg_type_reg)
            DISCOVER:      num_data_flits = 3'd4;
            REQUEST_INIT:  num_data_flits = 3'd5;
            REQUEST_RENEW: num_data_flits = 3'd4;
            default:       num_data_flits = 3'd4;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg    <= IDLE;
            flit_idx_reg <= '0;
            msg_type_reg <= DISCOVER;
        end else begin
            state_reg    <= state_next;
            flit_idx_reg <= flit_idx_next;
            msg_type_reg <= msg_type_next;
        end
    end

    always_comb begin
        state_next      = state_reg;
        flit_idx_next   = flit_idx_reg;
        msg_type_next   = msg_type_reg;
        to_udp_meta_val = 1'b0;
        to_udp_data_val = 1'b0;
        curr_flit_index = flit_idx_reg;
        tx_done         = 1'b0;

        case (state_reg)
            IDLE: begin
                if (tx_start) begin
                    msg_type_next = tx_msg_type;
                    flit_idx_next = '0;
                    state_next    = SEND_META;
                end
            end
            SEND_META: begin
                to_udp_meta_val = 1'b1;
                if (to_udp_meta_rdy) begin
                    state_next    = SEND_DATA;
                    flit_idx_next = '0;
                end
            end
            SEND_DATA: begin
                to_udp_data_val = 1'b1;
                if (to_udp_data_rdy) begin
                    if (flit_idx_reg + 1'b1 == num_data_flits) begin
                        tx_done    = 1'b1;
                        state_next = IDLE;
                    end else begin
                        flit_idx_next = flit_idx_reg + 1'b1;
                    end
                end
            end
            default: begin
                state_next = UND;
            end
        endcase
    end
endmodule
