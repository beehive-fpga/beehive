package rx_open_loop_pkg;
    typedef enum logic {
        PTR_UPDATE,
        MSG_REQ
    } rx_out_mux_sel_e;

    typedef enum logic {
        BUF_WRITE,
        TCP_WRITE
    } rx_noc_sel_e;

endpackage
