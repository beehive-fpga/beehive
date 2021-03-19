package simple_log_udp_noc_read_pkg;
    typedef enum logic[1:0] {
        HDR = 2'd0,
        META = 2'd1,
        DATA = 2'd2
    } simple_log_resp_sel_e;
endpackage
