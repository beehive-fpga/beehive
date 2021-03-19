package setup_open_loop_pkg;
    `include "noc_defs.vh"
    import open_loop_pkg::*;

    typedef struct packed {
        logic   [31:0]  num_reqs;
        logic   [31:0]  bufsize;
        logic   [31:0]  num_conns;        
        client_dir_e    dir;
        flag_e          should_copy;
    } setup_hdr_struct;

    localparam SETUP_HDR_W = $bits(setup_hdr_struct);
    localparam SETUP_HDR_BYTES = SETUP_HDR_W/8;

    localparam PADDING_W = `NOC_DATA_WIDTH - SETUP_HDR_W;
    typedef struct packed {
        setup_hdr_struct setup_hdr;
        logic [PADDING_W-1:0]   padding;
    } setup_hdr_data;

    typedef enum logic {
        PTR_UPDATE,
        HDR_REQ
    } buf_mux_sel_e;
    
    typedef enum logic[1:0] {
        BUF_READ = 2'd0,
        BUF_WRITE = 2'd1,
        TCP_WRITE = 2'd2
    } setup_noc_sel_e;

endpackage
