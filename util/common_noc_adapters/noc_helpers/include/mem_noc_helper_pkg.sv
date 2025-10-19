package mem_noc_helper_pkg;
    `include "noc_defs.vh"
    import beehive_noc_msg::*;

    typedef struct packed {
        logic   [`MSG_DATA_SIZE_WIDTH-1:0]  mem_req_size;
        logic   [`MEM_REQ_ADDR_W-1:0]       mem_req_addr;
        noc_loc_info                        mem_info;
    } sys_mem_req_struct;
    localparam MEM_REQ_STRUCT_W = $bits(sys_mem_req_struct);
endpackage
