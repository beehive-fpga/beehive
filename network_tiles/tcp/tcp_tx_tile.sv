`include "tcp_tx_tile_defs.svh"
module tcp_tx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter TX_DRAM_X = -1
    ,parameter TX_DRAM_Y = -1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]                src_tcp_tx_noc0_data_N 
    ,input [`NOC_DATA_WIDTH-1:0]                src_tcp_tx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]                src_tcp_tx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]                src_tcp_tx_noc0_data_W 
                                                                         
    ,input                                      src_tcp_tx_noc0_val_N  
    ,input                                      src_tcp_tx_noc0_val_E  
    ,input                                      src_tcp_tx_noc0_val_S  
    ,input                                      src_tcp_tx_noc0_val_W  
                                                                         
    ,output                                     tcp_tx_src_noc0_yummy_N
    ,output                                     tcp_tx_src_noc0_yummy_E
    ,output                                     tcp_tx_src_noc0_yummy_S
    ,output                                     tcp_tx_src_noc0_yummy_W
                                                                         
    ,output [`NOC_DATA_WIDTH-1:0]               tcp_tx_dst_noc0_data_N 
    ,output [`NOC_DATA_WIDTH-1:0]               tcp_tx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]               tcp_tx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]               tcp_tx_dst_noc0_data_W 
                                                                         
    ,output                                     tcp_tx_dst_noc0_val_N  
    ,output                                     tcp_tx_dst_noc0_val_E  
    ,output                                     tcp_tx_dst_noc0_val_S  
    ,output                                     tcp_tx_dst_noc0_val_W  
                                                                         
    ,input                                      dst_tcp_tx_noc0_yummy_N
    ,input                                      dst_tcp_tx_noc0_yummy_E
    ,input                                      dst_tcp_tx_noc0_yummy_S
    ,input                                      dst_tcp_tx_noc0_yummy_W
    
    ,input                                      send_dst_tx_val
    ,input  logic   [`FLOW_ID_W-1:0]            send_dst_tx_flowid
    ,input  logic   [`IP_ADDR_W-1:0]            send_dst_tx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]            send_dst_tx_dst_ip
    ,input  tcp_pkt_hdr                         send_dst_tx_tcp_hdr
    ,input  payload_buf_entry                   send_dst_tx_payload
    ,output                                     dst_send_tx_rdy
    
    ,output logic                           app_tail_ptr_tx_wr_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_tail_ptr_tx_wr_req_flowid
    ,output logic   [`PAYLOAD_PTR_W:0]      app_tail_ptr_tx_wr_req_data
    ,input                                  tail_ptr_app_tx_wr_req_rdy
    
    ,output logic                           app_tail_ptr_tx_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_tail_ptr_tx_rd_req_flowid
    ,input  logic                           tail_ptr_app_tx_rd_req_rdy

    ,input                                  tail_ptr_app_tx_rd_resp_val
    ,input  logic   [`FLOW_ID_W-1:0]        tail_ptr_app_tx_rd_resp_flowid
    ,input  logic   [`PAYLOAD_PTR_W:0]      tail_ptr_app_tx_rd_resp_data
    ,output logic                           app_tail_ptr_tx_rd_resp_rdy

    ,output                                 app_head_ptr_tx_rd_req_val
    ,output         [`FLOW_ID_W-1:0]        app_head_ptr_tx_rd_req_flowid
    ,input  logic                           head_ptr_app_tx_rd_req_rdy

    ,input                                  head_ptr_app_tx_rd_resp_val
    ,input  logic   [`FLOW_ID_W-1:0]        head_ptr_app_tx_rd_resp_flowid
    ,input  logic   [`PAYLOAD_PTR_W:0]      head_ptr_app_tx_rd_resp_data
    ,output logic                           app_head_ptr_tx_rd_resp_rdy
);
    typedef struct packed {
        logic   [`MAC_INTERFACE_W-1:0]  data;
        logic   [`MAC_PADBYTES_W-1:0]   padbytes;
        logic                           last;
    } fifo_struct;
    localparam FIFO_STRUCT_W = $bits(fifo_struct);

    logic       payload_fifo_wr_val;
    fifo_struct payload_fifo_wr_data;
    logic       fifo_payload_wr_rdy;

    logic       fifo_chksum_rd_val;
    fifo_struct fifo_chksum_rd_data;
    logic       chksum_fifo_rd_req;
    logic       chksum_fifo_rd_rdy;

    
    logic                           noc0_vrtoc_tile_tx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_tx_router_data;
    logic                           tile_tx_router_noc0_vrtoc_yummy;

    logic                           tile_tx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_tx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_tx_router_yummy;
    
    logic                           noc0_ctovr_splitter_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_splitter_data;
    logic                           splitter_noc0_ctovr_rdy;     
    
    logic                           merger_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_merger_rdy;
    
    logic                           tcp_tx_out_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_out_noc0_data;
    logic                           noc0_tcp_tx_out_rdy;
    
    logic                           tx_payload_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tx_payload_noc0_data;
    logic                           noc0_tx_payload_rdy;
   
    logic                           noc0_tx_payload_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_tx_payload_data;
    logic                           tx_payload_noc0_rdy;
    
    logic                           noc0_ctovr_tcp_tx_ptr_if_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_tx_ptr_if_data;
    logic                           tcp_tx_ptr_if_noc0_ctovr_rdy;     
    
    logic                           tcp_tx_ptr_if_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_ptr_if_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_tcp_tx_ptr_if_rdy;
    
    logic                           payload_chksum_tx_hdr_val;
    logic                           chksum_payload_tx_hdr_rdy;
    logic   [`IP_ADDR_W-1:0]        payload_chksum_tx_src_ip;
    logic   [`IP_ADDR_W-1:0]        payload_chksum_tx_dst_ip;
    logic   [`TOT_LEN_W-1:0]        payload_chksum_tx_payload_len;
    tcp_pkt_hdr                     payload_chksum_tx_tcp_hdr;

    logic                           payload_chksum_tx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  payload_chksum_tx_data;
    logic                           payload_chksum_tx_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   payload_chksum_tx_data_padbytes;
    logic                           chksum_payload_tx_data_rdy;
    
    logic                           chksum_tcp_tx_out_hdr_val;
    logic   [`IP_ADDR_W-1:0]        chksum_tcp_tx_out_src_ip;
    logic   [`IP_ADDR_W-1:0]        chksum_tcp_tx_out_dst_ip;
    logic   [`TOT_LEN_W-1:0]        chksum_tcp_tx_out_tcp_len;
    tcp_pkt_hdr                     chksum_tcp_tx_out_tcp_hdr;
    logic                           tcp_tx_out_chksum_hdr_rdy;

    logic                           chksum_tcp_tx_out_data_val;
    logic                           tcp_tx_out_chksum_data_rdy;
    logic   [`MAC_INTERFACE_W-1:0]  chksum_tcp_tx_out_data;
    logic                           chksum_tcp_tx_out_last;
    logic   [`MAC_PADBYTES_W-1:0]   chksum_tcp_tx_out_padbytes;

    logic                           noc_in_payload_fifo_wr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc_in_payload_fifo_wr_data;
    logic                           payload_fifo_noc_in_wr_rdy;

    logic                           payload_fifo_engine_rd_val;
    logic   [`NOC_DATA_WIDTH-1:0]   payload_fifo_engine_rd_data;
    logic                           engine_payload_fifo_rd_rdy;
    logic                           engine_payload_fifo_rd_req;

    
    
    dynamic_node_top_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.XY_COORD_W        (`XY_WIDTH          )
        ,.CHIP_ID_W         (`CHIP_ID_WIDTH     )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
    ) tile_tx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_tcp_tx_noc0_data_N             )
        ,.src_router_data_E     (src_tcp_tx_noc0_data_E             )
        ,.src_router_data_S     (src_tcp_tx_noc0_data_S             )
        ,.src_router_data_W     (src_tcp_tx_noc0_data_W             )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data     )
                                
        ,.src_router_val_N      (src_tcp_tx_noc0_val_N              )
        ,.src_router_val_E      (src_tcp_tx_noc0_val_E              )
        ,.src_router_val_S      (src_tcp_tx_noc0_val_S              )
        ,.src_router_val_W      (src_tcp_tx_noc0_val_W              )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val      )
                                
        ,.router_src_yummy_N    (tcp_tx_src_noc0_yummy_N            )
        ,.router_src_yummy_E    (tcp_tx_src_noc0_yummy_E            )
        ,.router_src_yummy_S    (tcp_tx_src_noc0_yummy_S            )
        ,.router_src_yummy_W    (tcp_tx_src_noc0_yummy_W            )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (tcp_tx_dst_noc0_data_N             )
        ,.router_dst_data_E     (tcp_tx_dst_noc0_data_E             )
        ,.router_dst_data_S     (tcp_tx_dst_noc0_data_S             )
        ,.router_dst_data_W     (tcp_tx_dst_noc0_data_W             )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (tcp_tx_dst_noc0_val_N              )
        ,.router_dst_val_E      (tcp_tx_dst_noc0_val_E              )
        ,.router_dst_val_S      (tcp_tx_dst_noc0_val_S              )
        ,.router_dst_val_W      (tcp_tx_dst_noc0_val_W              )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_tcp_tx_noc0_yummy_N            )
        ,.dst_router_yummy_E    (dst_tcp_tx_noc0_yummy_E            )
        ,.dst_router_yummy_S    (dst_tcp_tx_noc0_yummy_S            )
        ,.dst_router_yummy_W    (dst_tcp_tx_noc0_yummy_W            )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_tx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_tx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_tx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_tx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_splitter_data      )
        ,.ctovr_dst_val     (noc0_ctovr_splitter_val       )
        ,.dst_ctovr_rdy     (splitter_noc0_ctovr_rdy       )
    );

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_tx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (merger_noc0_vrtoc_data         )
        ,.src_vrtoc_val     (merger_noc0_vrtoc_val          )
        ,.vrtoc_src_rdy     (noc0_vrtoc_merger_rdy          )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_tx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_tx_router_val  )
		,.dst_vrtoc_yummy   (tile_tx_router_noc0_vrtoc_yummy)
    );
    
    // merge NoC traffic for
    // - sending pkts to the IP engine
    // - sending buffer read requests
    // - responses to apps
    noc_prio_merger #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.num_sources       (3)
    ) merger (   
         .clk   (clk)
        ,.rst_n (~rst)
    
        ,.src0_merger_vr_noc_val    (tcp_tx_out_noc0_val    )
        ,.src0_merger_vr_noc_dat    (tcp_tx_out_noc0_data   )
        ,.merger_src0_vr_noc_rdy    (noc0_tcp_tx_out_rdy    )
    
        ,.src1_merger_vr_noc_val    (tx_payload_noc0_val    )
        ,.src1_merger_vr_noc_dat    (tx_payload_noc0_data   )
        ,.merger_src1_vr_noc_rdy    (noc0_tx_payload_rdy    )
    
        ,.src2_merger_vr_noc_val    (tcp_tx_ptr_if_noc0_vrtoc_val   )
        ,.src2_merger_vr_noc_dat    (tcp_tx_ptr_if_noc0_vrtoc_data  )
        ,.merger_src2_vr_noc_rdy    (noc0_vrtoc_tcp_tx_ptr_if_rdy   )
    
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

    // split NoC traffic between
    // - responses to buffer read requests
    // - requests from apps
    noc_fbits_splitter #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.FBITS_HI          (`MSG_DST_FBITS_HI  )
        ,.FBITS_LO          (`MSG_DST_FBITS_LO  )
        ,.num_targets       (3'd2)
        ,.fbits_type0       (TCP_TX_BUF_IF_FBITS        )
        ,.fbits_type1       (TCP_TX_APP_PTR_IF_FBITS    )
    ) splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )

        ,.src_splitter_vr_noc_val   (noc0_ctovr_splitter_val        )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_splitter_data       )
        ,.splitter_src_vr_noc_rdy   (splitter_noc0_ctovr_rdy        )

        ,.splitter_dst0_vr_noc_val  (noc_in_payload_fifo_wr_val     )
        ,.splitter_dst0_vr_noc_dat  (noc_in_payload_fifo_wr_data    )
        ,.dst0_splitter_vr_noc_rdy  (payload_fifo_noc_in_wr_rdy     )

        ,.splitter_dst1_vr_noc_val  (noc0_ctovr_tcp_tx_ptr_if_val   )
        ,.splitter_dst1_vr_noc_dat  (noc0_ctovr_tcp_tx_ptr_if_data  )
        ,.dst1_splitter_vr_noc_rdy  (tcp_tx_ptr_if_noc0_ctovr_rdy   )

        ,.splitter_dst2_vr_noc_val  ()
        ,.splitter_dst2_vr_noc_dat  ()
        ,.dst2_splitter_vr_noc_rdy  (1'b0)

        ,.splitter_dst3_vr_noc_val  ()
        ,.splitter_dst3_vr_noc_dat  ()
        ,.dst3_splitter_vr_noc_rdy  (1'b0)

        ,.splitter_dst4_vr_noc_val  ()
        ,.splitter_dst4_vr_noc_dat  ()
        ,.dst4_splitter_vr_noc_rdy  (1'b0)
    );

    bsg_fifo_1r1w_small #( 
         .width_p   (`NOC_DATA_WIDTH    )
        ,.els_p     (4                  )
        ,.harden_p  (1                  )
    ) noc_in_payload_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (noc_in_payload_fifo_wr_val )
        ,.data_i    (noc_in_payload_fifo_wr_data)
        ,.ready_o   (payload_fifo_noc_in_wr_rdy )
    
        ,.v_o       (payload_fifo_engine_rd_val )
        ,.data_o    (payload_fifo_engine_rd_data)
        ,.yumi_i    (engine_payload_fifo_rd_req )
    );

    assign engine_payload_fifo_rd_req = payload_fifo_engine_rd_val 
                                        & engine_payload_fifo_rd_rdy;

    frontend_tx_payload_engine #( 
         .SRC_X     (SRC_X                  )
        ,.SRC_Y     (SRC_Y                  )
        ,.TX_DRAM_X (TX_DRAM_X              )
        ,.TX_DRAM_Y (TX_DRAM_Y              )
        ,.FBITS     (TCP_TX_BUF_IF_FBITS    )
    ) tx_payload_engine (
         .clk   (clk)
        ,.rst   (rst)
    
        // I/O for the NoC
        ,.tx_payload_noc0_val           (tx_payload_noc0_val            )
        ,.tx_payload_noc0_data          (tx_payload_noc0_data           )
        ,.noc0_tx_payload_rdy           (noc0_tx_payload_rdy            )
                                                                
        ,.noc0_tx_payload_val           (payload_fifo_engine_rd_val     )
        ,.noc0_tx_payload_data          (payload_fifo_engine_rd_data    )
        ,.tx_payload_noc0_rdy           (engine_payload_fifo_rd_rdy     )
        
        // Read req
        ,.src_payload_tx_val            (send_dst_tx_val                )
        ,.src_payload_tx_flowid         (send_dst_tx_flowid             )
        ,.src_payload_tx_src_ip         (send_dst_tx_src_ip             )
        ,.src_payload_tx_dst_ip         (send_dst_tx_dst_ip             )
        ,.src_payload_tx_tcp_hdr        (send_dst_tx_tcp_hdr            )
        ,.src_payload_tx_payload_entry  (send_dst_tx_payload            )
        ,.payload_src_tx_rdy            (dst_send_tx_rdy                )
     
        // Read resp
        ,.payload_dst_tx_hdr_val        (payload_chksum_tx_hdr_val      )
        ,.payload_dst_tx_src_ip         (payload_chksum_tx_src_ip       )
        ,.payload_dst_tx_dst_ip         (payload_chksum_tx_dst_ip       )
        ,.payload_dst_tx_payload_len    (payload_chksum_tx_payload_len  )
        ,.payload_dst_tx_tcp_hdr        (payload_chksum_tx_tcp_hdr      )
        ,.dst_payload_tx_hdr_rdy        (chksum_payload_tx_hdr_rdy      )
        
        ,.payload_dst_tx_data_val       (payload_fifo_wr_val            )
        ,.payload_dst_tx_data           (payload_fifo_wr_data.data      )
        ,.payload_dst_tx_data_last      (payload_fifo_wr_data.last      )
        ,.payload_dst_tx_data_padbytes  (payload_fifo_wr_data.padbytes  )
        ,.dst_payload_tx_data_rdy       (fifo_payload_wr_rdy            )
    );

    bsg_fifo_1r1w_small #( 
         .width_p   (FIFO_STRUCT_W  )
        ,.els_p     (4              )
        ,.harden_p  (1              )
    ) payload_chksum_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (payload_fifo_wr_val    )
        ,.data_i    (payload_fifo_wr_data   )
        ,.ready_o   (fifo_payload_wr_rdy    )
    
        ,.v_o       (fifo_chksum_rd_val     )
        ,.data_o    (fifo_chksum_rd_data    )
        ,.yumi_i    (chksum_fifo_rd_req     )
    );

    assign chksum_fifo_rd_req = fifo_chksum_rd_val & chksum_fifo_rd_rdy;
    
    frontend_tx_chksum_engine #(
        .DATA_WIDTH (`MAC_INTERFACE_W   )
    ) tcp_tx_chksum (
         .clk   (clk)
        ,.rst   (rst)

        // I/O from the payload engine
        ,.src_chksum_tx_hdr_val         (payload_chksum_tx_hdr_val      )
        ,.src_chksum_tx_src_ip          (payload_chksum_tx_src_ip       )
        ,.src_chksum_tx_dst_ip          (payload_chksum_tx_dst_ip       )
        ,.src_chksum_tx_payload_len     (payload_chksum_tx_payload_len  )
        ,.src_chksum_tx_tcp_hdr         (payload_chksum_tx_tcp_hdr      )
        ,.chksum_src_tx_hdr_rdy         (chksum_payload_tx_hdr_rdy      )

        ,.src_chksum_tx_data_val        (fifo_chksum_rd_val             )
        ,.src_chksum_tx_data            (fifo_chksum_rd_data.data       )
        ,.src_chksum_tx_data_last       (fifo_chksum_rd_data.last       )
        ,.src_chksum_tx_data_padbytes   (fifo_chksum_rd_data.padbytes   )
        ,.chksum_src_tx_data_rdy        (chksum_fifo_rd_rdy             )

        // I/O to the MAC side
        ,.chksum_dst_tx_hdr_val         (chksum_tcp_tx_out_hdr_val      )
        ,.chksum_dst_tx_src_ip          (chksum_tcp_tx_out_src_ip       )
        ,.chksum_dst_tx_dst_ip          (chksum_tcp_tx_out_dst_ip       )
        ,.chksum_dst_tx_tcp_len         (chksum_tcp_tx_out_tcp_len      )
        ,.dst_chksum_tx_hdr_rdy         (tcp_tx_out_chksum_hdr_rdy      )

        ,.chksum_dst_tx_data_val        (chksum_tcp_tx_out_data_val     )
        ,.chksum_dst_tx_data            (chksum_tcp_tx_out_data         )
        ,.chksum_dst_tx_data_last       (chksum_tcp_tx_out_last         )
        ,.chksum_dst_tx_data_padbytes   (chksum_tcp_tx_out_padbytes     )
        ,.dst_chksum_tx_data_rdy        (tcp_tx_out_chksum_data_rdy     )
    );


    to_ip_tx_noc_out #(
         .SRC_X (SRC_X          )
        ,.SRC_Y (SRC_Y          )
    ) tcp_tx_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.to_ip_tx_out_noc0_val         (tcp_tx_out_noc0_val                )
        ,.to_ip_tx_out_noc0_data        (tcp_tx_out_noc0_data               )
        ,.noc0_to_ip_tx_out_rdy         (noc0_tcp_tx_out_rdy                )
                                                                            
        ,.src_to_ip_tx_out_hdr_val      (chksum_tcp_tx_out_hdr_val          )
        ,.src_to_ip_tx_out_src_ip       (chksum_tcp_tx_out_src_ip           )
        ,.src_to_ip_tx_out_dst_ip       (chksum_tcp_tx_out_dst_ip           )
        ,.src_to_ip_tx_out_payload_len  (chksum_tcp_tx_out_tcp_len          )
        ,.src_to_ip_tx_out_protocol     (`IPPROTO_TCP                       )
        ,.src_to_ip_tx_out_dst_x        (TCP_LOGGER_TX_TILE_X[`XY_WIDTH-1:0])
        ,.src_to_ip_tx_out_dst_y        (TCP_LOGGER_TX_TILE_Y[`XY_WIDTH-1:0])
        ,.to_ip_tx_out_src_hdr_rdy      (tcp_tx_out_chksum_hdr_rdy          )

        ,.src_to_ip_tx_out_data_val     (chksum_tcp_tx_out_data_val         )
        ,.src_to_ip_tx_out_data         (chksum_tcp_tx_out_data             )
        ,.src_to_ip_tx_out_last         (chksum_tcp_tx_out_last             )
        ,.src_to_ip_tx_out_padbytes     (chksum_tcp_tx_out_padbytes         )
        ,.to_ip_tx_out_src_data_rdy     (tcp_tx_out_chksum_data_rdy         )
    );

    tcp_tx_app_if_wrap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) tx_app_if (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_tcp_tx_ptr_if_val      (noc0_ctovr_tcp_tx_ptr_if_val   )
        ,.noc0_ctovr_tcp_tx_ptr_if_data     (noc0_ctovr_tcp_tx_ptr_if_data  )
        ,.tcp_tx_ptr_if_noc0_ctovr_rdy      (tcp_tx_ptr_if_noc0_ctovr_rdy   )
                                                                            
        ,.tcp_tx_ptr_if_noc0_vrtoc_val      (tcp_tx_ptr_if_noc0_vrtoc_val   )
        ,.tcp_tx_ptr_if_noc0_vrtoc_data     (tcp_tx_ptr_if_noc0_vrtoc_data  )
        ,.noc0_vrtoc_tcp_tx_ptr_if_rdy      (noc0_vrtoc_tcp_tx_ptr_if_rdy   )
                                                                            
        ,.app_tail_ptr_tx_wr_req_val        (app_tail_ptr_tx_wr_req_val     )
        ,.app_tail_ptr_tx_wr_req_addr       (app_tail_ptr_tx_wr_req_flowid  )
        ,.app_tail_ptr_tx_wr_req_data       (app_tail_ptr_tx_wr_req_data    )
        ,.tail_ptr_app_tx_wr_req_rdy        (tail_ptr_app_tx_wr_req_rdy     )
                                                                            
        ,.app_tail_ptr_tx_rd_req_val        (app_tail_ptr_tx_rd_req_val     )
        ,.app_tail_ptr_tx_rd_req_addr       (app_tail_ptr_tx_rd_req_flowid  )
        ,.tail_ptr_app_tx_rd_req_rdy        (tail_ptr_app_tx_rd_req_rdy     )
                                                                            
        ,.tail_ptr_app_tx_rd_resp_val       (tail_ptr_app_tx_rd_resp_val    )
        ,.tail_ptr_app_tx_rd_resp_addr      (tail_ptr_app_tx_rd_resp_flowid )
        ,.tail_ptr_app_tx_rd_resp_data      (tail_ptr_app_tx_rd_resp_data   )
        ,.app_tail_ptr_tx_rd_resp_rdy       (app_tail_ptr_tx_rd_resp_rdy    )
                                                                            
        ,.app_head_ptr_tx_rd_req_val        (app_head_ptr_tx_rd_req_val     )
        ,.app_head_ptr_tx_rd_req_addr       (app_head_ptr_tx_rd_req_flowid  )
        ,.head_ptr_app_tx_rd_req_rdy        (head_ptr_app_tx_rd_req_rdy     )
                                                                            
        ,.head_ptr_app_tx_rd_resp_val       (head_ptr_app_tx_rd_resp_val    )
        ,.head_ptr_app_tx_rd_resp_addr      (head_ptr_app_tx_rd_resp_flowid )
        ,.head_ptr_app_tx_rd_resp_data      (head_ptr_app_tx_rd_resp_data   )
        ,.app_head_ptr_tx_rd_resp_rdy       (app_head_ptr_tx_rd_resp_rdy    )
    );
endmodule
