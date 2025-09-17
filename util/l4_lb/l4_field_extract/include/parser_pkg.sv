package parser_pkg;
    `include "packet_defs.vh"
    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]    src_ip;
        logic   [`IP_ADDR_W-1:0]    dst_ip;
        logic   [`PORT_NUM_W-1:0]   src_port;
        logic   [`PORT_NUM_W-1:0]   dst_port;
    } tuple_struct;

    localparam HASH_STRUCT_W = $bits(tuple_struct);
endpackage
