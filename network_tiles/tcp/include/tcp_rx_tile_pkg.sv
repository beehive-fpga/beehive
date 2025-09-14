package tcp_rx_tile_pkg;
    `include "noc_defs.vh"
    import tcp_pkg::*;

    typedef struct packed {
        logic   [`XY_WIDTH-1:0]         dst_x;
        logic   [`XY_WIDTH-1:0]         dst_y;
        logic   [`NOC_FBITS_WIDTH-1:0]  dst_fbits;
    } tcp_notif_cam_entry;
    localparam TCP_NOTIF_CAM_ENTRY_W = $bits(tcp_notif_cam_entry);

    typedef enum logic {
        MINT_OP = 1'b0,
        SEND_OP = 1'b1
    } tcp_notif_mux_sel_e;


    typedef enum logic[1:0] {
        HDR = 2'b0,
        REQ = 2'b1,
        NOTIF = 2'd2
    } cap_sel_e;

endpackage
