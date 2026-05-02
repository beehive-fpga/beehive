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

    // ctrl <-> datap boundary
    logic datap_ctrl_dst_port_is_client;

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

    // Client tile: replies always egress through udp_tx, so destination is fixed.
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

    dhcp_tile_ctrl ctrl (
        .clk(clk),
        .rst(rst),

        .fr_udp_meta_val(fr_udp_meta_val),
        .fr_udp_meta_rdy(fr_udp_meta_rdy),
        .fr_udp_data_val(fr_udp_data_val),
        .fr_udp_data_last(fr_udp_data_last),
        .fr_udp_data_rdy(fr_udp_data_rdy),

        .to_udp_meta_val(to_udp_meta_val),
        .to_udp_meta_rdy(to_udp_meta_rdy),
        .to_udp_data_val(to_udp_data_val),
        .to_udp_data_rdy(to_udp_data_rdy),

        .datap_ctrl_dst_port_is_client(datap_ctrl_dst_port_is_client)
    );

    dhcp_tile_datap #(
        .NOC_DATA_W(NOC_DATA_W)
    ) datap (
        .fr_udp_meta_info(fr_udp_meta_info),
        .fr_udp_data(fr_udp_data),

        .to_udp_meta_info(to_udp_meta_info),
        .to_udp_data(to_udp_data),

        .datap_ctrl_dst_port_is_client(datap_ctrl_dst_port_is_client)
    );

    // Observe-only DHCP parser. Outputs are unused; visible via deep
    // hierarchy so cocotb can verify field extraction before the lease
    // FSM consumes them.
    logic                          parser_parsed_val;
    logic [`DHCP_OP_W-1:0]         parser_parsed_op;
    logic [`DHCP_XID_W-1:0]        parser_parsed_xid;
    logic [`IP_ADDR_W-1:0]         parser_parsed_yiaddr;
    logic [`IP_ADDR_W-1:0]         parser_parsed_siaddr;
    logic                          parser_parsed_cookie_valid;
    logic [2:0]                    parser_parsed_msg_type_53;
    logic [DHCP_LEASE_SECS_W-1:0]  parser_parsed_lease_secs;
    logic [`IP_ADDR_W-1:0]         parser_parsed_srv_id;

    dhcp_parser #(
        .NOC_DATA_W(NOC_DATA_W)
    ) parser (
        .clk(clk),
        .rst(rst),
        .data_flit_val(fr_udp_data_val & fr_udp_data_rdy),
        .data_flit_data(fr_udp_data),
        .data_flit_last(fr_udp_data_last),

        .parsed_val(parser_parsed_val),
        .parsed_op(parser_parsed_op),
        .parsed_xid(parser_parsed_xid),
        .parsed_yiaddr(parser_parsed_yiaddr),
        .parsed_siaddr(parser_parsed_siaddr),
        .parsed_cookie_valid(parser_parsed_cookie_valid),
        .parsed_msg_type_53(parser_parsed_msg_type_53),
        .parsed_lease_secs(parser_parsed_lease_secs),
        .parsed_srv_id(parser_parsed_srv_id)
    );
endmodule
