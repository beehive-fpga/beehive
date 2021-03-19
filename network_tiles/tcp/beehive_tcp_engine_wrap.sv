`include "beehive_tcp_engine_defs.svh"
module beehive_tcp_engine_wrap (
     input clk
    ,input rst
    
    // Write req inputs
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
    
    ,input  logic                               app_rx_head_ptr_wr_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_head_ptr_wr_req_addr
    ,input  logic   [RX_PAYLOAD_PTR_W:0]        app_rx_head_ptr_wr_req_data
    ,output logic                               rx_head_ptr_app_wr_req_rdy

    ,input  logic                               app_rx_head_ptr_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_head_ptr_rd_req_addr
    ,output logic                               rx_head_ptr_app_rd_req_rdy
    
    ,output logic                               rx_head_ptr_app_rd_resp_val
    ,output logic   [RX_PAYLOAD_PTR_W:0]        rx_head_ptr_app_rd_resp_data
    ,input  logic                               app_rx_head_ptr_rd_resp_rdy

    ,input  logic                               app_rx_commit_ptr_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              app_rx_commit_ptr_rd_req_addr
    ,output logic                               rx_commit_ptr_app_rd_req_rdy

    ,output logic                               rx_commit_ptr_app_rd_resp_val
    ,output logic   [RX_PAYLOAD_PTR_W:0]        rx_commit_ptr_app_rd_resp_data
    ,input  logic                               app_rx_commit_ptr_rd_resp_rdy
    
    ,input  logic                               store_buf_commit_ptr_wr_req_val
    ,input  logic   [FLOWID_W-1:0]              store_buf_commit_ptr_wr_req_addr
    ,input  logic   [RX_PAYLOAD_PTR_W:0]        store_buf_commit_ptr_wr_req_data
    ,output logic                               commit_ptr_store_buf_wr_req_rdy

    ,input  logic                               store_buf_commit_ptr_rd_req_val
    ,input  logic   [FLOWID_W-1:0]              store_buf_commit_ptr_rd_req_addr
    ,output logic                               commit_ptr_store_buf_rd_req_rdy

    ,output logic                               commit_ptr_store_buf_rd_resp_val
    ,output logic   [RX_PAYLOAD_PTR_W:0]        commit_ptr_store_buf_rd_resp_data
    ,input  logic                               store_buf_commit_ptr_rd_resp_rdy
    
    ,input  logic                               app_sched_update_val
    ,input  sched_cmd_struct                    app_sched_update_cmd
    ,output logic                               sched_app_update_rdy

);
    logic                           tmp_buf_rx_pipe_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        tmp_buf_rx_pipe_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        tmp_buf_rx_pipe_rx_dst_ip;
    tcp_pkt_hdr                     tmp_buf_rx_pipe_rx_tcp_hdr;
    logic                           rx_pipe_tmp_buf_rx_rdy;

    logic                           tmp_buf_rx_pipe_rx_payload_val;
    payload_buf_struct              tmp_buf_rx_pipe_rx_payload_entry;
    
    logic                           send_q_tail_ptr_rd_req_val;
    logic   [FLOWID_W-1:0]          send_q_tail_ptr_rd_req_flowid;
    logic                           send_q_tail_ptr_rd_req_rdy;

    logic                           send_q_tail_ptr_rd_resp_val;
    logic   [TX_PAYLOAD_PTR_W:0]    send_q_tail_ptr_rd_resp_data;
    logic                           send_q_tail_ptr_rd_resp_rdy;
    
    logic                           rx_pipe_tx_head_ptr_wr_req_val;
    logic   [FLOWID_W-1:0]          rx_pipe_tx_head_ptr_wr_req_flowid;
    logic   [TX_PAYLOAD_PTR_W:0]    rx_pipe_tx_head_ptr_wr_req_data;
    logic                           tx_head_ptr_rx_pipe_wr_req_rdy;
    
    logic                           send_pipe_tx_state_rd_req_val;
    logic   [FLOWID_W-1:0]          send_pipe_tx_state_rd_req_flowid;
    logic                           tx_state_send_pipe_rd_req_rdy;

    logic                           tx_state_send_pipe_rd_resp_val;
    tx_state_struct                 tx_state_send_pipe_rd_resp_data;
    logic                           send_pipe_tx_state_rd_resp_rdy;

    logic                           send_pipe_tx_state_wr_req_val;
    logic   [FLOWID_W-1:0]          send_pipe_tx_state_wr_req_flowid;
    tx_state_struct                 send_pipe_tx_state_wr_req_data;
    logic                           tx_state_send_pipe_wr_req_rdy;
    
    logic                           new_flow_val;
    logic   [FLOWID_W-1:0]          new_flow_flowid;
    four_tuple_struct               new_flow_lookup_entry;
    tx_state_struct                 new_flow_tx_state;
    recv_state_entry                new_flow_rx_state;
    logic                           new_flow_rdy;

    logic                           new_flow_send_pipe_rdy;
    logic                           new_flow_tx_payload_ptrs_rdy;
    logic                           new_flow_tx_state_rdy;
    logic                           new_flow_rx_state_rdy;
    
    logic                           curr_recv_state_rd_req_val;
    logic   [FLOWID_W-1:0]          curr_recv_state_rd_req_addr;
    logic                           curr_recv_state_rd_req_rdy;

    logic                           curr_recv_state_rd_resp_val;
    recv_state_entry                curr_recv_state_rd_resp_data;
    logic                           curr_recv_state_rd_resp_rdy;
    
    logic                           next_recv_state_wr_req_val;
    logic   [FLOWID_W-1:0]          next_recv_state_wr_req_addr;
    recv_state_entry                next_recv_state_wr_req_data;
    logic                           next_recv_state_wr_req_rdy;
    
    logic                           send_pipe_recv_state_rd_req_val;
    logic   [FLOWID_W-1:0]          send_pipe_recv_state_rd_req_flowid;
    logic                           recv_state_send_pipe_rd_req_rdy;

    logic                           recv_state_send_pipe_rd_resp_val;
    recv_state_entry                recv_state_send_pipe_rd_resp_data;
    logic                           send_pipe_recv_state_rd_resp_rdy;
    
    logic                           recv_pipe_tx_state_rd_req_val;
    logic   [FLOWID_W-1:0]          recv_pipe_tx_state_rd_req_flowid;
    tx_state_struct                 recv_pipe_tx_state_rd_req_data;
    logic                           tx_state_recv_pipe_rd_req_rdy;

    logic                           tx_state_recv_pipe_rd_resp_val;
    tx_state_struct                 tx_state_recv_pipe_rd_resp_data;
    logic                           recv_pipe_tx_state_rd_resp_rdy;

    logic                           recv_pipe_tx_state_wr_req_val;
    logic   [FLOWID_W-1:0]          recv_pipe_tx_state_wr_req_flowid;
    tx_state_struct                 recv_pipe_tx_state_wr_req_data;
    logic                           tx_state_recv_pipe_wr_req_rdy;
    
    logic                           rx_send_queue_deq_req_val;
    rx_send_queue_struct            rx_send_queue_deq_resp_data;
    logic                           rx_send_queue_empty;

    logic                           rx_send_queue_enq_req_val;
    rx_send_queue_struct            rx_send_queue_enq_req_data;
    logic                           send_queue_rx_full;
    
    logic                           rx_pipe_rt_store_set_rt_flag_val;
    logic   [FLOWID_W-1:0]          rx_pipe_rt_store_set_rt_flag_flowid;
    
    logic                           tx_pipe_dst_tx_val;
    logic   [FLOWID_W-1:0]          tx_pipe_dst_tx_flowid;
    logic   [`IP_ADDR_W-1:0]        tx_pipe_dst_tx_src_ip;
    logic   [`IP_ADDR_W-1:0]        tx_pipe_dst_tx_dst_ip;
    tcp_pkt_hdr                     tx_pipe_dst_tx_tcp_hdr;
    payload_buf_struct              tx_pipe_dst_tx_payload;
    logic                           dst_tx_pipe_tx_rdy;


    logic                           rx_pipe_rx_head_ptr_rd_req_val;
    logic   [FLOWID_W-1:0]          rx_pipe_rx_head_ptr_rd_req_addr;
    logic                           rx_head_ptr_rx_pipe_rd_req_rdy;

    logic                           rx_head_ptr_rx_pipe_rd_resp_val;
    logic   [RX_PAYLOAD_PTR_W:0]    rx_head_ptr_rx_pipe_rd_resp_data;
    logic                           rx_pipe_rx_head_ptr_rd_resp_rdy;
    
    logic                           rx_pipe_rx_commit_ptr_wr_req_val;
    logic   [FLOWID_W-1:0]          rx_pipe_rx_commit_ptr_wr_req_addr;
    logic   [RX_PAYLOAD_PTR_W:0]    rx_pipe_rx_commit_ptr_wr_req_data;
    logic                           rx_commit_ptr_rx_pipe_wr_req_rdy;

    logic                           rx_pipe_rx_commit_ptr_rd_req_val;
    logic   [FLOWID_W-1:0]          rx_pipe_rx_commit_ptr_rd_req_addr;
    logic                           rx_commit_ptr_rx_pipe_rd_req_rdy;

    logic                           rx_commit_ptr_rx_pipe_rd_resp_val;
    logic   [RX_PAYLOAD_PTR_W:0]    rx_commit_ptr_rx_pipe_rd_resp_data;
    logic                           rx_pipe_rx_commit_ptr_rd_resp_rdy;

    logic                           rx_pipe_rx_tail_ptr_wr_req_val;
    logic   [FLOWID_W-1:0]          rx_pipe_rx_tail_ptr_wr_req_addr;
    logic   [RX_PAYLOAD_PTR_W:0]    rx_pipe_rx_tail_ptr_wr_req_data;
    logic                           rx_tail_ptr_rx_pipe_wr_req_rdy;

    logic                           rx_pipe_rx_tail_ptr_rd_req_val;
    logic   [FLOWID_W-1:0]          rx_pipe_rx_tail_ptr_rd_req_addr;
    logic                           rx_tail_ptr_rx_pipe_rd_req_rdy;

    logic                           rx_tail_ptr_rx_pipe_rd_resp_val;
    logic   [RX_PAYLOAD_PTR_W:0]    rx_tail_ptr_rx_pipe_rd_resp_data;
    logic                           rx_pipe_rx_tail_ptr_rd_resp_rdy;

    logic   [RX_PAYLOAD_PTR_W:0]    new_rx_head_ptr;
    logic   [RX_PAYLOAD_PTR_W:0]    new_rx_tail_ptr;
    logic                           new_flow_rx_payload_ptrs_rdy;

    assign new_flow_rdy = new_flow_send_pipe_rdy 
                          & new_flow_tx_payload_ptrs_rdy 
                          & new_flow_tx_state_rdy
                          & new_flow_rx_state_rdy;

    assign sched_app_update_rdy = 1'b1;
    
    /**********************************************************************************
     * TX pipe
     *********************************************************************************/ 
    
    send_pipe_wrapper send_pipe (
         .clk   (clk)
        ,.rst   (rst)
    
        ,.src_new_flow_val                          (new_flow_val                           )
        ,.src_new_flow_flowid                       (new_flow_flowid                        )
        ,.src_new_flow_lookup_entry                 (new_flow_lookup_entry                  )
        ,.new_flow_src_rdy                          (new_flow_send_pipe_rdy                 )

        ,.send_q_tail_ptr_rd_req_val                (send_q_tail_ptr_rd_req_val             )
        ,.send_q_tail_ptr_rd_req_flowid             (send_q_tail_ptr_rd_req_flowid          )
        ,.send_q_tail_ptr_rd_req_rdy                (send_q_tail_ptr_rd_req_rdy             )
                                                                                  
        ,.send_q_tail_ptr_rd_resp_val               (send_q_tail_ptr_rd_resp_val            )
        ,.send_q_tail_ptr_rd_resp_data              (send_q_tail_ptr_rd_resp_data           )
        ,.send_q_tail_ptr_rd_resp_rdy               (send_q_tail_ptr_rd_resp_rdy            )
    
        ,.send_pipe_tx_state_rd_req_val             (send_pipe_tx_state_rd_req_val          )
        ,.send_pipe_tx_state_rd_req_flowid          (send_pipe_tx_state_rd_req_flowid       )
        ,.tx_state_send_pipe_rd_req_rdy             (tx_state_send_pipe_rd_req_rdy          )
                                                                                                      
        ,.tx_state_send_pipe_rd_resp_val            (tx_state_send_pipe_rd_resp_val         )
        ,.tx_state_send_pipe_rd_resp_data           (tx_state_send_pipe_rd_resp_data        )
        ,.send_pipe_tx_state_rd_resp_rdy            (send_pipe_tx_state_rd_resp_rdy         )
                                                                                                      
        ,.send_pipe_tx_state_wr_req_val             (send_pipe_tx_state_wr_req_val          )
        ,.send_pipe_tx_state_wr_req_flowid          (send_pipe_tx_state_wr_req_flowid       )
        ,.send_pipe_tx_state_wr_req_data            (send_pipe_tx_state_wr_req_data         )
        ,.tx_state_send_pipe_wr_req_rdy             (tx_state_send_pipe_wr_req_rdy          )
    
        ,.send_pipe_recv_state_rd_req_val           (send_pipe_recv_state_rd_req_val        )
        ,.send_pipe_recv_state_rd_req_flowid        (send_pipe_recv_state_rd_req_flowid     )
        ,.recv_state_send_pipe_rd_req_rdy           (recv_state_send_pipe_rd_req_rdy        )

        ,.recv_state_send_pipe_rd_resp_val          (recv_state_send_pipe_rd_resp_val       )
        ,.recv_state_send_pipe_rd_resp_data         (recv_state_send_pipe_rd_resp_data      )
        ,.send_pipe_recv_state_rd_resp_rdy          (send_pipe_recv_state_rd_resp_rdy       )
        
        ,.rx_pipe_rt_store_set_rt_flag_val          (rx_pipe_rt_store_set_rt_flag_val       )
        ,.rx_pipe_rt_store_set_rt_flag_flowid       (rx_pipe_rt_store_set_rt_flag_flowid    )

        ,.send_dst_tx_val                           (tx_pipe_dst_tx_val                     )
        ,.send_dst_tx_flowid                        (tx_pipe_dst_tx_flowid                  )
        ,.send_dst_tx_src_ip                        (tx_pipe_dst_tx_src_ip                  )
        ,.send_dst_tx_dst_ip                        (tx_pipe_dst_tx_dst_ip                  )
        ,.send_dst_tx_tcp_hdr                       (tx_pipe_dst_tx_tcp_hdr                 )
        ,.send_dst_tx_payload                       (tx_pipe_dst_tx_payload                 )
        ,.dst_send_tx_rdy                           (dst_tx_pipe_tx_rdy                     )
    );

    logic   [TX_PAYLOAD_PTR_W:0]  new_tx_head_ptr;
    logic   [TX_PAYLOAD_PTR_W:0]  new_tx_tail_ptr;

    assign new_tx_head_ptr = new_flow_tx_state.tx_curr_ack_state.tx_curr_ack_num[TX_PAYLOAD_PTR_W:0];
    assign new_tx_tail_ptr = new_flow_tx_state.tx_curr_ack_state.tx_curr_ack_num[TX_PAYLOAD_PTR_W:0];

    payload_pointers send_qs (
         .clk   (clk)
        ,.rst   (rst)

        ,.payload_head_ptr_rd_req0_val      (app_head_ptr_tx_rd_req_val         )
        ,.payload_head_ptr_rd_req0_flowid   (app_head_ptr_tx_rd_req_flowid      )
        ,.payload_head_ptr_rd_req0_rdy      (head_ptr_app_tx_rd_req_rdy         )

        ,.payload_head_ptr_rd_resp0_val     (head_ptr_app_tx_rd_resp_val        )
        ,.payload_head_ptr_rd_resp0_flowid  (head_ptr_app_tx_rd_resp_flowid     )
        ,.payload_head_ptr_rd_resp0_data    (head_ptr_app_tx_rd_resp_data       )
        ,.payload_head_ptr_rd_resp0_rdy     (app_head_ptr_tx_rd_resp_rdy        )

        ,.payload_head_ptr_rd_req1_val      (1'b0                               )
        ,.payload_head_ptr_rd_req1_flowid   ('0                                 )
        ,.payload_head_ptr_rd_req1_rdy      (                                   )

        ,.payload_head_ptr_rd_resp1_val     (                                   )
        ,.payload_head_ptr_rd_resp1_flowid  (                                   )
        ,.payload_head_ptr_rd_resp1_data    (                                   )
        ,.payload_head_ptr_rd_resp1_rdy     (1'b1                               )

        ,.payload_head_ptr_wr_req_val       (rx_pipe_tx_head_ptr_wr_req_val     )
        ,.payload_head_ptr_wr_req_flowid    (rx_pipe_tx_head_ptr_wr_req_flowid  )
        ,.payload_head_ptr_wr_req_data      (rx_pipe_tx_head_ptr_wr_req_data    )
        ,.payload_head_ptr_wr_req_rdy       (tx_head_ptr_rx_pipe_wr_req_rdy     )

        ,.payload_tail_ptr_rd_req0_val      (send_q_tail_ptr_rd_req_val         )
        ,.payload_tail_ptr_rd_req0_flowid   (send_q_tail_ptr_rd_req_flowid      )
        ,.payload_tail_ptr_rd_req0_rdy      (send_q_tail_ptr_rd_req_rdy         )

        ,.payload_tail_ptr_rd_resp0_val     (send_q_tail_ptr_rd_resp_val        )
        ,.payload_tail_ptr_rd_resp0_flowid  (                                   )
        ,.payload_tail_ptr_rd_resp0_data    (send_q_tail_ptr_rd_resp_data       )
        ,.payload_tail_ptr_rd_resp0_rdy     (send_q_tail_ptr_rd_resp_rdy        )

        ,.payload_tail_ptr_rd_req1_val      (app_tail_ptr_tx_rd_req_val         )
        ,.payload_tail_ptr_rd_req1_flowid   (app_tail_ptr_tx_rd_req_flowid      )
        ,.payload_tail_ptr_rd_req1_rdy      (tail_ptr_app_tx_rd_req_rdy         )

        ,.payload_tail_ptr_rd_resp1_val     (tail_ptr_app_tx_rd_resp_val        )
        ,.payload_tail_ptr_rd_resp1_flowid  (tail_ptr_app_tx_rd_resp_flowid     )
        ,.payload_tail_ptr_rd_resp1_data    (tail_ptr_app_tx_rd_resp_data       )
        ,.payload_tail_ptr_rd_resp1_rdy     (app_tail_ptr_tx_rd_resp_rdy        )

        ,.payload_tail_ptr_wr_req_val       (app_tail_ptr_tx_wr_req_val         )
        ,.payload_tail_ptr_wr_req_flowid    (app_tail_ptr_tx_wr_req_flowid      )
        ,.payload_tail_ptr_wr_req_data      (app_tail_ptr_tx_wr_req_data        )
        ,.payload_tail_ptr_wr_req_rdy       (tail_ptr_app_tx_wr_req_rdy         )

        ,.new_flow_val                      (new_flow_val                       )
        ,.new_flow_flowid                   (new_flow_flowid                    )
        ,.new_flow_head_ptr                 (new_tx_head_ptr                    )
        ,.new_flow_tail_ptr                 (new_tx_tail_ptr                    )
        ,.new_flow_rdy                      (new_flow_tx_payload_ptrs_rdy       )
    );

   tx_state_store tx_state_store (
         .clk   (clk)
        ,.rst   (rst)

        ,.send_pipe_rd_req_val      (send_pipe_tx_state_rd_req_val      )
        ,.send_pipe_rd_req_flowid   (send_pipe_tx_state_rd_req_flowid   )
        ,.send_pipe_rd_req_rdy      (tx_state_send_pipe_rd_req_rdy      )
                                                                               
        ,.send_pipe_rd_resp_val     (tx_state_send_pipe_rd_resp_val     )
        ,.send_pipe_rd_resp_flowid  ()
        ,.send_pipe_rd_resp_data    (tx_state_send_pipe_rd_resp_data    )
        ,.send_pipe_rd_resp_rdy     (send_pipe_tx_state_rd_resp_rdy     )

        ,.recv_pipe_rd_req_val      (recv_pipe_tx_state_rd_req_val      )
        ,.recv_pipe_rd_req_flowid   (recv_pipe_tx_state_rd_req_flowid   )
        ,.recv_pipe_rd_req_rdy      (tx_state_recv_pipe_rd_req_rdy      )

        ,.recv_pipe_rd_resp_val     (tx_state_recv_pipe_rd_resp_val     )
        ,.recv_pipe_rd_resp_flowid  ()
        ,.recv_pipe_rd_resp_data    (tx_state_recv_pipe_rd_resp_data    )
        ,.recv_pipe_rd_resp_rdy     (recv_pipe_tx_state_rd_resp_rdy     )

        ,.send_pipe_wr_req_val      (send_pipe_tx_state_wr_req_val      )
        ,.send_pipe_wr_req_flowid   (send_pipe_tx_state_wr_req_flowid   )
        ,.send_pipe_wr_req_data     (send_pipe_tx_state_wr_req_data     )
        ,.send_pipe_wr_req_rdy      (tx_state_send_pipe_wr_req_rdy      )

        ,.recv_pipe_wr_req_val      (recv_pipe_tx_state_wr_req_val      )
        ,.recv_pipe_wr_req_flowid   (recv_pipe_tx_state_wr_req_flowid   )
        ,.recv_pipe_wr_req_data     (recv_pipe_tx_state_wr_req_data     )
        ,.recv_pipe_wr_req_rdy      (tx_state_recv_pipe_wr_req_rdy      )

        ,.new_flow_val              (new_flow_val                       )
        ,.new_flow_flowid           (new_flow_flowid                    )
        ,.new_flow_tx_state         (new_flow_tx_state                  )
        ,.new_flow_rdy              (new_flow_tx_state_rdy              )
    );
    
    /**********************************************************************************
     * RX pipe
     *********************************************************************************/ 
    
    rx_state_store rx_state_store (
         .clk   (clk)
        ,.rst   (rst)

        ,.recv_state_wr_req_val             (next_recv_state_wr_req_val         )
        ,.recv_state_wr_req_addr            (next_recv_state_wr_req_addr        )
        ,.recv_state_wr_req_data            (next_recv_state_wr_req_data        )
        ,.recv_state_wr_req_rdy             (next_recv_state_wr_req_rdy         )


        ,.curr_recv_state_rd_req_val        (curr_recv_state_rd_req_val         )
        ,.curr_recv_state_rd_req_addr       (curr_recv_state_rd_req_addr        )
        ,.curr_recv_state_rd_req_rdy        (curr_recv_state_rd_req_rdy         )

        ,.curr_recv_state_rd_resp_val       (curr_recv_state_rd_resp_val        )
        ,.curr_recv_state_rd_resp_data      (curr_recv_state_rd_resp_data       )
        ,.curr_recv_state_rd_resp_rdy       (curr_recv_state_rd_resp_rdy        )

        ,.send_pipe_recv_state_rd_req_val   (send_pipe_recv_state_rd_req_val    )
        ,.send_pipe_recv_state_rd_req_addr  (send_pipe_recv_state_rd_req_flowid )
        ,.recv_state_send_pipe_rd_req_rdy   (recv_state_send_pipe_rd_req_rdy    )
                                                                                
        ,.recv_state_send_pipe_rd_resp_val  (recv_state_send_pipe_rd_resp_val   )
        ,.recv_state_send_pipe_rd_resp_data (recv_state_send_pipe_rd_resp_data  )
        ,.send_pipe_recv_state_rd_resp_rdy  (send_pipe_recv_state_rd_resp_rdy   )
    
        ,.new_flow_val                      (new_flow_val                       )
        ,.new_flow_flowid                   (new_flow_flowid                    )
        ,.new_flow_recv_state               (new_flow_rx_state                  )
        ,.new_flow_rdy                      (new_flow_rx_state_rdy              )
    );
    
    tcp_tmp_rx_buf_wrap tmp_buf (
         .clk   (clk)
        ,.rst   (rst)
        
        // Write req inputs
        ,.src_tmp_buf_rx_hdr_val            (src_tmp_buf_rx_hdr_val             )
        ,.src_tmp_buf_rx_src_ip             (src_tmp_buf_rx_src_ip              )
        ,.src_tmp_buf_rx_dst_ip             (src_tmp_buf_rx_dst_ip              )
        ,.src_tmp_buf_rx_tcp_payload_len    (src_tmp_buf_rx_tcp_payload_len     )
        ,.src_tmp_buf_rx_tcp_hdr            (src_tmp_buf_rx_tcp_hdr             )
        ,.tmp_buf_src_rx_hdr_rdy            (tmp_buf_src_rx_hdr_rdy             )
        
        ,.src_tmp_buf_rx_data_val           (src_tmp_buf_rx_data_val            )
        ,.src_tmp_buf_rx_data               (src_tmp_buf_rx_data                )
        ,.src_tmp_buf_rx_data_last          (src_tmp_buf_rx_data_last           )
        ,.src_tmp_buf_rx_data_padbytes      (src_tmp_buf_rx_data_padbytes       )
        ,.tmp_buf_src_rx_data_rdy           (tmp_buf_src_rx_data_rdy            )
        
        // Write resp
        ,.tmp_buf_dst_rx_hdr_val            (tmp_buf_rx_pipe_rx_hdr_val         )
        ,.tmp_buf_dst_rx_src_ip             (tmp_buf_rx_pipe_rx_src_ip          )
        ,.tmp_buf_dst_rx_dst_ip             (tmp_buf_rx_pipe_rx_dst_ip          )
        ,.tmp_buf_dst_rx_tcp_hdr            (tmp_buf_rx_pipe_rx_tcp_hdr         )
        ,.dst_tmp_buf_rx_rdy                (rx_pipe_tmp_buf_rx_rdy             )
                                                                                  
        ,.tmp_buf_dst_rx_payload_val        (tmp_buf_rx_pipe_rx_payload_val     )
        ,.tmp_buf_dst_rx_payload_entry      (tmp_buf_rx_pipe_rx_payload_entry   )
    
        ,.src_tmp_buf_store_rd_req_val      (src_tmp_buf_store_rd_req_val       )
        ,.src_tmp_buf_store_rd_req_addr     (src_tmp_buf_store_rd_req_addr      )
        ,.tmp_buf_store_src_rd_req_rdy      (tmp_buf_store_src_rd_req_rdy       )
                                                                                
        ,.tmp_buf_store_src_rd_resp_val     (tmp_buf_store_src_rd_resp_val      )
        ,.tmp_buf_store_src_rd_resp_data    (tmp_buf_store_src_rd_resp_data     )
        ,.src_tmp_buf_store_rd_resp_rdy     (src_tmp_buf_store_rd_resp_rdy      )
                                                                                
        ,.src_tmp_buf_free_slab_req_val     (src_tmp_buf_free_slab_req_val      )
        ,.src_tmp_buf_free_slab_req_addr    (src_tmp_buf_free_slab_req_addr     )
        ,.tmp_buf_free_slab_src_req_rdy     (tmp_buf_free_slab_src_req_rdy      )
    );

    beehive_rx_pipe_wrap rx_pipe_wrap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.recv_tcp_hdr_val                   (tmp_buf_rx_pipe_rx_hdr_val            )
        ,.recv_src_ip                        (tmp_buf_rx_pipe_rx_src_ip             )
        ,.recv_dst_ip                        (tmp_buf_rx_pipe_rx_dst_ip             )
        ,.recv_tcp_hdr                       (tmp_buf_rx_pipe_rx_tcp_hdr            )
        ,.recv_payload_val                   (tmp_buf_rx_pipe_rx_payload_val        )
        ,.recv_payload_entry                 (tmp_buf_rx_pipe_rx_payload_entry      )
        ,.recv_hdr_rdy                       (rx_pipe_tmp_buf_rx_rdy                )
        
        ,.new_flow_val                       (new_flow_val                          )
        ,.new_flow_flow_id                   (new_flow_flowid                       )
        ,.new_flow_lookup_entry              (new_flow_lookup_entry                 )
        ,.new_flow_tx_state                  (new_flow_tx_state                     )
        ,.new_flow_rx_state                  (new_flow_rx_state                     )
        ,.new_flow_rdy                       (new_flow_rdy                          )

        ,.app_new_flow_notif_val             (app_new_flow_notif_val                )
        ,.app_new_flow_flowid                (app_new_flow_flowid                   )
        ,.app_new_flow_entry                 (app_new_flow_lookup                   )
        ,.app_new_flow_notif_rdy             (app_new_flow_notif_rdy                )
        
        ,.curr_recv_state_rd_req_val         (curr_recv_state_rd_req_val            )
        ,.curr_recv_state_rd_req_addr        (curr_recv_state_rd_req_addr           )
        ,.curr_recv_state_rd_req_rdy         (curr_recv_state_rd_req_rdy            )
                                                                                    
        ,.curr_recv_state_rd_resp_val        (curr_recv_state_rd_resp_val           )
        ,.curr_recv_state_rd_resp_data       (curr_recv_state_rd_resp_data          )
        ,.curr_recv_state_rd_resp_rdy        (curr_recv_state_rd_resp_rdy           )
                                                                                    
        ,.next_recv_state_wr_req_val         (next_recv_state_wr_req_val            )
        ,.next_recv_state_wr_req_addr        (next_recv_state_wr_req_addr           )
        ,.next_recv_state_wr_req_data        (next_recv_state_wr_req_data           )
        ,.next_recv_state_wr_req_rdy         (next_recv_state_wr_req_rdy            )
                                                                                    
        ,.curr_tx_state_rd_req_val           (recv_pipe_tx_state_rd_req_val         )
        ,.curr_tx_state_rd_req_flowid        (recv_pipe_tx_state_rd_req_flowid      )
        ,.curr_tx_state_rd_req_rdy           (tx_state_recv_pipe_rd_req_rdy         )
                                                                                       
        ,.curr_tx_state_rd_resp_val          (tx_state_recv_pipe_rd_resp_val        )
        ,.curr_tx_state_rd_resp_data         (tx_state_recv_pipe_rd_resp_data       )
        ,.curr_tx_state_rd_resp_rdy          (recv_pipe_tx_state_rd_resp_rdy        )
                                                                                    
        ,.rx_pipe_tx_state_wr_req_val        (recv_pipe_tx_state_wr_req_val         )
        ,.rx_pipe_tx_state_wr_req_flowid     (recv_pipe_tx_state_wr_req_flowid      )
        ,.rx_pipe_tx_state_wr_req_data       (recv_pipe_tx_state_wr_req_data        )
        ,.tx_state_rx_pipe_wr_req_rdy        (tx_state_recv_pipe_wr_req_rdy         )
                                                                                    
        ,.rx_pipe_rt_store_set_rt_flag_val   (rx_pipe_rt_store_set_rt_flag_val      )
        ,.rx_pipe_rt_store_set_rt_flag_flowid(rx_pipe_rt_store_set_rt_flag_flowid   )
        
        ,.rx_pipe_tx_head_ptr_wr_req_val     (rx_pipe_tx_head_ptr_wr_req_val        )
        ,.rx_pipe_tx_head_ptr_wr_req_flowid  (rx_pipe_tx_head_ptr_wr_req_flowid     )
        ,.rx_pipe_tx_head_ptr_wr_req_data    (rx_pipe_tx_head_ptr_wr_req_data       )
        ,.tx_head_ptr_rx_pipe_wr_req_rdy     (tx_head_ptr_rx_pipe_wr_req_rdy        )
                                                                                    
        ,.rx_send_queue_enq_req_val          (rx_send_queue_enq_req_val             )
        ,.rx_send_queue_enq_req_data         (rx_send_queue_enq_req_data            )
        ,.send_queue_rx_full                 (send_queue_rx_full                    )
                                                                                    
        ,.rx_pipe_rx_head_ptr_rd_req_val     (rx_pipe_rx_head_ptr_rd_req_val        )
        ,.rx_pipe_rx_head_ptr_rd_req_addr    (rx_pipe_rx_head_ptr_rd_req_addr       )
        ,.rx_head_ptr_rx_pipe_rd_req_rdy     (rx_head_ptr_rx_pipe_rd_req_rdy        )
                                                                                    
        ,.rx_head_ptr_rx_pipe_rd_resp_val    (rx_head_ptr_rx_pipe_rd_resp_val       )
        ,.rx_head_ptr_rx_pipe_rd_resp_data   (rx_head_ptr_rx_pipe_rd_resp_data      )
        ,.rx_pipe_rx_head_ptr_rd_resp_rdy    (rx_pipe_rx_head_ptr_rd_resp_rdy       )
                                                                                    
        ,.rx_pipe_rx_tail_ptr_wr_req_val     (rx_pipe_rx_tail_ptr_wr_req_val        )
        ,.rx_pipe_rx_tail_ptr_wr_req_addr    (rx_pipe_rx_tail_ptr_wr_req_addr       )
        ,.rx_pipe_rx_tail_ptr_wr_req_data    (rx_pipe_rx_tail_ptr_wr_req_data       )
        ,.rx_tail_ptr_rx_pipe_wr_req_rdy     (rx_tail_ptr_rx_pipe_wr_req_rdy        )
                                                                                    
        ,.rx_pipe_rx_tail_ptr_rd_req_val     (rx_pipe_rx_tail_ptr_rd_req_val        )
        ,.rx_pipe_rx_tail_ptr_rd_req_addr    (rx_pipe_rx_tail_ptr_rd_req_addr       )
        ,.rx_tail_ptr_rx_pipe_rd_req_rdy     (rx_tail_ptr_rx_pipe_rd_req_rdy        )
                                                                                    
        ,.rx_tail_ptr_rx_pipe_rd_resp_val    (rx_tail_ptr_rx_pipe_rd_resp_val       )
        ,.rx_tail_ptr_rx_pipe_rd_resp_data   (rx_tail_ptr_rx_pipe_rd_resp_data      )
        ,.rx_pipe_rx_tail_ptr_rd_resp_rdy    (rx_pipe_rx_tail_ptr_rd_resp_rdy       )
                                                                                    
        ,.rx_store_buf_q_rd_req_val          (rx_store_buf_q_rd_req_val             )
        ,.rx_store_buf_q_rd_req_data         (rx_store_buf_q_rd_req_data            )
        ,.rx_store_buf_q_empty               (rx_store_buf_q_empty                  )
    );

    fifo_1r1w #(
         .width_p    (RX_SEND_QUEUE_STRUCT_W)
        ,.log2_els_p (2)
    ) rx_send_queue (
         .clk       (clk)
        ,.rst       (rst)

        ,.rd_req    (rx_send_queue_deq_req_val  )
        ,.empty     (rx_send_queue_empty        )
        ,.rd_data   (rx_send_queue_deq_resp_data)

        ,.wr_req    (rx_send_queue_enq_req_val )
        ,.wr_data   (rx_send_queue_enq_req_data)
        ,.full      (send_queue_rx_full        )
    );

    send_merger send_merger (
         .tx_pipe_merger_tx_val             (tx_pipe_dst_tx_val         )
        ,.tx_pipe_merger_tx_flowid          (tx_pipe_dst_tx_flowid      )
        ,.tx_pipe_merger_tx_src_ip          (tx_pipe_dst_tx_src_ip      )
        ,.tx_pipe_merger_tx_dst_ip          (tx_pipe_dst_tx_dst_ip      )
        ,.tx_pipe_merger_tx_tcp_hdr         (tx_pipe_dst_tx_tcp_hdr     )
        ,.tx_pipe_merger_tx_payload         (tx_pipe_dst_tx_payload     )
        ,.merger_tx_pipe_tx_rdy             (dst_tx_pipe_tx_rdy         )
   
        ,.rx_pipe_merger_tx_deq_req_val     (rx_send_queue_deq_req_val  )
        ,.rx_pipe_merger_tx_deq_resp_data   (rx_send_queue_deq_resp_data)
        ,.rx_pipe_merger_tx_empty           (rx_send_queue_empty        )
    
        ,.send_dst_tx_val                   (send_dst_tx_val            )
        ,.send_dst_tx_flowid                (send_dst_tx_flowid         )
        ,.send_dst_tx_src_ip                (send_dst_tx_src_ip         )
        ,.send_dst_tx_dst_ip                (send_dst_tx_dst_ip         )
        ,.send_dst_tx_tcp_hdr               (send_dst_tx_tcp_hdr        )
        ,.send_dst_tx_payload               (send_dst_tx_payload        )
        ,.dst_send_tx_rdy                   (dst_send_tx_rdy            )
    );

    rx_payload_ptrs rx_payload_qs (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.head_ptr_wr_req_val           (app_rx_head_ptr_wr_req_val         )
        ,.head_ptr_wr_req_addr          (app_rx_head_ptr_wr_req_addr        )
        ,.head_ptr_wr_req_data          (app_rx_head_ptr_wr_req_data        )
        ,.head_ptr_wr_req_rdy           (rx_head_ptr_app_wr_req_rdy         )

        ,.head_ptr_rd0_req_val          (rx_pipe_rx_head_ptr_rd_req_val     )
        ,.head_ptr_rd0_req_addr         (rx_pipe_rx_head_ptr_rd_req_addr    )
        ,.head_ptr_rd0_req_rdy          (rx_head_ptr_rx_pipe_rd_req_rdy     )

        ,.head_ptr_rd0_resp_val         (rx_head_ptr_rx_pipe_rd_resp_val    )
        ,.head_ptr_rd0_resp_data        (rx_head_ptr_rx_pipe_rd_resp_data   )
        ,.head_ptr_rd0_resp_rdy         (rx_pipe_rx_head_ptr_rd_resp_rdy    )

        ,.head_ptr_rd1_req_val          (app_rx_head_ptr_rd_req_val         )
        ,.head_ptr_rd1_req_addr         (app_rx_head_ptr_rd_req_addr        )
        ,.head_ptr_rd1_req_rdy          (rx_head_ptr_app_rd_req_rdy         )

        ,.head_ptr_rd1_resp_val         (rx_head_ptr_app_rd_resp_val        )
        ,.head_ptr_rd1_resp_data        (rx_head_ptr_app_rd_resp_data       )
        ,.head_ptr_rd1_resp_rdy         (app_rx_head_ptr_rd_resp_rdy        )

        ,.commit_ptr_wr_req_val         (store_buf_commit_ptr_wr_req_val    )
        ,.commit_ptr_wr_req_addr        (store_buf_commit_ptr_wr_req_addr   )
        ,.commit_ptr_wr_req_data        (store_buf_commit_ptr_wr_req_data   )
        ,.commit_ptr_wr_req_rdy         (commit_ptr_store_buf_wr_req_rdy    )

        ,.commit_ptr_rd0_req_val        (store_buf_commit_ptr_rd_req_val    )
        ,.commit_ptr_rd0_req_addr       (store_buf_commit_ptr_rd_req_addr   )
        ,.commit_ptr_rd0_req_rdy        (commit_ptr_store_buf_rd_req_rdy    )
                                                                               
        ,.commit_ptr_rd0_resp_val       (commit_ptr_store_buf_rd_resp_val   )
        ,.commit_ptr_rd0_resp_data      (commit_ptr_store_buf_rd_resp_data  )
        ,.commit_ptr_rd0_resp_rdy       (store_buf_commit_ptr_rd_resp_rdy   )

        ,.commit_ptr_rd1_req_val        (app_rx_commit_ptr_rd_req_val       )
        ,.commit_ptr_rd1_req_addr       (app_rx_commit_ptr_rd_req_addr      )
        ,.commit_ptr_rd1_req_rdy        (rx_commit_ptr_app_rd_req_rdy       )

        ,.commit_ptr_rd1_resp_val       (rx_commit_ptr_app_rd_resp_val      )
        ,.commit_ptr_rd1_resp_data      (rx_commit_ptr_app_rd_resp_data     )
        ,.commit_ptr_rd1_resp_rdy       (app_rx_commit_ptr_rd_resp_rdy      )

        ,.tail_ptr_wr_req_val           (rx_pipe_rx_tail_ptr_wr_req_val     )
        ,.tail_ptr_wr_req_addr          (rx_pipe_rx_tail_ptr_wr_req_addr    )
        ,.tail_ptr_wr_req_data          (rx_pipe_rx_tail_ptr_wr_req_data    )
        ,.tail_ptr_wr_req_rdy           (rx_tail_ptr_rx_pipe_wr_req_rdy     )
                                                                              
        ,.tail_ptr_rd_req_val           (rx_pipe_rx_tail_ptr_rd_req_val     )
        ,.tail_ptr_rd_req_addr          (rx_pipe_rx_tail_ptr_rd_req_addr    )
        ,.tail_ptr_rd_req_rdy           (rx_tail_ptr_rx_pipe_rd_req_rdy     )
                                                                              
        ,.tail_ptr_rd_resp_val          (rx_tail_ptr_rx_pipe_rd_resp_val    )
        ,.tail_ptr_rd_resp_data         (rx_tail_ptr_rx_pipe_rd_resp_data   )
        ,.tail_ptr_rd_resp_rdy          (rx_pipe_rx_tail_ptr_rd_resp_rdy    )

        ,.new_flow_val                  (new_flow_val                       )
        ,.new_flow_flowid               (new_flow_flowid                    )
        ,.new_rx_head_ptr               ('0)
        ,.new_rx_tail_ptr               ('0)
        ,.new_flow_rx_payload_ptrs_rdy  (new_flow_rx_payload_ptrs_rdy       )
    );

endmodule
