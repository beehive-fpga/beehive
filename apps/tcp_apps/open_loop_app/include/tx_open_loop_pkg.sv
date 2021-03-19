package tx_open_loop_pkg;
    import tcp_pkg::*;
    typedef enum logic {
        CTRL_RESP,
        BENCH
    } send_cmd_e; 

    typedef struct packed {
        send_cmd_e              cmd;
        logic   [FLOWID_W-1:0]  flowid;
    } send_q_struct;
    localparam SEND_Q_STRUCT_W = $bits(send_q_struct);

    typedef enum logic {
        MSG_REQ,
        PTR_UPDATE
    } tx_out_mux_sel_e;

    typedef enum logic {
        BUF_WRITE,
        TCP_WRITE
    } tx_noc_sel_e;

endpackage
