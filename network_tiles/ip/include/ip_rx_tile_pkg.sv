package ip_rx_tile_pkg;
   
    typedef enum logic[1:0] {
        SEL_HDR_FLIT = 2'd0,
        SEL_META_FLIT = 2'd1,
        SEL_DATA_FLIT = 2'd2
    } noc_out_flit_mux_sel;

endpackage
