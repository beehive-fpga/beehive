`include "tcp_rx_tile_defs.svh"
module tcp_rx_app_if_wrap 
    import tcp_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           tcp_rx_notif_if_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_notif_if_noc0_vrtoc_data
    ,input  logic                           noc0_vrtoc_tcp_rx_notif_if_rdy
    
    ,input  logic                           app_new_flow_notif_val
    ,input  logic   [FLOWID_W-1:0]          app_new_flow_flowid
    ,input  four_tuple_struct               app_new_flow_entry
    ,output logic                           app_new_flow_notif_rdy
    
    ,input  logic                           noc_tcp_rx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_tcp_rx_ptr_if_data
    ,output logic                           tcp_rx_ptr_if_noc_rdy

    ,output logic                           tcp_rx_ptr_if_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_ptr_if_noc_data
    ,input  logic                           noc_tcp_rx_ptr_if_rdy
    
    ,output logic                           app_rx_head_idx_wr_req_val
    ,output logic   [FLOWID_W-1:0]          app_rx_head_idx_wr_req_addr
    ,output tcp_buf_idx                     app_rx_head_idx_wr_req_data
    ,input  logic                           rx_head_idx_app_wr_req_rdy

    ,output logic                           app_rx_head_idx_rd_req_val
    ,output logic   [FLOWID_W-1:0]          app_rx_head_idx_rd_req_addr
    ,input  logic                           rx_head_idx_app_rd_req_rdy
    
    ,input  logic                           rx_head_idx_app_rd_resp_val
    ,input  tcp_buf_idx                     rx_head_idx_app_rd_resp_data
    ,output logic                           app_rx_head_idx_rd_resp_rdy

    ,output logic                           app_rx_commit_idx_rd_req_val
    ,output logic   [FLOWID_W-1:0]          app_rx_commit_idx_rd_req_addr
    ,input  logic                           rx_commit_idx_app_rd_req_rdy

    ,input  logic                           rx_commit_idx_app_rd_resp_val
    ,input  tcp_buf_idx                     rx_commit_idx_app_rd_resp_data
    ,output logic                           app_rx_commit_idx_rd_resp_rdy

    ,output logic                           app_rx_free_req_val
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]  app_rx_free_req_addr
    ,output logic   [MALLOC_LEN_W-1:0]      app_rx_free_req_len
    ,input  logic                           rx_free_app_req_rdy
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
    tcp_buf_with_idx                poller_msg_noc_if_head_buf;
    logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_x;
    logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_y;
    logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_noc_if_dst_fbits;
    logic                           noc_if_poller_msg_meta_rdy;
    
    tcp_app_notif #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) rx_app_notif (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tcp_rx_notif_if_noc0_vrtoc_val    (tcp_rx_notif_if_noc0_vrtoc_val     )
        ,.tcp_rx_notif_if_noc0_vrtoc_data   (tcp_rx_notif_if_noc0_vrtoc_data    )
        ,.noc0_vrtoc_tcp_rx_notif_if_rdy    (noc0_vrtoc_tcp_rx_notif_if_rdy     )
                                                                                
        ,.app_new_flow_notif_val            (app_new_flow_notif_val             )
        ,.app_new_flow_entry                (app_new_flow_entry                 )
        ,.app_new_flow_flowid               (app_new_flow_flowid                )
        ,.app_new_flow_notif_rdy            (app_new_flow_notif_rdy             )
    );

    tcp_rx_msg_noc_if #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) rx_noc_msg_if (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_tcp_rx_ptr_if_val         (noc_tcp_rx_ptr_if_val          )
        ,.noc_tcp_rx_ptr_if_data        (noc_tcp_rx_ptr_if_data         )
        ,.tcp_rx_ptr_if_noc_rdy         (tcp_rx_ptr_if_noc_rdy          )
                                                                         
        ,.tcp_rx_ptr_if_noc_val         (tcp_rx_ptr_if_noc_val          )
        ,.tcp_rx_ptr_if_noc_data        (tcp_rx_ptr_if_noc_data         )
        ,.noc_tcp_rx_ptr_if_rdy         (noc_tcp_rx_ptr_if_rdy          )
                                                                        
        ,.noc_if_poller_msg_req_val     (noc_if_poller_msg_req_val      )
        ,.noc_if_poller_msg_req_flowid  (noc_if_poller_msg_req_flowid   )
        ,.noc_if_poller_msg_req_len     (noc_if_poller_msg_req_len      )
        ,.noc_if_poller_msg_dst_x       (noc_if_poller_msg_dst_x        )
        ,.noc_if_poller_msg_dst_y       (noc_if_poller_msg_dst_y        )
        ,.noc_if_poller_msg_dst_fbits   (noc_if_poller_msg_dst_fbits    )
        ,.poller_noc_if_msg_req_rdy     (poller_noc_if_msg_req_rdy      )
                                                                        
        ,.poller_msg_noc_if_meta_val    (poller_msg_noc_if_meta_val     )
        ,.poller_msg_noc_if_flowid      (poller_msg_noc_if_flowid       )
        ,.poller_msg_noc_if_head_buf    (poller_msg_noc_if_head_buf     )
        ,.poller_msg_noc_if_dst_x       (poller_msg_noc_if_dst_x        )
        ,.poller_msg_noc_if_dst_y       (poller_msg_noc_if_dst_y        )
        ,.poller_msg_noc_if_dst_fbits   (poller_msg_noc_if_dst_fbits    )
        ,.noc_if_poller_msg_meta_rdy    (noc_if_poller_msg_meta_rdy     )
                                                                        
        ,.app_rx_head_idx_wr_req_val    (app_rx_head_idx_wr_req_val     )
        ,.app_rx_head_idx_wr_req_addr   (app_rx_head_idx_wr_req_addr    )
        ,.app_rx_head_idx_wr_req_data   (app_rx_head_idx_wr_req_data    )
        ,.rx_head_idx_app_wr_req_rdy    (rx_head_idx_app_wr_req_rdy     )

        ,.app_rx_free_req_val           (app_rx_free_req_val            )
        ,.app_rx_free_req_addr          (app_rx_free_req_addr           )
        ,.app_rx_free_req_len           (app_rx_free_req_len            )
        ,.rx_free_app_req_rdy           (rx_free_app_req_rdy            )
    );

    tcp_msg_poller #(
         .CHK_SPACE_EMPTY   (0)
        ,.POLLER_PTR_W      (RX_PAYLOAD_PTR_W   ) // TODO adjust TX
        ,.POLLER_IDX_W      (RX_PAYLOAD_IDX_W   )
    ) msg_poller (
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
        ,.poller_msg_dst_base_ptr   (                               ) // only for TX
        ,.poller_msg_dst_len        (                               ) // only for TX
        ,.poller_msg_dst_base_buf   (poller_msg_noc_if_head_buf     )
        ,.poller_msg_dst_dst_x      (poller_msg_noc_if_dst_x        )
        ,.poller_msg_dst_dst_y      (poller_msg_noc_if_dst_y        )
        ,.poller_msg_dst_dst_fbits  (poller_msg_noc_if_dst_fbits    )
        ,.dst_poller_msg_meta_rdy   (noc_if_poller_msg_meta_rdy     )
    
        ,.app_base_idx_rd_req_val   (app_rx_head_idx_rd_req_val     )
        ,.app_base_idx_rd_req_addr  (app_rx_head_idx_rd_req_addr    )
        ,.base_idx_app_rd_req_rdy   (rx_head_idx_app_rd_req_rdy     )
        
        ,.base_idx_app_rd_resp_val  (rx_head_idx_app_rd_resp_val    )
        ,.base_idx_app_rd_resp_data (rx_head_idx_app_rd_resp_data   )
        ,.app_base_idx_rd_resp_rdy  (app_rx_head_idx_rd_resp_rdy    )
    
        ,.app_end_idx_rd_req_val    (app_rx_commit_idx_rd_req_val   )
        ,.app_end_idx_rd_req_addr   (app_rx_commit_idx_rd_req_addr  )
        ,.end_idx_app_rd_req_rdy    (rx_commit_idx_app_rd_req_rdy   )
    
        ,.end_idx_app_rd_resp_val   (rx_commit_idx_app_rd_resp_val  )
        ,.end_idx_app_rd_resp_data  (rx_commit_idx_app_rd_resp_data )
        ,.app_end_idx_rd_resp_rdy   (app_rx_commit_idx_rd_resp_rdy  )
    );

endmodule
