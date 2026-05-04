`include "dhcp_tile_defs.svh"

// Builds a static, well-formed DHCP DISCOVER payload (253 bytes / 4 flits)
// plus the matching udp_info metadata. The flit slice presented on
// `to_udp_data` is selected by `curr_flit_index` driven from dhcp_tx_ctrl.
// Bytes are serialised MSB-first to match the convention to_udp expects
// (byte 0 of the payload at the most-significant byte of the flit).
module dhcp_tx_datap #(
    parameter NOC_DATA_W = `NOC_DATA_WIDTH
) (
    input  logic [`DHCP_XID_W-1:0] xid,
    input  logic [1:0]             curr_flit_index,

    output udp_info                to_udp_meta_info,
    output logic [NOC_DATA_W-1:0]  to_udp_data
);
    localparam int NOC_DATA_BYTES = NOC_DATA_W / 8;
    // 253 payload bytes round up to 4 flits of 64 B.
    localparam int MAX_PAYLOAD_BYTES = 4 * NOC_DATA_BYTES;

    logic [7:0] payload [0:MAX_PAYLOAD_BYTES-1];
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
        // bytes 8-235: secs/flags/ciaddr/yiaddr/siaddr/giaddr/chaddr/sname/file = 0
        // Magic cookie at offset 236
        payload[236] = `DHCP_COOKIE_0;
        payload[237] = `DHCP_COOKIE_1;
        payload[238] = `DHCP_COOKIE_2;
        payload[239] = `DHCP_COOKIE_3;
        // Option 53 - DHCP message type = DISCOVER
        payload[240] = `DHCP_OPT_MSG_TYPE;
        payload[241] = 8'd1;
        payload[242] = `DHCP_MSG_DISCOVER;
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
        // Option END
        payload[252] = `DHCP_OPT_END;
    end

    always_comb begin
        to_udp_meta_info             = '0;
        to_udp_meta_info.src_ip      = '0;
        to_udp_meta_info.dst_ip      = {`IP_ADDR_W{1'b1}};
        to_udp_meta_info.src_port    = DHCP_CLIENT_PORT;
        to_udp_meta_info.dst_port    = DHCP_SERVER_PORT;
        to_udp_meta_info.data_length = DHCP_MIN_PAYLOAD_BYTES[`UDP_LENGTH_W-1:0];
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
