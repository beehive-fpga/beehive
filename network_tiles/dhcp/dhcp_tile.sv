`include "dhcp_tile_defs.svh"

module dhcp_tile #(
    parameter SRC_X = -1,
    parameter SRC_Y = -1,
    parameter SRC_FBITS = PKT_IF_FBITS,
    parameter NOC_DATA_W = `NOC_DATA_WIDTH,
    parameter int CLK_HZ = 100_000_000,
    parameter int MAX_LEASE_SEC = 86_400,

    // Bind-notification subscriber list. Up to 2 subscribers; default 1
    // (IP RX tile). When NUM_SUBSCRIBERS==2 the dhcp_notify_tx FSM walks
    // both back-to-back per lease event. SUB_1_* is ignored at the
    // default count.
    parameter int                              NUM_SUBSCRIBERS = 1,
    parameter logic [`MSG_DST_X_WIDTH-1:0]     SUB_0_X     = IP_RX_TILE_X,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]     SUB_0_Y     = IP_RX_TILE_Y,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0] SUB_0_FBITS = PKT_IF_FBITS,
    parameter logic [`MSG_DST_X_WIDTH-1:0]     SUB_1_X     = '0,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]     SUB_1_Y     = '0,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0] SUB_1_FBITS = PKT_IF_FBITS
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
    // RX path: from_udp -> drained by dhcp_tile_ctrl, observed by parser.
    logic fr_udp_meta_val;
    udp_info fr_udp_meta_info;
    logic fr_udp_meta_rdy;
    logic fr_udp_data_val;
    logic [NOC_DATA_W-1:0] fr_udp_data;
    logic fr_udp_data_last;
    logic [`NOC_DATA_BYTES_W-1:0] fr_udp_data_padbytes;
    logic fr_udp_data_rdy;

    // TX boundary between lease FSM (in ctrl), tx_ctrl, and tx_datap.
    logic                   tx_start;
    dhcp_tx_msg_type_e      tx_msg_type;       // FSM -> tx_ctrl
    dhcp_tx_msg_type_e      tx_msg_type_reg;   // tx_ctrl -> tx_datap (latched)
    logic                   tx_done;
    logic [`DHCP_XID_W-1:0] current_xid;
    logic [`IP_ADDR_W-1:0]  lease_yiaddr;
    logic [`IP_ADDR_W-1:0]  lease_siaddr;
    logic [2:0]             tx_curr_flit_index;
    dhcp_client_state_e     lease_state_dbg;

    // Bind notify boundary.
    logic                          notify_start;
    logic [`MSG_TYPE_WIDTH-1:0]    notify_msg_type;
    logic [`IP_ADDR_W-1:0]         notify_yiaddr;
    logic                          notify_done;

    // Query-response override (single-burst dst override on notify_tx).
    logic                                  notify_override_en;
    logic [`MSG_DST_X_WIDTH-1:0]           notify_override_x;
    logic [`MSG_DST_Y_WIDTH-1:0]           notify_override_y;
    logic [`MSG_DST_FBITS_WIDTH-1:0]       notify_override_fbits;

    // dhcp_query_rx output: a DHCP_IP_QUERY landed; coords of requester.
    logic                                  query_received;
    logic [`MSG_DST_X_WIDTH-1:0]           query_src_x;
    logic [`MSG_DST_Y_WIDTH-1:0]           query_src_y;

    // dhcp_query_rx <-> from_udp wires (post-demux NoC RX into from_udp).
    logic                          fr_udp_rx_val;
    logic [NOC_DATA_W-1:0]         fr_udp_rx_data;
    logic                          fr_udp_rx_rdy;

    // UDP-side NoC TX (from to_udp) and notify-side NoC TX (from
    // dhcp_notify_tx) feed a priority mux below. After BOUND the lease
    // FSM keeps to_udp idle, so the mux's notify-priority choice cannot
    // truncate an in-flight UDP burst in step 7. Step 8 needs a real
    // arbiter once REQUEST_RENEW shares the path with binds.
    logic                  udp_noc_val;
    logic [NOC_DATA_W-1:0] udp_noc_data;
    logic                  udp_noc_rdy;

    logic                  notify_noc_val;
    logic [NOC_DATA_W-1:0] notify_noc_data;
    logic                  notify_noc_rdy;

    // udp side feeds to_udp_meta/data through to to_udp adapter.
    logic to_udp_meta_val;
    udp_info to_udp_meta_info;
    logic to_udp_meta_rdy;
    logic to_udp_data_val;
    logic [NOC_DATA_W-1:0] to_udp_data;
    logic to_udp_data_rdy;

    // RX demux: peel DHCP_IP_QUERY headers locally so from_udp only ever
    // sees UDP_RX_SEGMENT msgs (the format it knows how to parse).
    dhcp_query_rx query_rx (
        .clk(clk),
        .rst(rst),

        .src_val(noc_dhcp_rx_val),
        .src_data(noc_dhcp_rx_data),
        .src_rdy(dhcp_rx_noc_rdy),

        .dst_val(fr_udp_rx_val),
        .dst_data(fr_udp_rx_data),
        .dst_rdy(fr_udp_rx_rdy),

        .query_received(query_received),
        .query_src_x(query_src_x),
        .query_src_y(query_src_y)
    );

    from_udp #(
        .NOC_DATA_W(NOC_DATA_W)
    ) from_udp_i (
        .clk(clk),
        .rst(rst),
        .noc_ctovr_fr_udp_val(fr_udp_rx_val),
        .noc_ctovr_fr_udp_data(fr_udp_rx_data),
        .fr_udp_noc_ctovr_rdy(fr_udp_rx_rdy),
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
        .to_udp_noc_vrtoc_val(udp_noc_val),
        .to_udp_noc_vrtoc_data(udp_noc_data),
        .noc_vrtoc_to_udp_rdy(udp_noc_rdy),
        .src_to_udp_dst_x(UDP_TX_TILE_X[`XY_WIDTH-1:0]),
        .src_to_udp_dst_y(UDP_TX_TILE_Y[`XY_WIDTH-1:0]),
        .src_to_udp_dst_fbits(PKT_IF_FBITS[`NOC_FBITS_WIDTH-1:0])
    );

    // Observe-only DHCP parser. Outputs feed the lease FSM via ctrl below
    // and remain visible via deep hierarchy for parser-only tests.
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

    dhcp_tile_ctrl #(
        .CLK_HZ(CLK_HZ),
        .MAX_LEASE_SEC(MAX_LEASE_SEC)
    ) ctrl (
        .clk(clk),
        .rst(rst),

        .fr_udp_meta_val(fr_udp_meta_val),
        .fr_udp_meta_rdy(fr_udp_meta_rdy),
        .fr_udp_data_val(fr_udp_data_val),
        .fr_udp_data_last(fr_udp_data_last),
        .fr_udp_data_rdy(fr_udp_data_rdy),

        .parser_parsed_val(parser_parsed_val),
        .parser_parsed_cookie_valid(parser_parsed_cookie_valid),
        .parser_parsed_msg_type_53(parser_parsed_msg_type_53),
        .parser_parsed_xid(parser_parsed_xid),
        .parser_parsed_yiaddr(parser_parsed_yiaddr),
        .parser_parsed_siaddr(parser_parsed_siaddr),
        .parser_parsed_lease_secs(parser_parsed_lease_secs),

        .tx_done(tx_done),
        .tx_start(tx_start),
        .tx_msg_type(tx_msg_type),
        .current_xid(current_xid),
        .lease_yiaddr(lease_yiaddr),
        .lease_siaddr(lease_siaddr),

        .notify_start(notify_start),
        .notify_msg_type(notify_msg_type),
        .notify_yiaddr(notify_yiaddr),
        .notify_done(notify_done),

        .notify_override_en(notify_override_en),
        .notify_override_x(notify_override_x),
        .notify_override_y(notify_override_y),
        .notify_override_fbits(notify_override_fbits),

        .query_received(query_received),
        .query_src_x(query_src_x),
        .query_src_y(query_src_y),

        .lease_state_dbg(lease_state_dbg)
    );

    dhcp_tx_ctrl tx_ctrl (
        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_msg_type(tx_msg_type),
        .tx_msg_type_reg(tx_msg_type_reg),

        .to_udp_meta_val(to_udp_meta_val),
        .to_udp_meta_rdy(to_udp_meta_rdy),
        .to_udp_data_val(to_udp_data_val),
        .to_udp_data_rdy(to_udp_data_rdy),

        .curr_flit_index(tx_curr_flit_index),
        .tx_done(tx_done)
    );

    dhcp_tx_datap #(
        .NOC_DATA_W(NOC_DATA_W)
    ) tx_datap (
        .tx_msg_type(tx_msg_type_reg),
        .xid(current_xid),
        .lease_yiaddr(lease_yiaddr),
        .lease_siaddr(lease_siaddr),
        .curr_flit_index(tx_curr_flit_index),
        .to_udp_meta_info(to_udp_meta_info),
        .to_udp_data(to_udp_data)
    );

    dhcp_notify_tx #(
        .NOC_DATA_W(NOC_DATA_W),
        .NUM_SUBSCRIBERS(NUM_SUBSCRIBERS),
        .SRC_X(SRC_X[`MSG_DST_X_WIDTH-1:0]),
        .SRC_Y(SRC_Y[`MSG_DST_Y_WIDTH-1:0]),
        .SRC_FBITS(SRC_FBITS),
        .SUB_0_X(SUB_0_X),
        .SUB_0_Y(SUB_0_Y),
        .SUB_0_FBITS(SUB_0_FBITS),
        .SUB_1_X(SUB_1_X),
        .SUB_1_Y(SUB_1_Y),
        .SUB_1_FBITS(SUB_1_FBITS)
    ) notify (
        .clk(clk),
        .rst(rst),

        .notify_start(notify_start),
        .notify_msg_type(notify_msg_type),
        .notify_yiaddr(notify_yiaddr),

        .override_dst_en(notify_override_en),
        .override_dst_x(notify_override_x),
        .override_dst_y(notify_override_y),
        .override_dst_fbits(notify_override_fbits),

        .noc_val(notify_noc_val),
        .noc_data(notify_noc_data),
        .noc_rdy(notify_noc_rdy),

        .notify_done(notify_done)
    );

    // Priority mux: notify wins when active. Safe in step 7 because the
    // lease FSM keeps to_udp quiescent across BOUND -> notify -> BOUND.
    always_comb begin
        if (notify_noc_val) begin
            noc_dhcp_tx_val  = 1'b1;
            noc_dhcp_tx_data = notify_noc_data;
            notify_noc_rdy   = noc_dhcp_tx_rdy;
            udp_noc_rdy      = 1'b0;
        end else begin
            noc_dhcp_tx_val  = udp_noc_val;
            noc_dhcp_tx_data = udp_noc_data;
            udp_noc_rdy      = noc_dhcp_tx_rdy;
            notify_noc_rdy   = 1'b0;
        end
    end
endmodule
