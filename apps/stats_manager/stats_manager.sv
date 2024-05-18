module stats_manager 
    import stats_manager_pkg::*;
    import tracker_pkg::*;
    import beehive_tcp_msg::*;
#(
     parameter NOC0_DATA_W = -1
    ,parameter NOC1_DATA_W = -1
    ,parameter NOC0_DATA_BYTES = NOC0_DATA_W/8
    ,parameter NOC0_PADBYTES_W = $clog2(NOC0_DATA_BYTES)
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter TX_DST_DRAM_X = -1
    ,parameter TX_DST_DRAM_Y = -1
    ,parameter RX_DST_DRAM_X = -1
    ,parameter RX_DST_DRAM_Y = -1
)(
     input clk
    ,input rst

    ,input  logic                       in_manager_noc0_val
    ,input  logic   [NOC0_DATA_W-1:0]   in_manager_noc0_data
    ,output logic                       manager_in_noc0_rdy

    ,input  logic                       in_manager_notif_noc1_val
    ,input  logic   [NOC1_DATA_W-1:0]   in_manager_notif_noc1_data
    ,output logic                       manager_in_notif_noc1_rdy

    ,output logic                       manager_out_notif_noc1_val
    ,output logic   [NOC1_DATA_W-1:0]   manager_out_notif_noc1_data
    ,input  logic                       notif_manager_out_noc1_rdy

    ,output logic                       rd_buf_out_noc1_val
    ,output logic   [NOC1_DATA_W-1:0]   rd_buf_out_noc1_data
    ,input  logic                       out_rd_buf_noc1_rdy

    ,input  logic                       in_rd_buf_noc0_val
    ,input  logic   [NOC0_DATA_W-1:0]   in_rd_buf_noc0_data
    ,output logic                       rd_buf_in_noc0_rdy

    ,output logic                       wr_buf_out_noc0_val
    ,output logic   [NOC0_DATA_W-1:0]   wr_buf_out_noc0_data
    ,input  logic                       out_wr_buf_noc0_rdy

    ,input  logic                       in_wr_buf_noc1_val
    ,input  logic   [NOC1_DATA_W-1:0]   in_wr_buf_noc1_data
    ,output logic                       wr_buf_in_noc1_rdy

    ,input  logic                       in_request_noc1_val
    ,input  logic   [NOC1_DATA_W-1:0]   in_request_noc1_data
    ,output logic                       request_in_noc1_rdy

    ,output logic                       request_out_noc1_val
    ,output logic   [NOC1_DATA_W-1:0]   request_out_noc1_data
    ,input  logic                       out_request_noc1_rdy
);
    
    logic                               ctrl_datap_store_new_flow;
    logic                               ctrl_datap_store_notif;
    logic                               ctrl_datap_store_req;
    logic                               ctrl_datap_store_meta;
    logic                               ctrl_datap_rx_notif_req;
    logic                               ctrl_datap_make_req;
    tracker_req_type                    ctrl_datap_req_type;
    logic                               ctrl_datap_output_len;
    
    requester_input                     datap_requester_req;

    logic   [NOC0_DATA_W-1:0]           requester_datap_resp_data;

    logic                               ctrl_rd_buf_req_val;
    logic                               rd_buf_ctrl_req_rdy;
    logic   [FLOWID_W-1:0]              datap_rd_buf_req_flowid;
    logic   [RX_PAYLOAD_PTR_W-1:0]      datap_rd_buf_req_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_rd_buf_req_size;
    
    logic                               rd_buf_ctrl_resp_data_val;
    logic                               ctrl_rd_buf_resp_data_rdy;
    logic   [NOC0_DATA_W-1:0]           rd_buf_datap_resp_data;
    logic                               rd_buf_datap_resp_data_last;
    logic   [NOC0_PADBYTES_W-1:0]       rd_buf_datap_resp_data_padbytes;
    
    logic                               ctrl_wr_buf_req_val;
    logic                               wr_buf_ctrl_req_rdy;
    logic   [FLOWID_W-1:0]              datap_wr_buf_req_flowid;
    logic   [TX_PAYLOAD_PTR_W-1:0]      datap_wr_buf_req_wr_ptr;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_wr_buf_req_size;

    logic   [NOC0_DATA_W-1:0]           datap_wr_buf_req_data;
    logic                               ctrl_wr_buf_req_data_last;
    logic                               ctrl_wr_buf_req_data_val;
    logic                               wr_buf_ctrl_req_data_rdy;
    
    logic                               wr_buf_ctrl_req_done;
    logic                               ctrl_wr_buf_done_rdy;

    logic                               rd_req_noc_dtc_val;
    logic   [NOC0_DATA_W-1:0]           rd_req_noc_dtc_data;
    logic                               noc_dtc_rd_req_rdy;
    
    logic                               app_notif_noc_dtc_val;
    logic   [NOC0_DATA_W-1:0]           app_notif_noc_dtc_data;
    logic                               noc_dtc_app_notif_rdy;
    
    logic                               noc_ctd_app_notif_val;
    logic   [NOC0_DATA_W-1:0]           noc_ctd_app_notif_data;
    logic                               app_notif_noc_ctd_rdy;
    
    logic                               noc_ctd_wr_buf_val;
    logic   [NOC0_DATA_W-1:0]           noc_ctd_wr_buf_data;
    logic                               wr_buf_noc_ctd_rdy;

    stats_requester #(
         .NOC_DATA_W    (NOC0_DATA_W    )
        ,.NOC1_DATA_W   (NOC1_DATA_W    )
        ,.SRC_X         (SRC_X          )
        ,.SRC_Y         (SRC_Y          )
    ) requester (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_requester_hdr_val     (ctrl_requester_hdr_val     )
        ,.src_requester_req         (datap_requester_req        )
        ,.requester_src_hdr_rdy     (requester_ctrl_hdr_rdy     )

        ,.requester_src_resp_val    (requester_ctrl_resp_val    )
        ,.requester_src_resp_data   (requester_datap_resp_data  )
        ,.requester_src_resp_last   (requester_ctrl_resp_last   )
        ,.src_requester_resp_rdy    (ctrl_requester_resp_rdy    )

        ,.requester_noc_val         (request_out_noc1_val       )
        ,.requester_noc_data        (request_out_noc1_data      )
        ,.noc_requester_rdy         (out_request_noc1_rdy       )

        ,.noc_requester_val         (in_request_noc1_val        )
        ,.noc_requester_data        (in_request_noc1_data       )
        ,.requester_noc_rdy         (request_in_noc1_rdy        )
    );
    

    stats_manager_datap #(
         .NOC0_DATA_W   (NOC0_DATA_W    )
        ,.NOC1_DATA_W   (NOC1_DATA_W    )
        ,.SRC_X         (SRC_X          )
        ,.SRC_Y         (SRC_Y          )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.in_manager_noc0_data              (in_manager_noc0_data           )
                                                                            
        ,.in_manager_notif_noc1_data        (noc_ctd_app_notif_data         )
                                                                            
        ,.manager_out_notif_noc1_data       (app_notif_noc_dtc_data         )
    
        ,.ctrl_datap_store_new_flow         (ctrl_datap_store_new_flow      )
        ,.ctrl_datap_store_notif            (ctrl_datap_store_notif         )
        ,.ctrl_datap_store_req              (ctrl_datap_store_req           )
        ,.ctrl_datap_store_meta             (ctrl_datap_store_meta          )
        ,.ctrl_datap_rx_notif_req           (ctrl_datap_rx_notif_req        )
        ,.ctrl_datap_make_req               (ctrl_datap_make_req            )
        ,.ctrl_datap_req_type               (ctrl_datap_req_type            )
        ,.ctrl_datap_output_len             (ctrl_datap_output_len          )
                                                                            
        ,.datap_requester_req               (datap_requester_req            )
                                                                            
        ,.requester_datap_resp_data         (requester_datap_resp_data      )
        ,.requester_datap_resp_data_last    (requester_ctrl_resp_last       )
                                                                            
        ,.datap_rd_buf_req_flowid           (datap_rd_buf_req_flowid        )
        ,.datap_rd_buf_req_offset           (datap_rd_buf_req_offset        )
        ,.datap_rd_buf_req_size             (datap_rd_buf_req_size          )
                                                                            
        ,.rd_buf_datap_resp_data            (rd_buf_datap_resp_data         )
        ,.rd_buf_datap_resp_data_last       (rd_buf_datap_resp_data_last    )
        ,.rd_buf_datap_resp_data_padbytes   (rd_buf_datap_resp_data_padbytes)
                                                                            
        ,.datap_wr_buf_req_flowid           (datap_wr_buf_req_flowid        )
        ,.datap_wr_buf_req_wr_ptr           (datap_wr_buf_req_wr_ptr        )
        ,.datap_wr_buf_req_size             (datap_wr_buf_req_size          )
                                                                            
        ,.datap_wr_buf_req_data             (datap_wr_buf_req_data          )
    );

    stats_manager_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.in_manager_noc0_val           (in_manager_noc0_val        )
        ,.manager_in_noc0_rdy           (manager_in_noc0_rdy        )
                                                                    
        ,.in_manager_notif_noc1_val     (noc_ctd_app_notif_val      )
        ,.manager_in_notif_noc1_rdy     (app_notif_noc_ctd_rdy      )
                                                                    
        ,.manager_out_notif_noc1_val    (app_notif_noc_dtc_val      )
        ,.out_manager_notif_noc1_rdy    (noc_dtc_app_notif_rdy      )
                                                                    
        ,.ctrl_datap_store_new_flow     (ctrl_datap_store_new_flow  )
        ,.ctrl_datap_store_notif        (ctrl_datap_store_notif     )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req       )
        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta      )
        ,.ctrl_datap_rx_notif_req       (ctrl_datap_rx_notif_req    )
        ,.ctrl_datap_make_req           (ctrl_datap_make_req        )
        ,.ctrl_datap_req_type           (ctrl_datap_req_type        )
        ,.ctrl_datap_output_len         (ctrl_datap_output_len      )
                                                                    
        ,.ctrl_requester_hdr_val        (ctrl_requester_hdr_val     )
        ,.requester_ctrl_hdr_rdy        (requester_ctrl_hdr_rdy     )
                                                                    
        ,.requester_ctrl_resp_val       (requester_ctrl_resp_val    )
        ,.requester_ctrl_resp_last      (requester_ctrl_resp_last   )
        ,.ctrl_requester_resp_rdy       (ctrl_requester_resp_rdy    )
                                                                    
        ,.ctrl_rd_buf_req_val           (ctrl_rd_buf_req_val        )
        ,.rd_buf_ctrl_req_rdy           (rd_buf_ctrl_req_rdy        )
                                                                    
        ,.rd_buf_ctrl_resp_data_val     (rd_buf_ctrl_resp_data_val  )
        ,.rd_buf_ctrl_resp_data_last    (rd_buf_ctrl_resp_data_last )
        ,.ctrl_rd_buf_resp_data_rdy     (ctrl_rd_buf_resp_data_rdy  )
                                                                    
        ,.ctrl_wr_buf_req_val           (ctrl_wr_buf_req_val        )
        ,.wr_buf_ctrl_req_rdy           (wr_buf_ctrl_req_rdy        )
                                                                    
        ,.ctrl_wr_buf_req_data_val      (ctrl_wr_buf_req_data_val   )
        ,.ctrl_wr_buf_req_data_last     (ctrl_wr_buf_req_data_last  )
        ,.wr_buf_ctrl_req_data_rdy      (wr_buf_ctrl_req_data_rdy   )
        
        ,.wr_buf_ctrl_req_done          (wr_buf_ctrl_req_done       )
        ,.ctrl_wr_buf_done_rdy          (ctrl_wr_buf_done_rdy       )
    );

    

    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W(TCP_EXTRA_W    )
    ) rx_ptr_if_ctd (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (in_manager_notif_noc1_val  )
        ,.src_noc_ctd_data  (in_manager_notif_noc1_data )
        ,.noc_ctd_src_rdy   (manager_in_notif_noc1_rdy  )
    
        ,.noc_ctd_dst_val   (noc_ctd_app_notif_val      )
        ,.noc_ctd_dst_data  (noc_ctd_app_notif_data     )
        ,.dst_noc_ctd_rdy   (app_notif_noc_ctd_rdy      )
    );
    
    extra_hdr_noc_data_to_ctrl #(
        .EXTRA_W    (TCP_EXTRA_W    )
    ) ptr_if_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (app_notif_noc_dtc_val          )
        ,.src_noc_dtc_data  (app_notif_noc_dtc_data         )
        ,.noc_dtc_src_rdy   (noc_dtc_app_notif_rdy          )
    
        ,.noc_dtc_dst_val   (manager_out_notif_noc1_val     )
        ,.noc_dtc_dst_data  (manager_out_notif_noc1_data    )
        ,.dst_noc_dtc_rdy   (notif_manager_out_noc1_rdy     )
    );
    
    extra_hdr_noc_data_to_ctrl #(
        .EXTRA_W    (DRAM_REQ_W )
    ) rd_req_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (rd_req_noc_dtc_val             )
        ,.src_noc_dtc_data  (rd_req_noc_dtc_data            )
        ,.noc_dtc_src_rdy   (noc_dtc_rd_req_rdy             )
    
        ,.noc_dtc_dst_val   (rd_buf_out_noc1_val            )
        ,.noc_dtc_dst_data  (rd_buf_out_noc1_data           )
        ,.dst_noc_dtc_rdy   (out_rd_buf_noc1_rdy            )
    );

    rd_circ_buf_new #(
         .BUF_PTR_W     (RX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (RX_DST_DRAM_X      )
        ,.DST_DRAM_Y    (RX_DST_DRAM_Y      )
        ,.FBITS         (RX_IF_FBITS        )
    ) circ_buf_reader (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_buf_noc0_val           (rd_req_noc_dtc_val               )
        ,.rd_buf_noc0_data          (rd_req_noc_dtc_data              )
        ,.noc0_rd_buf_rdy           (noc_dtc_rd_req_rdy               )
       
        ,.noc0_rd_buf_val           (in_rd_buf_noc0_val               )
        ,.noc0_rd_buf_data          (in_rd_buf_noc0_data              )
        ,.rd_buf_noc0_rdy           (rd_buf_in_noc0_rdy               )
    
        ,.src_rd_buf_req_val        (ctrl_rd_buf_req_val              )
        ,.src_rd_buf_req_flowid     (datap_rd_buf_req_flowid          )
        ,.src_rd_buf_req_offset     (datap_rd_buf_req_offset          )
        ,.src_rd_buf_req_size       (datap_rd_buf_req_size            )
        ,.rd_buf_src_req_rdy        (rd_buf_ctrl_req_rdy              )
    
        ,.rd_buf_src_data_val       (rd_buf_ctrl_resp_data_val        )
        ,.rd_buf_src_data           (rd_buf_datap_resp_data           )
        ,.rd_buf_src_data_last      (rd_buf_datap_resp_data_last      )
        ,.rd_buf_src_data_padbytes  (rd_buf_datap_resp_data_padbytes  )
        ,.src_rd_buf_data_rdy       (ctrl_rd_buf_resp_data_rdy        )
    );
    
    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W    (DRAM_REQ_W )
    ) wr_buf (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (in_wr_buf_noc1_val     )
        ,.src_noc_ctd_data  (in_wr_buf_noc1_data    )
        ,.noc_ctd_src_rdy   (wr_buf_in_noc1_rdy     )
    
        ,.noc_ctd_dst_val   (noc_ctd_wr_buf_val     )
        ,.noc_ctd_dst_data  (noc_ctd_wr_buf_data    ) 
        ,.dst_noc_ctd_rdy   (wr_buf_noc_ctd_rdy     )
    );

    wr_circ_buf #(
         .BUF_PTR_W     (TX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (TX_DST_DRAM_X      )
        ,.DST_DRAM_Y    (TX_DST_DRAM_Y      )
        ,.FBITS         (TX_IF_FBITS        )
    ) wr_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_buf_noc_req_noc_val    (wr_buf_out_noc0_val        )
        ,.wr_buf_noc_req_noc_data   (wr_buf_out_noc0_data       )
        ,.noc_wr_buf_req_noc_rdy    (out_wr_buf_noc0_rdy        )
        
        ,.noc_wr_buf_resp_noc_val   (noc_ctd_wr_buf_val         )
        ,.noc_wr_buf_resp_noc_data  (noc_ctd_wr_buf_data        )
        ,.wr_buf_noc_resp_noc_rdy   (wr_buf_noc_ctd_rdy         )
    
        ,.src_wr_buf_req_val        (ctrl_wr_buf_req_val        )
        ,.src_wr_buf_req_flowid     (datap_wr_buf_req_flowid    )
        ,.src_wr_buf_req_wr_ptr     (datap_wr_buf_req_wr_ptr    )
        ,.src_wr_buf_req_size       (datap_wr_buf_req_size      )
        ,.wr_buf_src_req_rdy        (wr_buf_ctrl_req_rdy        )
    
        ,.src_wr_buf_req_data_val   (ctrl_wr_buf_req_data_val   )
        ,.src_wr_buf_req_data       (datap_wr_buf_req_data      )
        ,.wr_buf_src_req_data_rdy   (wr_buf_ctrl_req_data_rdy   )
        
        ,.wr_buf_src_req_done       (wr_buf_ctrl_req_done       )
        ,.src_wr_buf_done_rdy       (ctrl_wr_buf_done_rdy       )
    );

endmodule
