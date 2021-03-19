`ifndef PACKET_DEFS_V
`define PACKET_DEFS_V

`define IP_ADDR_W     32
`define PORT_NUM_W    16
`define SEQ_NUM_W     32
`define ACK_NUM_W     32
`define DATA_OFFSET_W 4
`define RESERVED_W    3
`define FLAGS_W       9
`define WIN_SIZE_W    16
`define TCP_CHKSUM_W  16
`define URG_W         16

`define TCP_FIN           `FLAGS_W'b0_0000_0001
`define TCP_SYN           `FLAGS_W'b0_0000_0010
`define TCP_RST           `FLAGS_W'b0_0000_0100
`define TCP_PSH           `FLAGS_W'b0_0000_1000
`define TCP_ACK           `FLAGS_W'b0_0001_0000
`define TCP_URG           `FLAGS_W'b0_0010_0000
`define TCP_ECE           `FLAGS_W'b0_0100_0000
`define TCP_CWR           `FLAGS_W'b0_1000_0000
`define TCP_NS            `FLAGS_W'b1_0000_0000 

`define TCP_FIN_INDEX       0 
`define TCP_SYN_INDEX       1
`define TCP_RST_INDEX       2
`define TCP_PSH_INDEX       3    
`define TCP_ACK_INDEX       4
`define TCP_URG_INDEX       5
`define TCP_ECE_INDEX       6
`define TCP_CWR_INDEX       7
`define TCP_NS_INDEX        8

`define MTU_SIZE            9100
`define MAX_SEG_SIZE        8800

`define FOUR_TUPLE_W ((2 * `IP_ADDR_W) + 2 * (`PORT_NUM_W))

`define UDP_LENGTH_W 16
`define UDP_CHKSUM_W `TCP_CHKSUM_W

`define IHL_W           4
`define IP_VERSION_W    4
`define TOS_W           8
`define TOT_LEN_W       16
`define ID_W            16
`define FRAG_OFF_W      16
`define TTL_W           8
`define PROTOCOL_W      8
`define IP_CHKSUM_W     16

`define IPPROTO_TCP         `PROTOCOL_W'd6
`define IPPROTO_UDP         `PROTOCOL_W'd17

`define MAC_ADDR_W 48
`define ETH_TYPE_W 16
`define VLAN_TAG_W 32

`define ETH_TYPE_IPV4 `ETH_TYPE_W'h08_00
`define ETH_TYPE_VLAN `ETH_TYPE_W'h81_00
`define MIN_FRAME_SIZE 64

`define MTU_SIZE 9100
`define MTU_SIZE_W $clog2(`MTU_SIZE)

`endif
