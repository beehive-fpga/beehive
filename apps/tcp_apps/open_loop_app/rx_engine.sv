`include "noc_defs.vh"
module open_loop_rx_engine 
import tcp_pkg::*;
import beehive_tcp_msg::*;
import open_loop_pkg::*;
import rx_open_loop_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter DST_BUF_X = -1
    ,parameter DST_BUF_Y = -1
)(
     input clk
    ,input rst

    ,input                                  recv_q_empty
    ,input  logic   [FLOWID_W-1:0]          recv_q_rd_data
    ,output                                 recv_q_rd_req

    ,input  logic                           recv_q_full
    ,output logic                           recv_q_wr_req
    ,output logic   [FLOWID_W-1:0]          recv_q_wr_data

    ,output logic                           rx_engine_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rx_engine_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_rx_engine_rdy

    ,input  logic                           noc_ctovr_rx_engine_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_rx_engine_data
    ,output logic                           rx_engine_noc_ctovr_rdy 
    
    ,output logic                           rx_engine_ctrl_noc_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] rx_engine_ctrl_noc_data
    ,input  logic                           ctrl_noc_rx_engine_rdy

    ,input  logic                           ctrl_noc_rx_engine_val
    ,input  logic   [`CTRL_NOC1_DATA_W-1:0] ctrl_noc_rx_engine_data
    ,output logic                           rx_engine_ctrl_noc_rdy     
 
    ,output logic                           rx_app_state_rd_req_val
    ,output logic   [FLOWID_W-1:0]          rx_app_state_rd_flowid
    ,input  logic                           app_state_rx_rd_req_rdy

    ,output logic                           rx_app_state_wr_req_val
    ,output app_cntxt_struct                rx_app_state_wr_data
    ,output logic   [FLOWID_W-1:0]          rx_app_state_wr_flowid

    ,input  logic                           app_state_rx_rd_resp_val
    ,input  app_cntxt_struct                app_state_rx_rd_data
    ,output logic                           rx_app_state_rd_resp_rdy

    ,input                                  setup_done
);

    logic   [FLOWID_W-1:0]              datap_rd_buf_req_flowid;
    logic   [RX_PAYLOAD_PTR_W-1:0]      datap_rd_buf_req_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_rd_buf_req_size;
    
    logic   [`NOC_DATA_WIDTH-1:0]       rd_buf_datap_resp_data;
    logic                               rd_buf_datap_resp_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_buf_datap_resp_data_padbytes;
    
    logic                               ctrl_datap_store_inputs;
    logic                               ctrl_datap_store_app_state;
    logic                               ctrl_datap_store_notif;
    rx_out_mux_sel_e                    ctrl_datap_out_mux_sel;

    logic                               datap_ctrl_last_pkt;
    logic                               datap_ctrl_last_data;
    flag_e                              datap_ctrl_should_copy;
    
    logic                               ctrl_rd_buf_req_val;
    logic                               rd_buf_ctrl_req_rdy;

    logic                               rd_buf_ctrl_resp_data_val;
    logic                               ctrl_rd_buf_resp_data_rdy;

    rx_noc_sel_e                        noc_unit_sel;
    
    logic                               rx_app_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       rx_app_noc_vrtoc_data;
    logic                               noc_vrtoc_rx_app_rdy;

    logic                               noc_ctovr_rx_app_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_rx_app_data;
    logic                               rx_app_noc_ctovr_rdy;
    
    logic                               rx_buf_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       rx_buf_noc_vrtoc_data;
    logic                               noc_vrtoc_rx_buf_rdy;

    logic                               noc_ctovr_rx_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_rx_buf_data;
    logic                               rx_buf_noc_ctovr_rdy;
    
    logic                               noc_ctd_ptr_if_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctd_ptr_if_data;
    logic                               ptr_if_noc_ctd_rdy;
    
    logic                               ptr_if_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       ptr_if_noc_dtc_data;
    logic                               noc_dtc_ptr_if_rdy;
    
    logic                               rd_req_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_req_noc_dtc_data;
    logic                               noc_dtc_rd_req_rdy;
    
    logic                               ptr_dtc_merger_ctrl_noc_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     ptr_dtc_merger_ctrl_noc_data;
    logic                               ctrl_noc_ptr_dtc_merger_rdy;
    
    logic                               rd_dtc_merger_ctrl_noc_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     rd_dtc_merger_ctrl_noc_data;
    logic                               ctrl_noc_rd_dtc_merger_rdy;

    assign noc_ctovr_rx_app_data = noc_ctovr_rx_engine_data;
    assign noc_ctovr_rx_buf_data = noc_ctovr_rx_engine_data;

    always_comb begin
        noc_ctovr_rx_app_val = 1'b0;
        noc_ctovr_rx_buf_val = 1'b0;
        noc_vrtoc_rx_buf_rdy = 1'b0;
        noc_vrtoc_rx_app_rdy = 1'b0;

        if (noc_unit_sel == BUF_WRITE) begin
            rx_engine_noc_vrtoc_val = rx_buf_noc_vrtoc_val;
            rx_engine_noc_vrtoc_data = rx_buf_noc_vrtoc_data;
            noc_vrtoc_rx_buf_rdy = noc_vrtoc_rx_engine_rdy;

            noc_ctovr_rx_buf_val = noc_ctovr_rx_engine_val;
            rx_engine_noc_ctovr_rdy = rx_buf_noc_ctovr_rdy;
        end
        else begin
            rx_engine_noc_vrtoc_val = rx_app_noc_vrtoc_val;
            rx_engine_noc_vrtoc_data = rx_app_noc_vrtoc_data;
            noc_vrtoc_rx_app_rdy = noc_vrtoc_rx_engine_rdy;

            noc_ctovr_rx_app_val = noc_ctovr_rx_engine_val;
            rx_engine_noc_ctovr_rdy = rx_app_noc_ctovr_rdy;
        end
    end
    
    extra_hdr_noc_data_to_ctrl #(
        .EXTRA_W    (TCP_EXTRA_W    )
    ) ptr_if_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (ptr_if_noc_dtc_val             )
        ,.src_noc_dtc_data  (ptr_if_noc_dtc_data            )
        ,.noc_dtc_src_rdy   (noc_dtc_ptr_if_rdy             )
    
        ,.noc_dtc_dst_val   (ptr_dtc_merger_ctrl_noc_val    )
        ,.noc_dtc_dst_data  (ptr_dtc_merger_ctrl_noc_data   )
        ,.dst_noc_dtc_rdy   (ctrl_noc_ptr_dtc_merger_rdy    )
    );

    extra_hdr_noc_data_to_ctrl #(
        .EXTRA_W    (DRAM_REQ_W )
    ) rd_req_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (rd_req_noc_dtc_val             )
        ,.src_noc_dtc_data  (rd_req_noc_dtc_data            )
        ,.noc_dtc_src_rdy   (noc_dtc_rd_req_rdy             )
    
        ,.noc_dtc_dst_val   (rd_dtc_merger_ctrl_noc_val     )
        ,.noc_dtc_dst_data  (rd_dtc_merger_ctrl_noc_data    )
        ,.dst_noc_dtc_rdy   (ctrl_noc_rd_dtc_merger_rdy     )
    );

    beehive_noc_prio_merger #(
         .NOC_DATA_W        (`CTRL_NOC1_DATA_W  )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
        ,.MSG_LEN_HI        (CTRL_MSG_LEN_OFFSET)
        ,.num_sources       (2)
    ) ctrl_noc1_merger (
         .clk   (clk    )
        ,.rst_n (~rst   )
    
        ,.src0_merger_vr_noc_val    (ptr_dtc_merger_ctrl_noc_val    )
        ,.src0_merger_vr_noc_dat    (ptr_dtc_merger_ctrl_noc_data   )
        ,.merger_src0_vr_noc_rdy    (ctrl_noc_ptr_dtc_merger_rdy    )
    
        ,.src1_merger_vr_noc_val    (rd_dtc_merger_ctrl_noc_val     )
        ,.src1_merger_vr_noc_dat    (rd_dtc_merger_ctrl_noc_data    )
        ,.merger_src1_vr_noc_rdy    (ctrl_noc_rd_dtc_merger_rdy     )
    
        ,.src2_merger_vr_noc_val    ()
        ,.src2_merger_vr_noc_dat    ()
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ()
        ,.src3_merger_vr_noc_dat    ()
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ()
        ,.src4_merger_vr_noc_dat    ()
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (rx_engine_ctrl_noc_val         )
        ,.merger_dst_vr_noc_dat     (rx_engine_ctrl_noc_data        )
        ,.dst_merger_vr_noc_rdy     (ctrl_noc_rx_engine_rdy         )
    );
    
    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W    (TCP_EXTRA_W    )
    ) ptr_if_ctd (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (ctrl_noc_rx_engine_val     )
        ,.src_noc_ctd_data  (ctrl_noc_rx_engine_data    )
        ,.noc_ctd_src_rdy   (rx_engine_ctrl_noc_rdy     )
    
        ,.noc_ctd_dst_val   (noc_ctd_ptr_if_val         )
        ,.noc_ctd_dst_data  (noc_ctd_ptr_if_data        ) 
        ,.dst_noc_ctd_rdy   (ptr_if_noc_ctd_rdy         )
    );

    rx_engine_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.recv_q_rd_data                    (recv_q_rd_data                     )

        ,.recv_q_wr_data                    (recv_q_wr_data                     )

        ,.rx_app_noc_vrtoc_data             (rx_app_noc_vrtoc_data              )

        ,.noc_ctovr_rx_app_data             (noc_ctovr_rx_app_data              )
    
        ,.rx_engine_ctrl_noc_data           (ptr_if_noc_dtc_data                )
                                                                                
        ,.ctrl_noc_rx_engine_data           (noc_ctd_ptr_if_data                )

        ,.rx_app_state_rd_flowid            (rx_app_state_rd_flowid             )

        ,.rx_app_state_wr_data              (rx_app_state_wr_data               )
        ,.rx_app_state_wr_flowid            (rx_app_state_wr_flowid             )

        ,.app_state_rx_rd_data              (app_state_rx_rd_data               )

        ,.datap_rd_buf_req_flowid           (datap_rd_buf_req_flowid            )
        ,.datap_rd_buf_req_offset           (datap_rd_buf_req_offset            )
        ,.datap_rd_buf_req_size             (datap_rd_buf_req_size              )

        ,.rd_buf_datap_resp_data            (rd_buf_datap_resp_data             )
        ,.rd_buf_datap_resp_data_last       (rd_buf_datap_resp_data_last        )
        ,.rd_buf_datap_resp_data_padbytes   (rd_buf_datap_resp_data_padbytes    )

        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
        ,.ctrl_datap_store_app_state        (ctrl_datap_store_app_state         )
        ,.ctrl_datap_store_notif            (ctrl_datap_store_notif             )
        ,.ctrl_datap_out_mux_sel            (ctrl_datap_out_mux_sel             )

        ,.datap_ctrl_last_pkt               (datap_ctrl_last_pkt                )
        ,.datap_ctrl_last_data              (datap_ctrl_last_data               )
        ,.datap_ctrl_should_copy            (datap_ctrl_should_copy             )
    );

    rx_engine_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.recv_q_empty                  (recv_q_empty               )
        ,.recv_q_rd_req                 (recv_q_rd_req              )

        ,.recv_q_full                   (recv_q_full                )
        ,.recv_q_wr_req                 (recv_q_wr_req              )

        ,.rx_app_noc_vrtoc_val          (rx_app_noc_vrtoc_val       )
        ,.noc_vrtoc_rx_app_rdy          (noc_vrtoc_rx_app_rdy       )

        ,.noc_ctovr_rx_app_val          (noc_ctovr_rx_app_val       )
        ,.rx_app_noc_ctovr_rdy          (rx_app_noc_ctovr_rdy       )
    
        ,.rx_engine_ctrl_noc_val        (ptr_if_noc_dtc_val         )
        ,.ctrl_noc_rx_engine_rdy        (noc_dtc_ptr_if_rdy         )
                                         
        ,.ctrl_noc_rx_engine_val        (noc_ctd_ptr_if_val         )
        ,.rx_engine_ctrl_noc_rdy        (ptr_if_noc_ctd_rdy         )

        ,.rx_app_state_rd_req_val       (rx_app_state_rd_req_val    )
        ,.app_state_rx_rd_req_rdy       (app_state_rx_rd_req_rdy    )

        ,.rx_app_state_wr_req_val       (rx_app_state_wr_req_val    )

        ,.app_state_rx_rd_resp_val      (app_state_rx_rd_resp_val   )
        ,.rx_app_state_rd_resp_rdy      (rx_app_state_rd_resp_rdy   )

        ,.ctrl_rd_buf_req_val           (ctrl_rd_buf_req_val        )
        ,.rd_buf_ctrl_req_rdy           (rd_buf_ctrl_req_rdy        )

        ,.rd_buf_ctrl_resp_data_val     (rd_buf_ctrl_resp_data_val  )
        ,.ctrl_rd_buf_resp_data_rdy     (ctrl_rd_buf_resp_data_rdy  )

        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs    )
        ,.ctrl_datap_store_app_state    (ctrl_datap_store_app_state )
        ,.ctrl_datap_store_notif        (ctrl_datap_store_notif     )
        ,.ctrl_datap_out_mux_sel        (ctrl_datap_out_mux_sel     )

        ,.datap_ctrl_last_pkt           (datap_ctrl_last_pkt        )
        ,.datap_ctrl_last_data          (datap_ctrl_last_data       )
        ,.datap_ctrl_should_copy        (datap_ctrl_should_copy     )

        ,.noc_unit_sel                  (noc_unit_sel               )
        ,.setup_done                    (setup_done                 )
    );
    
    rd_circ_buf_new #(
         .BUF_PTR_W     (RX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (DST_BUF_X          )
        ,.DST_DRAM_Y    (DST_BUF_Y          )
        ,.FBITS         (RX_IF_FBITS        )
    ) rd_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_buf_noc0_val           (rd_req_noc_dtc_val                 )
        ,.rd_buf_noc0_data          (rd_req_noc_dtc_data                )
        ,.noc0_rd_buf_rdy           (noc_dtc_rd_req_rdy                 )
       
        ,.noc0_rd_buf_val           (noc_ctovr_rx_buf_val               )
        ,.noc0_rd_buf_data          (noc_ctovr_rx_buf_data              )
        ,.rd_buf_noc0_rdy           (rx_buf_noc_ctovr_rdy               )
    
        ,.src_rd_buf_req_val        (ctrl_rd_buf_req_val                )
        ,.src_rd_buf_req_flowid     (datap_rd_buf_req_flowid            )
        ,.src_rd_buf_req_offset     (datap_rd_buf_req_offset            )
        ,.src_rd_buf_req_size       (datap_rd_buf_req_size              )
        ,.rd_buf_src_req_rdy        (rd_buf_ctrl_req_rdy                )
    
        ,.rd_buf_src_data_val       (rd_buf_ctrl_resp_data_val          )
        ,.rd_buf_src_data           (rd_buf_datap_resp_data             )
        ,.rd_buf_src_data_last      (rd_buf_datap_resp_data_last        )
        ,.rd_buf_src_data_padbytes  (rd_buf_datap_resp_data_padbytes    )
        ,.src_rd_buf_data_rdy       (ctrl_rd_buf_resp_data_rdy          )
    );
endmodule
