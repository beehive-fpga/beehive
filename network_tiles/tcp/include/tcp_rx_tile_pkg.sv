package tcp_rx_tile_pkg;
    `include "noc_defs.vh"
    import tcp_pkg::*;

    typedef struct packed {
        logic   [`XY_WIDTH-1:0]         dst_x;
        logic   [`XY_WIDTH-1:0]         dst_y;
        logic   [`NOC_FBITS_WIDTH-1:0]  dst_fbits;
    } tcp_notif_cam_entry;
    localparam TCP_NOTIF_CAM_ENTRY_W = $bits(tcp_notif_cam_entry);
    
endpackage
