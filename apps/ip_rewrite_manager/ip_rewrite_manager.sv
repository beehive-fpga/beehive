`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager #(
     parameter RX_SRC_X = -1
    ,parameter RX_SRC_Y = -1
    ,parameter TX_SRC_X = -1
    ,parameter TX_SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_ip_rewrite_manager_rx_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_rewrite_manager_rx_data
    ,output logic                           ip_rewrite_manager_rx_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_manager_rx_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_manager_rx_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_ip_rewrite_manager_rx_rdy
    
    ,input                                  noc0_ctovr_ip_rewrite_manager_tx_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_rewrite_manager_tx_data
    ,output logic                           ip_rewrite_manager_tx_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_manager_tx_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_manager_tx_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_ip_rewrite_manager_tx_rdy
    
    ,input                                  noc0_ctovr_rd_rx_buf_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rd_rx_buf_data
    ,output logic                           rd_rx_buf_noc0_ctovr_rdy
    
    ,output logic                           rd_rx_buf_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rd_rx_buf_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_rd_rx_buf_rdy
    
    ,input                                  noc0_ctovr_wr_tx_buf_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_wr_tx_buf_data
    ,output logic                           wr_tx_buf_noc0_ctovr_rdy
    
    ,output logic                           wr_tx_buf_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   wr_tx_buf_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_wr_tx_buf_rdy

    ,input                                  noc_rewrite_ctrl_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc_rewrite_ctrl_in_data
    ,output                                 rewrite_ctrl_noc_in_rdy

    ,output                                 rewrite_ctrl_noc_out_val
    ,output         [`NOC_DATA_WIDTH-1:0]   rewrite_ctrl_noc_out_data
    ,input                                  noc_rewrite_ctrl_out_rdy
);
    logic                               in_ctrl_out_ctrl_resp_val;
    logic                               out_ctrl_in_ctrl_resp_rdy;
    logic   [`FLOW_ID_W-1:0]            in_datap_out_datap_resp_flowid;
    logic   [`PAYLOAD_PTR_W:0]          in_datap_out_datap_resp_offset;

    logic                               in_ctrl_in_datap_store_flow_notif;
    ip_manager_noc_sel                  in_ctrl_in_datap_noc_sel;
    ip_manager_tile_sel                 in_ctrl_in_datap_tile_sel;
    ip_manager_if_sel                   in_ctrl_in_datap_if_sel;
    logic                               in_ctrl_in_datap_store_req_notif;
    logic                               in_ctrl_in_datap_store_rewrite_req;

    logic                               in_ctrl_rd_rx_buf_val;
    logic                               rd_rx_buf_in_ctrl_rdy;
    
    logic   [`FLOW_ID_W-1:0]            in_datap_rd_rx_buf_flowid;
    logic   [`RX_PAYLOAD_PTR_W-1:0]     in_datap_rd_rx_buf_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  in_datap_rd_rx_buf_size;

    logic                               rd_rx_buf_in_ctrl_data_val;
    logic                               in_ctrl_rd_rx_buf_data_rdy;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_rx_buf_resp_data;
    
    logic                               out_ctrl_out_datap_store_inputs;
    ip_manager_tx_noc_sel               out_ctrl_out_datap_noc_sel;
    logic                               out_ctrl_out_datap_store_notif;
    ip_manager_tx_tile_sel              out_ctrl_out_datap_tile_sel;

    logic                               out_ctrl_wr_tx_buf_req_val;
    logic                               wr_tx_buf_out_ctrl_req_rdy;
    logic   [`FLOW_ID_W-1:0]            out_datap_wr_tx_buf_flowid;
    logic   [`PAYLOAD_PTR_W-1:0]        out_datap_wr_tx_buf_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  out_datap_wr_tx_buf_size;

    logic                               out_ctrl_wr_tx_buf_req_data_val;
    logic                               out_ctrl_wr_tx_buf_req_data_last;
    logic                               wr_tx_buf_out_ctrl_req_data_rdy;
    logic   [`NOC_DATA_WIDTH-1:0]       out_datap_wr_tx_buf_data;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   out_datap_wr_tx_buf_data_padbytes;

    logic                               wr_tx_buf_out_ctrl_done;
    logic                               out_ctrl_wr_tx_buf_done_rdy;

    ip_rewrite_manager_rx_ctrl rx_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_manager_rx_val  (noc0_ctovr_ip_rewrite_manager_rx_val   )
        ,.ip_rewrite_manager_rx_noc0_ctovr_rdy  (ip_rewrite_manager_rx_noc0_ctovr_rdy   )
                                                                                        
        ,.ip_rewrite_manager_rx_noc0_vrtoc_val  (ip_rewrite_manager_rx_noc0_vrtoc_val   )
        ,.noc0_vrtoc_ip_rewrite_manager_rx_rdy  (noc0_vrtoc_ip_rewrite_manager_rx_rdy   )
                                                                                        
        ,.in_ctrl_out_ctrl_resp_val             (in_ctrl_out_ctrl_resp_val              )
        ,.out_ctrl_in_ctrl_resp_rdy             (out_ctrl_in_ctrl_resp_rdy              )
                                                                                        
        ,.in_ctrl_in_datap_store_flow_notif     (in_ctrl_in_datap_store_flow_notif      )
        ,.in_ctrl_in_datap_noc_sel              (in_ctrl_in_datap_noc_sel               )
        ,.in_ctrl_in_datap_tile_sel             (in_ctrl_in_datap_tile_sel              )
        ,.in_ctrl_in_datap_if_sel               (in_ctrl_in_datap_if_sel                )
        ,.in_ctrl_in_datap_store_req_notif      (in_ctrl_in_datap_store_req_notif       )
        ,.in_ctrl_in_datap_store_rewrite_req    (in_ctrl_in_datap_store_rewrite_req     )
                                                                                        
        ,.in_ctrl_rd_rx_buf_val                 (in_ctrl_rd_rx_buf_val                  )
        ,.rd_rx_buf_in_ctrl_rdy                 (rd_rx_buf_in_ctrl_rdy                  )
    
        ,.rd_rx_buf_in_ctrl_data_val            (rd_rx_buf_in_ctrl_data_val             )
        ,.in_ctrl_rd_rx_buf_data_rdy            (in_ctrl_rd_rx_buf_data_rdy             )
    
        ,.noc_rewrite_ctrl_in_val               (noc_rewrite_ctrl_in_val                )
        ,.rewrite_ctrl_noc_in_rdy               (rewrite_ctrl_noc_in_rdy                )
                                                                                        
        ,.rewrite_ctrl_noc_out_val              (rewrite_ctrl_noc_out_val               )
        ,.noc_rewrite_ctrl_out_rdy              (noc_rewrite_ctrl_out_rdy               )
    );

    ip_rewrite_manager_rx_datap #(
         .SRC_X (RX_SRC_X  )
        ,.SRC_Y (RX_SRC_Y  )
    ) rx_datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_manager_rx_data (noc0_ctovr_ip_rewrite_manager_rx_data  )
                                                                                        
        ,.ip_rewrite_manager_rx_noc0_vrtoc_data (ip_rewrite_manager_rx_noc0_vrtoc_data  )
                                                                                        
        ,.in_ctrl_in_datap_store_flow_notif     (in_ctrl_in_datap_store_flow_notif      )
        ,.in_ctrl_in_datap_noc_sel              (in_ctrl_in_datap_noc_sel               )
        ,.in_ctrl_in_datap_tile_sel             (in_ctrl_in_datap_tile_sel              )
        ,.in_ctrl_in_datap_if_sel               (in_ctrl_in_datap_if_sel                )
        ,.in_ctrl_in_datap_store_req_notif      (in_ctrl_in_datap_store_req_notif       )
        ,.in_ctrl_in_datap_store_rewrite_req    (in_ctrl_in_datap_store_rewrite_req     )
                                                                                        
        ,.in_datap_rd_rx_buf_flowid             (in_datap_rd_rx_buf_flowid              )
        ,.in_datap_rd_rx_buf_offset             (in_datap_rd_rx_buf_offset              )
        ,.in_datap_rd_rx_buf_size               (in_datap_rd_rx_buf_size                )
                                                                                        
        ,.rd_rx_buf_resp_data                   (rd_rx_buf_resp_data                    )
                                                                                        
        ,.in_datap_out_datap_resp_flowid        (in_datap_out_datap_resp_flowid         )
        ,.in_datap_out_datap_resp_offset        (in_datap_out_datap_resp_offset         )
    
        ,.noc_rewrite_ctrl_in_data              (noc_rewrite_ctrl_in_data               )
                                                                                        
        ,.rewrite_ctrl_noc_out_data             (rewrite_ctrl_noc_out_data              )
    );

    rd_circ_buf_new #(
         .BUF_PTR_W     (`PAYLOAD_PTR_W                 )
        ,.SRC_X         (RX_SRC_X                       )
        ,.SRC_Y         (RX_SRC_Y                       )
        ,.DST_DRAM_X    (DRAM_RX_TILE_X                 )
        ,.DST_DRAM_Y    (DRAM_RX_TILE_Y                 )
        ,.FBITS         (IP_REWRITE_TCP_RX_BUF_FBITS    )
    ) rd_rx_buf (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_buf_noc0_val           (rd_rx_buf_noc0_vrtoc_val   )
        ,.rd_buf_noc0_data          (rd_rx_buf_noc0_vrtoc_data  )
        ,.noc0_rd_buf_rdy           (noc0_vrtoc_rd_rx_buf_rdy   )
       
        ,.noc0_rd_buf_val           (noc0_ctovr_rd_rx_buf_val   )
        ,.noc0_rd_buf_data          (noc0_ctovr_rd_rx_buf_data  )
        ,.rd_buf_noc0_rdy           (rd_rx_buf_noc0_ctovr_rdy   )
    
        ,.src_rd_buf_req_val        (in_ctrl_rd_rx_buf_val      )
        ,.src_rd_buf_req_flowid     (in_datap_rd_rx_buf_flowid  )
        ,.src_rd_buf_req_offset     (in_datap_rd_rx_buf_offset  )
        ,.src_rd_buf_req_size       (in_datap_rd_rx_buf_size    )
        ,.rd_buf_src_req_rdy        (rd_rx_buf_in_ctrl_rdy      )
    
        ,.rd_buf_src_data_val       (rd_rx_buf_in_ctrl_data_val )
        ,.rd_buf_src_data           (rd_rx_buf_resp_data        )
        ,.rd_buf_src_data_last      ()
        ,.rd_buf_src_data_padbytes  ()
        ,.src_rd_buf_data_rdy       (in_ctrl_rd_rx_buf_data_rdy )
    );

    ip_rewrite_manager_tx_ctrl tx_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_ctovr_ip_rewrite_manager_tx_val  (noc0_ctovr_ip_rewrite_manager_tx_val   )
        ,.ip_rewrite_manager_tx_noc0_ctovr_rdy  (ip_rewrite_manager_tx_noc0_ctovr_rdy   )
                                                                                        
        ,.ip_rewrite_manager_tx_noc0_vrtoc_val  (ip_rewrite_manager_tx_noc0_vrtoc_val   )
        ,.noc0_vrtoc_ip_rewrite_manager_tx_rdy  (noc0_vrtoc_ip_rewrite_manager_tx_rdy   )
                                                                                        
        ,.in_ctrl_out_ctrl_resp_val             (in_ctrl_out_ctrl_resp_val              )
        ,.out_ctrl_in_ctrl_resp_rdy             (out_ctrl_in_ctrl_resp_rdy              )
                                                                                        
        ,.out_ctrl_out_datap_store_inputs       (out_ctrl_out_datap_store_inputs        )
        ,.out_ctrl_out_datap_noc_sel            (out_ctrl_out_datap_noc_sel             )
        ,.out_ctrl_out_datap_store_notif        (out_ctrl_out_datap_store_notif         )
        ,.out_ctrl_out_datap_tile_sel           (out_ctrl_out_datap_tile_sel            )
                                                                                        
        ,.out_ctrl_wr_tx_buf_req_val            (out_ctrl_wr_tx_buf_req_val             )
        ,.wr_tx_buf_out_ctrl_req_rdy            (wr_tx_buf_out_ctrl_req_rdy             )
                                                                                        
        ,.out_ctrl_wr_tx_buf_req_data_val       (out_ctrl_wr_tx_buf_req_data_val        )
        ,.out_ctrl_wr_tx_buf_req_data_last      (out_ctrl_wr_tx_buf_req_data_last       )
        ,.wr_tx_buf_out_ctrl_req_data_rdy       (wr_tx_buf_out_ctrl_req_data_rdy        )
                                                                                        
        ,.wr_tx_buf_out_ctrl_done               (wr_tx_buf_out_ctrl_done                )
        ,.out_ctrl_wr_tx_buf_done_rdy           (out_ctrl_wr_tx_buf_done_rdy            )
    );

    ip_rewrite_manager_tx_datap #(
         .SRC_X (TX_SRC_X   )
        ,.SRC_Y (TX_SRC_Y   )
    ) tx_datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_manager_tx_data (noc0_ctovr_ip_rewrite_manager_tx_data  )
                                                                                        
        ,.ip_rewrite_manager_tx_noc0_vrtoc_data (ip_rewrite_manager_tx_noc0_vrtoc_data  )
                                                                                        
        ,.in_datap_out_datap_resp_flowid        (in_datap_out_datap_resp_flowid         )
        ,.in_datap_out_datap_resp_offset        (in_datap_out_datap_resp_offset         )
                                                                                        
        ,.out_ctrl_out_datap_store_inputs       (out_ctrl_out_datap_store_inputs        )
        ,.out_ctrl_out_datap_noc_sel            (out_ctrl_out_datap_noc_sel             )
        ,.out_ctrl_out_datap_store_notif        (out_ctrl_out_datap_store_notif         )
        ,.out_ctrl_out_datap_tile_sel           (out_ctrl_out_datap_tile_sel            )
                                                                                        
        ,.out_datap_wr_tx_buf_flowid            (out_datap_wr_tx_buf_flowid             )
        ,.out_datap_wr_tx_buf_offset            (out_datap_wr_tx_buf_offset             )
        ,.out_datap_wr_tx_buf_size              (out_datap_wr_tx_buf_size               )
                                                                                        
        ,.out_datap_wr_tx_buf_data              (out_datap_wr_tx_buf_data               )
        ,.out_datap_wr_tx_buf_data_padbytes     (out_datap_wr_tx_buf_data_padbytes      )
    );

    wr_circ_buf #(
         .BUF_PTR_W     (`PAYLOAD_PTR_W                 )
        ,.SRC_X         (TX_SRC_X                       )
        ,.SRC_Y         (TX_SRC_Y                       )
        ,.DST_DRAM_X    (DRAM_TX_TILE_X                 )
        ,.DST_DRAM_Y    (DRAM_TX_TILE_Y                 )
        ,.FBITS         (IP_REWRITE_TCP_TX_BUF_FBITS    )
    ) wr_tx_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_buf_noc_req_noc0_val   (wr_tx_buf_noc0_vrtoc_val           )
        ,.wr_buf_noc_req_noc0_data  (wr_tx_buf_noc0_vrtoc_data          )
        ,.noc_wr_buf_req_noc0_rdy   (noc0_vrtoc_wr_tx_buf_rdy           )
        
        ,.noc_wr_buf_resp_noc0_val  (noc0_ctovr_wr_tx_buf_val           )
        ,.noc_wr_buf_resp_noc0_data (noc0_ctovr_wr_tx_buf_data          )
        ,.wr_buf_noc_resp_noc0_rdy  (wr_tx_buf_noc0_ctovr_rdy           )
    
        ,.src_wr_buf_req_val        (out_ctrl_wr_tx_buf_req_val         )
        ,.src_wr_buf_req_flowid     (out_datap_wr_tx_buf_flowid         )
        ,.src_wr_buf_req_wr_ptr     (out_datap_wr_tx_buf_offset         )
        ,.src_wr_buf_req_size       (out_datap_wr_tx_buf_size           )
        ,.wr_buf_src_req_rdy        (wr_tx_buf_out_ctrl_req_rdy         )
    
        ,.src_wr_buf_req_data_val   (out_ctrl_wr_tx_buf_req_data_val    )
        ,.src_wr_buf_req_data       (out_datap_wr_tx_buf_data           )
        ,.wr_buf_src_req_data_rdy   (wr_tx_buf_out_ctrl_req_data_rdy    )
        
        ,.wr_buf_src_req_done       (wr_tx_buf_out_ctrl_done            )
        ,.src_wr_buf_done_rdy       (out_ctrl_wr_tx_buf_done_rdy        )
    );

endmodule
