module notif_mgr 
import tcp_pkg::*;
import mem_msg_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter MONITOR_DATA_W = -1
)(
     input clk
    ,input rst

    ,input  logic                           src_notif_mgr_rx_val
    ,input  logic   [MONITOR_DATA_W-1:0]    src_notif_mgr_rx_data
    ,output logic                           notif_mgr_src_rx_rdy

    ,output logic                           notif_mgr_rx_index_wr_req
    ,output logic   [FLOWID_W-1:0]          notif_mgr_rx_index_wr_req_addr
    ,output logic   [CAP_TABLE_INDEX_W-1:0] notif_mgr_rx_index_wr_req_data
    ,input  logic                           rx_index_notif_mgr_wr_req_rdy
    
    ,output logic                           notif_mgr_tx_index_wr_req
    ,output logic   [FLOWID_W-1:0]          notif_mgr_tx_index_wr_req_addr
    ,output logic   [CAP_TABLE_INDEX_W-1:0] notif_mgr_tx_index_wr_req_data
    ,input  logic                           tx_index_notif_mgr_wr_req_rdy

    ,input  logic   [MAX_FLOW_CNT-1:0]      rx_index_vals_notif_mgr
    ,input  logic   [MAX_FLOW_CNT-1:0]      tx_index_vals_notif_mgr

    ,output logic                           notif_mgr_active_q_wr_req_val
    ,output logic   [FLOWID_W-1:0]          notif_mgr_active_q_wr_req_data
    ,input  logic                           active_q_notif_mgr_wr_req_rdy 
);

    logic                           ctrl_datap_store_hdr;
    logic                           ctrl_datap_store_index_line;
    logic                           ctrl_datap_store_flow_info;
    
    buf_dir_e                       datap_ctrl_info_dir;
    logic                           datap_ctrl_bufs_valid;
    

    notif_mgr_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_notif_mgr_rx_val          (src_notif_mgr_rx_val          )
        ,.notif_mgr_src_rx_rdy          (notif_mgr_src_rx_rdy          )

        ,.ctrl_rx_index_wr_req_val      (notif_mgr_rx_index_wr_req     )
        ,.rx_index_ctrl_wr_req_rdy      (rx_index_notif_mgr_wr_req_rdy )

        ,.ctrl_tx_index_wr_req_val      (notif_mgr_tx_index_wr_req     )
        ,.tx_index_ctrl_wr_req_rdy      (tx_index_notif_mgr_wr_req_rdy )

        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr          )
        ,.ctrl_datap_store_index_line   (ctrl_datap_store_index_line   )
        ,.ctrl_datap_store_flow_info    (ctrl_datap_store_flow_info    )

        ,.datap_ctrl_info_dir           (datap_ctrl_info_dir           )
        ,.datap_ctrl_bufs_valid         (datap_ctrl_bufs_valid         )

        ,.ctrl_active_q_wr_req          (notif_mgr_active_q_wr_req_val )
        ,.active_q_ctrl_wr_rdy          (active_q_notif_mgr_wr_req_rdy )
    );

    notif_mgr_datap #(
        .MONITOR_DATA_W (MONITOR_DATA_W)
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_notif_mgr_rx_data         (src_notif_mgr_rx_data  )

        ,.datap_rx_index_wr_req_index   (notif_mgr_rx_index_wr_req_data )
        ,.datap_rx_index_wr_req_addr    (notif_mgr_rx_index_wr_req_addr )

        ,.datap_tx_index_wr_req_index   (notif_mgr_tx_index_wr_req_data )
        ,.datap_tx_index_wr_req_addr    (notif_mgr_tx_index_wr_req_addr )

        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_index_line   (ctrl_datap_store_index_line    )
        ,.ctrl_datap_store_flow_info    (ctrl_datap_store_flow_info     )

        ,.rx_index_vals                 (rx_index_vals_notif_mgr        )
        ,.tx_index_vals                 (tx_index_vals_notif_mgr        )

        ,.datap_ctrl_info_dir           (datap_ctrl_info_dir            )
        ,.datap_ctrl_bufs_valid         (datap_ctrl_bufs_valid          )

        ,.datap_active_q_wr_req_data    (notif_mgr_active_q_wr_req_data )
    );

endmodule