`include "dhcp_tile_defs.svh"

// Builds the static payload + udp_info meta for one of three DHCP TX
// messages, selected by the latched `tx_msg_type` from dhcp_tx_ctrl:
//
//   DISCOVER       253 B / 4 flits, src=0, dst=broadcast, ciaddr=0
//   REQUEST_INIT   265 B / 5 flits, src=0, dst=broadcast, ciaddr=0,
//                  carries opt 50 (requested IP) + opt 54 (server id)
//   REQUEST_RENEW  253 B / 4 flits, src=yiaddr, dst=siaddr (unicast),
//                  ciaddr=yiaddr, no opt 50 / 54 (we already know our
//                  address; the server identifies us via ciaddr)
//
// `xid`, `lease_yiaddr`, `lease_siaddr` are owned by the lease FSM in
// dhcp_tile_ctrl. Bytes serialise MSB-first to match what `to_udp`
// expects (byte 0 of the payload at the most-significant byte of the
// flit).
module dhcp_tx_datap #(
    parameter NOC_DATA_W = `NOC_DATA_WIDTH
) (
    input  dhcp_tx_msg_type_e      tx_msg_type,
    input  logic [`DHCP_XID_W-1:0] xid,
    input  logic [`IP_ADDR_W-1:0]  lease_yiaddr,
    input  logic [`IP_ADDR_W-1:0]  lease_siaddr,
    input  logic [2:0]             curr_flit_index,

    output udp_info                to_udp_meta_info,
    output logic [NOC_DATA_W-1:0]  to_udp_data
);
    localparam int NOC_DATA_BYTES = NOC_DATA_W / 8;
    // 5 flits covers the longest message we emit (REQUEST_INIT, 265 B).
    localparam int MAX_PAYLOAD_BYTES = 5 * NOC_DATA_BYTES;

    logic [7:0] payload [0:MAX_PAYLOAD_BYTES-1];
    logic [7:0] opt53_val;
    logic [`IP_ADDR_W-1:0] ciaddr_val;
    logic                  is_renew;

    assign is_renew  = (tx_msg_type == REQUEST_RENEW);
    assign opt53_val = (tx_msg_type == DISCOVER)
        ? `DHCP_MSG_DISCOVER
        : `DHCP_MSG_REQUEST;
    assign ciaddr_val = is_renew ? lease_yiaddr : '0;

    integer b;
    always_comb begin
        for (b = 0; b < MAX_PAYLOAD_BYTES; b++) payload[b] = 8'h00;
        // BOOTP fixed header
        payload[0]  = 8'd1;            // op = BOOTREQUEST
        payload[1]  = 8'd1;            // htype = Ethernet
        payload[2]  = 8'd6;            // hlen
        payload[3]  = 8'd0;            // hops
        payload[4]  = xid[31:24];
        payload[5]  = xid[23:16];
        payload[6]  = xid[15:8];
        payload[7]  = xid[7:0];
        // ciaddr (12-15): set to yiaddr only in REQUEST_RENEW.
        payload[12] = ciaddr_val[31:24];
        payload[13] = ciaddr_val[23:16];
        payload[14] = ciaddr_val[15:8];
        payload[15] = ciaddr_val[7:0];
        // yiaddr (16-19) stays 0 in client-originated messages.
        // siaddr (20-23) -- 0 for DISCOVER, server's IP otherwise.
        payload[20] = lease_siaddr[31:24];
        payload[21] = lease_siaddr[23:16];
        payload[22] = lease_siaddr[15:8];
        payload[23] = lease_siaddr[7:0];
        // Magic cookie at offset 236
        payload[236] = `DHCP_COOKIE_0;
        payload[237] = `DHCP_COOKIE_1;
        payload[238] = `DHCP_COOKIE_2;
        payload[239] = `DHCP_COOKIE_3;
        // Option 53 - DHCP message type
        payload[240] = `DHCP_OPT_MSG_TYPE;
        payload[241] = 8'd1;
        payload[242] = opt53_val;
        // Option 61 - client identifier (htype + 6 zero bytes)
        payload[243] = `DHCP_OPT_CLIENT_ID;
        payload[244] = 8'd7;
        payload[245] = 8'd1;
        payload[246] = 8'd0;
        payload[247] = 8'd0;
        payload[248] = 8'd0;
        payload[249] = 8'd0;
        payload[250] = 8'd0;
        payload[251] = 8'd0;

        if (tx_msg_type == REQUEST_INIT) begin
            // Option 50 - requested IP = offered yiaddr
            payload[252] = `DHCP_OPT_REQ_IP;
            payload[253] = 8'd4;
            payload[254] = lease_yiaddr[31:24];
            payload[255] = lease_yiaddr[23:16];
            payload[256] = lease_yiaddr[15:8];
            payload[257] = lease_yiaddr[7:0];
            // Option 54 - server identifier
            payload[258] = `DHCP_OPT_SERVER_ID;
            payload[259] = 8'd4;
            payload[260] = lease_siaddr[31:24];
            payload[261] = lease_siaddr[23:16];
            payload[262] = lease_siaddr[15:8];
            payload[263] = lease_siaddr[7:0];
            payload[264] = `DHCP_OPT_END;
        end else begin
            // DISCOVER + REQUEST_RENEW: END right after opt 61.
            payload[252] = `DHCP_OPT_END;
        end
    end

    always_comb begin
        to_udp_meta_info             = '0;
        to_udp_meta_info.src_ip      = is_renew ? lease_yiaddr : '0;
        to_udp_meta_info.dst_ip      = is_renew ? lease_siaddr : {`IP_ADDR_W{1'b1}};
        to_udp_meta_info.src_port    = DHCP_CLIENT_PORT;
        to_udp_meta_info.dst_port    = DHCP_SERVER_PORT;
        to_udp_meta_info.data_length = (tx_msg_type == REQUEST_INIT)
            ? DHCP_REQUEST_PAYLOAD_BYTES[`UDP_LENGTH_W-1:0]
            : DHCP_MIN_PAYLOAD_BYTES[`UDP_LENGTH_W-1:0];
    end

    integer j;
    always_comb begin
        to_udp_data = '0;
        for (j = 0; j < NOC_DATA_BYTES; j++) begin
            automatic int byte_idx = curr_flit_index * NOC_DATA_BYTES + j;
            if (byte_idx < MAX_PAYLOAD_BYTES) begin
                to_udp_data[((NOC_DATA_BYTES-1-j)*8) +: 8] = payload[byte_idx];
            end
        end
    end
endmodule
