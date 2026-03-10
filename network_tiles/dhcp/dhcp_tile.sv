`include "dhcp_tile_defs.svh"

module dhcp_tile #(
    parameter SRC_X = -1,
    parameter SRC_Y = -1,
    parameter SRC_FBITS = PKT_IF_FBITS,
    parameter NOC_DATA_W = `NOC_DATA_WIDTH
) (
    input logic clk,
    input logic rst,
    input logic noc_dhcp_rx_val,
    input logic [NOC_DATA_W-1:0] noc_dhcp_rx_data,
    output logic dhcp_rx_noc_rdy,
    output logic noc_dhcp_tx_val,
    output logic [NOC_DATA_W-1:0] noc_dhcp_tx_data,
    input logic noc_dhcp_tx_rdy
);
    // UDP packet extracted from incoming NoC flits.
    logic fr_udp_meta_val;
    udp_info fr_udp_meta_info;
    logic fr_udp_meta_rdy;
    logic fr_udp_data_val;
    logic [NOC_DATA_W-1:0] fr_udp_data;
    logic fr_udp_data_last;
    logic [`NOC_DATA_BYTES_W-1:0] fr_udp_data_padbytes;
    logic fr_udp_data_rdy;

    // UDP packet stream driven into the outgoing NoC path.
    logic to_udp_meta_val;
    udp_info to_udp_meta_info;
    logic to_udp_meta_rdy;
    logic to_udp_data_val;
    logic [NOC_DATA_W-1:0] to_udp_data;
    logic to_udp_data_rdy;

    // Minimal step-1 behavior: only forward packets targeted to DHCP client port.
    typedef enum logic [1:0] {
        WAIT_META = 2'd0,
        FORWARD_DATA = 2'd1,
        DROP_DATA = 2'd2
    } bridge_state_e;

    bridge_state_e bridge_state_reg;
    bridge_state_e bridge_state_next;

    from_udp #(
        .NOC_DATA_W(NOC_DATA_W)
    ) from_udp_i (
        .clk(clk),
        .rst(rst),
        .noc_ctovr_fr_udp_val(noc_dhcp_rx_val),
        .noc_ctovr_fr_udp_data(noc_dhcp_rx_data),
        .fr_udp_noc_ctovr_rdy(dhcp_rx_noc_rdy),
        .fr_udp_dst_meta_val(fr_udp_meta_val),
        .fr_udp_dst_meta_info(fr_udp_meta_info),
        .dst_fr_udp_meta_rdy(fr_udp_meta_rdy),
        .fr_udp_dst_data_val(fr_udp_data_val),
        .fr_udp_dst_data(fr_udp_data),
        .fr_udp_dst_data_last(fr_udp_data_last),
        .fr_udp_dst_data_padbytes(fr_udp_data_padbytes),
        .dst_fr_udp_data_rdy(fr_udp_data_rdy)
    );

    to_udp #(
        .NOC_DATA_W(NOC_DATA_W),
        .SRC_X(SRC_X),
        .SRC_Y(SRC_Y),
        .SRC_FBITS(SRC_FBITS)
    ) to_udp_i (
        .clk(clk),
        .rst(rst),
        .src_to_udp_meta_val(to_udp_meta_val),
        .src_to_udp_meta_info(to_udp_meta_info),
        .to_udp_src_meta_rdy(to_udp_meta_rdy),
        .src_to_udp_data_val(to_udp_data_val),
        .src_to_udp_data(to_udp_data),
        .to_udp_src_data_rdy(to_udp_data_rdy),
        .to_udp_noc_vrtoc_val(noc_dhcp_tx_val),
        .to_udp_noc_vrtoc_data(noc_dhcp_tx_data),
        .noc_vrtoc_to_udp_rdy(noc_dhcp_tx_rdy),
        .src_to_udp_dst_x(UDP_TX_TILE_X[`XY_WIDTH-1:0]),
        .src_to_udp_dst_y(UDP_TX_TILE_Y[`XY_WIDTH-1:0]),
        .src_to_udp_dst_fbits(PKT_IF_FBITS[`NOC_FBITS_WIDTH-1:0])
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            bridge_state_reg <= WAIT_META;
        end else begin
            bridge_state_reg <= bridge_state_next;
        end
    end

    always_comb begin
        to_udp_meta_val = 1'b0;
        to_udp_meta_info = fr_udp_meta_info;
        to_udp_data_val = 1'b0;
        to_udp_data = fr_udp_data;

        fr_udp_meta_rdy = 1'b0;
        fr_udp_data_rdy = 1'b0;

        bridge_state_next = bridge_state_reg;

        case (bridge_state_reg)
            WAIT_META: begin
                if (fr_udp_meta_val) begin
                    if (fr_udp_meta_info.dst_port == DHCP_CLIENT_PORT) begin
                        to_udp_meta_val = 1'b1;
                        fr_udp_meta_rdy = to_udp_meta_rdy;
                        if (to_udp_meta_rdy) begin
                            bridge_state_next = FORWARD_DATA;
                        end
                    end else begin
                        // Consume and discard non-DHCP traffic.
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
