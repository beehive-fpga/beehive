package udp_echo_app_pkg;
    typedef enum logic[1:0] {
        HDR_FLIT = 2'd0,
        META_FLIT = 2'd1,
        DATA_FLITS = 2'd2
    } udp_app_out_mux_sel_e;
endpackage
