module tcp_context_mgmt 
import tcp_pkg::*;
import mem_msg_pkg::*;
#(
     parameter MONITOR_DATA_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input  clk
    ,input  rst 

    ,input  logic                           src_notif_mgr_rx_val
    ,input  logic   [MONITOR_DATA_W-1:0]    src_notif_mgr_rx_data
    ,output logic                           notif_mgr_src_rx_rdy

    ,input  logic                           src_context_mgmt_rd_rx_cap_val
    ,input  logic   [FLOWID_W-1:0]          src_context_mgmt_rd_rx_cap_addr
    ,output logic                           context_mgmt_src_rd_rx_cap_rdy

    ,output logic                           context_mgmt_dst_rd_rx_cap_val
    ,output logic   [CAP_TABLE_INDEX_W-1:0] context_mgmt_dst_rd_rx_cap_data
    ,input  logic                           dst_context_mgmt_rd_rx_cap_rdy
    
    ,input  logic                           src_context_mgmt_rd_tx_cap_val
    ,input  logic   [FLOWID_W-1:0]          src_context_mgmt_rd_tx_cap_addr
    ,output logic                           context_mgmt_src_rd_tx_cap_rdy

    ,output logic                           context_mgmt_dst_rd_tx_cap_val
    ,output logic   [CAP_TABLE_INDEX_W-1:0] context_mgmt_dst_rd_tx_cap_data
    ,input  logic                           dst_context_mgmt_rd_tx_cap_rdy

    ,output logic                           active_q_dst_empty
    ,output logic   [FLOWID_W-1:0]          active_q_dst_rd_data
    ,input  logic                           dst_active_q_rd_req

    ,input  logic                           src_active_q_wr_val
    ,input  logic   [FLOWID_W-1:0]          src_active_q_wr_data
    ,output logic                           active_q_src_rdy

);
    
    logic                           notif_mgr_rx_index_wr_req;
    logic   [FLOWID_W-1:0]          notif_mgr_rx_index_wr_req_addr;
    logic   [CAP_TABLE_INDEX_W-1:0] notif_mgr_rx_index_wr_req_data;
    logic                           rx_index_notif_mgr_wr_req_rdy;
    
    logic                           notif_mgr_tx_index_wr_req;
    logic   [FLOWID_W-1:0]          notif_mgr_tx_index_wr_req_addr;
    logic   [CAP_TABLE_INDEX_W-1:0] notif_mgr_tx_index_wr_req_data;
    logic                           tx_index_notif_mgr_wr_req_rdy;

    logic   [MAX_FLOW_CNT-1:0]      rx_index_vals_notif_mgr;
    logic   [MAX_FLOW_CNT-1:0]      tx_index_vals_notif_mgr;

    logic                           notif_mgr_active_q_wr_req_val;
    logic   [FLOWID_W-1:0]          notif_mgr_active_q_wr_req_data;
    logic                           active_q_notif_mgr_wr_req_rdy;

    logic                           active_q_mux_rdy;
    logic                           mux_active_q_val;
    logic                           mux_active_q_req;
    logic   [FLOWID_W-1:0]          mux_active_q_data;

    notif_mgr #(
         .SRC_X             (SRC_X          )
        ,.SRC_Y             (SRC_Y          )
        ,.MONITOR_DATA_W    (MONITOR_DATA_W )
    ) notif_mgr (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_notif_mgr_rx_val              (src_notif_mgr_rx_val           )
        ,.src_notif_mgr_rx_data             (src_notif_mgr_rx_data          )
        ,.notif_mgr_src_rx_rdy              (notif_mgr_src_rx_rdy           )

        ,.notif_mgr_rx_index_wr_req         (notif_mgr_rx_index_wr_req      )
        ,.notif_mgr_rx_index_wr_req_addr    (notif_mgr_rx_index_wr_req_addr )
        ,.notif_mgr_rx_index_wr_req_data    (notif_mgr_rx_index_wr_req_data )
        ,.rx_index_notif_mgr_wr_req_rdy     (rx_index_notif_mgr_wr_req_rdy  )

        ,.notif_mgr_tx_index_wr_req         (notif_mgr_tx_index_wr_req      )
        ,.notif_mgr_tx_index_wr_req_addr    (notif_mgr_tx_index_wr_req_addr )
        ,.notif_mgr_tx_index_wr_req_data    (notif_mgr_tx_index_wr_req_data )
        ,.tx_index_notif_mgr_wr_req_rdy     (tx_index_notif_mgr_wr_req_rdy  )

        ,.rx_index_vals_notif_mgr           (rx_index_vals_notif_mgr        )
        ,.tx_index_vals_notif_mgr           (tx_index_vals_notif_mgr        )

        ,.notif_mgr_active_q_wr_req_val     (notif_mgr_active_q_wr_req_val  )
        ,.notif_mgr_active_q_wr_req_data    (notif_mgr_active_q_wr_req_data )
        ,.active_q_notif_mgr_wr_req_rdy     (active_q_notif_mgr_wr_req_rdy  )
    );

    valrdy_arb #(
         .DATA_W    (FLOWID_W   )
        ,.NUM_ELS   (2          )
    ) active_q_wr_mux (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_vals  ({notif_mgr_active_q_wr_req_val, src_active_q_wr_val})
        ,.src_datas ({notif_mgr_active_q_wr_req_data, src_active_q_wr_data})
        ,.rdys_src  ({active_q_notif_mgr_wr_req_rdy, active_q_src_rdy}  )

        ,.val_dst   (mux_active_q_val   )
        ,.data_dst  (mux_active_q_data  )
        ,.dst_rdy   (active_q_mux_rdy   )
    );

    assign active_q_mux_rdy = ~active_q_mux_full;
    assign mux_active_q_req = mux_active_q_val & active_q_mux_rdy;

    fifo_1r1w #(
         .width_p    (FLOWID_W  )
        ,.log2_els_p (FLOWID_W  )
    ) active_q (
         .clk    (clk   )
        ,.rst    (rst   )
    
        ,.rd_req    (dst_active_q_rd_req    )
        ,.rd_data   (active_q_dst_rd_data   )
        ,.empty     (active_q_dst_empty     )
    
        ,.wr_req    (mux_active_q_req       )
        ,.wr_data   (mux_active_q_data      )
        ,.full      (active_q_mux_full      )
    );

    ram_1r1w_sync_backpressure #(
         .width_p  (CAP_TABLE_INDEX_W   )
        ,.els_p    (MAX_FLOW_CNT        )
    ) rx_base_addrs (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.wr_req_val    (notif_mgr_rx_index_wr_req          )
        ,.wr_req_addr   (notif_mgr_rx_index_wr_req_addr     )
        ,.wr_req_data   (notif_mgr_rx_index_wr_req_data     )
        ,.wr_req_rdy    (rx_index_notif_mgr_wr_req_rdy      )

        ,.rd_req_val    (src_context_mgmt_rd_rx_cap_val     )
        ,.rd_req_addr   (src_context_mgmt_rd_rx_cap_addr    )
        ,.rd_req_rdy    (context_mgmt_src_rd_rx_cap_rdy     )

        ,.rd_resp_val   (context_mgmt_dst_rd_rx_cap_val     )
        ,.rd_resp_data  (context_mgmt_dst_rd_rx_cap_data    )
        ,.rd_resp_rdy   (dst_context_mgmt_rd_rx_cap_rdy     )
    );
    
    ram_1r1w_sync_backpressure #(
         .width_p  (CAP_TABLE_INDEX_W   )
        ,.els_p    (MAX_FLOW_CNT        )
    ) tx_base_addrs (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.wr_req_val    (notif_mgr_tx_index_wr_req          )
        ,.wr_req_addr   (notif_mgr_tx_index_wr_req_addr     )
        ,.wr_req_data   (notif_mgr_tx_index_wr_req_data     )
        ,.wr_req_rdy    (tx_index_notif_mgr_wr_req_rdy      )

        ,.rd_req_val    (src_context_mgmt_rd_tx_cap_val     )
        ,.rd_req_addr   (src_context_mgmt_rd_tx_cap_addr    )
        ,.rd_req_rdy    (context_mgmt_src_rd_tx_cap_rdy     )

        ,.rd_resp_val   (context_mgmt_dst_rd_tx_cap_val     )
        ,.rd_resp_data  (context_mgmt_dst_rd_tx_cap_data    )
        ,.rd_resp_rdy   (dst_context_mgmt_rd_tx_cap_rdy     )
    );

    valid_bitvector #(
         .BITVECTOR_SIZE    (MAX_FLOW_CNT   )
        ,.INIT_TO_ONE       (0              )
    ) rx_index_vals (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.set_val           (notif_mgr_rx_index_wr_req      )
        ,.set_index         (notif_mgr_rx_index_wr_req_addr )

        // FIXME: connection cleanup
        ,.clear_val         ('0)
        ,.clear_index       ('0)

        ,.valid_bitvector   (rx_index_vals_notif_mgr        )
    );

    valid_bitvector #(
         .BITVECTOR_SIZE    (MAX_FLOW_CNT   )
        ,.INIT_TO_ONE       (0              )
    ) tx_index_vals (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.set_val           (notif_mgr_tx_index_wr_req      )
        ,.set_index         (notif_mgr_tx_index_wr_req_addr )

        // FIXME: connection cleanup
        ,.clear_val         ('0)
        ,.clear_index       ('0)

        ,.valid_bitvector   (tx_index_vals_notif_mgr        )
    );

endmodule