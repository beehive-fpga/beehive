`include "echo_app_defs.svh"
module echo_app_rx_msg_if #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter DST_BUF_X = -1
    ,parameter DST_BUF_Y = -1
)(
     input clk
    ,input rst

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

    ,input  logic                           active_q_msg_if_empty
    ,output logic                           msg_if_active_q_rd_req
    ,input  logic   [FLOWID_W-1:0]          active_q_msg_if_rd_data

    ,output logic                           msg_if_active_q_wr_req
    ,output logic   [FLOWID_W-1:0]          msg_if_active_q_wr_data
    ,input  logic                           active_q_msg_if_wr_rdy
    
    ,output logic                           rx_if_tx_if_msg_val
    ,output         tx_msg_struct           rx_if_tx_if_msg_data
    ,input  logic                           tx_if_rx_if_msg_rdy
);
    
    logic                               ctrl_rd_buf_req_val;
    logic   [FLOWID_W-1:0]              datap_rd_buf_req_flowid;
    logic   [RX_PAYLOAD_PTR_W:0]        datap_rd_buf_req_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_rd_buf_req_size;
    logic                               rd_buf_ctrl_req_rdy;

    logic                               rd_buf_ctrl_resp_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_buf_datap_resp_data;
    logic                               rd_buf_datap_resp_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_buf_datap_resp_data_padbytes;
    logic                               ctrl_rd_buf_resp_data_rdy;

    logic                               ctrl_datap_store_flowid;
    logic                               ctrl_datap_store_hdr;
    logic                               ctrl_datap_store_notif;
    buf_mux_sel_e                       ctrl_datap_buf_mux_sel;

    logic                               datap_ctrl_last_req;

    echo_app_rx_msg_if_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rx_app_noc_vrtoc_data             (rx_app_noc_vrtoc_data              )

        ,.noc_ctovr_rx_app_data             (noc_ctovr_rx_app_data              )

        ,.active_q_msg_if_rd_data           (active_q_msg_if_rd_data            )

        ,.msg_if_active_q_wr_data           (msg_if_active_q_wr_data            )

        ,.rx_if_tx_if_msg_data              (rx_if_tx_if_msg_data               )

        ,.datap_rd_buf_req_flowid           (datap_rd_buf_req_flowid            )
        ,.datap_rd_buf_req_offset           (datap_rd_buf_req_offset            )
        ,.datap_rd_buf_req_size             (datap_rd_buf_req_size              )

        ,.rd_buf_datap_resp_data            (rd_buf_datap_resp_data             )
        ,.rd_buf_datap_resp_data_last       (rd_buf_datap_resp_data_last        )
        ,.rd_buf_datap_resp_data_padbytes   (rd_buf_datap_resp_data_padbytes    )

        ,.ctrl_datap_store_flowid           (ctrl_datap_store_flowid            )
        ,.ctrl_datap_store_hdr              (ctrl_datap_store_hdr               )
        ,.ctrl_datap_store_notif            (ctrl_datap_store_notif             )
        ,.ctrl_datap_buf_mux_sel            (ctrl_datap_buf_mux_sel             )

        ,.datap_ctrl_last_req               (datap_ctrl_last_req                )
    );

    echo_app_rx_msg_if_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.rx_app_noc_vrtoc_val      (rx_app_noc_vrtoc_val       )
        ,.noc_vrtoc_rx_app_rdy      (noc_vrtoc_rx_app_rdy       )

        ,.noc_ctovr_rx_app_val      (noc_ctovr_rx_app_val       )
        ,.rx_app_noc_ctovr_rdy      (rx_app_noc_ctovr_rdy       )

        ,.active_q_msg_if_empty     (active_q_msg_if_empty      )
        ,.msg_if_active_q_rd_req    (msg_if_active_q_rd_req     )

        ,.msg_if_active_q_wr_req    (msg_if_active_q_wr_req     )
        ,.active_q_msg_if_wr_rdy    (active_q_msg_if_wr_rdy     )

        ,.ctrl_rd_buf_req_val       (ctrl_rd_buf_req_val        )
        ,.rd_buf_ctrl_req_rdy       (rd_buf_ctrl_req_rdy        )

        ,.rd_buf_ctrl_resp_data_val (rd_buf_ctrl_resp_data_val  )
        ,.ctrl_rd_buf_resp_data_rdy (ctrl_rd_buf_resp_data_rdy  )

        ,.rx_if_tx_if_msg_val       (rx_if_tx_if_msg_val        )
        ,.tx_if_rx_if_msg_rdy       (tx_if_rx_if_msg_rdy        )

        ,.ctrl_datap_store_flowid   (ctrl_datap_store_flowid    )
        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_store_notif    (ctrl_datap_store_notif     )
        ,.ctrl_datap_buf_mux_sel    (ctrl_datap_buf_mux_sel     )

        ,.datap_ctrl_last_req       (datap_ctrl_last_req        )
    );

    rd_circ_buf_new #(
         .BUF_PTR_W     (RX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (DST_BUF_X          )
        ,.DST_DRAM_Y    (DST_BUF_Y          )
        ,.FBITS         (RX_BUF_IF_FBITS    )
    ) rd_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_buf_noc0_val           (rx_buf_req_noc_val                 )
        ,.rd_buf_noc0_data          (rx_buf_req_noc_data                )
        ,.noc0_rd_buf_rdy           (req_rx_buf_noc_rdy                 )
       
        ,.noc0_rd_buf_val           (noc0_ctovr_rx_buf_val              )
        ,.noc0_rd_buf_data          (noc0_ctovr_rx_buf_data             )
        ,.rd_buf_noc0_rdy           (rx_buf_noc0_ctovr_rdy              )
    
        ,.src_rd_buf_req_val        (ctrl_rd_buf_req_val                )
        ,.src_rd_buf_req_flowid     (datap_rd_buf_req_flowid            )
        ,.src_rd_buf_req_offset     (datap_rd_buf_req_offset[RX_PAYLOAD_PTR_W-1:0])
        ,.src_rd_buf_req_size       (datap_rd_buf_req_size              )
        ,.rd_buf_src_req_rdy        (rd_buf_ctrl_req_rdy                )
    
        ,.rd_buf_src_data_val       (rd_buf_ctrl_resp_data_val          )
        ,.rd_buf_src_data           (rd_buf_datap_resp_data             )
        ,.rd_buf_src_data_last      (rd_buf_datap_resp_data_last        )
        ,.rd_buf_src_data_padbytes  (rd_buf_datap_resp_data_padbytes    )
        ,.src_rd_buf_data_rdy       (ctrl_rd_buf_resp_data_rdy          )
    );
endmodule
