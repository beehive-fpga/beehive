package msg_req_pkg;
import tcp_pkg::*;
    typedef enum logic {
        TCP_MSG_REQ = 1'b0,
        TCP_PTR_UPDATE = 1'b1
    } cmd_type_e;

    typedef struct packed {
        logic   [FLOWID_W-1:0]      flowid;
        logic   [PAYLOAD_PTR_W-1:0] size;
        logic   [PAYLOAD_PTR_W-1:0] head_ptr;
        logic   [PAYLOAD_PTR_W-1:0] tail_ptr;
        cmd_type_e                  cmd;
    } tcp_msg_req;

    typedef struct packed {
        logic   [PAYLOAD_PTR_W:0]   head_ptr;
        logic   [PAYLOAD_PTR_W:0]   tail_ptr; 
    } tcp_msg_resp;
endpackage