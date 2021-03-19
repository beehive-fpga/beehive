// TODO: finish piping wire modifications up thru wrapper from TX

module open_loop_tx_engine 
import tcp_pkg::*;
import open_loop_pkg::*;
import tx_open_loop_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter DST_BUF_X = -1
    ,parameter DST_BUF_Y = -1
)(
     input clk
    ,input rst
    
    ,input                                  send_q_empty
    ,input  send_q_struct                   send_q_rd_data
    ,output logic                           send_q_rd_req

    ,output logic                           send_q_wr_req
    ,output send_q_struct                   send_q_wr_data
    ,input  logic                           send_q_full

    ,output logic                           tx_engine_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tx_engine_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_tx_engine_rdy

    ,input  logic                           noc_ctovr_tx_engine_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_tx_engine_data
    ,output logic                           tx_engine_noc_ctovr_rdy
    
    ,input  logic                           ctrl_noc_tx_engine_val
    ,input  logic   [`CTRL_NOC1_DATA_W-1:0] ctrl_noc_tx_engine_data
    ,output logic                           tx_engine_ctrl_noc_rdy

    ,output logic                           tx_engine_ctrl_noc_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] tx_engine_ctrl_noc_data
    ,input  logic                           ctrl_noc_tx_engine_rdy
    
    ,output logic                           tx_app_state_rd_req_val
    ,output logic   [FLOWID_W-1:0]          tx_app_state_rd_flowid
    ,input  logic                           app_state_tx_rd_req_rdy

    ,output logic                           tx_app_state_wr_req_val
    ,output app_cntxt_struct                tx_app_state_wr_data
    ,output logic   [FLOWID_W-1:0]          tx_app_state_wr_flowid

    ,input  logic                           app_state_tx_rd_resp_val
    ,input  app_cntxt_struct                app_state_tx_rd_data
    ,output logic                           tx_app_state_rd_resp_rdy

    ,input                                  setup_done
);                                                       
    
    logic                               tx_ptr_if_ctrl_noc_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     tx_ptr_if_ctrl_noc_data;
    logic                               ctrl_noc_tx_ptr_if_rdy;
    
    logic                               ctrl_noc_tx_ptr_if_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     ctrl_noc_tx_ptr_if_data;
    logic                               tx_ptr_if_ctrl_noc_rdy;
    
    logic                               ctrl_noc_tx_wr_buf_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     ctrl_noc_tx_wr_buf_data;
    logic                               tx_wr_buf_ctrl_noc_rdy;
                                                         
    logic                               ctrl_wr_buf_req_val;
    logic                               wr_buf_ctrl_req_rdy;
    logic   [FLOWID_W-1:0]              datap_wr_buf_req_flowid;
    logic   [TX_PAYLOAD_PTR_W-1:0]      datap_wr_buf_req_wr_ptr;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_wr_buf_req_size;
                                                     
    logic                               ctrl_wr_buf_req_data_val;
    logic                               wr_buf_ctrl_req_data_rdy;
    logic   [`NOC_DATA_WIDTH-1:0]       datap_wr_buf_req_data;
    logic                               datap_wr_buf_req_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   datap_wr_buf_req_data_padbytes;
    
    logic                               wr_buf_ctrl_req_done;
    logic                               ctrl_wr_buf_done_rdy;
    
    logic                               noc_ctd_wr_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctd_wr_buf_data;
    logic                               wr_buf_noc_ctd_rdy;
    
    logic                               noc_ctd_ptr_if_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctd_ptr_if_data;
    logic                               ptr_if_noc_ctd_rdy;
    
    logic                               ptr_if_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       ptr_if_noc_dtc_data;
    logic                               noc_dtc_ptr_if_rdy;
    
    logic                               ctrl_datap_store_inputs;
    logic                               ctrl_datap_store_app_state;
    logic                               ctrl_datap_decr_bytes_left;
    logic                               ctrl_datap_store_notif;
    tx_out_mux_sel_e                    ctrl_datap_out_mux_sel;
    
    logic                               datap_ctrl_last_wr;
    logic                               datap_ctrl_last_pkt;
    flag_e                              datap_ctrl_should_copy;
    
    logic                               tx_app_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       tx_app_noc_vrtoc_data;
    logic                               noc_vrtoc_tx_app_rdy;

    logic                               noc_ctovr_tx_app_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_tx_app_data;
    logic                               tx_app_noc_ctovr_rdy;

    logic                               tx_buf_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       tx_buf_noc_vrtoc_data;
    logic                               noc_vrtoc_tx_buf_rdy;

    logic                               noc_ctovr_tx_buf_val;
    logic                               tx_buf_noc_ctovr_rdy;
    
    tx_noc_sel_e                        noc_unit_sel;

    assign noc_ctovr_tx_app_data = noc_ctovr_tx_engine_data;

    // mux the noc ports between the two units
    always_comb begin
        tx_engine_noc_vrtoc_val = 1'b0;
        tx_engine_noc_ctovr_rdy = 1'b0;

        noc_ctovr_tx_app_val = 1'b0;
        noc_ctovr_tx_buf_val = 1'b0;
        noc_vrtoc_tx_buf_rdy = 1'b0;
        noc_vrtoc_tx_app_rdy = 1'b0;

        if (noc_unit_sel == BUF_WRITE) begin
            tx_engine_noc_vrtoc_val = tx_buf_noc_vrtoc_val;
            tx_engine_noc_vrtoc_data = tx_buf_noc_vrtoc_data;
            noc_vrtoc_tx_buf_rdy = noc_vrtoc_tx_engine_rdy;

        end
        else begin
            tx_engine_noc_vrtoc_val = tx_app_noc_vrtoc_val;
            tx_engine_noc_vrtoc_data = tx_app_noc_vrtoc_data;
            noc_vrtoc_tx_app_rdy = noc_vrtoc_tx_engine_rdy;

            noc_ctovr_tx_app_val = noc_ctovr_tx_engine_val;
            tx_engine_noc_ctovr_rdy = tx_app_noc_ctovr_rdy;
        end
    end
    
    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W    (DRAM_REQ_W )
    ) wr_buf (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (ctrl_noc_tx_wr_buf_val     )
        ,.src_noc_ctd_data  (ctrl_noc_tx_wr_buf_data    )
        ,.noc_ctd_src_rdy   (tx_wr_buf_ctrl_noc_rdy     )
    
        ,.noc_ctd_dst_val   (noc_ctd_wr_buf_val         )
        ,.noc_ctd_dst_data  (noc_ctd_wr_buf_data        ) 
        ,.dst_noc_ctd_rdy   (wr_buf_noc_ctd_rdy         )
    );
    
    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W    (TCP_EXTRA_W    )
    ) ptr_if_ctd (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (ctrl_noc_tx_ptr_if_val     )
        ,.src_noc_ctd_data  (ctrl_noc_tx_ptr_if_data    )
        ,.noc_ctd_src_rdy   (tx_ptr_if_ctrl_noc_rdy     )
    
        ,.noc_ctd_dst_val   (noc_ctd_ptr_if_val         )
        ,.noc_ctd_dst_data  (noc_ctd_ptr_if_data        ) 
        ,.dst_noc_ctd_rdy   (ptr_if_noc_ctd_rdy         )
    );
    
    assign ctrl_noc_tx_ptr_if_data = ctrl_noc_tx_engine_data;
    assign ctrl_noc_tx_wr_buf_data = ctrl_noc_tx_engine_data;

    always_comb begin
        ctrl_noc_tx_wr_buf_val = 1'b0;
        ctrl_noc_tx_ptr_if_val = 1'b0;

        if (noc_unit_sel == BUF_WRITE) begin
            ctrl_noc_tx_wr_buf_val = ctrl_noc_tx_engine_val;
            tx_engine_ctrl_noc_rdy = tx_wr_buf_ctrl_noc_rdy;
        end
        else begin
            ctrl_noc_tx_ptr_if_val = ctrl_noc_tx_engine_val;
            tx_engine_ctrl_noc_rdy = tx_ptr_if_ctrl_noc_rdy;
        end
    end
    
    extra_hdr_noc_data_to_ctrl #(
        .EXTRA_W    (TCP_EXTRA_W    )
    ) ptr_if_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (ptr_if_noc_dtc_val         )
        ,.src_noc_dtc_data  (ptr_if_noc_dtc_data        )
        ,.noc_dtc_src_rdy   (noc_dtc_ptr_if_rdy         )
    
        ,.noc_dtc_dst_val   (tx_ptr_if_ctrl_noc_val     )
        ,.noc_dtc_dst_data  (tx_ptr_if_ctrl_noc_data    )
        ,.dst_noc_dtc_rdy   (ctrl_noc_tx_ptr_if_rdy     )
    );

    assign tx_engine_ctrl_noc_data = tx_ptr_if_ctrl_noc_data;

    tx_engine_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.send_q_rd_data                    (send_q_rd_data                 )
                                                                            
        ,.tx_app_noc_vrtoc_data             (tx_app_noc_vrtoc_data          )
                                                                            
        ,.noc_ctovr_tx_app_data             (noc_ctovr_tx_app_data          )
    
        ,.tx_ptr_if_ctrl_noc_data           (ptr_if_noc_dtc_data            )
                                             
        ,.ctrl_noc_tx_ptr_if_data           (noc_ctd_ptr_if_data            )
                                                                            
        ,.datap_wr_buf_req_flowid           (datap_wr_buf_req_flowid        )
        ,.datap_wr_buf_req_wr_ptr           (datap_wr_buf_req_wr_ptr        )
        ,.datap_wr_buf_req_size             (datap_wr_buf_req_size          )
                                                                            
        ,.datap_wr_buf_req_data             (datap_wr_buf_req_data          )
        ,.datap_wr_buf_req_data_last        (datap_wr_buf_req_data_last     )
        ,.datap_wr_buf_req_data_padbytes    (datap_wr_buf_req_data_padbytes )
                                                                            
        ,.tx_app_state_rd_flowid            (tx_app_state_rd_flowid         )
        ,.tx_app_state_wr_flowid            (tx_app_state_wr_flowid         )
                                                                            
        ,.app_state_tx_rd_data              (app_state_tx_rd_data           )
        ,.tx_app_state_wr_data              (tx_app_state_wr_data           )
                                                                            
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs        )
        ,.ctrl_datap_store_app_state        (ctrl_datap_store_app_state     )
        ,.ctrl_datap_decr_bytes_left        (ctrl_datap_decr_bytes_left     )
        ,.ctrl_datap_store_notif            (ctrl_datap_store_notif         )
        ,.ctrl_datap_out_mux_sel            (ctrl_datap_out_mux_sel         )
                                                                            
        ,.datap_ctrl_last_wr                (datap_ctrl_last_wr             )
        ,.datap_ctrl_last_pkt               (datap_ctrl_last_pkt            )
        ,.datap_ctrl_should_copy            (datap_ctrl_should_copy         )
    );

    assign tx_engine_ctrl_noc_val = tx_ptr_if_ctrl_noc_val;
    assign ctrl_noc_tx_ptr_if_rdy = ctrl_noc_tx_engine_rdy;

    tx_engine_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.send_q_empty                  (send_q_empty               )
        ,.send_q_rd_data                (send_q_rd_data             )
        ,.send_q_rd_req                 (send_q_rd_req              )
                                                                    
        ,.send_q_wr_req                 (send_q_wr_req              )
        ,.send_q_wr_data                (send_q_wr_data             )
        ,.send_q_full                   (send_q_full                )
                                                                    
        ,.tx_app_noc_vrtoc_val          (tx_app_noc_vrtoc_val       )
        ,.noc_vrtoc_tx_app_rdy          (noc_vrtoc_tx_app_rdy       )
                                                                    
        ,.noc_ctovr_tx_app_val          (noc_ctovr_tx_app_val       )
        ,.tx_app_noc_ctovr_rdy          (tx_app_noc_ctovr_rdy       )
    
        ,.tx_ptr_if_ctrl_noc_val        (ptr_if_noc_dtc_val         )
        ,.ctrl_noc_tx_ptr_if_rdy        (noc_dtc_ptr_if_rdy         )
                                         
        ,.ctrl_noc_tx_ptr_if_val        (noc_ctd_ptr_if_val         )
        ,.tx_ptr_if_ctrl_noc_rdy        (ptr_if_noc_ctd_rdy         )
                                                                    
        ,.ctrl_wr_buf_req_val           (ctrl_wr_buf_req_val        )
        ,.wr_buf_ctrl_req_rdy           (wr_buf_ctrl_req_rdy        )
                                                                    
        ,.ctrl_wr_buf_req_data_val      (ctrl_wr_buf_req_data_val   )
        ,.wr_buf_ctrl_req_data_rdy      (wr_buf_ctrl_req_data_rdy   )
                                                                    
        ,.wr_buf_ctrl_req_done          (wr_buf_ctrl_req_done       )
        ,.ctrl_wr_buf_done_rdy          (ctrl_wr_buf_done_rdy       )
                                                                    
        ,.tx_app_state_rd_req_val       (tx_app_state_rd_req_val    )
        ,.app_state_tx_rd_req_rdy       (app_state_tx_rd_req_rdy    )
        ,.tx_app_state_wr_req_val       (tx_app_state_wr_req_val    )
                                                                    
        ,.app_state_tx_rd_resp_val      (app_state_tx_rd_resp_val   )
        ,.tx_app_state_rd_resp_rdy      (tx_app_state_rd_resp_rdy   )
                                                                    
        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs    )
        ,.ctrl_datap_store_app_state    (ctrl_datap_store_app_state )
        ,.ctrl_datap_decr_bytes_left    (ctrl_datap_decr_bytes_left )
        ,.ctrl_datap_store_notif        (ctrl_datap_store_notif     )
        ,.ctrl_datap_out_mux_sel        (ctrl_datap_out_mux_sel     )
                                                                    
        ,.datap_ctrl_last_wr            (datap_ctrl_last_wr         )
        ,.datap_ctrl_last_pkt           (datap_ctrl_last_pkt        )
        ,.datap_ctrl_should_copy        (datap_ctrl_should_copy     )
                                                                    
        ,.noc_unit_sel                  (noc_unit_sel               )
        ,.setup_done                    (setup_done                 )
    );
    
    wr_circ_buf #(
         .BUF_PTR_W     (TX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (DST_BUF_X          )
        ,.DST_DRAM_Y    (DST_BUF_Y          )
        ,.FBITS         (TX_IF_FBITS        )
    ) wr_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_buf_noc_req_noc_val    (tx_buf_noc_vrtoc_val       )
        ,.wr_buf_noc_req_noc_data   (tx_buf_noc_vrtoc_data      )
        ,.noc_wr_buf_req_noc_rdy    (noc_vrtoc_tx_engine_rdy    )
        
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
