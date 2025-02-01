`include "packet_defs.vh"
`include "soc_defs.vh"
module beehive_tcp_slow_engine_wrap 
import tcp_rx_tile_pkg::*;
import tcp_pkg::*;
import tcp_misc_pkg::*;
import packet_struct_pkg::*;
(
     input clk
    ,input rst

    ,input                                      src_tmp_buf_rx_hdr_val
    ,output logic                               tmp_buf_src_rx_hdr_rdy
    ,input          [`IP_ADDR_W-1:0]            src_tmp_buf_rx_src_ip
    ,input          [`IP_ADDR_W-1:0]            src_tmp_buf_rx_dst_ip
    ,input          [`TOT_LEN_W-1:0]            src_tmp_buf_rx_tcp_payload_len
    ,input tcp_pkt_hdr                          src_tmp_buf_rx_tcp_hdr
    
    ,input                                      src_tmp_buf_rx_data_val
    ,input          [`MAC_INTERFACE_W-1:0]      src_tmp_buf_rx_data
    ,input                                      src_tmp_buf_rx_data_last
    ,input          [`MAC_PADBYTES_W-1:0]       src_tmp_buf_rx_data_padbytes
    ,output logic                               tmp_buf_src_rx_data_rdy
    
    ,output                                     send_dst_tx_val
    ,output logic   [FLOWID_W-1:0]              send_dst_tx_flowid
    ,output logic   [`IP_ADDR_W-1:0]            send_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            send_dst_tx_dst_ip
    ,output tcp_pkt_hdr                         send_dst_tx_tcp_hdr
    ,output payload_buf_struct                  send_dst_tx_payload
    ,input                                      dst_send_tx_rdy

    ,output logic                               app_new_flow_notif_val
    ,output logic   [FLOWID_W-1:0]              app_new_flow_flowid
    ,output four_tuple_struct                   app_new_flow_lookup
    ,input  logic                               app_new_flow_notif_rdy
    
    ,input  logic                               rx_store_buf_q_rd_req_val
    ,output rx_store_buf_q_struct               rx_store_buf_q_rd_req_data
    ,output logic                               rx_store_buf_q_empty
    
    ,input  logic                               src_tmp_buf_store_rd_req_val
    ,input          [PAYLOAD_ENTRY_ADDR_W-1:0]  src_tmp_buf_store_rd_req_addr
    ,output logic                               tmp_buf_store_src_rd_req_rdy

    ,output logic                               tmp_buf_store_src_rd_resp_val
    ,output logic   [`MAC_INTERFACE_W-1:0]      tmp_buf_store_src_rd_resp_data
    ,input  logic                               src_tmp_buf_store_rd_resp_rdy

    ,input  logic                               src_tmp_buf_free_slab_req_val
    ,input  logic   [RX_TMP_BUF_ADDR_W-1:0]     src_tmp_buf_free_slab_req_addr
    ,output logic                               tmp_buf_free_slab_src_req_rdy
    
    ,input                                      app_tail_ptr_tx_wr_req_val
    ,input          [FLOWID_W-1:0]              app_tail_ptr_tx_wr_req_flowid
    ,input          [TX_PAYLOAD_PTR_W:0]        app_tail_ptr_tx_wr_req_data
    ,output                                     tail_ptr_app_tx_wr_req_rdy
    
    ,input                                      app_tail_ptr_tx_rd_req_val
    ,input          [FLOWID_W-1:0]              app_tail_ptr_tx_rd_req_flowid
    ,output logic                               tail_ptr_app_tx_rd_req_rdy

    ,output                                     tail_ptr_app_tx_rd_resp_val
    ,output logic   [FLOWID_W-1:0]              tail_ptr_app_tx_rd_resp_flowid
    ,output logic   [TX_PAYLOAD_PTR_W:0]        tail_ptr_app_tx_rd_resp_data
    ,input  logic                               app_tail_ptr_tx_rd_resp_rdy

    ,input                                      app_head_ptr_tx_rd_req_val
    ,input          [FLOWID_W-1:0]              app_head_ptr_tx_rd_req_flowid
    ,output logic                               head_ptr_app_tx_rd_req_rdy

    ,output                                     head_ptr_app_tx_rd_resp_val
    ,output logic   [FLOWID_W-1:0]              head_ptr_app_tx_rd_resp_flowid
    ,output logic   [TX_PAYLOAD_PTR_W:0]        head_ptr_app_tx_rd_resp_data
    ,input  logic                               app_head_ptr_tx_rd_resp_rdy
    
    ,input  logic                               app_rx_head_idx_wr_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_head_idx_wr_req_addr
    ,input  tcp_buf_idx                         app_rx_head_idx_wr_req_data
    ,output logic                               rx_head_idx_app_wr_req_rdy

    ,input  logic                               app_rx_head_idx_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_head_idx_rd_req_addr
    ,output logic                               rx_head_idx_app_rd_req_rdy
    
    ,output logic                               rx_head_idx_app_rd_resp_val
    ,output tcp_buf_idx                         rx_head_idx_app_rd_resp_data
    ,input  logic                               app_rx_head_idx_rd_resp_rdy

    ,input  logic                               app_rx_commit_idx_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_commit_idx_rd_req_addr
    ,output logic                               rx_commit_idx_app_rd_req_rdy

    ,output logic                               rx_commit_idx_app_rd_resp_val
    ,output tcp_buf_idx                         rx_commit_idx_app_rd_resp_data
    ,input  logic                               app_rx_commit_idx_rd_resp_rdy

    ,input  logic                               app_rx_free_req_val
    ,input  logic   [RX_PAYLOAD_PTR_W-1:0]      app_rx_free_req_addr
    ,input  logic   [MALLOC_LEN_W-1:0]          app_rx_free_req_len
    ,output logic                               rx_free_app_req_rdy
    
    ,input  logic                               store_buf_commit_idx_wr_req_val
    ,input  logic   [FLOWID_W-1:0]              store_buf_commit_idx_wr_req_addr
    ,input  tcp_buf_idx                         store_buf_commit_idx_wr_req_data
    ,output logic                               commit_idx_store_buf_wr_req_rdy

    ,input  logic                               store_buf_commit_idx_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              store_buf_commit_idx_rd_req_addr
    ,output logic                               commit_idx_store_buf_rd_req_rdy

    ,output logic                               commit_idx_store_buf_rd_resp_val
    ,output tcp_buf_idx                         commit_idx_store_buf_rd_resp_data
    ,input  logic                               store_buf_commit_idx_rd_resp_rdy
    
    ,input  logic                               app_sched_update_val
    ,input  sched_cmd_struct                    app_sched_update_cmd
    ,output logic                               sched_app_update_rdy

    ,input  logic                               app_rx_head_buf_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_head_buf_rd_req_flowid
    ,input  logic   [RX_PAYLOAD_IDX_W-1:0]      app_rx_head_buf_rd_req_idx
    ,output logic                               rx_head_buf_app_rd_req_rdy

    ,output logic                               rx_head_buf_app_rd_resp_val
    ,output         tcp_buf                     rx_head_buf_app_rd_resp_data
    ,input  logic                               app_rx_head_buf_rd_resp_rdy

    ,input                                  rx_store_buf_rx_buf_store_rd_req_val
    ,input          [FLOWID_W-1:0]          rx_store_buf_rx_buf_store_rd_req_flowid
    ,input          [RX_PAYLOAD_IDX_W-1:0]  rx_store_buf_rx_buf_store_rd_req_idx
    ,output logic                           rx_buf_store_rx_store_buf_rd_req_rdy

    ,output logic                           rx_buf_store_rx_store_buf_rd_resp_val
    ,output         tcp_buf                 rx_buf_store_rx_store_buf_rd_resp_data
    ,input                                  rx_store_buf_rx_buf_store_rd_resp_rdy
);
    logic                       tmp_buf_engine_rx_hdr_val;
    logic                       engine_tmp_buf_rx_rdy;
    logic   [`IP_ADDR_W-1:0]    tmp_buf_engine_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]    tmp_buf_engine_rx_dst_ip;
    tcp_pkt_hdr                 tmp_buf_engine_rx_tcp_hdr;
    logic                       tmp_buf_engine_rx_payload_val;
    payload_buf_struct          tmp_buf_engine_rx_payload_entry;
   
    logic                       tcp_rx_store_buf_val;
    logic   [FLOWID_W-1:0]      tcp_rx_store_buf_flowid;
    logic                       tcp_rx_store_buf_pkt_accept;
    payload_buf_struct          tcp_rx_store_buf_payload_entry;
    logic                       store_buf_tcp_rx_rdy;

    assign rx_store_buf_q_empty = ~tcp_rx_store_buf_val;
    assign store_buf_tcp_rx_rdy = rx_store_buf_q_rd_req_val;
    assign rx_store_buf_q_rd_req_data.flowid = tcp_rx_store_buf_flowid;
    assign rx_store_buf_q_rd_req_data.accept_payload = tcp_rx_store_buf_pkt_accept;
    assign rx_store_buf_q_rd_req_data.payload_entry = tcp_rx_store_buf_payload_entry;

    tcp engine (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_tcp_rx_hdr_val                (tmp_buf_engine_rx_hdr_val          )
        ,.src_tcp_rx_src_ip                 (tmp_buf_engine_rx_src_ip           )
        ,.src_tcp_rx_dst_ip                 (tmp_buf_engine_rx_dst_ip           )
        ,.src_tcp_rx_tcp_hdr                (tmp_buf_engine_rx_tcp_hdr          )
        ,.src_tcp_rx_payload_entry          (tmp_buf_engine_rx_payload_entry    )
        ,.tcp_src_rx_hdr_rdy                (engine_tmp_buf_rx_rdy              )
    
        ,.tx_pkt_hdr_val                    (send_dst_tx_val                    )
        ,.tx_pkt_hdr                        (send_dst_tx_tcp_hdr                )
        ,.tx_pkt_flowid                     (send_dst_tx_flowid                 )
        ,.tx_pkt_src_ip_addr                (send_dst_tx_src_ip                 )
        ,.tx_pkt_dst_ip_addr                (send_dst_tx_dst_ip                 )
        ,.tx_pkt_payload                    (send_dst_tx_payload                )
        ,.tx_pkt_hdr_rdy                    (dst_send_tx_rdy                    )
       
        /********************************
         * RX copy to buffers
         *******************************/
        ,.tcp_rx_dst_hdr_val                (tcp_rx_store_buf_val               )
        ,.tcp_rx_dst_flowid                 (tcp_rx_store_buf_flowid            )
        ,.tcp_rx_dst_pkt_accept             (tcp_rx_store_buf_pkt_accept        )
        ,.tcp_rx_dst_payload_entry          (tcp_rx_store_buf_payload_entry     )
        ,.dst_tcp_rx_hdr_rdy                (store_buf_tcp_rx_rdy               )
    
        ,.store_buf_commit_idx_wr_req_val   (store_buf_commit_idx_wr_req_val    )
        ,.store_buf_commit_idx_wr_req_addr  (store_buf_commit_idx_wr_req_addr   )
        ,.store_buf_commit_idx_wr_req_data  (store_buf_commit_idx_wr_req_data   )
        ,.commit_idx_store_buf_wr_req_rdy   (commit_idx_store_buf_wr_req_rdy    )
                                                                                
        ,.store_buf_commit_idx_rd_req_val   (store_buf_commit_idx_rd_req_val    )
        ,.store_buf_commit_idx_rd_req_addr  (store_buf_commit_idx_rd_req_addr   )
        ,.commit_idx_store_buf_rd_req_rdy   (commit_idx_store_buf_rd_req_rdy    )
                                                                                
        ,.commit_idx_store_buf_rd_resp_val  (commit_idx_store_buf_rd_resp_val   )
        ,.commit_idx_store_buf_rd_resp_data (commit_idx_store_buf_rd_resp_data  )
        ,.store_buf_commit_idx_rd_resp_rdy  (store_buf_commit_idx_rd_resp_rdy   )
    
        /********************************
         * App interface
         *******************************/
        ,.app_new_flow_notif_val            (app_new_flow_notif_val             )
        ,.app_new_flow_flowid               (app_new_flow_flowid                )
        ,.app_new_flow_entry                (app_new_flow_lookup                )
        ,.app_new_flow_notif_rdy            (app_new_flow_notif_rdy             )
        
        ,.app_rx_head_idx_wr_req_val        (app_rx_head_idx_wr_req_val         )
        ,.app_rx_head_idx_wr_req_addr       (app_rx_head_idx_wr_req_addr        )
        ,.app_rx_head_idx_wr_req_data       (app_rx_head_idx_wr_req_data        )
        ,.rx_head_idx_app_wr_req_rdy        (rx_head_idx_app_wr_req_rdy         )

        ,.app_rx_head_idx_rd_req_val        (app_rx_head_idx_rd_req_val         )
        ,.app_rx_head_idx_rd_req_addr       (app_rx_head_idx_rd_req_addr        )
        ,.rx_head_idx_app_rd_req_rdy        (rx_head_idx_app_rd_req_rdy         )
                                                                                
        ,.rx_head_idx_app_rd_resp_val       (rx_head_idx_app_rd_resp_val        )
        ,.rx_head_idx_app_rd_resp_data      (rx_head_idx_app_rd_resp_data       )
        ,.app_rx_head_idx_rd_resp_rdy       (app_rx_head_idx_rd_resp_rdy        )
        
        ,.app_rx_commit_idx_rd_req_val      (app_rx_commit_idx_rd_req_val       )
        ,.app_rx_commit_idx_rd_req_addr     (app_rx_commit_idx_rd_req_addr      )
        ,.rx_commit_idx_app_rd_req_rdy      (rx_commit_idx_app_rd_req_rdy       )
                                                                                
        ,.rx_commit_idx_app_rd_resp_val     (rx_commit_idx_app_rd_resp_val      )
        ,.rx_commit_idx_app_rd_resp_data    (rx_commit_idx_app_rd_resp_data     )
        ,.app_rx_commit_idx_rd_resp_rdy     (app_rx_commit_idx_rd_resp_rdy      )
        
        ,.app_rx_free_req_val               (app_rx_free_req_val                )
        ,.app_rx_free_req_addr              (app_rx_free_req_addr               )
        ,.app_rx_free_req_len               (app_rx_free_req_len                )
        ,.rx_free_app_req_rdy               (rx_free_app_req_rdy                )

        ,.app_tx_head_ptr_rd_req_val        (app_head_ptr_tx_rd_req_val         )
        ,.app_tx_head_ptr_rd_req_addr       (app_head_ptr_tx_rd_req_flowid      )
        ,.tx_head_ptr_app_rd_req_rdy        (head_ptr_app_tx_rd_req_rdy         )
    
        ,.tx_head_ptr_app_rd_resp_val       (head_ptr_app_tx_rd_resp_val        )
        ,.tx_head_ptr_app_rd_resp_addr      (head_ptr_app_tx_rd_resp_flowid     )
        ,.tx_head_ptr_app_rd_resp_data      (head_ptr_app_tx_rd_resp_data       )
        ,.app_tx_head_ptr_rd_resp_rdy       (app_head_ptr_tx_rd_resp_rdy        )
        
        ,.app_tx_tail_ptr_wr_req_val        (app_tail_ptr_tx_wr_req_val         )
        ,.app_tx_tail_ptr_wr_req_addr       (app_tail_ptr_tx_wr_req_flowid      )
        ,.app_tx_tail_ptr_wr_req_data       (app_tail_ptr_tx_wr_req_data        )
        ,.tx_tail_ptr_app_wr_req_rdy        (tail_ptr_app_tx_wr_req_rdy         )
        
        ,.app_tx_tail_ptr_rd_req_val        (app_tail_ptr_tx_rd_req_val         )
        ,.app_tx_tail_ptr_rd_req_addr       (app_tail_ptr_tx_rd_req_flowid      )
        ,.tx_tail_ptr_app_rd_req_rdy        (tail_ptr_app_tx_rd_req_rdy         )
        
        ,.tx_tail_ptr_app_rd_resp_val       (tail_ptr_app_tx_rd_resp_val        )
        ,.tx_tail_ptr_app_rd_resp_flowid    (tail_ptr_app_tx_rd_resp_flowid     )
        ,.tx_tail_ptr_app_rd_resp_data      (tail_ptr_app_tx_rd_resp_data       )
        ,.app_tx_tail_ptr_rd_resp_rdy       (app_tail_ptr_tx_rd_resp_rdy        )

        ,.app_sched_update_val              (app_sched_update_val               )
        ,.app_sched_update_cmd              (app_sched_update_cmd               )
        ,.sched_app_update_rdy              (sched_app_update_rdy               )

        ,.app_rx_head_buf_rd_req_val        (app_rx_head_buf_rd_req_val         )
        ,.app_rx_head_buf_rd_req_flowid     (app_rx_head_buf_rd_req_flowid      )
        ,.app_rx_head_buf_rd_req_idx        (app_rx_head_buf_rd_req_idx         )
        ,.rx_head_buf_app_rd_req_rdy        (rx_head_buf_app_rd_req_rdy         )

        ,.rx_head_buf_app_rd_resp_val       (rx_head_buf_app_rd_resp_val        )
        ,.rx_head_buf_app_rd_resp_data      (rx_head_buf_app_rd_resp_data       )
        ,.app_rx_head_buf_rd_resp_rdy       (app_rx_head_buf_rd_resp_rdy        )
        
        ,.rx_store_buf_rx_buf_store_rd_req_val(rx_store_buf_rx_buf_store_rd_req_val)
        ,.rx_store_buf_rx_buf_store_rd_req_flowid(rx_store_buf_rx_buf_store_rd_req_flowid)
        ,.rx_store_buf_rx_buf_store_rd_req_idx(rx_store_buf_rx_buf_store_rd_req_idx)
        ,.rx_buf_store_rx_store_buf_rd_req_rdy(rx_buf_store_rx_store_buf_rd_req_rdy)

        ,.rx_buf_store_rx_store_buf_rd_resp_val(rx_buf_store_rx_store_buf_rd_resp_val)
        ,.rx_buf_store_rx_store_buf_rd_resp_data(rx_buf_store_rx_store_buf_rd_resp_data)
        ,.rx_store_buf_rx_buf_store_rd_resp_rdy(rx_store_buf_rx_buf_store_rd_resp_rdy)  
    );

    // drop if the tmp buf is backpressuring

    tcp_tmp_rx_buf_wrap tmp_buffer (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_tmp_buf_rx_hdr_val            (src_tmp_buf_rx_hdr_val         )
        ,.tmp_buf_src_rx_hdr_rdy            (tmp_buf_src_rx_hdr_rdy         )
        ,.src_tmp_buf_rx_src_ip             (src_tmp_buf_rx_src_ip          )
        ,.src_tmp_buf_rx_dst_ip             (src_tmp_buf_rx_dst_ip          )
        ,.src_tmp_buf_rx_tcp_payload_len    (src_tmp_buf_rx_tcp_payload_len )
        ,.src_tmp_buf_rx_tcp_hdr            (src_tmp_buf_rx_tcp_hdr         )
                                                                            
        ,.src_tmp_buf_rx_data_val           (src_tmp_buf_rx_data_val        )
        ,.src_tmp_buf_rx_data               (src_tmp_buf_rx_data            )
        ,.src_tmp_buf_rx_data_last          (src_tmp_buf_rx_data_last       )
        ,.src_tmp_buf_rx_data_padbytes      (src_tmp_buf_rx_data_padbytes   )
        ,.tmp_buf_src_rx_data_rdy           (tmp_buf_src_rx_data_rdy        )
        
        ,.tmp_buf_dst_rx_hdr_val            (tmp_buf_engine_rx_hdr_val      )
        ,.tmp_buf_dst_rx_src_ip             (tmp_buf_engine_rx_src_ip       )
        ,.tmp_buf_dst_rx_dst_ip             (tmp_buf_engine_rx_dst_ip       )
        ,.tmp_buf_dst_rx_tcp_hdr            (tmp_buf_engine_rx_tcp_hdr      )
        ,.tmp_buf_dst_rx_payload_val        ()
        ,.tmp_buf_dst_rx_payload_entry      (tmp_buf_engine_rx_payload_entry)
        ,.dst_tmp_buf_rx_rdy                (engine_tmp_buf_rx_rdy          )
    
        ,.src_tmp_buf_store_rd_req_val      (src_tmp_buf_store_rd_req_val   )
        ,.src_tmp_buf_store_rd_req_addr     (src_tmp_buf_store_rd_req_addr  )
        ,.tmp_buf_store_src_rd_req_rdy      (tmp_buf_store_src_rd_req_rdy   )
    
        ,.tmp_buf_store_src_rd_resp_val     (tmp_buf_store_src_rd_resp_val  )
        ,.tmp_buf_store_src_rd_resp_data    (tmp_buf_store_src_rd_resp_data )
        ,.src_tmp_buf_store_rd_resp_rdy     (src_tmp_buf_store_rd_resp_rdy  )
    
        ,.src_tmp_buf_free_slab_req_val     (src_tmp_buf_free_slab_req_val  )
        ,.src_tmp_buf_free_slab_req_addr    (src_tmp_buf_free_slab_req_addr )
        ,.tmp_buf_free_slab_src_req_rdy     (tmp_buf_free_slab_src_req_rdy  )
    );

    // add a small buffer for the metadata to be fed into the receive side since we don't
    //  have the extra buffering from the pipeline
endmodule
