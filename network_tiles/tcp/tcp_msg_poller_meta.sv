`include "tcp_msg_poller_defs.svh"
module tcp_msg_poller_meta #(
    parameter POLLER_PTR_W = 0
)(
     input clk
    ,input rst
    
    ,input  logic                           src_poller_msg_req_val
    ,input  logic   [FLOWID_W-1:0]          src_poller_msg_req_flowid
    ,input  logic   [POLLER_PTR_W-1:0]      src_poller_msg_req_len
    ,input  logic   [`MSG_SRC_X_WIDTH-1:0]  src_poller_msg_dst_x
    ,input  logic   [`MSG_SRC_Y_WIDTH-1:0]  src_poller_msg_dst_y
    ,input  logic   [`NOC_FBITS_WIDTH-1:0]  src_poller_msg_dst_fbits
    ,output logic                           poller_src_msg_req_rdy
    
    ,output                                 meta_ctrl_msg_req_q_wr_req_val
    ,output logic   [FLOWID_W-1:0]          meta_data_msg_req_q_wr_req_data
    ,input                                  msg_req_q_meta_ctrl_wr_req_rdy

    ,output                                 meta_ctrl_active_bitvec_set_req_val
    ,output logic   [FLOWID_W-1:0]          meta_data_active_bitvec_set_req_flowid

    ,output logic                           meta_ctrl_msg_req_mem_wr_val
    ,output logic   [FLOWID_W-1:0]          meta_data_msg_req_mem_wr_addr
    ,output         msg_req_mem_struct      meta_data_msg_req_mem_wr_data
    ,input  logic                           msg_req_mem_meta_ctrl_wr_rdy

    ,input  logic   [MAX_FLOW_CNT-1:0]      meta_active_bitvec
);

    tcp_msg_poller_meta_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_poller_msg_req_val                (src_poller_msg_req_val                 )
        ,.poller_src_msg_req_rdy                (poller_src_msg_req_rdy                 )
                                                                                        
        ,.meta_ctrl_msg_req_q_wr_req_val        (meta_ctrl_msg_req_q_wr_req_val         )
        ,.msg_req_q_meta_ctrl_wr_req_rdy        (msg_req_q_meta_ctrl_wr_req_rdy         )
                                                                                        
        ,.meta_ctrl_active_bitvec_set_req_val   (meta_ctrl_active_bitvec_set_req_val    )
                                                                                        
        ,.meta_ctrl_msg_req_mem_wr_val          (meta_ctrl_msg_req_mem_wr_val           )
        ,.msg_req_mem_meta_ctrl_wr_rdy          (msg_req_mem_meta_ctrl_wr_rdy           )
                                                                                        
        ,.ctrl_data_store_inputs                (ctrl_data_store_inputs                 )
        ,.data_ctrl_req_pending                 (data_ctrl_req_pending                  )
    );

    tcp_msg_poller_meta_datap #(
        .POLLER_PTR_W   (POLLER_PTR_W)
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_poller_msg_req_flowid                 (src_poller_msg_req_flowid             )
        ,.src_poller_msg_req_len                    (src_poller_msg_req_len                )
        ,.src_poller_msg_dst_x                      (src_poller_msg_dst_x                  )
        ,.src_poller_msg_dst_y                      (src_poller_msg_dst_y                  )
        ,.src_poller_msg_dst_fbits                  (src_poller_msg_dst_fbits              )
                                                                                                
        ,.meta_data_msg_req_q_wr_req_data           (meta_data_msg_req_q_wr_req_data       )
                                                                                                
        ,.meta_data_active_bitvec_set_req_flowid    (meta_data_active_bitvec_set_req_flowid)
                                                                                                
        ,.meta_data_msg_req_mem_wr_addr             (meta_data_msg_req_mem_wr_addr         )
        ,.meta_data_msg_req_mem_wr_data             (meta_data_msg_req_mem_wr_data         )
                                                                                                
        ,.meta_active_bitvec                        (meta_active_bitvec                    )
                                                                                                
        ,.ctrl_data_store_inputs                    (ctrl_data_store_inputs                )
        ,.data_ctrl_req_pending                     (data_ctrl_req_pending                 )
    );

endmodule
