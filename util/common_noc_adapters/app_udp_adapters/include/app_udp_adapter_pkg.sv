package app_udp_adapter_pkg;

    typedef enum logic [1:0] {
        HDR_OUT = 0,
        META_OUT = 1,
        DATA_OUT = 2
    } to_udp_mux_out_e;

endpackage
