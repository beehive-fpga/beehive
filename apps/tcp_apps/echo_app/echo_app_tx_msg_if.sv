`include "echo_app_defs.svh"
module echo_app_tx_msg_if #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter DST_BUF_X = -1
    ,parameter DST_BUF_Y = -1
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

    ,input  logic                           rx_if_tx_if_msg_val
    ,input          tx_msg_struct           rx_if_tx_if_msg_data
    ,output logic                           tx_if_rx_if_msg_rdy
);
    
    logic                               ctrl_wr_buf_req_val;
    logic   [FLOWID_W-1:0]              datap_wr_buf_req_flowid;
    logic   [TX_PAYLOAD_PTR_W:0]        datap_wr_buf_req_wr_ptr;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_wr_buf_req_size;
    logic                               wr_buf_ctrl_req_rdy;

    logic                               ctrl_wr_buf_req_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]       datap_wr_buf_req_data;
    logic                               datap_wr_buf_req_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   datap_wr_buf_req_data_padbytes;
    logic                               wr_buf_ctrl_req_data_rdy;

    logic                               wr_buf_ctrl_req_done;
    logic                               ctrl_wr_buf_done_rdy;

    logic                               ctrl_datap_store_inputs;
    logic                               ctrl_datap_decr_bytes_left;
    buf_mux_sel_e                       ctrl_datap_buf_mux_sel;
    logic                               ctrl_datap_store_notif;

    logic                               datap_ctrl_last_wr;

    logic                               echo_app_incr_req_done;
    
    logic                               noc_ctd_echo_app_stats_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctd_echo_app_stats_data;
    logic                               echo_app_stats_noc_ctd_rdy;
    
    logic                               echo_app_stats_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       echo_app_stats_noc_dtc_data;
    logic                               noc_dtc_echo_app_stats_rdy;


    echo_app_tx_msg_if_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tx_app_noc_vrtoc_data             (tx_app_noc_vrtoc_data          )

        ,.noc_ctovr_tx_app_data             (noc_ctovr_tx_app_data          )

        ,.rx_if_tx_if_msg_data              (rx_if_tx_if_msg_data           )

        ,.datap_wr_buf_req_flowid           (datap_wr_buf_req_flowid        )
        ,.datap_wr_buf_req_wr_ptr           (datap_wr_buf_req_wr_ptr        )
        ,.datap_wr_buf_req_size             (datap_wr_buf_req_size          )

        ,.datap_wr_buf_req_data             (datap_wr_buf_req_data          )
        ,.datap_wr_buf_req_data_last        (datap_wr_buf_req_data_last     )
        ,.datap_wr_buf_req_data_padbytes    (datap_wr_buf_req_data_padbytes )

        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs        )
        ,.ctrl_datap_decr_bytes_left        (ctrl_datap_decr_bytes_left     )
        ,.ctrl_datap_buf_mux_sel            (ctrl_datap_buf_mux_sel         )
        ,.ctrl_datap_store_notif            (ctrl_datap_store_notif         )

        ,.datap_ctrl_last_wr                (datap_ctrl_last_wr             )
    );

    echo_app_tx_msg_if_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tx_app_noc_vrtoc_val          (tx_app_noc_vrtoc_val       )
        ,.noc_vrtoc_tx_app_rdy          (noc_vrtoc_tx_app_rdy       )

        ,.noc_ctovr_tx_app_val          (noc_ctovr_tx_app_val       )
        ,.tx_app_noc_ctovr_rdy          (tx_app_noc_ctovr_rdy       )

        ,.rx_if_tx_if_msg_val           (rx_if_tx_if_msg_val        )
        ,.tx_if_rx_if_msg_rdy           (tx_if_rx_if_msg_rdy        )

        ,.ctrl_wr_buf_req_val           (ctrl_wr_buf_req_val        )
        ,.wr_buf_ctrl_req_rdy           (wr_buf_ctrl_req_rdy        )

        ,.ctrl_wr_buf_req_data_val      (ctrl_wr_buf_req_data_val   )
        ,.wr_buf_ctrl_req_data_rdy      (wr_buf_ctrl_req_data_rdy   )

        ,.wr_buf_ctrl_req_done          (wr_buf_ctrl_req_done       )
        ,.ctrl_wr_buf_done_rdy          (ctrl_wr_buf_done_rdy       )

        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs    )
        ,.ctrl_datap_decr_bytes_left    (ctrl_datap_decr_bytes_left )
        ,.ctrl_datap_buf_mux_sel        (ctrl_datap_buf_mux_sel     )
        ,.ctrl_datap_store_notif        (ctrl_datap_store_notif     )

        ,.datap_ctrl_last_wr            (datap_ctrl_last_wr         )

        ,.echo_app_incr_req_done        (echo_app_incr_req_done     )
    );

    wr_circ_buf #(
         .BUF_PTR_W     (TX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (DST_BUF_X          )
        ,.DST_DRAM_Y    (DST_BUF_Y          )
        ,.FBITS         (TX_BUF_IF_FBITS    )
    ) wr_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_buf_noc_req_noc_val   (tx_buf_noc0_vrtoc_val      )
        ,.wr_buf_noc_req_noc_data  (tx_buf_noc0_vrtoc_data     )
        ,.noc_wr_buf_req_noc_rdy   (noc0_vrtoc_tx_buf_rdy      )
        
        ,.noc_wr_buf_resp_noc_val  (noc_wr_resp_val            )
        ,.noc_wr_buf_resp_noc_data (noc_wr_resp_data           )
        ,.wr_buf_noc_resp_noc_rdy  (wr_resp_noc_rdy            )
    
        ,.src_wr_buf_req_val        (ctrl_wr_buf_req_val        )
        ,.src_wr_buf_req_flowid     (datap_wr_buf_req_flowid    )
        ,.src_wr_buf_req_wr_ptr     (datap_wr_buf_req_wr_ptr[TX_PAYLOAD_PTR_W-1:0])
        ,.src_wr_buf_req_size       (datap_wr_buf_req_size      )
        ,.wr_buf_src_req_rdy        (wr_buf_ctrl_req_rdy        )
    
        ,.src_wr_buf_req_data_val   (ctrl_wr_buf_req_data_val   )
        ,.src_wr_buf_req_data       (datap_wr_buf_req_data      )
        ,.wr_buf_src_req_data_rdy   (wr_buf_ctrl_req_data_rdy   )
        
        ,.wr_buf_src_req_done       (wr_buf_ctrl_req_done       )
        ,.src_wr_buf_done_rdy       (ctrl_wr_buf_done_rdy       )
    );

generate
    if (NOC1_DATA_W != `NOC_DATA_WIDTH) begin
        noc_ctrl_to_data ctd (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_noc_ctd_val   (ctovr_echo_app_stats_val       )
            ,.src_noc_ctd_data  (ctovr_echo_app_stats_data      )
            ,.noc_ctd_src_rdy   (echo_app_stats_ctovr_rdy       )
        
            ,.noc_ctd_dst_val   (noc_ctd_echo_app_stats_val     )
            ,.noc_ctd_dst_data  (noc_ctd_echo_app_stats_data    )
            ,.dst_noc_ctd_rdy   (echo_app_stats_noc_ctd_rdy     )
        );
    end
    else begin
        assign noc_ctd_echo_app_stats_val = ctovr_echo_app_stats_val;
        assign noc_ctd_echo_app_stats_data = ctovr_echo_app_stats_data;
        assign echo_app_stats_ctovr_rdy = echo_app_stats_noc_ctd_rdy;
    end
