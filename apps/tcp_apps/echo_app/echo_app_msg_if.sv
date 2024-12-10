`include "echo_app_defs.svh"
module echo_app_msg_if #(
     parameter TX_SRC_X = -1
    ,parameter TX_SRC_Y = -1
    ,parameter TX_DST_BUF_X = -1
    ,parameter TX_DST_BUF_Y = -1
    ,parameter RX_SRC_X = -1
    ,parameter RX_SRC_Y = -1
    ,parameter RX_DST_BUF_X = -1
    ,parameter RX_DST_BUF_Y = -1
    ,parameter NOC1_DATA_W = -1
    ,parameter NOC2_DATA_W = -1
)(
     input clk
    ,input rst
    
    ,output logic                           tx_app_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tx_app_noc_vrtoc_data    
    ,input  logic                           noc_vrtoc_tx_app_rdy

    ,input  logic                           noc_ctovr_tx_app_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_tx_app_data
    ,output logic                           tx_app_noc_ctovr_rdy     
    
    ,output logic                           tx_buf_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tx_buf_noc0_vrtoc_data    
    ,input  logic                           noc0_vrtoc_tx_buf_rdy

    ,input  logic                           noc0_ctovr_tx_buf_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tx_buf_data
    ,output logic                           tx_buf_noc0_ctovr_rdy     
    
    ,input  logic                           noc_wr_resp_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_wr_resp_data
    ,output logic                           wr_resp_noc_rdy
    
    ,input                                  ctovr_echo_app_stats_val
    ,input          [NOC1_DATA_W-1:0]       ctovr_echo_app_stats_data
    ,output logic                           echo_app_stats_ctovr_rdy

    ,output logic                           echo_app_stats_vrtoc_val
    ,output logic   [NOC2_DATA_W-1:0]       echo_app_stats_vrtoc_data
    ,input                                  vrtoc_echo_app_stats_rdy
    
    ,output logic                           rx_app_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rx_app_noc_vrtoc_data    
    ,input  logic                           noc_vrtoc_rx_app_rdy

    ,input  logic                           noc_ctovr_rx_app_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_rx_app_data
    ,output logic                           rx_app_noc_ctovr_rdy    
    
    ,output logic                           rx_buf_req_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rx_buf_req_noc_data    
    ,input  logic                           req_rx_buf_noc_rdy

    ,input  logic                           noc0_ctovr_rx_buf_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rx_buf_data
    ,output logic                           rx_buf_noc0_ctovr_rdy    
    
    ,input  logic                           noc0_ctovr_rx_notif_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rx_notif_data
    ,output logic                           rx_notif_noc0_ctovr_rdy
);
    
    logic                   rx_if_tx_if_msg_val;
    tx_msg_struct           rx_if_tx_if_msg_data;
    logic                   tx_if_rx_if_msg_rdy;
    
    logic                   rx_notif_active_q_wr_req;
    logic   [FLOWID_W-1:0]  rx_notif_active_q_wr_data;
    
    logic                   active_q_msg_if_empty;
    logic                   msg_if_active_q_rd_req;
    logic   [FLOWID_W-1:0]  active_q_msg_if_rd_data;

    logic                   msg_if_active_q_wr_req;
    logic   [FLOWID_W-1:0]  msg_if_active_q_wr_data;

    logic                   active_flow_q_wr_req;
    logic   [FLOWID_W-1:0]  active_flow_q_wr_data;

    assign active_flow_q_wr_req = msg_if_active_q_wr_req | rx_notif_active_q_wr_req;
    assign active_flow_q_wr_data = rx_notif_active_q_wr_req
                                ? rx_notif_active_q_wr_data
                                : msg_if_active_q_wr_data;
    assign active_q_msg_if_wr_rdy = ~rx_notif_active_q_wr_req;

    fifo_1r1w #(
         .width_p       (FLOWID_W               )
        ,.log2_els_p    ($clog2(MAX_FLOW_CNT)   )
    ) active_flow_q (
         .clk    (clk   )
        ,.rst    (rst   )
    
        ,.rd_req    (msg_if_active_q_rd_req     )
        ,.rd_data   (active_q_msg_if_rd_data    )
        ,.empty     (active_q_msg_if_empty      )
    
        ,.wr_req    (active_flow_q_wr_req       )
        ,.wr_data   (active_flow_q_wr_data      )
        ,.full      (/* This queue should never get full */)
    );

    echo_app_new_flow_notif new_flow_notif (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_rx_notif_val   (noc0_ctovr_rx_notif_val    )
        ,.noc0_ctovr_rx_notif_data  (noc0_ctovr_rx_notif_data   )
        ,.rx_notif_noc0_ctovr_rdy   (rx_notif_noc0_ctovr_rdy    )
                                                                
        ,.rx_notif_active_q_wr_req  (rx_notif_active_q_wr_req   )
        ,.rx_notif_active_q_wr_data (rx_notif_active_q_wr_data  )
    );

    echo_app_rx_msg_if #(
         .SRC_X     (RX_SRC_X       )
        ,.SRC_Y     (RX_SRC_Y       )
        ,.DST_BUF_X (RX_DST_BUF_X   )
        ,.DST_BUF_Y (RX_DST_BUF_Y   )
    ) rx_msg_if (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.rx_app_noc_vrtoc_val      (rx_app_noc_vrtoc_val       )
        ,.rx_app_noc_vrtoc_data     (rx_app_noc_vrtoc_data      )
        ,.noc_vrtoc_rx_app_rdy      (noc_vrtoc_rx_app_rdy       )

        ,.noc_ctovr_rx_app_val      (noc_ctovr_rx_app_val       )
        ,.noc_ctovr_rx_app_data     (noc_ctovr_rx_app_data      )
        ,.rx_app_noc_ctovr_rdy      (rx_app_noc_ctovr_rdy       )

        ,.rx_buf_req_noc_val        (rx_buf_req_noc_val         )
        ,.rx_buf_req_noc_data       (rx_buf_req_noc_data        )
        ,.req_rx_buf_noc_rdy        (req_rx_buf_noc_rdy         )

        ,.noc0_ctovr_rx_buf_val     (noc0_ctovr_rx_buf_val      )
        ,.noc0_ctovr_rx_buf_data    (noc0_ctovr_rx_buf_data     )
        ,.rx_buf_noc0_ctovr_rdy     (rx_buf_noc0_ctovr_rdy      )

        ,.active_q_msg_if_empty     (active_q_msg_if_empty      )
        ,.msg_if_active_q_rd_req    (msg_if_active_q_rd_req     )
        ,.active_q_msg_if_rd_data   (active_q_msg_if_rd_data    )

        ,.msg_if_active_q_wr_req    (msg_if_active_q_wr_req     )
        ,.msg_if_active_q_wr_data   (msg_if_active_q_wr_data    )
        ,.active_q_msg_if_wr_rdy    (active_q_msg_if_wr_rdy     )

        ,.rx_if_tx_if_msg_val       (rx_if_tx_if_msg_val        )
        ,.rx_if_tx_if_msg_data      (rx_if_tx_if_msg_data       )
        ,.tx_if_rx_if_msg_rdy       (tx_if_rx_if_msg_rdy        )
    );

    echo_app_tx_msg_if #(
         .SRC_X         (TX_SRC_X           )
        ,.SRC_Y         (TX_SRC_Y           )
        ,.DST_BUF_X     (TX_DST_BUF_X       )
        ,.DST_BUF_Y     (TX_DST_BUF_Y       )
        ,.NOC1_DATA_W   (NOC1_DATA_W        )
        ,.NOC2_DATA_W   (NOC2_DATA_W        )
    ) tx_msg_if (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tx_app_noc_vrtoc_val      (tx_app_noc_vrtoc_val       )
        ,.tx_app_noc_vrtoc_data     (tx_app_noc_vrtoc_data      )
        ,.noc_vrtoc_tx_app_rdy      (noc_vrtoc_tx_app_rdy       )

        ,.noc_ctovr_tx_app_val      (noc_ctovr_tx_app_val       )
        ,.noc_ctovr_tx_app_data     (noc_ctovr_tx_app_data      )
        ,.tx_app_noc_ctovr_rdy      (tx_app_noc_ctovr_rdy       )

        ,.tx_buf_noc0_vrtoc_val     (tx_buf_noc0_vrtoc_val      )
        ,.tx_buf_noc0_vrtoc_data    (tx_buf_noc0_vrtoc_data     )
        ,.noc0_vrtoc_tx_buf_rdy     (noc0_vrtoc_tx_buf_rdy      )

        ,.noc0_ctovr_tx_buf_val     (noc0_ctovr_tx_buf_val      )
        ,.noc0_ctovr_tx_buf_data    (noc0_ctovr_tx_buf_data     )
        ,.tx_buf_noc0_ctovr_rdy     (tx_buf_noc0_ctovr_rdy      )

        ,.noc_wr_resp_val           (noc_wr_resp_val            )
        ,.noc_wr_resp_data          (noc_wr_resp_data           )
        ,.wr_resp_noc_rdy           (wr_resp_noc_rdy            )

        ,.rx_if_tx_if_msg_val       (rx_if_tx_if_msg_val        )
        ,.rx_if_tx_if_msg_data      (rx_if_tx_if_msg_data       )
        ,.tx_if_rx_if_msg_rdy       (tx_if_rx_if_msg_rdy        )

        ,.ctovr_echo_app_stats_val  (ctovr_echo_app_stats_val   )
        ,.ctovr_echo_app_stats_data (ctovr_echo_app_stats_data  )
        ,.echo_app_stats_ctovr_rdy  (echo_app_stats_ctovr_rdy   )

        ,.echo_app_stats_vrtoc_val  (echo_app_stats_vrtoc_val   )
        ,.echo_app_stats_vrtoc_data (echo_app_stats_vrtoc_data  )
        ,.vrtoc_echo_app_stats_rdy  (vrtoc_echo_app_stats_rdy   )
    );

endmodule
