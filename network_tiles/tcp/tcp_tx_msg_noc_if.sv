`include "tcp_tx_tile_defs.svh"
module tcp_tx_msg_noc_if 
import tcp_pkg::*;
import tcp_misc_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input  logic                               noc_tcp_tx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_tcp_tx_ptr_if_data
    ,output logic                               tcp_tx_ptr_if_noc_rdy

    ,output logic                               tcp_tx_ptr_if_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       tcp_tx_ptr_if_noc_data
    ,input  logic                               noc_tcp_tx_ptr_if_rdy

    ,output logic                               noc_if_poller_msg_req_val
    ,output logic   [FLOWID_W-1:0]              noc_if_poller_msg_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      noc_if_poller_msg_req_len
    ,output logic   [`MSG_SRC_X_WIDTH-1:0]      noc_if_poller_msg_dst_x
    ,output logic   [`MSG_SRC_Y_WIDTH-1:0]      noc_if_poller_msg_dst_y
    ,output logic   [`MSG_SRC_FBITS_WIDTH-1:0]  noc_if_poller_msg_dst_fbits
    ,input  logic                               poller_noc_if_msg_req_rdy

    ,input  logic                               poller_msg_noc_if_meta_val
    ,input  logic   [FLOWID_W-1:0]              poller_msg_noc_if_flowid
    ,input  logic   [TX_PAYLOAD_PTR_W:0]        poller_msg_noc_if_base_ptr
    ,input  logic   [TX_PAYLOAD_PTR_W-1:0]      poller_msg_noc_if_len
    ,input  logic   [`XY_WIDTH-1:0]             poller_msg_noc_if_dst_x
    ,input  logic   [`XY_WIDTH-1:0]             poller_msg_noc_if_dst_y
    ,input  logic   [`MSG_SRC_FBITS_WIDTH-1:0]  poller_msg_noc_if_dst_fbits
    ,output logic                               noc_if_poller_msg_meta_rdy
    
    ,output logic                               app_tail_ptr_tx_wr_req_val
    ,output logic   [FLOWID_W-1:0]              app_tail_ptr_tx_wr_req_addr
    ,output logic   [TX_PAYLOAD_PTR_W:0]        app_tail_ptr_tx_wr_req_data
    ,input                                      tail_ptr_app_tx_wr_req_rdy
    
    ,output logic                               app_sched_update_val
    ,output sched_cmd_struct                    app_sched_update_cmd
    ,input  logic                               sched_app_update_rdy
);

    tcp_tx_msg_noc_if_in noc_if_in (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.noc_tcp_tx_ptr_if_val         (noc_tcp_tx_ptr_if_val          )
        ,.noc_tcp_tx_ptr_if_data        (noc_tcp_tx_ptr_if_data         )
        ,.tcp_tx_ptr_if_noc_rdy         (tcp_tx_ptr_if_noc_rdy          )
                                                                        
        ,.noc_if_poller_msg_req_val     (noc_if_poller_msg_req_val      )
        ,.noc_if_poller_msg_req_flowid  (noc_if_poller_msg_req_flowid   )
        ,.noc_if_poller_msg_req_len     (noc_if_poller_msg_req_len      )
        ,.noc_if_poller_msg_dst_x       (noc_if_poller_msg_dst_x        )
        ,.noc_if_poller_msg_dst_y       (noc_if_poller_msg_dst_y        )
        ,.noc_if_poller_msg_dst_fbits   (noc_if_poller_msg_dst_fbits    )
        ,.poller_noc_if_msg_req_rdy     (poller_noc_if_msg_req_rdy      )
                                                                        
        ,.app_tail_ptr_tx_wr_req_val    (app_tail_ptr_tx_wr_req_val     )
        ,.app_tail_ptr_tx_wr_req_addr   (app_tail_ptr_tx_wr_req_addr    )
        ,.app_tail_ptr_tx_wr_req_data   (app_tail_ptr_tx_wr_req_data    )
        ,.tail_ptr_app_tx_wr_req_rdy    (tail_ptr_app_tx_wr_req_rdy     )

        ,.app_sched_update_val          (app_sched_update_val           )
        ,.app_sched_update_cmd          (app_sched_update_cmd           )
        ,.sched_app_update_rdy          (sched_app_update_rdy           )
    );

    tcp_tx_msg_noc_if_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) noc_if_out (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.tcp_tx_ptr_if_noc_val         (tcp_tx_ptr_if_noc_val          )
        ,.tcp_tx_ptr_if_noc_data        (tcp_tx_ptr_if_noc_data         )
        ,.noc_tcp_tx_ptr_if_rdy         (noc_tcp_tx_ptr_if_rdy          )
                                                                        
        ,.poller_msg_noc_if_meta_val    (poller_msg_noc_if_meta_val     )
        ,.poller_msg_noc_if_flowid      (poller_msg_noc_if_flowid       )
        ,.poller_msg_noc_if_base_ptr    (poller_msg_noc_if_base_ptr     )
        ,.poller_msg_noc_if_len         (poller_msg_noc_if_len          )
        ,.poller_msg_noc_if_dst_x       (poller_msg_noc_if_dst_x        )
        ,.poller_msg_noc_if_dst_y       (poller_msg_noc_if_dst_y        )
        ,.poller_msg_noc_if_dst_fbits   (poller_msg_noc_if_dst_fbits    )
        ,.noc_if_poller_msg_meta_rdy    (noc_if_poller_msg_meta_rdy     )
    );
endmodule
