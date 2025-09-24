module tcp_msg_req 
import tcp_pkg::*;
import msg_req_pkg::*;
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

    ,input  logic                       src_msg_req_val
    ,input  tcp_msg_req                 src_msg_req_data
    ,output logic                       msg_req_src_rdy

    ,output logic                       msg_req_dst_val
    ,output tcp_msg_resp                msg_req_dst_data
    ,input  logic                       dst_msg_req_rdy

    ,input  logic                           monitor_msg_req_val
    ,input  logic   [MONITOR_DATA_W-1:0]    monitor_msg_req_data
    ,output logic                           msg_req_monitor_rdy

    ,output logic                           msg_req_monitor_val
    ,output logic   [MONITOR_DATA_W-1:0]    msg_req_monitor_data
    ,input  logic                           monitor_msg_req_rdy
);
    
    logic                           ctrl_datap_store_inputs;
    logic                           ctrl_datap_send_hdr;
    logic                           ctrl_datap_store_rsp_body;

    tcp_msg_req_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_msg_req_val           (src_msg_req_val            )
        ,.msg_req_src_rdy           (msg_req_src_rdy            )

        ,.msg_req_dst_val           (msg_req_dst_val            )
        ,.dst_msg_req_rdy           (dst_msg_req_rdy            )

        ,.monitor_msg_req_val       (monitor_msg_req_val        )
        ,.msg_req_monitor_rdy       (msg_req_monitor_rdy        )

        ,.msg_req_monitor_val       (msg_req_monitor_val        )
        ,.monitor_msg_req_rdy       (monitor_msg_req_rdy        )

        ,.ctrl_datap_store_inputs   (ctrl_datap_store_inputs    )
        ,.ctrl_datap_send_hdr       (ctrl_datap_send_hdr        )
        ,.ctrl_datap_store_rsp_body (ctrl_datap_store_rsp_body  )
    );

    tcp_msg_req_datap
    #(
         .MONITOR_DATA_W (MONITOR_DATA_W    )
        ,.TCP_X          (TCP_X             )
        ,.TCP_Y          (TCP_Y             )
        ,.TCP_FBITS      (TCP_FBITS         )
        ,.TCP_MSG_TYPE   (TCP_MSG_TYPE      )
        ,.SRC_X          (SRC_X             )
        ,.SRC_Y          (SRC_Y             )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_msg_req_data          (src_msg_req_data           )

        ,.msg_req_dst_data          (msg_req_dst_data           )

        ,.monitor_msg_req_data      (monitor_msg_req_data       )

        ,.msg_req_monitor_data      (msg_req_monitor_data       )

        ,.ctrl_datap_store_inputs   (ctrl_datap_store_inputs    )
        ,.ctrl_datap_send_hdr       (ctrl_datap_send_hdr        )
        ,.ctrl_datap_store_rsp_body (ctrl_datap_store_rsp_body  )
    );
endmodule