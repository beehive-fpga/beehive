`include "dhcp_tile_defs.svh"

// One-shot DHCP DISCOVER transmit FSM. Coming out of reset the tile sends
// exactly one DISCOVER (meta + 4 data flits) into to_udp and then idles in
// DONE forever. Step 6 will replace this with the lease FSM that retriggers
// on lease events.
module dhcp_tx_ctrl (
    input  logic clk,
    input  logic rst,

    output logic       to_udp_meta_val,
    input  logic       to_udp_meta_rdy,
    output logic       to_udp_data_val,
    input  logic       to_udp_data_rdy,

    output logic [1:0] curr_flit_index
);
    localparam logic [1:0] NUM_DATA_FLITS = 2'd3;  // index of the last flit (0..3)

    typedef enum logic [1:0] {
        SEND_META = 2'd0,
        SEND_DATA = 2'd1,
        DONE      = 2'd2,
        UND       = 'X
    } tx_state_e;

    tx_state_e state_reg, state_next;
    logic [1:0] flit_idx_reg, flit_idx_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg    <= SEND_META;
            flit_idx_reg <= '0;
        end else begin
            state_reg    <= state_next;
            flit_idx_reg <= flit_idx_next;
        end
    end

    always_comb begin
        state_next      = state_reg;
        flit_idx_next   = flit_idx_reg;
        to_udp_meta_val = 1'b0;
        to_udp_data_val = 1'b0;
        curr_flit_index = flit_idx_reg;

        case (state_reg)
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
                    if (flit_idx_reg == NUM_DATA_FLITS) begin
                        state_next = DONE;
                    end else begin
                        flit_idx_next = flit_idx_reg + 1'b1;
                    end
                end
            end
            DONE: begin
                // Latched: stay here until the lease FSM (step 6) drives more sends.
            end
            default: begin
                state_next = UND;
            end
        endcase
    end
endmodule
