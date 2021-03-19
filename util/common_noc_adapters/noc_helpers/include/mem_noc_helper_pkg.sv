package mem_noc_helper_pkg;
    `include "noc_defs.vh"

    typedef struct packed {
        logic   [`MSG_DATA_SIZE_WIDTH-1:0]  mem_req_size;
        logic   [`MEM_REQ_ADDR_W-1:0]       mem_req_addr;
    } mem_req_struct;
    localparam MEM_REQ_STRUCT_W = $bits(mem_req_struct);
endpackage
