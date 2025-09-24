`include "noc_defs.vh"
module rs_encode_wrap 
import tcp_pkg::*;
import mem_msg_pkg::*;
import beehive_topology::*;
#(
     parameter MONITOR_DATA_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter DST_DRAM_X = -1
    ,parameter DST_DRAM_Y = -1
)(
     input clk
    ,input rst

    ,output                         app_monitor_noc_val
    ,output [`NOC_DATA_WIDTH-1:0]   app_monitor_noc_data
    ,input                          monitor_app_noc_rdy

    ,input                          monitor_app_noc_val
    ,input  [`NOC_DATA_WIDTH-1:0]   monitor_app_noc_data
    ,output                         app_monitor_noc_rdy
    
    ,input                          monitor_app_ctrl_noc_val
    ,input  [`NOC_DATA_WIDTH-1:0]   monitor_app_ctrl_noc_data
    ,output                         app_monitor_ctrl_noc_rdy

);
    logic                                   active_q_encode_in_empty;
    logic   [FLOWID_W-1:0]                  active_q_encode_in_rd_data;
    logic                                   encode_in_active_q_rd_req;

    logic                                   encode_in_msg_req_req_val;
    tcp_msg_req                             encode_in_msg_req_req_data;
    logic                                   msg_req_encode_in_req_rdy;

    logic                                   msg_req_encode_in_rsp_val;
    tcp_msg_resp                            msg_req_encode_in_rsp_data;
    logic                                   encode_in_msg_req_rsp_rdy;
    
    logic                                   encode_in_rd_buf_req_val;
    vaddr_t                                 encode_in_rd_buf_req_base_addr;
    logic   [PAYLOAD_PTR_W-1:0]             encode_in_rd_buf_req_offset;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]      encode_in_rd_buf_req_size;
    logic                                   rd_buf_encode_in_req_rdy;

    logic                                   rd_buf_encode_in_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]           rd_buf_encode_in_data;
    logic                                   rd_buf_encode_in_data_last;
    logic   [`NOC_DATA_BYTES_W-1:0]         rd_buf_encode_in_data_padbytes;
    logic                                   encode_in_rd_buf_data_rdy;
    
    logic                                   encode_in_stream_encoder_req_val;
    logic  [ENCODER_NUM_REQ_BLOCKS-1:0]     encode_in_stream_encoder_req_num_blocks;
    logic                                   stream_encoder_encode_in_req_rdy;

    logic                                   encode_in_stream_encoder_req_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]           encode_in_stream_encoder_req_data;
    logic                                   stream_encoder_encode_in_req_data_rdy;

    logic                                   encode_in_rx_cap_rd_req_val;
    logic   [FLOWID_W-1:0]                  encode_in_rx_cap_rd_req_addr;
    logic                                   rx_cap_encode_in_rd_req_rdy;

    logic                                   rx_cap_encode_in_rd_rsp_val;
    logic   [CAP_TABLE_INDEX_W-1:0]         rx_cap_encode_in_rd_rsp_data;
    logic                                   encode_in_rx_cap_rd_rsp_rdy;

    logic                                   in_out_meta_val;
    tcp_rs_metadata                         in_out_meta_data;
    logic                                   out_in_meta_rdy;
    
    logic                               encode_out_active_q_wr_val;
    logic   [FLOWID_W-1:0]              encode_out_active_q_wr_data;
    logic                               active_q_encode_out_rdy;

    logic                               encode_out_msg_req_req_val;
    tcp_msg_req                         encode_out_msg_req_req_data;
    logic                               msg_req_encode_out_req_rdy;

    logic                               msg_req_encode_out_rsp_val;
    tcp_msg_resp                        msg_req_encode_out_rsp_data;
    logic                               encode_out_msg_req_rsp_rdy;
    
    logic                               encode_out_wr_buf_req_val;
    vaddr_t                             encode_out_wr_buf_req_base_addr;
    logic   [BUF_PTR_W-1:0]             encode_out_wr_buf_req_wr_ptr;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  encode_out_wr_buf_req_size;
    logic                               wr_buf_encode_out_req_rdy;
    
    logic                               encode_out_wr_buf_req_data_val;
    logic    [`NOC_DATA_WIDTH-1:0]      encode_out_wr_buf_req_data;
    logic                               wr_buf_encode_out_req_data_rdy;
    
    logic                               wr_buf_encode_out_req_done;
    logic                               encode_out_wr_buf_done_rdy;
    
    logic                               stream_encoder_out_resp_data_val;
    logic   [DATA_W-1:0]                stream_encoder_out_resp_data;
    logic                               stream_encoder_out_resp_last;
    logic                               out_stream_encoder_resp_data_rdy;
    
    logic                               encode_out_tx_cap_rd_req_val;
    logic   [FLOWID_W-1:0]              encode_out_tx_cap_rd_req_addr;
    logic                               tx_cap_encode_out_rd_req_rdy;

    logic                               tx_cap_encode_out_rd_rsp_val;
    logic   [CAP_TABLE_INDEX_W-1:0]     tx_cap_encode_out_rd_rsp_data;
    logic                               encode_out_tx_cap_rd_rsp_rdy;
    
    logic                           monitor_notif_mgr_rx_val;
    logic   [MONITOR_DATA_W-1:0]    monitor_notif_mgr_rx_data;
    logic                           notif_mgr_monitor_rx_rdy;
    
    logic                           monitor_rx_msg_req_val;
    logic   [MONITOR_DATA_W-1:0]    monitor_rx_msg_req_data;
    logic                           rx_msg_req_monitor_rdy;

    logic                           rx_msg_req_monitor_val;
    logic   [MONITOR_DATA_W-1:0]    rx_msg_req_monitor_data;
    logic                           monitor_rx_msg_req_rdy;
    
    logic                                   rd_buf_monitor_val;
    logic   [MONITOR_DATA_W-1:0]            rd_buf_monitor_data;
    logic                                   monitor_rd_buf_rdy;
    
    logic                           monitor_tx_msg_req_val;
    logic   [MONITOR_DATA_W-1:0]    monitor_tx_msg_req_data;
    logic                           tx_msg_req_monitor_rdy;

    logic                           tx_msg_req_monitor_val;
    logic   [MONITOR_DATA_W-1:0]    tx_msg_req_monitor_data;
    logic                           monitor_tx_msg_req_rdy;
    
    logic                               wr_buf_noc_req_noc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       wr_buf_noc_req_noc_data;
    logic                               noc_wr_buf_req_noc_rdy;
    
    logic                               noc_wr_buf_resp_noc_val;
    logic   [`NOC_DATA_WIDTH-1:0]       noc_wr_buf_resp_noc_data;
    logic                               wr_buf_noc_resp_noc_rdy;

    beehive_noc_prio_merger #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
        ,.MSG_LEN_HI        (`MSG_LEN_HI        )
        ,.num_sources       (4)
    ) send_merger (   
         .clk   (clk    )
        ,.rst_n (~rst    )

         // Highest priority
        ,.src0_merger_vr_noc_val    (rx_msg_req_monitor_val     )
        ,.src0_merger_vr_noc_dat    (rx_msg_req_monitor_data    )
        ,.merger_src0_vr_noc_rdy    (monitor_rx_msg_req_rdy     )

        ,.src1_merger_vr_noc_val    (rd_buf_monitor_val         )
        ,.src1_merger_vr_noc_dat    (rd_buf_monitor_data        )
        ,.merger_src1_vr_noc_rdy    (monitor_rd_buf_rdy         )

        ,.src2_merger_vr_noc_val    (tx_msg_req_monitor_val     )
        ,.src2_merger_vr_noc_dat    (tx_msg_req_monitor_data    )
        ,.merger_src2_vr_noc_rdy    (monitor_tx_msg_req_rdy     )

        ,.src3_merger_vr_noc_val    (wr_buf_noc_req_noc_val     )
        ,.src3_merger_vr_noc_dat    (wr_buf_noc_req_noc_data    )
        ,.merger_src3_vr_noc_rdy    (noc_wr_buf_req_noc_rdy     )

        // Lowest priority
        ,.src4_merger_vr_noc_val    ()
        ,.src4_merger_vr_noc_dat    ()
        ,.merger_src4_vr_noc_rdy    ()

        ,.merger_dst_vr_noc_val     (app_monitor_noc_val    )
        ,.merger_dst_vr_noc_dat     (app_monitor_noc_data   )
        ,.dst_merger_vr_noc_rdy     (monitor_app_noc_rdy    )
    );

    beehive_noc_fbits_splitter #(
         .NOC_FBITS_W     (`NOC_FBITS_WIDTH )
        ,.NOC_DATA_W      (`NOC_DATA_W      )
        ,.MSG_PAYLOAD_LEN (`MSG_LENGTH_WIDTH    )
        ,.MSG_LEN_HI      (`MSG_LEN_HI  )
        ,.FBITS_HI        (`FBITS_HI    )
        ,.num_targets     (1)
        ,.fbits_type0     (TCP_RX_APP_NOTIF_FBITS   )
        ,.fbits_type1     (TCP_RX_APP_PTR_IF_FBITS  )
        ,.fbits_type2     (TCP_TX_APP_PTR_IF_FBITS  )
        ,.fbits_type3     (TX_MEM_FBITS             )
        ,.fbits_type4     ()
    ) ctrl_splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val (monitor_app_ctrl_noc_val     )
        ,.src_splitter_vr_noc_dat (monitor_app_ctrl_noc_data    )
        ,.splitter_src_vr_noc_rdy (app_monitor_ctrl_noc_rdy     )

        ,.splitter_dst0_vr_noc_val(monitor_notif_mgr_rx_val     )
        ,.splitter_dst0_vr_noc_dat(monitor_notif_mgr_rx_data    )
        ,.dst0_splitter_vr_noc_rdy(notif_mgr_monitor_rx_rdy     )

        ,.splitter_dst1_vr_noc_val(monitor_rx_msg_req_val       )
        ,.splitter_dst1_vr_noc_dat(monitor_rx_msg_req_data      )
        ,.dst1_splitter_vr_noc_rdy(rx_msg_req_monitor_rdy       )

        ,.splitter_dst2_vr_noc_val(monitor_tx_msg_req_val       )
        ,.splitter_dst2_vr_noc_dat(monitor_tx_msg_req_data      )
        ,.dst2_splitter_vr_noc_rdy(tx_msg_req_monitor_rdy       )

        ,.splitter_dst3_vr_noc_val(noc_wr_buf_resp_noc_val      )
        ,.splitter_dst3_vr_noc_dat(noc_wr_buf_resp_noc_data     )
        ,.dst3_splitter_vr_noc_rdy(wr_buf_noc_resp_noc_rdy      )

        ,.splitter_dst4_vr_noc_val()
        ,.splitter_dst4_vr_noc_dat()
        ,.dst4_splitter_vr_noc_rdy()
    );
    

    rs_encode_mgr_in mgr_in (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.active_q_encode_in_empty               (active_q_encode_in_empty      )
        ,.active_q_encode_in_rd_data             (active_q_encode_in_rd_data    )
        ,.encode_in_active_q_rd_req              (encode_in_active_q_rd_req     )

        ,.encode_in_msg_req_req_val              (encode_in_msg_req_req_val     )
        ,.encode_in_msg_req_req_data             (encode_in_msg_req_req_data    )
        ,.msg_req_encode_in_req_rdy              (msg_req_encode_in_req_rdy     )

        ,.msg_req_encode_in_rsp_val              (msg_req_encode_in_rsp_val     )
        ,.msg_req_encode_in_rsp_data             (msg_req_encode_in_rsp_data    )
        ,.encode_in_msg_req_rsp_rdy              (encode_in_msg_req_rsp_rdy     )

        ,.encode_in_rd_buf_req_val               (encode_in_rd_buf_req_val      )
        ,.encode_in_rd_buf_req_base_addr         (encode_in_rd_buf_req_base_addr)
        ,.encode_in_rd_buf_req_offset            (encode_in_rd_buf_req_offset   )
        ,.encode_in_rd_buf_req_size              (encode_in_rd_buf_req_size     )
        ,.rd_buf_encode_in_req_rdy               (rd_buf_encode_in_req_rdy      )

        ,.rd_buf_encode_in_data_val              (rd_buf_encode_in_data_val     )
        ,.rd_buf_encode_in_data                  (rd_buf_encode_in_data         )
        ,.rd_buf_encode_in_data_last             (rd_buf_encode_in_data_last    )
        ,.rd_buf_encode_in_data_padbytes         (rd_buf_encode_in_data_padbytes)
        ,.encode_in_rd_buf_data_rdy              (encode_in_rd_buf_data_rdy     )

        ,.encode_in_stream_encoder_req_val       (encode_in_stream_encoder_req_val          )
        ,.encode_in_stream_encoder_req_num_blocks(encode_in_stream_encoder_req_num_blocks   )
        ,.stream_encoder_encode_in_req_rdy       (stream_encoder_encode_in_req_rdy          )

        ,.encode_in_stream_encoder_req_data_val  (encode_in_stream_encoder_req_data_val     )
        ,.encode_in_stream_encoder_req_data      (encode_in_stream_encoder_req_data         )
        ,.stream_encoder_encode_in_req_data_rdy  (stream_encoder_encode_in_req_data_rdy     )

        ,.encode_in_rx_cap_rd_req_val            (encode_in_rx_cap_rd_req_val   )
        ,.encode_in_rx_cap_rd_req_addr           (encode_in_rx_cap_rd_req_addr  )
        ,.rx_cap_encode_in_rd_req_rdy            (rx_cap_encode_in_rd_req_rdy   )

        ,.rx_cap_encode_in_rd_rsp_val            (rx_cap_encode_in_rd_rsp_val   )
        ,.rx_cap_encode_in_rd_rsp_data           (rx_cap_encode_in_rd_rsp_data  )
        ,.encode_in_rx_cap_rd_rsp_rdy            (encode_in_rx_cap_rd_rsp_rdy   )

        ,.in_out_meta_val                        (in_out_meta_val   )
        ,.in_out_meta_data                       (in_out_meta_data  )
        ,.out_in_meta_rdy                        (out_in_meta_rdy   )
    );

    rs_encode_stream_wrap #(
         .NUM_REQ_BLOCKS    (ENCODER_NUM_REQ_BLOCKS )
        ,.DATA_W            (`NOC_DATA_WIDTH    )
        ,.NUM_RS_UNITS      (16 )
    ) encode_stream_wrap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_stream_encoder_req_val       (encode_in_stream_encoder_req_val        )
        ,.src_stream_encoder_req_num_blocks(encode_in_stream_encoder_req_num_blocks )
        ,.stream_encoder_src_req_rdy       (stream_encoder_encode_in_req_rdy        )

        ,.src_stream_encoder_req_data_val  (encode_in_stream_encoder_req_data_val   )
        ,.src_stream_encoder_req_data      (encode_in_stream_encoder_req_data       )
        ,.stream_encoder_src_req_data_rdy  (stream_encoder_encode_in_req_data_rdy   )

        ,.stream_encoder_dst_resp_data_val (stream_encoder_out_resp_data_val    )
        ,.stream_encoder_dst_resp_data     (stream_encoder_out_resp_data        )
        ,.stream_encoder_dst_resp_last     (stream_encoder_out_resp_last        )
        ,.dst_stream_encoder_resp_data_rdy (out_stream_encoder_resp_data_rdy    )
    );

    rs_encode_mgr_out mgr_out (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.encode_out_active_q_wr_val      (encode_out_active_q_wr_val   )
        ,.encode_out_active_q_wr_data     (encode_out_active_q_wr_data  )
        ,.active_q_encode_out_rdy         (active_q_encode_out_rdy      )

        ,.encode_out_msg_req_req_val      (encode_out_msg_req_req_val   )
        ,.encode_out_msg_req_req_data     (encode_out_msg_req_req_data  )
        ,.msg_req_encode_out_req_rdy      (msg_req_encode_out_req_rdy   )
                                           
        ,.msg_req_encode_out_rsp_val      (msg_req_encode_out_rsp_val   )
        ,.msg_req_encode_out_rsp_data     (msg_req_encode_out_rsp_data  )
        ,.encode_out_msg_req_rsp_rdy      (encode_out_msg_req_rsp_rdy   )

        ,.encode_out_wr_buf_req_val       (encode_out_wr_buf_req_val        )
        ,.encode_out_wr_buf_req_base_addr (encode_out_wr_buf_req_base_addr  )
        ,.encode_out_wr_buf_req_wr_ptr    (encode_out_wr_buf_req_wr_ptr     )
        ,.encode_out_wr_buf_req_size      (encode_out_wr_buf_req_size       )
        ,.wr_buf_encode_out_req_rdy       (wr_buf_encode_out_req_rdy        )
                                           
        ,.encode_out_wr_buf_req_data_val  (encode_out_wr_buf_req_data_val   )
        ,.encode_out_wr_buf_req_data      (encode_out_wr_buf_req_data       )
        ,.wr_buf_encode_out_req_data_rdy  (wr_buf_encode_out_req_data_rdy   )
                                           
        ,.wr_buf_encode_out_req_done      (wr_buf_encode_out_req_done       )
        ,.encode_out_wr_buf_done_rdy      (encode_out_wr_buf_done_rdy       )

        ,.stream_encoder_out_resp_data_val(stream_encoder_out_resp_data_val )
        ,.stream_encoder_out_resp_data    (stream_encoder_out_resp_data     )
        ,.stream_encoder_out_resp_last    (stream_encoder_out_resp_last     )
        ,.out_stream_encoder_resp_data_rdy(out_stream_encoder_resp_data_rdy )

        ,.encode_out_tx_cap_rd_req_val    (encode_out_tx_cap_rd_req_val     )
        ,.encode_out_tx_cap_rd_req_addr   (encode_out_tx_cap_rd_req_addr    )
        ,.tx_cap_encode_out_rd_req_rdy    (tx_cap_encode_out_rd_req_rdy     )
                                           
        ,.tx_cap_encode_out_rd_rsp_val    (tx_cap_encode_out_rd_rsp_val     )
        ,.tx_cap_encode_out_rd_rsp_data   (tx_cap_encode_out_rd_rsp_data    )
        ,.encode_out_tx_cap_rd_rsp_rdy    (encode_out_tx_cap_rd_rsp_rdy     )

        ,.in_out_meta_val                 (in_out_meta_val                  )
        ,.in_out_meta_data                (in_out_meta_data                 )
        ,.out_in_meta_rdy                 (out_in_meta_rdy                  )

    );

    tcp_context_mgmt #(
         .MONITOR_DATA_W    (MONITOR_DATA_W )
        ,.SRC_X             (SRC_X          )
        ,.SRC_Y             (SRC_Y          )
    ) tcp_mgmt (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_notif_mgr_rx_val              (monitor_notif_mgr_rx_val   )
        ,.src_notif_mgr_rx_data             (monitor_notif_mgr_rx_data  )
        ,.notif_mgr_src_rx_rdy              (notif_mgr_monitor_rx_rdy   )

        ,.src_context_mgmt_rd_rx_cap_val    (encode_in_rx_cap_rd_req_val    )
        ,.src_context_mgmt_rd_rx_cap_addr   (encode_in_rx_cap_rd_req_addr   )
        ,.context_mgmt_src_rd_rx_cap_rdy    (rx_cap_encode_in_rd_req_rdy    )

        ,.context_mgmt_dst_rd_rx_cap_val    (rx_cap_encode_in_rd_rsp_val    )
        ,.context_mgmt_dst_rd_rx_cap_data   (rx_cap_encode_in_rd_rsp_data   )
        ,.dst_context_mgmt_rd_rx_cap_rdy    (encode_in_rx_cap_rd_rsp_rdy    )

        ,.src_context_mgmt_rd_tx_cap_val    (encode_out_tx_cap_rd_req_val   )
        ,.src_context_mgmt_rd_tx_cap_addr   (encode_out_tx_cap_rd_req_addr  )
        ,.context_mgmt_src_rd_tx_cap_rdy    (tx_cap_encode_out_rd_req_rdy   )

        ,.context_mgmt_dst_rd_tx_cap_val    (tx_cap_encode_out_rd_rsp_val   )
        ,.context_mgmt_dst_rd_tx_cap_data   (tx_cap_encode_out_rd_rsp_data  )
        ,.dst_context_mgmt_rd_tx_cap_rdy    (encode_out_tx_cap_rd_rsp_rdy   )

        ,.active_q_dst_empty                (active_q_encode_in_empty       )
        ,.active_q_dst_rd_data              (active_q_encode_in_rd_data     )
        ,.dst_active_q_rd_req               (encode_in_active_q_rd_req      )

        ,.src_active_q_wr_val               (encode_out_active_q_wr_val     )
        ,.src_active_q_wr_data              (encode_out_active_q_wr_data    )
        ,.active_q_src_rdy                  (active_q_encode_out_rdy        )

    );


    tcp_msg_req #(
         .MONITOR_DATA_W            (MONITOR_DATA_W )
        ,.TCP_X                     (TCP_RX_TILE_X)
        ,.TCP_Y                     (TCP_RX_TILE_Y)
        ,.TCP_FBITS                 (TCP_RX_APP_PTR_IF_FBITS    )
        ,.TCP_MSG_TYPE_PTR_UPDATE   (TCP_RX_ADJUST_PTR  )
        ,.TCP_MSG_TYPE_MSG_REQ      (TCP_RX_MSG_REQ )
        ,.SRC_X                     (SRC_X)
        ,.SRC_Y                     (SRC_Y)
    ) rx_req (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_msg_req_val     (encode_in_msg_req_req_val    )
        ,.src_msg_req_data    (encode_in_msg_req_req_data   )
        ,.msg_req_src_rdy     (msg_req_encode_in_req_rdy    )

        ,.msg_req_dst_val     (msg_req_encode_in_rsp_val    )
        ,.msg_req_dst_data    (msg_req_encode_in_rsp_data   )
        ,.dst_msg_req_rdy     (encode_in_msg_req_rsp_rdy    )

        ,.monitor_msg_req_val (monitor_msg_req_val          )
        ,.monitor_msg_req_data(monitor_msg_req_data         )
        ,.msg_req_monitor_rdy (msg_req_monitor_rdy          )
                               
        ,.msg_req_monitor_val (msg_req_monitor_val          )
        ,.msg_req_monitor_data(msg_req_monitor_data         )
        ,.monitor_msg_req_rdy (monitor_msg_req_rdy          )
    );

    rd_circ_buf_new #(
         .BUF_PTR_W      (PAYLOAD_PTR_W )
        ,.SRC_X          (SRC_X     )
        ,.SRC_Y          (SRC_Y     )
        ,.DST_DRAM_X     (DST_DRAM_X)
        ,.DST_DRAM_Y     (DST_DRAM_Y)
        ,.FBITS          (RX_MEM_FBITS      )
        ,.MONITOR_DATA_W (MONITOR_DATA_W    )
    ) rx_rd_buf (
         .clk                     (clk  )
        ,.rst                     (rst  )

        ,.rd_buf_monitor_val      (rd_buf_monitor_val   )
        ,.rd_buf_monitor_data     (rd_buf_monitor_data  )
        ,.monitor_rd_buf_rdy      (monitor_rd_buf_rdy   )
    
        ,.monitor_rd_buf_val      (monitor_app_noc_val  )
        ,.monitor_rd_buf_data     (monitor_app_noc_data )
        ,.rd_buf_monitor_rdy      (app_monitor_noc_rdy  )

        ,.src_rd_buf_req_val      (encode_in_rd_buf_req_val         )
        ,.src_rd_buf_req_base_addr(encode_in_rd_buf_req_base_addr   )
        ,.src_rd_buf_req_offset   (encode_in_rd_buf_req_offset      )
        ,.src_rd_buf_req_size     (encode_in_rd_buf_req_size        )
        ,.rd_buf_src_req_rdy      (rd_buf_encode_in_req_rdy         )

        ,.rd_buf_src_data_val     (rd_buf_encode_in_data_val        )
        ,.rd_buf_src_data         (rd_buf_encode_in_data            )
        ,.rd_buf_src_data_last    (rd_buf_encode_in_data_last       )
        ,.rd_buf_src_data_padbytes(rd_buf_encode_in_data_padbytes   )
        ,.src_rd_buf_data_rdy     (encode_in_rd_buf_data_rdy        )
    );
    

    tcp_msg_req 
    #(
         .MONITOR_DATA_W            (MONITOR_DATA_W )
        ,.TCP_X                     (TCP_TX_TILE_X  )
        ,.TCP_Y                     (TCP_TX_TILE_Y  )
        ,.TCP_FBITS                 (TCP_TX_APP_PTR_IF_FBITS    )
        ,.TCP_MSG_TYPE_PTR_UPDATE   (TCP_TX_ADJUST_PTR  )
        ,.TCP_MSG_TYPE_MSG_REQ      (TCP_TX_MSG_REQ )
        ,.SRC_X                     (SRC_X  )
        ,.SRC_Y                     (SRC_Y  )
    ) tx_req (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_msg_req_val     (encode_out_msg_req_req_val   )
        ,.src_msg_req_data    (encode_out_msg_req_req_data  )
        ,.msg_req_src_rdy     (msg_req_encode_out_req_rdy   )

        ,.msg_req_dst_val     (msg_req_encode_out_rsp_val   )
        ,.msg_req_dst_data    (msg_req_encode_out_rsp_data  )
        ,.dst_msg_req_rdy     (encode_out_msg_req_rsp_rdy   )

        ,.monitor_msg_req_val (monitor_tx_msg_req_val       )
        ,.monitor_msg_req_data(monitor_tx_msg_req_data      )
        ,.msg_req_monitor_rdy (tx_msg_req_monitor_rdy       )

        ,.msg_req_monitor_val (tx_msg_req_monitor_val       )
        ,.msg_req_monitor_data(tx_msg_req_monitor_data      )
        ,.monitor_msg_req_rdy (monitor_tx_msg_req_rdy       )
    );

    wr_circ_buf  #(
         .BUF_PTR_W     (PAYLOAD_PTR_W  )
        ,.SRC_X         (SRC_X  )
        ,.SRC_Y         (SRC_Y  )
        ,.DST_DRAM_X    (DST_DRAM_X)
        ,.DST_DRAM_Y    (DST_DRAM_Y)
        ,.FBITS         (TX_MEM_FBITS   )
    ) tx_wr_buf (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.wr_buf_noc_req_noc_val  ()
        ,.wr_buf_noc_req_noc_data ()
        ,.noc_wr_buf_req_noc_rdy  ()

        ,.noc_wr_buf_resp_noc_val ()
        ,.noc_wr_buf_resp_noc_data()
        ,.wr_buf_noc_resp_noc_rdy ()

        ,.src_wr_buf_req_val      (encode_out_wr_buf_req_val        )
        ,.src_wr_buf_req_base_addr(encode_out_wr_buf_req_base_addr  )
        ,.src_wr_buf_req_wr_ptr   (encode_out_wr_buf_req_wr_ptr     )
        ,.src_wr_buf_req_size     (encode_out_wr_buf_req_size       )
        ,.wr_buf_src_req_rdy      (wr_buf_encode_out_req_rdy        )

        ,.src_wr_buf_req_data_val (encode_out_wr_buf_req_data_val   )
        ,.src_wr_buf_req_data     (encode_out_wr_buf_req_data       )
        ,.wr_buf_src_req_data_rdy (wr_buf_encode_out_req_data_rdy   )

        ,.wr_buf_src_req_done     (wr_buf_encode_out_req_done       )
        ,.src_wr_buf_done_rdy     (encode_out_wr_buf_done_rdy       )
    );
endmodule