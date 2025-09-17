package hash_pkg;
    `include "packet_defs.vh"
    `include "noc_defs.vh"
    typedef struct packed {
        logic   [`IP_ADDR_W-1:0]    src_ip;
        logic   [`IP_ADDR_W-1:0]    dst_ip;
        logic   [`PORT_NUM_W-1:0]   src_port;
        logic   [`PORT_NUM_W-1:0]   dst_port;
    } hash_struct;

    localparam HASH_STRUCT_W = $bits(hash_struct);

    typedef struct packed {
        logic   [`XY_WIDTH-1:0] x_coord;
        logic   [`XY_WIDTH-1:0] y_coord;
    } hash_table_data;
    localparam HASH_TABLE_DATA_W = $bits(hash_table_data);

endpackage
