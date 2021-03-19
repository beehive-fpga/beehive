package udp_rx_tile_pkg;
    `include "noc_defs.vh"

    typedef struct packed {
        logic   [`XY_WIDTH-1:0]         x_coord;
        logic   [`XY_WIDTH-1:0]         y_coord;
        logic   [`NOC_FBITS_WIDTH-1:0]  fbits;
    } udp_rx_cam_entry;
    localparam UDP_RX_CAM_ENTRY_W = `XY_WIDTH + `XY_WIDTH + `NOC_FBITS_WIDTH;

    typedef enum logic[1:0] {
        SEL_HDR_FLIT = 2'd0,
        SEL_META_FLIT = 2'd1,
        SEL_DATA_FLIT = 2'd2
    } noc_out_flit_mux_sel;
endpackage
