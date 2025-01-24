`include "tcp_tx_tile_defs.svh"
module tcp_tx_app_if_wrap 
import tcp_pkg::*;
import tcp_misc_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input  logic                           noc_tcp_tx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_tcp_tx_ptr_if_data
    ,output logic                           tcp_tx_ptr_if_noc_rdy

    ,output logic                           tcp_tx_ptr_if_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_ptr_if_noc_data
    ,input  logic                           noc_tcp_tx_ptr_if_rdy
    
    ,output logic                           app_tail_ptr_tx_wr_req_val
    ,output logic   [FLOWID_W-1:0]          app_tail_ptr_tx_wr_req_addr
    ,output logic   [TX_PAYLOAD_PTR_W:0]    app_tail_ptr_tx_wr_req_data
    ,input                                  tail_ptr_app_tx_wr_req_rdy
    
    ,output logic                           app_tail_ptr_tx_rd_req_val
    ,output logic   [FLOWID_W-1:0]          app_tail_ptr_tx_rd_req_addr
    ,input  logic                           tail_ptr_app_tx_rd_req_rdy

    ,input                                  tail_ptr_app_tx_rd_resp_val
    ,input  logic   [FLOWID_W-1:0]          tail_ptr_app_tx_rd_resp_addr
    ,input  logic   [TX_PAYLOAD_PTR_W:0]    tail_ptr_app_tx_rd_resp_data
    ,output logic                           app_tail_ptr_tx_rd_resp_rdy

    ,output                                 app_head_ptr_tx_rd_req_val
    ,output         [FLOWID_W-1:0]          app_head_ptr_tx_rd_req_addr
    ,input  logic                           head_ptr_app_tx_rd_req_rdy

    ,input                                  head_ptr_app_tx_rd_resp_val
    ,input  logic   [FLOWID_W-1:0]          head_ptr_app_tx_rd_resp_addr
    ,input  logic   [TX_PAYLOAD_PTR_W:0]    head_ptr_app_tx_rd_resp_data
    ,output logic                           app_head_ptr_tx_rd_resp_rdy
    
    ,output logic                           app_sched_update_val
    ,output sched_cmd_struct                app_sched_update_cmd
    ,input  logic                           sched_app_update_rdy
);
    
    logic                           noc_if_poller_msg_req_val;
    logic   [FLOWID_W-1:0]          noc_if_poller_msg_req_flowid;
    logic   [RX_PAYLOAD_PTR_W-1:0]  noc_if_poller_msg_req_len;
    logic   [`MSG_SRC_X_WIDTH-1:0]  noc_if_poller_msg_dst_x;
    logic   [`MSG_SRC_Y_WIDTH-1:0]  noc_if_poller_msg_dst_y;
    logic   [`NOC_FBITS_WIDTH-1:0]  noc_if_poller_msg_dst_fbits;
    logic                           poller_noc_if_msg_req_rdy;

    logic                           poller_msg_noc_if_meta_val;
    logic   [FLOWID_W-1:0]          poller_msg_noc_if_flowid;
    logic   [RX_PAYLOAD_PTR_W:0]    poller_msg_noc_if_base_ptr;
    logic   [RX_PAYLOAD_PTR_W-1:0]  poller_msg_noc_if_len;
    logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_x;
    logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_y;
    logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_noc_if_dst_fbits;
    logic                           noc_if_poller_msg_meta_rdy;

    tcp_tx_msg_noc_if #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) tx_msg_noc_if (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_tcp_tx_ptr_if_val         (noc_tcp_tx_ptr_if_val          )
        ,.noc_tcp_tx_ptr_if_data        (noc_tcp_tx_ptr_if_data         )
        ,.tcp_tx_ptr_if_noc_rdy         (tcp_tx_ptr_if_noc_rdy          )

        ,.tcp_tx_ptr_if_noc_val         (tcp_tx_ptr_if_noc_val          )
        ,.tcp_tx_ptr_if_noc_data        (tcp_tx_ptr_if_noc_data         )
        ,.noc_tcp_tx_ptr_if_rdy         (noc_tcp_tx_ptr_if_rdy          )
                                                                        
        ,.noc_if_poller_msg_req_val     (noc_if_poller_msg_req_val      )
        ,.noc_if_poller_msg_req_flowid  (noc_if_poller_msg_req_flowid   )
        ,.noc_if_poller_msg_req_len     (noc_if_poller_msg_req_len      )
        ,.noc_if_poller_msg_dst_x       (noc_if_poller_msg_dst_x        )
        ,.noc_if_poller_msg_dst_y       (noc_if_poller_msg_dst_y        )
        ,.noc_if_poller_msg_dst_fbits   (noc_if_poller_msg_dst_fbits    )
        ,.poller_noc_if_msg_req_rdy     (poller_noc_if_msg_req_rdy      )
                                                                        
        ,.poller_msg_noc_if_meta_val    (poller_msg_noc_if_meta_val     )
        ,.poller_msg_noc_if_flowid      (poller_msg_noc_if_flowid       )
        ,.poller_msg_noc_if_base_ptr    (poller_msg_noc_if_base_ptr     )
        ,.poller_msg_noc_if_len         (poller_msg_noc_if_len          )
        ,.poller_msg_noc_if_dst_x       (poller_msg_noc_if_dst_x        )
        ,.poller_msg_noc_if_dst_y       (poller_msg_noc_if_dst_y        )
        ,.poller_msg_noc_if_dst_fbits   (poller_msg_noc_if_dst_fbits    )
        ,.noc_if_poller_msg_meta_rdy    (noc_if_poller_msg_meta_rdy     )
                                                                        
        ,.app_tail_ptr_tx_wr_req_val    (app_tail_ptr_tx_wr_req_val     )
        ,.app_tail_ptr_tx_wr_req_addr   (app_tail_ptr_tx_wr_req_addr    )
        ,.app_tail_ptr_tx_wr_req_data   (app_tail_ptr_tx_wr_req_data    )
        ,.tail_ptr_app_tx_wr_req_rdy    (tail_ptr_app_tx_wr_req_rdy     )

        ,.app_sched_update_val          (app_sched_update_val           )
        ,.app_sched_update_cmd          (app_sched_update_cmd           )
        ,.sched_app_update_rdy          (sched_app_update_rdy           )
    );

    tcp_msg_poller #(
         .CHK_SPACE_EMPTY   (1)
        ,.POLLER_PTR_W      (TX_PAYLOAD_PTR_W   )
    ) tx_msg_poller (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_poller_msg_req_val    (noc_if_poller_msg_req_val      )
        ,.src_poller_msg_req_flowid (noc_if_poller_msg_req_flowid   )
        ,.src_poller_msg_req_len    (noc_if_poller_msg_req_len      )
        ,.src_poller_msg_dst_x      (noc_if_poller_msg_dst_x        )
        ,.src_poller_msg_dst_y      (noc_if_poller_msg_dst_y        )
        ,.src_poller_msg_dst_fbits  (noc_if_poller_msg_dst_fbits    )
        ,.poller_src_msg_req_rdy    (poller_noc_if_msg_req_rdy      )
                                                              
        ,.poller_msg_dst_meta_val   (poller_msg_noc_if_meta_val     )
        ,.poller_msg_dst_flowid     (poller_msg_noc_if_flowid       )
        ,.poller_msg_dst_base_ptr   (poller_msg_noc_if_base_ptr     )
        ,.poller_msg_dst_len        (poller_msg_noc_if_len          )
        ,.poller_msg_dst_dst_x      (poller_msg_noc_if_dst_x        )
        ,.poller_msg_dst_dst_y      (poller_msg_noc_if_dst_y        )
        ,.poller_msg_dst_dst_fbits  (poller_msg_noc_if_dst_fbits    )
        ,.dst_poller_msg_meta_rdy   (noc_if_poller_msg_meta_rdy     )
                                                              
        ,.app_base_ptr_rd_req_val   (app_tail_ptr_tx_rd_req_val     )
        ,.app_base_ptr_rd_req_addr  (app_tail_ptr_tx_rd_req_addr    )
        ,.base_ptr_app_rd_req_rdy   (tail_ptr_app_tx_rd_req_rdy     )
                                     
        ,.base_ptr_app_rd_resp_val  (tail_ptr_app_tx_rd_resp_val    )
        ,.base_ptr_app_rd_resp_data (tail_ptr_app_tx_rd_resp_data   )
        ,.app_base_ptr_rd_resp_rdy  (app_tail_ptr_tx_rd_resp_rdy    )
                                     
        ,.app_end_ptr_rd_req_val    (app_head_ptr_tx_rd_req_val     )
        ,.app_end_ptr_rd_req_addr   (app_head_ptr_tx_rd_req_addr    )
        ,.end_ptr_app_rd_req_rdy    (head_ptr_app_tx_rd_req_rdy     )
                                     
        ,.end_ptr_app_rd_resp_val   (head_ptr_app_tx_rd_resp_val    )
        ,.end_ptr_app_rd_resp_data  (head_ptr_app_tx_rd_resp_data   )
        ,.app_end_ptr_rd_resp_rdy   (app_head_ptr_tx_rd_resp_rdy    )
    );

endmodule
