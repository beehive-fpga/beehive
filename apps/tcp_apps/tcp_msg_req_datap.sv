module tcp_msg_req_datap
import tcp_pkg::*;
import msg_req_pkg::*;
import apiary_noc_msg::*;
#(
     parameter MONITOR_DATA_W = -1
    ,parameter TCP_X = -1
    ,parameter TCP_Y = -1
    ,parameter TCP_FBITS = -1
    ,parameter TCP_MSG_TYPE_PTR_UPDATE = -1
    ,parameter TCP_MSG_TYPE_MSG_REQ = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)
(
     input clk
    ,input rst 
    
    ,input  tcp_msg_req                 src_msg_req_data

    ,output tcp_msg_resp                msg_req_dst_data

    ,input  logic   [MONITOR_DATA_W-1:0]    monitor_msg_req_data

    ,output logic   [MONITOR_DATA_W-1:0]    msg_req_monitor_data
    
    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_send_hdr
    ,output logic                           ctrl_datap_store_rsp_body
);

    tcp_msg_req req_reg;
    tcp_msg_req req_next;

    tcp_msg_resp resp_cast;
    apiary_hdr_flit tcp_req_cast;
    tcp_noc_body_flit   tcp_body_cast;

    tcp_noc_body_flit   tcp_rsp_reg;
    tcp_noc_body_flit   tcp_rsp_next;

    assign resp_cast.head_ptr = tcp_rsp_reg.head_ptr;
    assign resp_cast.tail_ptr = tcp_rsp_reg.tail_ptr;

    assign msg_req_monitor_data = ctrl_datap_send_hdr
                            ? tcp_req_cast
                            : tcp_body_cast;

    always_ff @(posedge clk) begin
        req_reg <= req_next;
        tcp_rsp_reg <= tcp_rsp_next;
    end

    assign req_next = ctrl_datap_store_inputs
                    ? src_msg_req_data
                    : req_reg;

    assign tcp_rsp_next = ctrl_datap_store_rsp_body
                        ? monitor_msg_req_data
                        : tcp_rsp_reg;


    always_comb begin
        tcp_req_cast = '0;
        tcp_req_cast.core.dst_x_coord = TCP_X;
        tcp_req_cast.core.dst_y_coord = TCP_Y;
        tcp_req_cast.core.dst_fbits = TCP_FBITS;
        tcp_req_cast.core.msg_len = 1;
        tcp_req_cast.core.src_x_coord = SRC_X;
        tcp_req_cast.core.src_y_coord = SRC_Y;
        tcp_req_cast.core.src_fbits = TCP_FBITS;

        tcp_req_cast.core.msg_type = req_reg.cmd == TCP_MSG_REQ
                                    ? TCP_MSG_TYPE_MSG_REQ
                                    : TCP_MSG_TYPE_PTR_UPDATE;
    end

    always_comb begin
        tcp_body_cast = '0;
        tcp_body_cast.flowid = req_reg.flowid;
        tcp_body_cast.length = req_reg.size;
        tcp_body_cast.head_ptr = req_reg.head_ptr;
        tcp_body_cast.tail_ptr = req_reg.tail_ptr;
    end
endmodule