`include "tcp_tx_tile_defs.svh"
module tcp_tx_msg_noc_if_in 
    import tcp_pkg::*;
    import tcp_misc_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic                           noc_tcp_tx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_tcp_tx_ptr_if_data
    ,output logic                           tcp_tx_ptr_if_noc_rdy
    
    ,output logic                           noc_if_poller_msg_req_val
    ,output logic   [FLOWID_W-1:0]          noc_if_poller_msg_req_flowid
    ,output logic   [TX_PAYLOAD_PTR_W-1:0]  noc_if_poller_msg_req_len
    ,output logic   [`MSG_SRC_X_WIDTH-1:0]  noc_if_poller_msg_dst_x
    ,output logic   [`MSG_SRC_Y_WIDTH-1:0]  noc_if_poller_msg_dst_y
    ,output logic   [`NOC_FBITS_WIDTH-1:0]  noc_if_poller_msg_dst_fbits
    ,input  logic                           poller_noc_if_msg_req_rdy
    
    ,output logic                           app_tail_ptr_tx_wr_req_val
    ,output logic   [FLOWID_W-1:0]          app_tail_ptr_tx_wr_req_addr
    ,output logic   [TX_PAYLOAD_PTR_W:0]    app_tail_ptr_tx_wr_req_data
    ,input                                  tail_ptr_app_tx_wr_req_rdy

    ,output logic                           app_sched_update_val
    ,output sched_cmd_struct                app_sched_update_cmd
    ,input  logic                           sched_app_update_rdy
);
    logic                           ctrl_datap_store_hdr_flit;

    tcp_tx_msg_noc_if_in_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_tcp_tx_ptr_if_data        (noc_tcp_tx_ptr_if_data         )
                                                                        
        ,.noc_if_poller_msg_req_flowid  (noc_if_poller_msg_req_flowid   )
        ,.noc_if_poller_msg_req_len     (noc_if_poller_msg_req_len      )
        ,.noc_if_poller_msg_dst_x       (noc_if_poller_msg_dst_x        )
        ,.noc_if_poller_msg_dst_y       (noc_if_poller_msg_dst_y        )
        ,.noc_if_poller_msg_dst_fbits   (noc_if_poller_msg_dst_fbits    )
                                                                        
        ,.app_tail_ptr_tx_wr_req_addr   (app_tail_ptr_tx_wr_req_addr    )
        ,.app_tail_ptr_tx_wr_req_data   (app_tail_ptr_tx_wr_req_data    )

        ,.app_sched_update_cmd          (app_sched_update_cmd           )
    
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
    );

    tcp_tx_msg_noc_if_in_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_tcp_tx_ptr_if_val         (noc_tcp_tx_ptr_if_val          )
        ,.noc_tcp_tx_ptr_if_data        (noc_tcp_tx_ptr_if_data         )
        ,.tcp_tx_ptr_if_noc_rdy         (tcp_tx_ptr_if_noc_rdy          )
                                                                        
        ,.noc_if_poller_msg_req_val     (noc_if_poller_msg_req_val      )
        ,.poller_noc_if_msg_req_rdy     (poller_noc_if_msg_req_rdy      )
                                                                        
        ,.app_tail_ptr_tx_wr_req_val    (app_tail_ptr_tx_wr_req_val     )
        ,.tail_ptr_app_tx_wr_req_rdy    (tail_ptr_app_tx_wr_req_rdy     )
        
        ,.app_sched_update_val          (app_sched_update_val           )
        ,.sched_app_update_rdy          (sched_app_update_rdy           )
                                                                        
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
    );
endmodule
