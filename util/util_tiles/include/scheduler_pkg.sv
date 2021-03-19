package scheduler_pkg;
    `include "noc_defs.vh"

    typedef struct packed {
        logic   [`NOC_X_WIDTH-1:0]  dst_x;
        logic   [`NOC_Y_WIDTH-1:0]  dst_y;
    } sched_table_struct;
endpackage
