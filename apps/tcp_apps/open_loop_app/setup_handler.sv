`include "noc_defs.vh"
module setup_handler 
import tcp_pkg::*;
import open_loop_pkg::*;
import setup_open_loop_pkg::*;
    import tx_open_loop_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter RX_BUF_X = -1
    ,parameter RX_BUF_Y = -1
    ,parameter TX_BUF_X = -1
    ,parameter TX_BUF_Y = -1
)(
     input clk
    ,input rst

    ,input  logic                               setup_q_handler_empty
    ,input  logic   [FLOWID_W-1:0]              setup_q_handler_flowid
    ,output logic                               handler_setup_q_rd_req
    
    ,output logic                               setup_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       setup_noc_vrtoc_data
    ,input  logic                               noc_vrtoc_setup_rdy
    
    ,input  logic                               noc_ctovr_setup_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_setup_data
    ,output logic                               setup_noc_ctovr_rdy    
    
    ,input  logic                               ctrl_noc_setup_val
    ,input  logic   [`CTRL_NOC1_DATA_W-1:0]     ctrl_noc_setup_data
    ,output logic                               setup_ctrl_noc_rdy    

    ,output logic                               setup_ctrl_noc_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0]     setup_ctrl_noc_data
    ,input  logic                               ctrl_noc_setup_rdy

    ,output logic                               setup_app_mem_wr_req
    ,output logic   [FLOWID_W-1:0]              setup_app_mem_wr_addr
    ,output app_cntxt_struct                    setup_app_mem_wr_data

    ,output logic                               setup_send_loop_q_wr_req
    ,output send_q_struct                       setup_send_loop_q_wr_data
    
    ,output logic                               setup_recv_loop_q_wr_req
    ,output logic   [FLOWID_W-1:0]              setup_recv_loop_q_wr_flowid

    ,output logic                               setup_done
    ,output client_dir_e                        bench_dir
);
    logic           ctrl_datap_store_flowid;
    logic           ctrl_datap_store_notif;
    logic           ctrl_datap_store_hdr;
    buf_mux_sel_e   ctrl_datap_buf_mux_sel;
    logic           ctrl_datap_save_conn;
    logic           ctrl_datap_send_setup_confirm;
    logic           ctrl_datap_incr_bytes_written;
    logic           ctrl_datap_reset_bytes_written;

    client_dir_e    datap_ctrl_dir;
    logic           datap_ctrl_last_conn_recv;
    flag_e          datap_ctrl_should_copy;
    logic           datap_ctrl_last_line;

    setup_noc_sel_e noc_mux_sel;
    
    logic                               setup_eng_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       setup_eng_noc_vrtoc_data;
    logic                               noc_vrtoc_setup_eng_rdy;
    
    logic                               setup_ptr_merger_ctrl_noc_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     setup_ptr_merger_ctrl_noc_data;
    logic                               ctrl_noc_setup_ptr_merger_rdy;
    
    logic                               setup_rd_merger_ctrl_noc_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     setup_rd_merger_ctrl_noc_data;
    logic                               ctrl_noc_setup_rd_merger_rdy;

    logic                               ctrl_noc_setup_ptr_if_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     ctrl_noc_setup_ptr_if_data;
    logic                               setup_ptr_if_ctrl_noc_rdy;
    
    logic                               ctrl_noc_setup_wr_buf_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]     ctrl_noc_setup_wr_buf_data;
    logic                               setup_wr_buf_ctrl_noc_rdy;
    
    logic                               noc_ctovr_setup_eng_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_setup_eng_data;
    logic                               setup_eng_noc_ctovr_rdy;
    
    logic                               setup_rd_buf_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       setup_rd_buf_noc_vrtoc_data;
    logic                               noc_vrtoc_setup_rd_buf_rdy;
    
    logic                               noc_ctovr_setup_rd_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_setup_rd_buf_data;
    logic                               setup_rd_buf_noc_ctovr_rdy;
    
    logic                               setup_wr_buf_noc_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       setup_wr_buf_noc_vrtoc_data;
    logic                               noc_vrtoc_setup_wr_buf_rdy;
    
    logic                               setup_rd_buf_req_val;
    logic   [FLOWID_W-1:0]              setup_rd_buf_req_flowid;
    logic   [RX_PAYLOAD_PTR_W-1:0]      setup_rd_buf_req_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  setup_rd_buf_req_size;
    logic                               rd_buf_setup_req_rdy;

    logic                               rd_buf_setup_resp_val;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_buf_setup_resp_data;
    logic                               rd_buf_setup_resp_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_buf_setup_resp_padbytes;
    logic                               setup_rd_buf_resp_rdy;
    
    logic   [FLOWID_W-1:0]              setup_wr_buf_req_flowid;
    logic   [RX_PAYLOAD_PTR_W-1:0]      setup_wr_buf_req_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  setup_wr_buf_req_size;
    logic                               setup_wr_buf_req_val;
    logic                               wr_buf_setup_req_rdy;
    
    logic                               setup_wr_buf_req_data_val;
    logic                               wr_buf_setup_req_data_rdy;
    logic   [`NOC_DATA_WIDTH-1:0]       setup_wr_buf_req_data;
    
    logic                               wr_buf_setup_req_done;
    logic                               setup_wr_buf_done_rdy;
    
    logic                               noc_ctd_wr_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctd_wr_buf_data;
    logic                               wr_buf_noc_ctd_rdy;
    
    logic                               noc_ctd_ptr_if_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_ctd_ptr_if_data;
    logic                               ptr_if_noc_ctd_rdy;
    
    logic                               ptr_if_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       ptr_if_noc_dtc_data;
    logic                               noc_dtc_ptr_if_rdy;
    
    logic                               rd_req_if_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_req_if_noc_dtc_data;
    logic                               noc_dtc_rd_req_if_rdy;


    assign noc_ctovr_setup_eng_data = noc_ctovr_setup_data;
    assign noc_ctovr_setup_rd_buf_data = noc_ctovr_setup_data;
    assign noc_ctovr_setup_wr_buf_data = noc_ctovr_setup_data;

    assign bench_dir = datap_ctrl_dir;

    always_comb begin
        noc_ctovr_setup_eng_val = 1'b0;
        noc_ctovr_setup_rd_buf_val = 1'b0;
        noc_vrtoc_setup_eng_rdy = 1'b0;
        noc_vrtoc_setup_rd_buf_rdy = 1'b0;
        setup_noc_ctovr_rdy = 1'b0;

        if (noc_mux_sel == setup_open_loop_pkg::BUF_READ) begin
            setup_noc_vrtoc_val = setup_rd_buf_noc_vrtoc_val;
            setup_noc_vrtoc_data = setup_rd_buf_noc_vrtoc_data;
            noc_vrtoc_setup_rd_buf_rdy = noc_vrtoc_setup_rdy;

            noc_ctovr_setup_rd_buf_val = noc_ctovr_setup_val;
            setup_noc_ctovr_rdy = setup_rd_buf_noc_ctovr_rdy;
        end
        else if (noc_mux_sel == setup_open_loop_pkg::BUF_WRITE) begin
            setup_noc_vrtoc_val = setup_wr_buf_noc_vrtoc_val;
            setup_noc_vrtoc_data = setup_wr_buf_noc_vrtoc_data;
            noc_vrtoc_setup_wr_buf_rdy = noc_vrtoc_setup_rdy;
        end
        else begin
            setup_noc_vrtoc_val = setup_eng_noc_vrtoc_val;
            setup_noc_vrtoc_data = setup_eng_noc_vrtoc_data;
            noc_vrtoc_setup_eng_rdy = noc_vrtoc_setup_rdy;

            noc_ctovr_setup_eng_val = noc_ctovr_setup_val;
            setup_noc_ctovr_rdy = setup_eng_noc_ctovr_rdy;
        end
    end
    
    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W    (DRAM_REQ_W )
    ) wr_buf_ctd (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (ctrl_noc_setup_wr_buf_val  )
        ,.src_noc_ctd_data  (ctrl_noc_setup_wr_buf_data )
        ,.noc_ctd_src_rdy   (setup_wr_buf_ctrl_noc_rdy  )
    
        ,.noc_ctd_dst_val   (noc_ctd_wr_buf_val         )
        ,.noc_ctd_dst_data  (noc_ctd_wr_buf_data        ) 
        ,.dst_noc_ctd_rdy   (wr_buf_noc_ctd_rdy         )
    );
    
    extra_hdr_noc_ctrl_to_data #(
        .EXTRA_W    (TCP_EXTRA_W    )
    ) ptr_if_ctd (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (ctrl_noc_setup_ptr_if_val  )
        ,.src_noc_ctd_data  (ctrl_noc_setup_ptr_if_data )
        ,.noc_ctd_src_rdy   (setup_ptr_if_ctrl_noc_rdy  )
    
        ,.noc_ctd_dst_val   (noc_ctd_ptr_if_val         )
        ,.noc_ctd_dst_data  (noc_ctd_ptr_if_data        ) 
        ,.dst_noc_ctd_rdy   (ptr_if_noc_ctd_rdy         )
    );

    assign ctrl_noc_setup_wr_buf_data = ctrl_noc_setup_data;
    assign ctrl_noc_setup_ptr_if_data = ctrl_noc_setup_data;

    always_comb begin
        ctrl_noc_setup_wr_buf_val = 1'b0;
        ctrl_noc_setup_ptr_if_val = 1'b0;

        if (noc_mux_sel == setup_open_loop_pkg::BUF_WRITE) begin
            ctrl_noc_setup_wr_buf_val = ctrl_noc_setup_val;
            setup_ctrl_noc_rdy = setup_wr_buf_ctrl_noc_rdy;
        end
        else begin
            ctrl_noc_setup_ptr_if_val = ctrl_noc_setup_val;
            setup_ctrl_noc_rdy = setup_ptr_if_ctrl_noc_rdy;
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
    
        ,.noc_dtc_dst_val   (setup_ptr_merger_ctrl_noc_val  )
        ,.noc_dtc_dst_data  (setup_ptr_merger_ctrl_noc_data )
        ,.dst_noc_dtc_rdy   (ctrl_noc_setup_ptr_merger_rdy  )
    );

    extra_hdr_noc_data_to_ctrl #(
        .EXTRA_W    (DRAM_REQ_W )
    ) rd_req_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (rd_req_if_noc_dtc_val          )
        ,.src_noc_dtc_data  (rd_req_if_noc_dtc_data         )
        ,.noc_dtc_src_rdy   (noc_dtc_rd_req_if_rdy          )
    
        ,.noc_dtc_dst_val   (setup_rd_merger_ctrl_noc_val   )
        ,.noc_dtc_dst_data  (setup_rd_merger_ctrl_noc_data  )
        ,.dst_noc_dtc_rdy   (ctrl_noc_setup_rd_merger_rdy   )
    );

    beehive_noc_prio_merger #(
         .NOC_DATA_W          (`CTRL_NOC1_DATA_W    )
        ,.MSG_PAYLOAD_LEN     (`MSG_LENGTH_WIDTH    )
        ,.MSG_LEN_HI          (CTRL_MSG_LEN_OFFSET  )
        ,.num_sources         (2    )
    ) ctrl_noc1_merger (
         .clk   (clk    )
        ,.rst_n (~rst   )
    
        ,.src0_merger_vr_noc_val    (setup_rd_merger_ctrl_noc_val   )
        ,.src0_merger_vr_noc_dat    (setup_rd_merger_ctrl_noc_data  )
        ,.merger_src0_vr_noc_rdy    (ctrl_noc_setup_rd_merger_rdy   )
    
        ,.src1_merger_vr_noc_val    (setup_ptr_merger_ctrl_noc_val  )
        ,.src1_merger_vr_noc_dat    (setup_ptr_merger_ctrl_noc_data )
        ,.merger_src1_vr_noc_rdy    (ctrl_noc_setup_ptr_merger_rdy  )
    
        ,.src2_merger_vr_noc_val    ('0)
        ,.src2_merger_vr_noc_dat    ('0)
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ('0)
        ,.src3_merger_vr_noc_dat    ('0)
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ('0)
        ,.src4_merger_vr_noc_dat    ('0)
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (setup_ctrl_noc_val             )
        ,.merger_dst_vr_noc_dat     (setup_ctrl_noc_data            )
        ,.dst_merger_vr_noc_rdy     (ctrl_noc_setup_rdy             )
    );

    setup_handler_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.setup_q_handler_flowid        (setup_q_handler_flowid         )
                                                                        
        ,.setup_noc_vrtoc_data          (setup_eng_noc_vrtoc_data       )
                                                                        
        ,.noc_ctovr_setup_data          (noc_ctovr_setup_eng_data       )
    
        ,.setup_ptr_if_ctrl_noc_data    (ptr_if_noc_dtc_data            )

        ,.ctrl_noc_setup_ptr_if_data    (noc_ctd_ptr_if_data            )
                                                                        
        ,.setup_rd_buf_req_flowid       (setup_rd_buf_req_flowid        )
        ,.setup_rd_buf_req_offset       (setup_rd_buf_req_offset        )
        ,.setup_rd_buf_req_size         (setup_rd_buf_req_size          )
                                                                        
        ,.rd_buf_setup_resp_data        (rd_buf_setup_resp_data         )
        ,.rd_buf_setup_resp_data_last   (rd_buf_setup_resp_data_last    )
        ,.rd_buf_setup_resp_padbytes    (rd_buf_setup_resp_padbytes     )
    
        ,.setup_wr_buf_req_flowid       (setup_wr_buf_req_flowid        )
        ,.setup_wr_buf_req_offset       (setup_wr_buf_req_offset        )
        ,.setup_wr_buf_req_size         (setup_wr_buf_req_size          )
                                                                        
        ,.setup_wr_buf_req_data         (setup_wr_buf_req_data          )
                                                                        
        ,.setup_app_mem_wr_data         (setup_app_mem_wr_data          )
        ,.setup_app_mem_wr_addr         (setup_app_mem_wr_addr          )
                                                                        
        ,.setup_send_loop_q_wr_data     (setup_send_loop_q_wr_data      )
                                                                        
        ,.setup_recv_loop_q_wr_flowid   (setup_recv_loop_q_wr_flowid    )
                                                                        
        ,.ctrl_datap_store_flowid       (ctrl_datap_store_flowid        )
        ,.ctrl_datap_store_notif        (ctrl_datap_store_notif         )
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_buf_mux_sel        (ctrl_datap_buf_mux_sel         )
        ,.ctrl_datap_send_setup_confirm (ctrl_datap_send_setup_confirm  )
        ,.ctrl_datap_incr_bytes_written (ctrl_datap_incr_bytes_written  )
        ,.ctrl_datap_reset_bytes_written(ctrl_datap_reset_bytes_written )
                                                                        
        ,.ctrl_datap_save_conn          (ctrl_datap_save_conn           )
                                                                        
        ,.datap_ctrl_dir                (datap_ctrl_dir                 )
        ,.datap_ctrl_last_conn_recv     (datap_ctrl_last_conn_recv      )
        ,.datap_ctrl_should_copy        (datap_ctrl_should_copy         )
        ,.datap_ctrl_last_line          (datap_ctrl_last_line           )
    );

    setup_handler_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.setup_q_handler_empty         (setup_q_handler_empty          )
        ,.handler_setup_q_rd_req        (handler_setup_q_rd_req         )
                                                                 
        ,.setup_noc_vrtoc_val           (setup_eng_noc_vrtoc_val        )
        ,.noc_vrtoc_setup_rdy           (noc_vrtoc_setup_eng_rdy        )
                                                                 
        ,.noc_ctovr_setup_val           (noc_ctovr_setup_eng_val        )
        ,.setup_noc_ctovr_rdy           (setup_eng_noc_ctovr_rdy        )
    
        ,.setup_ptr_if_ctrl_noc_val     (ptr_if_noc_dtc_val             )
        ,.ctrl_noc_setup_ptr_if_rdy     (noc_dtc_ptr_if_rdy             )
                                         
        ,.ctrl_noc_setup_ptr_if_val     (noc_ctd_ptr_if_val             )
        ,.setup_ptr_if_ctrl_noc_rdy     (ptr_if_noc_ctd_rdy             )
                                                                 
        ,.setup_rd_buf_req_val          (setup_rd_buf_req_val           )
        ,.rd_buf_setup_req_rdy          (rd_buf_setup_req_rdy           )
                                                                 
        ,.rd_buf_setup_resp_val         (rd_buf_setup_resp_val          )
        ,.setup_rd_buf_resp_rdy         (setup_rd_buf_resp_rdy          )

        ,.setup_wr_buf_req_val          (setup_wr_buf_req_val           )
        ,.wr_buf_setup_req_rdy          (wr_buf_setup_req_rdy           )

        ,.setup_wr_buf_req_data_val     (setup_wr_buf_req_data_val      )
        ,.wr_buf_setup_req_data_rdy     (wr_buf_setup_req_data_rdy      )

        ,.wr_buf_setup_req_done         (wr_buf_setup_req_done          )
        ,.setup_wr_buf_done_rdy         (setup_wr_buf_done_rdy          )
                                                                 
        ,.setup_app_mem_wr_req          (setup_app_mem_wr_req           )
                                                                 
        ,.setup_send_loop_q_wr_req      (setup_send_loop_q_wr_req       )
                                                                 
        ,.setup_recv_loop_q_wr_req      (setup_recv_loop_q_wr_req       )
                                                                 
        ,.ctrl_datap_store_flowid       (ctrl_datap_store_flowid        )
        ,.ctrl_datap_store_notif        (ctrl_datap_store_notif         )
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_buf_mux_sel        (ctrl_datap_buf_mux_sel         )
        ,.ctrl_datap_send_setup_confirm (ctrl_datap_send_setup_confirm  )
        ,.ctrl_datap_incr_bytes_written (ctrl_datap_incr_bytes_written  )
        ,.ctrl_datap_reset_bytes_written(ctrl_datap_reset_bytes_written )
                                                                 
        ,.ctrl_datap_save_conn          (ctrl_datap_save_conn           )
                                                                 
        ,.datap_ctrl_dir                (datap_ctrl_dir                 )
        ,.datap_ctrl_last_conn_recv     (datap_ctrl_last_conn_recv      )
        ,.datap_ctrl_should_copy        (datap_ctrl_should_copy         )
        ,.datap_ctrl_last_line          (datap_ctrl_last_line           )
                                                                 
        ,.noc_mux_sel                   (noc_mux_sel                    )
        ,.setup_done                    (setup_done                     )
    );

    rd_circ_buf_new #(
         .BUF_PTR_W     (RX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (RX_BUF_X           )
        ,.DST_DRAM_Y    (RX_BUF_Y           )
        ,.FBITS         (SETUP_IF_FBITS     )
    ) rd_circ_buf (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_buf_noc0_val           (rd_req_if_noc_dtc_val              )
        ,.rd_buf_noc0_data          (rd_req_if_noc_dtc_data             )
        ,.noc0_rd_buf_rdy           (noc_dtc_rd_req_if_rdy              )
       
        ,.noc0_rd_buf_val           (noc_ctovr_setup_rd_buf_val         )
        ,.noc0_rd_buf_data          (noc_ctovr_setup_rd_buf_data        )
        ,.rd_buf_noc0_rdy           (setup_rd_buf_noc_ctovr_rdy         )
    
        ,.src_rd_buf_req_val        (setup_rd_buf_req_val               )
        ,.src_rd_buf_req_flowid     (setup_rd_buf_req_flowid            )
        ,.src_rd_buf_req_offset     (setup_rd_buf_req_offset            )
        ,.src_rd_buf_req_size       (setup_rd_buf_req_size              )
        ,.rd_buf_src_req_rdy        (rd_buf_setup_req_rdy               )
    
        ,.rd_buf_src_data_val       (rd_buf_setup_resp_val              )
        ,.rd_buf_src_data           (rd_buf_setup_resp_data             )
        ,.rd_buf_src_data_last      (rd_buf_setup_resp_data_last        )
        ,.rd_buf_src_data_padbytes  (rd_buf_setup_resp_padbytes         )
        ,.src_rd_buf_data_rdy       (setup_rd_buf_resp_rdy              )
    );

    wr_circ_buf #(
         .BUF_PTR_W     (RX_PAYLOAD_PTR_W   )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.DST_DRAM_X    (TX_BUF_X           )
        ,.DST_DRAM_Y    (TX_BUF_Y           )
        ,.FBITS         (SETUP_IF_FBITS     )
    ) wr_buf (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_buf_noc_req_noc_val    (setup_wr_buf_noc_vrtoc_val     )
        ,.wr_buf_noc_req_noc_data   (setup_wr_buf_noc_vrtoc_data    )
        ,.noc_wr_buf_req_noc_rdy    (noc_vrtoc_setup_wr_buf_rdy     )
        
        ,.noc_wr_buf_resp_noc_val   (noc_ctd_wr_buf_val             )
        ,.noc_wr_buf_resp_noc_data  (noc_ctd_wr_buf_data            )
        ,.wr_buf_noc_resp_noc_rdy   (wr_buf_noc_ctd_rdy             )
    
        ,.src_wr_buf_req_val        (setup_wr_buf_req_val           )
        ,.src_wr_buf_req_flowid     (setup_wr_buf_req_flowid        )
        ,.src_wr_buf_req_wr_ptr     (setup_wr_buf_req_offset        )
        ,.src_wr_buf_req_size       (setup_wr_buf_req_size          )
        ,.wr_buf_src_req_rdy        (wr_buf_setup_req_rdy           )
    
        ,.src_wr_buf_req_data_val   (setup_wr_buf_req_data_val      )
        ,.src_wr_buf_req_data       (setup_wr_buf_req_data          )
        ,.wr_buf_src_req_data_rdy   (wr_buf_setup_req_data_rdy      )
        
        ,.wr_buf_src_req_done       (wr_buf_setup_req_done          )
        ,.src_wr_buf_done_rdy       (setup_wr_buf_done_rdy          )
    );

endmodule