endgenerate


    echo_app_stats_log #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) app_stats_log (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.echo_app_incr_req_done    (echo_app_incr_req_done         )
                                                                                 
        ,.ctovr_echo_app_stats_val  (noc_ctd_echo_app_stats_val     )
        ,.ctovr_echo_app_stats_data (noc_ctd_echo_app_stats_data    )
        ,.echo_app_stats_ctovr_rdy  (echo_app_stats_noc_ctd_rdy     )
                                                                          
        ,.echo_app_stats_vrtoc_val  (echo_app_stats_noc_dtc_val     )
        ,.echo_app_stats_vrtoc_data (echo_app_stats_noc_dtc_data    )
        ,.vrtoc_echo_app_stats_rdy  (noc_dtc_echo_app_stats_rdy     )
    );

generate
    if (NOC2_DATA_W != `NOC_DATA_WIDTH) begin
        noc_data_to_ctrl dtc (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_noc_dtc_val   (echo_app_stats_noc_dtc_val     )
            ,.src_noc_dtc_data  (echo_app_stats_noc_dtc_data    )
            ,.noc_dtc_src_rdy   (noc_dtc_echo_app_stats_rdy     )
        
            ,.noc_dtc_dst_val   (echo_app_stats_vrtoc_val       )
            ,.noc_dtc_dst_data  (echo_app_stats_vrtoc_data      )
            ,.dst_noc_dtc_rdy   (vrtoc_echo_app_stats_rdy       )
        );
    end
    else begin
        assign echo_app_stats_vrtoc_val = echo_app_stats_noc_dtc_val;
        assign echo_app_stats_vrtoc_data = echo_app_stats_noc_dtc_data;
        assign noc_dtc_echo_app_stats_rdy = vrtoc_echo_app_stats_rdy;
    end
endgenerate

endmodule
