`include "dhcp_tile_defs.svh"

// Observe-only DHCP parser. Snapshots the first 4 data flits of each UDP
// payload (covers BOOTP fixed header bytes 0-191 + magic cookie / first
// options at bytes 192-255) and registers parsed fields on the cycle the
// final data flit fires.
module dhcp_parser #(
    parameter NOC_DATA_W = `NOC_DATA_WIDTH
) (
    input  logic clk,
    input  logic rst,

    input  logic                  data_flit_val,
    input  logic [NOC_DATA_W-1:0] data_flit_data,
    input  logic                  data_flit_last,

    output logic                          parsed_val,
    output logic [`DHCP_OP_W-1:0]         parsed_op,
    output logic [`DHCP_XID_W-1:0]        parsed_xid,
    output logic [`IP_ADDR_W-1:0]         parsed_yiaddr,
    output logic [`IP_ADDR_W-1:0]         parsed_siaddr,
    output logic                          parsed_cookie_valid,
    output logic [2:0]                    parsed_msg_type_53,
    output logic [DHCP_LEASE_SECS_W-1:0]  parsed_lease_secs,
    output logic [`IP_ADDR_W-1:0]         parsed_srv_id
);
    localparam int MAX_FLITS      = 4;
    localparam int CNT_W          = $clog2(MAX_FLITS + 1);
    localparam int NOC_DATA_BYTES = NOC_DATA_W / 8;

    // The NoC pipeline carries flits MSB-first (byte 0 of the UDP/DHCP
    // payload is in the most-significant byte). This parser indexes payload
    // byte O at bits [O*8 +: 8], so reorder once on input.
    logic [NOC_DATA_W-1:0] data_flit_data_le;
    integer j_swap;
    always_comb begin
        for (j_swap = 0; j_swap < NOC_DATA_BYTES; j_swap++) begin
            data_flit_data_le[j_swap*8 +: 8] =
                data_flit_data[((NOC_DATA_BYTES - 1 - j_swap) * 8) +: 8];
        end
    end

    logic [CNT_W-1:0] num_stored_reg;
    logic [CNT_W-1:0] num_stored_next;

    logic [NOC_DATA_W-1:0] flit_buf [0:MAX_FLITS-1];
    logic [NOC_DATA_W-1:0] flit_eff [0:MAX_FLITS-1];

    integer i_ff;
    always_ff @(posedge clk) begin
        if (rst) begin
            num_stored_reg <= '0;
            for (i_ff = 0; i_ff < MAX_FLITS; i_ff++) begin
                flit_buf[i_ff] <= '0;
            end
        end else begin
            num_stored_reg <= num_stored_next;
            if (data_flit_val && num_stored_reg < MAX_FLITS) begin
                flit_buf[num_stored_reg[CNT_W-2:0]] <= data_flit_data_le;
            end
        end
    end

    always_comb begin
        num_stored_next = num_stored_reg;
        if (data_flit_val) begin
            if (data_flit_last) begin
                num_stored_next = '0;
            end else if (num_stored_reg < MAX_FLITS) begin
                num_stored_next = num_stored_reg + 1'b1;
            end
        end
    end

    integer i_comb;
    always_comb begin
        for (i_comb = 0; i_comb < MAX_FLITS; i_comb++) begin
            flit_eff[i_comb] = flit_buf[i_comb];
        end
        if (data_flit_val && num_stored_reg < MAX_FLITS) begin
            flit_eff[num_stored_reg[CNT_W-2:0]] = data_flit_data_le;
        end
    end

    logic [`DHCP_OP_W-1:0]        op_next;
    logic [`DHCP_XID_W-1:0]       xid_next;
    logic [`IP_ADDR_W-1:0]        yiaddr_next;
    logic [`IP_ADDR_W-1:0]        siaddr_next;
    logic                         cookie_valid_next;
    logic [7:0] cookie0, cookie1, cookie2, cookie3;
    logic [7:0] opt_tag_240, opt_len_241, msg_type_val;
    logic [7:0] opt_tag_243, opt_len_244;
    logic [7:0] opt_tag_249, opt_len_250;
    logic [DHCP_LEASE_SECS_W-1:0] lease_secs_next;
    logic [`IP_ADDR_W-1:0]        srv_id_next;

    assign op_next     = flit_eff[0][(`DHCP_OP_O * 8) +: 8];
    assign xid_next    = { flit_eff[0][(`DHCP_XID_O * 8) +: 8],
                           flit_eff[0][((`DHCP_XID_O+1) * 8) +: 8],
                           flit_eff[0][((`DHCP_XID_O+2) * 8) +: 8],
                           flit_eff[0][((`DHCP_XID_O+3) * 8) +: 8] };
    assign yiaddr_next = { flit_eff[0][(`DHCP_YIADDR_O * 8) +: 8],
                           flit_eff[0][((`DHCP_YIADDR_O+1) * 8) +: 8],
                           flit_eff[0][((`DHCP_YIADDR_O+2) * 8) +: 8],
                           flit_eff[0][((`DHCP_YIADDR_O+3) * 8) +: 8] };
    assign siaddr_next = { flit_eff[0][(`DHCP_SIADDR_O * 8) +: 8],
                           flit_eff[0][((`DHCP_SIADDR_O+1) * 8) +: 8],
                           flit_eff[0][((`DHCP_SIADDR_O+2) * 8) +: 8],
                           flit_eff[0][((`DHCP_SIADDR_O+3) * 8) +: 8] };

    assign cookie0 = flit_eff[3][((236 - 192) * 8) +: 8];
    assign cookie1 = flit_eff[3][((237 - 192) * 8) +: 8];
    assign cookie2 = flit_eff[3][((238 - 192) * 8) +: 8];
    assign cookie3 = flit_eff[3][((239 - 192) * 8) +: 8];
    assign cookie_valid_next = (cookie0 == `DHCP_COOKIE_0) &&
                               (cookie1 == `DHCP_COOKIE_1) &&
                               (cookie2 == `DHCP_COOKIE_2) &&
                               (cookie3 == `DHCP_COOKIE_3);

    assign opt_tag_240 = flit_eff[3][((240 - 192) * 8) +: 8];
    assign opt_len_241 = flit_eff[3][((241 - 192) * 8) +: 8];
    assign msg_type_val = flit_eff[3][((242 - 192) * 8) +: 8];

    assign opt_tag_243 = flit_eff[3][((243 - 192) * 8) +: 8];
    assign opt_len_244 = flit_eff[3][((244 - 192) * 8) +: 8];
    assign lease_secs_next = (opt_tag_243 == `DHCP_OPT_LEASE_TIME && opt_len_244 == 8'd4)
        ? { flit_eff[3][((245 - 192) * 8) +: 8], flit_eff[3][((246 - 192) * 8) +: 8],
            flit_eff[3][((247 - 192) * 8) +: 8], flit_eff[3][((248 - 192) * 8) +: 8] }
        : '0;

    assign opt_tag_249 = flit_eff[3][((249 - 192) * 8) +: 8];
    assign opt_len_250 = flit_eff[3][((250 - 192) * 8) +: 8];
    assign srv_id_next = (opt_tag_249 == `DHCP_OPT_SERVER_ID && opt_len_250 == 8'd4)
        ? { flit_eff[3][((251 - 192) * 8) +: 8], flit_eff[3][((252 - 192) * 8) +: 8],
            flit_eff[3][((253 - 192) * 8) +: 8], flit_eff[3][((254 - 192) * 8) +: 8] }
        : '0;

    logic latch_now;
    assign latch_now = data_flit_val && data_flit_last;

    always_ff @(posedge clk) begin
        if (rst) begin
            parsed_val          <= 1'b0;
            parsed_op           <= '0;
            parsed_xid          <= '0;
            parsed_yiaddr       <= '0;
            parsed_siaddr       <= '0;
            parsed_cookie_valid <= 1'b0;
            parsed_msg_type_53  <= '0;
            parsed_lease_secs   <= '0;
            parsed_srv_id       <= '0;
        end else begin
            parsed_val <= latch_now;
            if (latch_now) begin
                parsed_op           <= op_next;
                parsed_xid          <= xid_next;
                parsed_yiaddr       <= yiaddr_next;
                parsed_siaddr       <= siaddr_next;
                parsed_cookie_valid <= cookie_valid_next;
                parsed_msg_type_53  <= (opt_tag_240 == `DHCP_OPT_MSG_TYPE && opt_len_241 == 8'd1)
                    ? msg_type_val[2:0] : 3'b0;
                parsed_lease_secs   <= lease_secs_next;
                parsed_srv_id       <= srv_id_next;
            end
        end
    end
endmodule
