package packet_struct_pkg;
    `include "packet_defs.vh"
    typedef struct packed {
            logic   [`MAC_ADDR_W-1:0]   dst;
            logic   [`MAC_ADDR_W-1:0]   src;
            logic   [`ETH_TYPE_W-1:0]   eth_type;
    } eth_hdr;
    localparam ETH_HDR_W = ((`MAC_ADDR_W * 2) + `ETH_TYPE_W);
    localparam ETH_HDR_BYTES = (ETH_HDR_W/8);
    
    typedef struct packed {
            logic   [`MAC_ADDR_W-1:0]   dst;
            logic   [`MAC_ADDR_W-1:0]   src;
            logic   [`VLAN_TAG_W-1:0]   vlan_tag;
            logic   [`ETH_TYPE_W-1:0]   eth_type;
    } eth_hdr_vlan;
    localparam ETH_HDR_VLAN_W = ((`MAC_ADDR_W * 2) + `VLAN_TAG_W + `ETH_TYPE_W);
    localparam ETH_HDR_VLAN_BYTES = (ETH_HDR_VLAN_W/8);

    // Core TCP packet. Does not include optional payloads
    typedef struct packed {
        logic [`PORT_NUM_W-1:0]     src_port;
        logic [`PORT_NUM_W-1:0]     dst_port;
        logic [`SEQ_NUM_W-1:0]      seq_num;
        logic [`ACK_NUM_W-1:0]      ack_num;
        // This is the offset in multiples of 4 bytes, because TCP defines it that way
        logic [`DATA_OFFSET_W-1:0]  raw_data_offset;
        // This bits are functionally unused and are just there to pad out the packet to an 
        // integer number of bits
        logic [`RESERVED_W-1:0]     reserved;
        logic [`FLAGS_W-1:0]        flags;
        logic [`WIN_SIZE_W-1:0]     win_size;
        logic [`TCP_CHKSUM_W-1:0]   chksum;
        // This is probably mostly ignored
        logic [`URG_W-1:0]          urg_pointer;
    } tcp_pkt_hdr;
    // The core header is 20 bytes. 
    // Multiply by 8 to get the number of bits
    localparam TCP_HDR_BYTES = 20;
    localparam TCP_HDR_W = (TCP_HDR_BYTES * 8);

    typedef struct packed {
        logic   [`PORT_NUM_W-1:0]   src_port;
        logic   [`PORT_NUM_W-1:0]   dst_port;
        logic   [`UDP_LENGTH_W-1:0] length;
        logic   [`UDP_CHKSUM_W-1:0] chksum;
    } udp_pkt_hdr;
    localparam UDP_HDR_W = ((2 * `PORT_NUM_W) + `UDP_LENGTH_W + `UDP_CHKSUM_W);
    localparam UDP_HDR_BYTES = (UDP_HDR_W/8);

    typedef struct packed {
        logic [`IP_ADDR_W-1:0]      source_addr;
        logic [`IP_ADDR_W-1:0]      dest_addr;
        logic [`TOT_LEN_W-1:0]      length;
        logic [7:0]                 zeros;
        logic [`PROTOCOL_W-1:0]     protocol;
    } chksum_pseudo_hdr;
    localparam CHKSUM_PSEUDO_HDR_BYTES = 12;
    localparam CHKSUM_PSEUDO_HDR_W = (CHKSUM_PSEUDO_HDR_BYTES * 8);

    typedef struct packed {
        logic [`IP_VERSION_W-1:0]   ip_version;
        // This is the header length in multiples of 4 bytes, because the spec
        // defines it that way
        logic [`IHL_W-1:0]          ip_hdr_len;
        logic [`TOS_W-1:0]          tos;
        logic [`TOT_LEN_W-1:0]      tot_len;
        logic [`ID_W-1:0]           id;
        logic [`FRAG_OFF_W-1:0]     frag_offset;
        logic [`TTL_W-1:0]          ttl;
        logic [`PROTOCOL_W-1:0]     protocol_no;
        logic [`IP_CHKSUM_W-1:0]    chksum;
        logic [`IP_ADDR_W-1:0]      source_addr;
        logic [`IP_ADDR_W-1:0]      dest_addr;
    } ip_pkt_hdr;
    // The core header size is 20 bytes times 8 to get width in bits
    localparam IP_HDR_BYTES = 20;
    localparam IP_HDR_W = (IP_HDR_BYTES * 8);
    
    typedef struct packed {
        logic [`IP_ADDR_W-1:0]      host_ip;
        logic [`IP_ADDR_W-1:0]      dest_ip;
        logic [`PORT_NUM_W-1:0]     host_port;
        logic [`PORT_NUM_W-1:0]     dest_port;
    } four_tuple_struct;
    localparam FOUR_TUPLE_STRUCT_W = ((`IP_ADDR_W * 2) + (`PORT_NUM_W * 2));
    
endpackage
