`ifndef DHCP_PKT_DEFS_SVH
`define DHCP_PKT_DEFS_SVH

// DHCP fixed-header field widths.
`define DHCP_OP_W 8
`define DHCP_HTYPE_W 8
`define DHCP_HLEN_W 8
`define DHCP_HOPS_W 8
`define DHCP_XID_W 32
`define DHCP_SECS_W 16
`define DHCP_FLAGS_W 16
`define DHCP_CIADDR_W 32
`define DHCP_YIADDR_W 32
`define DHCP_SIADDR_W 32
`define DHCP_GIADDR_W 32
`define DHCP_CHADDR_W 128
`define DHCP_OPTIONS_O 236

// Byte offsets in DHCP fixed header.
`define DHCP_OP_O 0
`define DHCP_HTYPE_O 1
`define DHCP_HLEN_O 2
`define DHCP_HOPS_O 3
`define DHCP_XID_O 4
`define DHCP_SECS_O 8
`define DHCP_FLAGS_O 10
`define DHCP_CIADDR_O 12
`define DHCP_YIADDR_O 16
`define DHCP_SIADDR_O 20
`define DHCP_GIADDR_O 24
`define DHCP_CHADDR_O 28

// DHCP magic cookie.
`define DHCP_COOKIE_0 8'd99
`define DHCP_COOKIE_1 8'd130
`define DHCP_COOKIE_2 8'd83
`define DHCP_COOKIE_3 8'd99

// DHCP option tags.
`define DHCP_OPT_MSG_TYPE 8'd53
`define DHCP_OPT_LEASE_TIME 8'd51
`define DHCP_OPT_SERVER_ID 8'd54
`define DHCP_OPT_REQ_IP 8'd50
`define DHCP_OPT_CLIENT_ID 8'd61
`define DHCP_OPT_END 8'd255

// DHCP message types (option 53 values).
`define DHCP_MSG_DISCOVER 8'd1
`define DHCP_MSG_OFFER 8'd2
`define DHCP_MSG_REQUEST 8'd3
`define DHCP_MSG_DECLINE 8'd4
`define DHCP_MSG_ACK 8'd5
`define DHCP_MSG_NAK 8'd6
`define DHCP_MSG_RELEASE 8'd7

`endif
