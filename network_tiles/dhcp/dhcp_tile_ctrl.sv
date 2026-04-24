`include "dhcp_tile_defs.svh"

module dhcp_tile_ctrl (
    input  logic clk,
    input  logic rst,

    input  logic fr_udp_meta_val,
    output logic fr_udp_meta_rdy,
    input  logic fr_udp_data_val,
    input  logic fr_udp_data_last,
    output logic fr_udp_data_rdy,

    output logic to_udp_meta_val,
    input  logic to_udp_meta_rdy,
    output logic to_udp_data_val,
    input  logic to_udp_data_rdy,

    input  logic datap_ctrl_dst_port_is_client
);
    typedef enum logic [1:0] {
        WAIT_META    = 2'd0,
        FORWARD_DATA = 2'd1,
        DROP_DATA    = 2'd2
    } bridge_state_e;

    bridge_state_e bridge_state_reg;
    bridge_state_e bridge_state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            bridge_state_reg <= WAIT_META;
        end else begin
            bridge_state_reg <= bridge_state_next;
        end
    end

    always_comb begin
        to_udp_meta_val = 1'b0;
        to_udp_data_val = 1'b0;

        fr_udp_meta_rdy = 1'b0;
        fr_udp_data_rdy = 1'b0;

        bridge_state_next = bridge_state_reg;

        case (bridge_state_reg)
            WAIT_META: begin
                if (fr_udp_meta_val) begin
                    if (datap_ctrl_dst_port_is_client) begin
                        to_udp_meta_val = 1'b1;
                        fr_udp_meta_rdy = to_udp_meta_rdy;
                        if (to_udp_meta_rdy) begin
                            bridge_state_next = FORWARD_DATA;
                        end
                    end else begin
                        fr_udp_meta_rdy = 1'b1;
                        bridge_state_next = DROP_DATA;
                    end
                end
            end
            FORWARD_DATA: begin
                to_udp_data_val = fr_udp_data_val;
                fr_udp_data_rdy = to_udp_data_rdy;
                if (fr_udp_data_val && to_udp_data_rdy && fr_udp_data_last) begin
                    bridge_state_next = WAIT_META;
                end
            end
            DROP_DATA: begin
                fr_udp_data_rdy = 1'b1;
                if (fr_udp_data_val && fr_udp_data_last) begin
                    bridge_state_next = WAIT_META;
                end
            end
            default: begin
                bridge_state_next = WAIT_META;
            end
        endcase
    end
endmodule
