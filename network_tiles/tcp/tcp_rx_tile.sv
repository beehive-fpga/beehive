`include "tcp_rx_tile_defs.svh"
module tcp_rx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter RX_DRAM_X = -1
    ,parameter RX_DRAM_Y = -1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_rx_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_rx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_rx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                    src_tcp_rx_noc0_data_W 
                                                                             
    ,input                                          src_tcp_rx_noc0_val_N  
    ,input                                          src_tcp_rx_noc0_val_E  
    ,input                                          src_tcp_rx_noc0_val_S  
    ,input                                          src_tcp_rx_noc0_val_W  
                                                                             
    ,output                                         tcp_rx_src_noc0_yummy_N
    ,output                                         tcp_rx_src_noc0_yummy_E
    ,output                                         tcp_rx_src_noc0_yummy_S
    ,output                                         tcp_rx_src_noc0_yummy_W
                                                                             
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_rx_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_rx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_rx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]                   tcp_rx_dst_noc0_data_W 
                                                                             
    ,output                                         tcp_rx_dst_noc0_val_N  
    ,output                                         tcp_rx_dst_noc0_val_E  
    ,output                                         tcp_rx_dst_noc0_val_S  
    ,output                                         tcp_rx_dst_noc0_val_W  
                                                                             
    ,input                                          dst_tcp_rx_noc0_yummy_N
    ,input                                          dst_tcp_rx_noc0_yummy_E
    ,input                                          dst_tcp_rx_noc0_yummy_S
    ,input                                          dst_tcp_rx_noc0_yummy_W
    
    // I/O to the TCP parser
    ,output                                         tcp_format_dst_rx_hdr_val
    ,input                                          dst_tcp_format_rx_hdr_rdy
    ,output logic   [`IP_ADDR_W-1:0]                tcp_format_dst_rx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]                tcp_format_dst_rx_dst_ip
    ,output logic   [`TOT_LEN_W-1:0]                tcp_format_dst_rx_tcp_tot_len
    ,output tcp_pkt_hdr                             tcp_format_dst_rx_tcp_hdr
    
    ,output logic                                   tcp_format_dst_rx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]          tcp_format_dst_rx_data
    ,input                                          dst_tcp_format_rx_data_rdy
    ,output logic                                   tcp_format_dst_rx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]           tcp_format_dst_rx_padbytes
    
    ,output logic                                   read_store_buf_q_req_val
    ,input  rx_store_buf_q_struct                   read_store_buf_q_req_data
    ,input  logic                                   read_store_buf_q_empty
    
    ,output logic                                   store_buf_tmp_buf_store_rx_rd_req_val
    ,output logic   [`PAYLOAD_ENTRY_ADDR_W-1:0]     store_buf_tmp_buf_store_rx_rd_req_addr
    ,input  logic                                   tmp_buf_store_store_buf_rx_rd_req_rdy

    ,input  logic                                   tmp_buf_store_store_buf_rx_rd_resp_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]          tmp_buf_store_store_buf_rx_rd_resp_data
    ,output logic                                   store_buf_tmp_buf_store_rx_rd_resp_rdy

    ,output logic                                   store_buf_tmp_buf_free_slab_rx_req_val
    ,output logic   [`RX_TMP_BUF_ADDR_W-1:0]        store_buf_tmp_buf_free_slab_rx_req_addr
    ,input  logic                                   tmp_buf_free_slab_store_buf_rx_req_rdy

    ,output logic                                   store_buf_commit_ptr_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]                store_buf_commit_ptr_rd_req_flowid
    ,input  logic                                   commit_ptr_store_buf_rd_req_rdy
                                                                            
    ,input  logic                                   commit_ptr_store_buf_rd_resp_val
    ,input  logic   [`RX_PAYLOAD_PTR_W:0]           commit_ptr_store_buf_rd_resp_data
    ,output logic                                   store_buf_commit_ptr_rd_resp_rdy
    
    ,output logic                                   store_buf_commit_ptr_wr_req_val
    ,output logic   [`FLOW_ID_W-1:0]                store_buf_commit_ptr_wr_req_flowid
    ,output logic   [`RX_PAYLOAD_PTR_W:0]           store_buf_commit_ptr_wr_req_data
    ,input  logic                                   commit_ptr_store_buf_wr_req_rdy
    
    ,input  logic                                   app_new_flow_notif_val
    ,input  logic   [`FLOW_ID_W-1:0]                app_new_flow_flowid
    ,input  flow_lookup_entry                       app_new_flow_lookup
    ,output logic                                   app_new_flow_notif_rdy
    
    ,output logic                                   app_rx_head_ptr_wr_req_val
    ,output logic   [`FLOW_ID_W-1:0]                app_rx_head_ptr_wr_req_addr
    ,output logic   [`RX_PAYLOAD_PTR_W:0]           app_rx_head_ptr_wr_req_data
    ,input  logic                                   rx_head_ptr_app_wr_req_rdy

    ,output logic                                   app_rx_head_ptr_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]                app_rx_head_ptr_rd_req_addr
    ,input  logic                                   rx_head_ptr_app_rd_req_rdy
    
    ,input  logic                                   rx_head_ptr_app_rd_resp_val
    ,input  logic   [`RX_PAYLOAD_PTR_W:0]           rx_head_ptr_app_rd_resp_data
    ,output logic                                   app_rx_head_ptr_rd_resp_rdy

    ,output logic                                   app_rx_commit_ptr_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]                app_rx_commit_ptr_rd_req_addr
    ,input  logic                                   rx_commit_ptr_app_rd_req_rdy

    ,input  logic                                   rx_commit_ptr_app_rd_resp_val
    ,input  logic   [`RX_PAYLOAD_PTR_W:0]           rx_commit_ptr_app_rd_resp_data
    ,output logic                                   app_rx_commit_ptr_rd_resp_rdy
);
    
    logic                           noc0_vrtoc_tile_rx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_rx_router_data;
    logic                           tile_rx_router_noc0_vrtoc_yummy;

    logic                           tile_rx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_rx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_rx_router_yummy;
    
    logic                           merger_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_merger_rdy;
    
    logic                           tcp_rx_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_tcp_rx_out_rdy;
    
    logic                           noc0_ctovr_splitter_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_data;
    logic                           splitter_noc0_ctovr_rdy;     
    
    logic                           noc0_ctovr_tcp_rx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_rx_in_data;
    logic                           tcp_rx_in_noc0_ctovr_rdy;     
    
    logic                           noc0_ctovr_tcp_rx_ptr_if_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_rx_ptr_if_data;
    logic                           tcp_rx_ptr_if_noc0_ctovr_rdy;     
    
    logic                           tcp_rx_ptr_if_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_ptr_if_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_tcp_rx_ptr_if_rdy;
    
    logic                           tcp_rx_notif_if_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_notif_if_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_tcp_rx_notif_if_rdy;
    
    logic                           tcp_rx_in_tcp_format_hdr_val;
    logic                           tcp_format_tcp_rx_in_hdr_rdy;
    logic   [`IP_ADDR_W-1:0]        tcp_rx_in_tcp_format_src_ip;
    logic   [`IP_ADDR_W-1:0]        tcp_rx_in_tcp_format_dst_ip;
    logic   [`TOT_LEN_W-1:0]        tcp_rx_in_tcp_format_tcp_len;

    logic                           tcp_rx_in_tcp_format_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  tcp_rx_in_tcp_format_data;
    logic                           tcp_format_tcp_rx_in_data_rdy;
    logic                           tcp_rx_in_tcp_format_last;
    logic   [`MAC_PADBYTES_W-1:0]   tcp_rx_in_tcp_format_padbytes;

    logic                           rx_payload_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   rx_payload_noc0_data;
    logic                           noc0_rx_payload_rdy;

    logic                           noc0_rx_payload_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_rx_payload_data;
    logic                           rx_payload_noc0_rdy;
    
    logic                           store_buf_fifo_wr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   store_buf_fifo_wr_data;
    logic                           fifo_store_buf_wr_rdy;

    logic                           fifo_noc_rd_val;
    logic   [`NOC_DATA_WIDTH-1:0]   fifo_noc_rd_data;
    logic                           noc_fifo_rd_rdy;
    logic                           noc_fifo_rd_req;

    
    dynamic_node_top_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.XY_COORD_W        (`XY_WIDTH          )
        ,.CHIP_ID_W         (`CHIP_ID_WIDTH     )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
    ) tile_rx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_tcp_rx_noc0_data_N             )
        ,.src_router_data_E     (src_tcp_rx_noc0_data_E             )
        ,.src_router_data_S     (src_tcp_rx_noc0_data_S             )
        ,.src_router_data_W     (src_tcp_rx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_rx_router_data     )
                                
        ,.src_router_val_N      (src_tcp_rx_noc0_val_N              )
        ,.src_router_val_E      (src_tcp_rx_noc0_val_E              )
        ,.src_router_val_S      (src_tcp_rx_noc0_val_S              )
        ,.src_router_val_W      (src_tcp_rx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_rx_router_val      )
                                
        ,.router_src_yummy_N    (tcp_rx_src_noc0_yummy_N            )
        ,.router_src_yummy_E    (tcp_rx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (tcp_rx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (tcp_rx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_rx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (tcp_rx_dst_noc0_data_N             )
        ,.router_dst_data_E     (tcp_rx_dst_noc0_data_E             )
        ,.router_dst_data_S     (tcp_rx_dst_noc0_data_S             )
        ,.router_dst_data_W     (tcp_rx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_rx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (tcp_rx_dst_noc0_val_N              )
        ,.router_dst_val_E      (tcp_rx_dst_noc0_val_E              )
        ,.router_dst_val_S      (tcp_rx_dst_noc0_val_S              )
        ,.router_dst_val_W      (tcp_rx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_rx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_tcp_rx_noc0_yummy_N            )
        ,.dst_router_yummy_E    (dst_tcp_rx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_tcp_rx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_tcp_rx_noc0_yummy_W            )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_rx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_rx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_rx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_rx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_rx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_splitter_data       )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_val        )
        ,.dst_ctovr_rdy     (splitter_noc0_ctovr_rdy        )
    );

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_rx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_noc0_vrtoc_data        )
        ,.src_vrtoc_val     (merger_noc0_vrtoc_val         )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_rdy         )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_rx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_rx_router_val  )
		,.dst_vrtoc_yummy   (tile_rx_router_noc0_vrtoc_yummy)
    );

    // merge NoC traffic for sending data from the TCP engine to DRAM buffers and
    // traffic for answering whether or not data is available
    noc_prio_merger #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.num_sources    (3)
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (fifo_noc_rd_val                )
        ,.src0_merger_vr_noc_dat    (fifo_noc_rd_data               )
        ,.merger_src0_vr_noc_rdy    (noc_fifo_rd_rdy                )
    
        ,.src1_merger_vr_noc_val    (tcp_rx_ptr_if_noc0_vrtoc_val   )
        ,.src1_merger_vr_noc_dat    (tcp_rx_ptr_if_noc0_vrtoc_data  )
        ,.merger_src1_vr_noc_rdy    (noc0_vrtoc_tcp_rx_ptr_if_rdy   )
    
        ,.src2_merger_vr_noc_val    (tcp_rx_notif_if_noc0_vrtoc_val )
        ,.src2_merger_vr_noc_dat    (tcp_rx_notif_if_noc0_vrtoc_data)
        ,.merger_src2_vr_noc_rdy    (noc0_vrtoc_tcp_rx_notif_if_rdy )
    
        ,.src3_merger_vr_noc_val    ('0)
        ,.src3_merger_vr_noc_dat    ('0)
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ('0)
        ,.src4_merger_vr_noc_dat    ('0)
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (merger_noc0_vrtoc_val  )
        ,.merger_dst_vr_noc_dat     (merger_noc0_vrtoc_data )
        ,.dst_merger_vr_noc_rdy     (noc0_vrtoc_merger_rdy  )
    );

    // split between the app interface requests and the buffer copy module response
    noc_fbits_splitter #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.FBITS_HI          (`MSG_DST_FBITS_HI  )
        ,.FBITS_LO          (`MSG_DST_FBITS_LO  )
        ,.num_targets   (3'd3)
        ,.fbits_type0   (TCP_RX_BUF_IF_FBITS    )
        ,.fbits_type1   (TCP_RX_APP_PTR_IF_FBITS)
        ,.fbits_type2   (PKT_IF_FBITS           )
    ) splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_val    )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_data   )
        ,.splitter_src_vr_noc_rdy   (splitter_noc0_ctovr_rdy    )

        ,.splitter_dst0_vr_noc_val  (noc0_rx_payload_val        )
        ,.splitter_dst0_vr_noc_dat  (noc0_rx_payload_data       )
        ,.dst0_splitter_vr_noc_rdy  (rx_payload_noc0_rdy        )

        ,.splitter_dst1_vr_noc_val  (noc0_ctovr_tcp_rx_ptr_if_val   )
        ,.splitter_dst1_vr_noc_dat  (noc0_ctovr_tcp_rx_ptr_if_data  )
        ,.dst1_splitter_vr_noc_rdy  (tcp_rx_ptr_if_noc0_ctovr_rdy   )

        ,.splitter_dst2_vr_noc_val  (noc0_ctovr_tcp_rx_in_val   )
        ,.splitter_dst2_vr_noc_dat  (noc0_ctovr_tcp_rx_in_data  )
        ,.dst2_splitter_vr_noc_rdy  (tcp_rx_in_noc0_ctovr_rdy   )

        ,.splitter_dst3_vr_noc_val  ()
        ,.splitter_dst3_vr_noc_dat  ()
        ,.dst3_splitter_vr_noc_rdy  (1'b0)

        ,.splitter_dst4_vr_noc_val  ()
        ,.splitter_dst4_vr_noc_dat  ()
        ,.dst4_splitter_vr_noc_rdy  (1'b0)
    );

    tcp_rx_noc_in tcp_rx_noc_in (
         .clk   (clk)
        ,.rst   (rst)

        ,.noc0_ctovr_tcp_rx_in_val      (noc0_ctovr_tcp_rx_in_val       )
        ,.noc0_ctovr_tcp_rx_in_data     (noc0_ctovr_tcp_rx_in_data      )
        ,.tcp_rx_in_noc0_ctovr_rdy      (tcp_rx_in_noc0_ctovr_rdy       )
                                                                        
        ,.tcp_rx_in_tcp_format_hdr_val  (tcp_rx_in_tcp_format_hdr_val   )
        ,.tcp_rx_in_tcp_format_src_ip   (tcp_rx_in_tcp_format_src_ip    )
        ,.tcp_rx_in_tcp_format_dst_ip   (tcp_rx_in_tcp_format_dst_ip    )
        ,.tcp_rx_in_tcp_format_tcp_len  (tcp_rx_in_tcp_format_tcp_len   )
        ,.tcp_format_tcp_rx_in_hdr_rdy  (tcp_format_tcp_rx_in_hdr_rdy   )
                                                                        
        ,.tcp_rx_in_tcp_format_data_val (tcp_rx_in_tcp_format_data_val  )
        ,.tcp_rx_in_tcp_format_data     (tcp_rx_in_tcp_format_data      )
        ,.tcp_rx_in_tcp_format_last     (tcp_rx_in_tcp_format_last      )
        ,.tcp_rx_in_tcp_format_padbytes (tcp_rx_in_tcp_format_padbytes  )
        ,.tcp_format_tcp_rx_in_data_rdy (tcp_format_tcp_rx_in_data_rdy  )
    );

    rx_tcp_format_wrap tcp_format (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.src_tcp_format_rx_hdr_val     (tcp_rx_in_tcp_format_hdr_val   )
        ,.src_tcp_format_rx_src_ip      (tcp_rx_in_tcp_format_src_ip    )
        ,.src_tcp_format_rx_dst_ip      (tcp_rx_in_tcp_format_dst_ip    )
        ,.src_tcp_format_rx_tcp_len     (tcp_rx_in_tcp_format_tcp_len   )
        ,.tcp_format_src_rx_hdr_rdy     (tcp_format_tcp_rx_in_hdr_rdy   )
                                                                        
        ,.src_tcp_format_rx_data_val    (tcp_rx_in_tcp_format_data_val  )
        ,.src_tcp_format_rx_data        (tcp_rx_in_tcp_format_data      )
        ,.src_tcp_format_rx_last        (tcp_rx_in_tcp_format_last      )
        ,.src_tcp_format_rx_padbytes    (tcp_rx_in_tcp_format_padbytes  )
        ,.tcp_format_src_rx_data_rdy    (tcp_format_tcp_rx_in_data_rdy  )
    
        ,.tcp_format_dst_rx_hdr_val     (tcp_format_dst_rx_hdr_val      )
        ,.dst_tcp_format_rx_hdr_rdy     (dst_tcp_format_rx_hdr_rdy      )
        ,.tcp_format_dst_rx_src_ip      (tcp_format_dst_rx_src_ip       )
        ,.tcp_format_dst_rx_dst_ip      (tcp_format_dst_rx_dst_ip       )
        ,.tcp_format_dst_rx_tcp_tot_len (tcp_format_dst_rx_tcp_tot_len  )
        ,.tcp_format_dst_rx_tcp_hdr     (tcp_format_dst_rx_tcp_hdr      )
                                                                        
        ,.tcp_format_dst_rx_data_val    (tcp_format_dst_rx_data_val     )
        ,.tcp_format_dst_rx_data        (tcp_format_dst_rx_data         )
        ,.dst_tcp_format_rx_data_rdy    (dst_tcp_format_rx_data_rdy     )
        ,.tcp_format_dst_rx_last        (tcp_format_dst_rx_last         )
        ,.tcp_format_dst_rx_padbytes    (tcp_format_dst_rx_padbytes     )
    );

    bsg_fifo_1r1w_small #( 
         .width_p   (`NOC_DATA_WIDTH    )
        ,.els_p     (4                  )
        ,.harden_p  (1)
    ) store_buf_noc_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (store_buf_fifo_wr_val  )
        ,.data_i    (store_buf_fifo_wr_data )
        ,.ready_o   (fifo_store_buf_wr_rdy  )
    
        ,.v_o       (fifo_noc_rd_val        )
        ,.data_o    (fifo_noc_rd_data       )
        ,.yumi_i    (noc_fifo_rd_req        )
    );
    
    assign noc_fifo_rd_req = fifo_noc_rd_val & noc_fifo_rd_rdy;

    rx_payload_store_buf_cp #(
         .SRC_X     (SRC_X                  )
        ,.SRC_Y     (SRC_Y                  )
        ,.RX_DRAM_X (RX_DRAM_X              )
        ,.RX_DRAM_Y (RX_DRAM_Y              )
        ,.FBITS     (TCP_RX_BUF_IF_FBITS    )
    ) store_buf (
         .clk   (clk)
        ,.rst   (rst)
        
        // I/O for the NoC
        ,.rx_payload_noc0_val                       (store_buf_fifo_wr_val  )
        ,.rx_payload_noc0_data                      (store_buf_fifo_wr_data )
        ,.noc0_rx_payload_rdy                       (fifo_store_buf_wr_rdy  )
                                                                                                
        ,.noc0_rx_payload_val                       (noc0_rx_payload_val                        )
        ,.noc0_rx_payload_data                      (noc0_rx_payload_data                       )
        ,.rx_payload_noc0_rdy                       (rx_payload_noc0_rdy                        )
        
        ,.read_store_buf_q_req_val                  (read_store_buf_q_req_val                   )
        ,.read_store_buf_q_req_data                 (read_store_buf_q_req_data                  )
        ,.read_store_buf_q_empty                    (read_store_buf_q_empty                     )

        ,.store_buf_tmp_buf_store_rx_rd_req_val     (store_buf_tmp_buf_store_rx_rd_req_val      )
        ,.store_buf_tmp_buf_store_rx_rd_req_addr    (store_buf_tmp_buf_store_rx_rd_req_addr     )
        ,.tmp_buf_store_store_buf_rx_rd_req_rdy     (tmp_buf_store_store_buf_rx_rd_req_rdy      )
                                                                                                
        ,.tmp_buf_store_store_buf_rx_rd_resp_val    (tmp_buf_store_store_buf_rx_rd_resp_val     )
        ,.tmp_buf_store_store_buf_rx_rd_resp_data   (tmp_buf_store_store_buf_rx_rd_resp_data    )
        ,.store_buf_tmp_buf_store_rx_rd_resp_rdy    (store_buf_tmp_buf_store_rx_rd_resp_rdy     )
                                                                                                
        ,.store_buf_tmp_buf_free_slab_rx_req_val    (store_buf_tmp_buf_free_slab_rx_req_val     )
        ,.store_buf_tmp_buf_free_slab_rx_req_addr   (store_buf_tmp_buf_free_slab_rx_req_addr    )
        ,.tmp_buf_free_slab_store_buf_rx_req_rdy    (tmp_buf_free_slab_store_buf_rx_req_rdy     )
                                                                                                
        ,.store_buf_commit_ptr_rd_req_val           (store_buf_commit_ptr_rd_req_val            )
        ,.store_buf_commit_ptr_rd_req_flowid        (store_buf_commit_ptr_rd_req_flowid         )
        ,.commit_ptr_store_buf_rd_req_rdy           (commit_ptr_store_buf_rd_req_rdy            )
                                                                                                
        ,.commit_ptr_store_buf_rd_resp_val          (commit_ptr_store_buf_rd_resp_val           )
        ,.commit_ptr_store_buf_rd_resp_data         (commit_ptr_store_buf_rd_resp_data          )
        ,.store_buf_commit_ptr_rd_resp_rdy          (store_buf_commit_ptr_rd_resp_rdy           )
                                                                                                
        ,.store_buf_commit_ptr_wr_req_val           (store_buf_commit_ptr_wr_req_val            )
        ,.store_buf_commit_ptr_wr_req_flowid        (store_buf_commit_ptr_wr_req_flowid         )
        ,.store_buf_commit_ptr_wr_req_data          (store_buf_commit_ptr_wr_req_data           )
        ,.commit_ptr_store_buf_wr_req_rdy           (commit_ptr_store_buf_wr_req_rdy            )
    );


    tcp_rx_app_if_wrap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) app_if_wrap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.tcp_rx_notif_if_noc0_vrtoc_val    (tcp_rx_notif_if_noc0_vrtoc_val     )
        ,.tcp_rx_notif_if_noc0_vrtoc_data   (tcp_rx_notif_if_noc0_vrtoc_data    )
        ,.noc0_vrtoc_tcp_rx_notif_if_rdy    (noc0_vrtoc_tcp_rx_notif_if_rdy     )
                                                                                
        ,.app_new_flow_notif_val            (app_new_flow_notif_val             )
        ,.app_new_flow_flowid               (app_new_flow_flowid                )
        ,.app_new_flow_entry                (app_new_flow_lookup                )
        ,.app_new_flow_notif_rdy            (app_new_flow_notif_rdy             )
                                                                                
        ,.noc0_ctovr_tcp_rx_ptr_if_val      (noc0_ctovr_tcp_rx_ptr_if_val       )
        ,.noc0_ctovr_tcp_rx_ptr_if_data     (noc0_ctovr_tcp_rx_ptr_if_data      )
        ,.tcp_rx_ptr_if_noc0_ctovr_rdy      (tcp_rx_ptr_if_noc0_ctovr_rdy       )
                                                                                
        ,.tcp_rx_ptr_if_noc0_vrtoc_val      (tcp_rx_ptr_if_noc0_vrtoc_val       )
        ,.tcp_rx_ptr_if_noc0_vrtoc_data     (tcp_rx_ptr_if_noc0_vrtoc_data      )
        ,.noc0_vrtoc_tcp_rx_ptr_if_rdy      (noc0_vrtoc_tcp_rx_ptr_if_rdy       )
                                                                                
        ,.app_rx_head_ptr_wr_req_val        (app_rx_head_ptr_wr_req_val         )
        ,.app_rx_head_ptr_wr_req_addr       (app_rx_head_ptr_wr_req_addr        )
        ,.app_rx_head_ptr_wr_req_data       (app_rx_head_ptr_wr_req_data        )
        ,.rx_head_ptr_app_wr_req_rdy        (rx_head_ptr_app_wr_req_rdy         )
                                                                                
        ,.app_rx_head_ptr_rd_req_val        (app_rx_head_ptr_rd_req_val         )
        ,.app_rx_head_ptr_rd_req_addr       (app_rx_head_ptr_rd_req_addr        )
        ,.rx_head_ptr_app_rd_req_rdy        (rx_head_ptr_app_rd_req_rdy         )
                                                                                
        ,.rx_head_ptr_app_rd_resp_val       (rx_head_ptr_app_rd_resp_val        )
        ,.rx_head_ptr_app_rd_resp_data      (rx_head_ptr_app_rd_resp_data       )
        ,.app_rx_head_ptr_rd_resp_rdy       (app_rx_head_ptr_rd_resp_rdy        )
                                                                                
        ,.app_rx_commit_ptr_rd_req_val      (app_rx_commit_ptr_rd_req_val       )
        ,.app_rx_commit_ptr_rd_req_addr     (app_rx_commit_ptr_rd_req_addr      )
        ,.rx_commit_ptr_app_rd_req_rdy      (rx_commit_ptr_app_rd_req_rdy       )
                                                                                
        ,.rx_commit_ptr_app_rd_resp_val     (rx_commit_ptr_app_rd_resp_val      )
        ,.rx_commit_ptr_app_rd_resp_data    (rx_commit_ptr_app_rd_resp_data     )
        ,.app_rx_commit_ptr_rd_resp_rdy     (app_rx_commit_ptr_rd_resp_rdy      )
    );

endmodule
