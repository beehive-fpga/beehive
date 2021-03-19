package packet_gen_pkg;
    import beehive_udp_msg::*;

    localparam CYCLES_BYTES = 8;
    localparam PACKET_SIZE_BYTES = 8;
    localparam CYCLES_W = CYCLES_BYTES * 8;
    localparam PACKET_SIZE_W = PACKET_SIZE_BYTES * 8;

    typedef struct packed {
        logic   [CYCLES_W-1:0]      runtime;
        logic   [PACKET_SIZE_W-1:0] packet_size;
        logic   [`IP_ADDR_W-1:0]    dst_ip;
        logic   [`PORT_NUM_W-1:0]   dst_port;
    } setup_data_struct;

    localparam SETUP_DATA_STRUCT_W = $bits(setup_data_struct);

endpackage
