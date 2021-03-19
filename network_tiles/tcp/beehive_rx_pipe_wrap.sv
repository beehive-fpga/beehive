`include "beehive_tcp_engine_defs.svh"
module beehive_rx_pipe_wrap (
     input                                clk
    ,input                                rst
    
    ,input  logic   [`IP_ADDR_W-1:0]        recv_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        recv_dst_ip
    ,input  logic                           recv_tcp_hdr_val
    ,input  tcp_pkt_hdr                     recv_tcp_hdr
    ,input  logic                           recv_payload_val
    ,input  payload_buf_struct              recv_payload_entry
    ,output logic                           recv_hdr_rdy
    
    ,output logic                           new_flow_val
    ,output logic   [FLOWID_W-1:0]          new_flow_flow_id
    ,output four_tuple_struct               new_flow_lookup_entry
    ,output tx_state_struct                 new_flow_tx_state
    ,output recv_state_entry                new_flow_rx_state
    ,input  logic                           new_flow_rdy

    ,output logic                           app_new_flow_notif_val
    ,output logic   [FLOWID_W-1:0]          app_new_flow_flowid
    ,output four_tuple_struct               app_new_flow_entry
    ,input  logic                           app_new_flow_notif_rdy
    
    ,output logic                           curr_recv_state_rd_req_val
    ,output logic   [FLOWID_W-1:0]          curr_recv_state_rd_req_addr
    ,input  logic                           curr_recv_state_rd_req_rdy
    
    ,input  logic                           curr_recv_state_rd_resp_val
    ,input  recv_state_entry                curr_recv_state_rd_resp_data
    ,output logic                           curr_recv_state_rd_resp_rdy

    ,output logic                           next_recv_state_wr_req_val
    ,output logic   [FLOWID_W-1:0]          next_recv_state_wr_req_addr
    ,output recv_state_entry                next_recv_state_wr_req_data
    ,input  logic                           next_recv_state_wr_req_rdy

    ,output logic                           curr_tx_state_rd_req_val
    ,output logic   [FLOWID_W-1:0]          curr_tx_state_rd_req_flowid
    ,input  logic                           curr_tx_state_rd_req_rdy

    ,input  logic                           curr_tx_state_rd_resp_val
    ,input  tx_state_struct                 curr_tx_state_rd_resp_data
    ,output logic                           curr_tx_state_rd_resp_rdy

    ,output logic                           rx_pipe_tx_state_wr_req_val
    ,output logic   [FLOWID_W-1:0]          rx_pipe_tx_state_wr_req_flowid
    ,output tx_state_struct                 rx_pipe_tx_state_wr_req_data
    ,input  logic                           tx_state_rx_pipe_wr_req_rdy

    ,output logic                           rx_pipe_rt_store_set_rt_flag_val
    ,output logic   [FLOWID_W-1:0]          rx_pipe_rt_store_set_rt_flag_flowid
    
    ,output                                 rx_pipe_tx_head_ptr_wr_req_val
    ,output         [FLOWID_W-1:0]          rx_pipe_tx_head_ptr_wr_req_flowid
    ,output         [TX_PAYLOAD_PTR_W:0]    rx_pipe_tx_head_ptr_wr_req_data
    ,input                                  tx_head_ptr_rx_pipe_wr_req_rdy

    ,output logic                           rx_send_queue_enq_req_val
    ,output rx_send_queue_struct            rx_send_queue_enq_req_data
    ,input  logic                           send_queue_rx_full
    
    ,output logic                           rx_pipe_rx_head_ptr_rd_req_val
    ,output logic   [FLOWID_W-1:0]          rx_pipe_rx_head_ptr_rd_req_addr
    ,input  logic                           rx_head_ptr_rx_pipe_rd_req_rdy

    ,input  logic                           rx_head_ptr_rx_pipe_rd_resp_val
    ,input  logic   [RX_PAYLOAD_PTR_W:0]    rx_head_ptr_rx_pipe_rd_resp_data
    ,output logic                           rx_pipe_rx_head_ptr_rd_resp_rdy
    
    ,output logic                           rx_pipe_rx_tail_ptr_wr_req_val
    ,output logic   [FLOWID_W-1:0]          rx_pipe_rx_tail_ptr_wr_req_addr
    ,output logic   [RX_PAYLOAD_PTR_W:0]    rx_pipe_rx_tail_ptr_wr_req_data
    ,input  logic                           rx_tail_ptr_rx_pipe_wr_req_rdy

    ,output logic                           rx_pipe_rx_tail_ptr_rd_req_val
    ,output logic   [FLOWID_W-1:0]          rx_pipe_rx_tail_ptr_rd_req_addr
    ,input  logic                           rx_tail_ptr_rx_pipe_rd_req_rdy

    ,input  logic                           rx_tail_ptr_rx_pipe_rd_resp_val
    ,input  logic   [RX_PAYLOAD_PTR_W:0]    rx_tail_ptr_rx_pipe_rd_resp_data
    ,output logic                           rx_pipe_rx_tail_ptr_rd_resp_rdy
    
    ,input  logic                           rx_store_buf_q_rd_req_val
    ,output rx_store_buf_q_struct           rx_store_buf_q_rd_req_data
    ,output logic                           rx_store_buf_q_empty
);
    
    logic                       tcp_fsm_clear_temp_flowid_val;
    four_tuple_struct           tcp_fsm_clear_temp_tag;
    
    logic                       tcp_fsm_update_tcp_state_val;
    logic   [FLOWID_W-1:0]    tcp_fsm_update_tcp_state_flowid;
    tcp_flow_state_struct       tcp_fsm_update_tcp_state_data;
    logic                       tcp_fsm_update_tcp_state_rdy;
    
    logic                       est_hdr_val;
    tcp_pkt_hdr                 est_tcp_hdr;
    logic   [FLOWID_W-1:0]    est_flowid;
    logic                       est_payload_val;
    payload_buf_struct           est_payload_entry;
    logic                       est_pipe_rdy;
    
    logic                       fsm_send_pkt_enqueue_val;
    logic   [FLOWID_W-1:0]    fsm_send_pkt_enqueue_flowid;
    logic   [`IP_ADDR_W-1:0]    fsm_send_pkt_enqueue_src_ip;
    logic   [`IP_ADDR_W-1:0]    fsm_send_pkt_enqueue_dst_ip;
    tcp_pkt_hdr                 fsm_send_pkt_enqueue_hdr;
    logic                       fsm_send_pkt_enqueue_rdy;
    
    logic                       tcp_fsm_new_flow_val;
    logic   [FLOWID_W-1:0]    tcp_fsm_new_flow_flowid;
    four_tuple_struct           tcp_fsm_new_flow_lookup_entry;
    recv_state_entry            tcp_fsm_new_flow_rx_state;
    tx_state_struct             tcp_fsm_new_flow_tx_state;
    logic                       tcp_fsm_clear_flowid_val;
    four_tuple_struct           tcp_fsm_clear_flowid_tag;
    logic                       tcp_fsm_new_flow_state_rdy;

    rx_send_queue_struct        rx_send_queue_entry;

    logic                       fsm_reinject_q_enq_req_val;
    fsm_reinject_queue_struct   fsm_reinject_q_enq_req_data;
    logic                       fsm_reinject_q_full;
    
    logic                       merger_fsm_reinject_q_deq_req_val;
    fsm_reinject_queue_struct   fsm_reinject_q_merger_deq_resp_data;
    logic                       fsm_reinject_q_merger_empty;
    
    logic                       issue_merger_est_hdr_val;
    tcp_pkt_hdr                 issue_merger_est_tcp_hdr;
    logic   [FLOWID_W-1:0]    issue_merger_est_flowid;
    logic                       issue_merger_est_payload_val;
    payload_buf_struct           issue_merger_est_payload_entry;
    logic                       merger_issue_est_pipe_rdy;
    
    logic                       issue_fsm_q_hdr_val;
    logic   [`IP_ADDR_W-1:0]    issue_fsm_q_hdr_src_ip;
    logic   [`IP_ADDR_W-1:0]    issue_fsm_q_hdr_dst_ip;
    tcp_pkt_hdr                 issue_fsm_q_tcp_hdr;
    logic                       issue_fsm_q_payload_val;
    payload_buf_struct           issue_fsm_q_payload_entry;
    logic                       issue_fsm_q_new_flow;
    logic   [FLOWID_W-1:0]    issue_fsm_q_flowid;
    logic                       fsm_q_issue_rdy;

    logic                       issue_fsm_q_enq_req_val;
    fsm_input_queue_struct      issue_fsm_q_enq_req_data;
    logic                       fsm_q_issue_full;
    
    logic                       fsm_q_fsm_pipe_hdr_val;
    logic   [`IP_ADDR_W-1:0]    fsm_q_fsm_pipe_hdr_src_ip;
    logic   [`IP_ADDR_W-1:0]    fsm_q_fsm_pipe_hdr_dst_ip;
    tcp_pkt_hdr                 fsm_q_fsm_pipe_tcp_hdr;
    logic                       fsm_q_fsm_pipe_payload_val;
    payload_buf_struct           fsm_q_fsm_pipe_payload_entry;
    logic                       fsm_q_fsm_pipe_new_flow;
    logic   [FLOWID_W-1:0]    fsm_q_fsm_pipe_flowid;
    logic                       fsm_pipe_fsm_q_rdy;

    logic                       fsm_q_fsm_pipe_empty;
    fsm_input_queue_struct      fsm_q_fsm_pipe_deq_resp_data;
    logic                       fsm_pipe_fsm_q_deq_req_val;
    
    logic                       fsm_tcp_state_rd_req_val;
    logic   [FLOWID_W-1:0]    fsm_tcp_state_rd_req_flowid;
    logic                       tcp_state_fsm_rd_req_rdy;

    logic                       tcp_state_fsm_rd_resp_val;
    tcp_flow_state_struct       tcp_state_fsm_rd_resp_data;
    logic                       fsm_tcp_state_rd_resp_rdy;
    
    logic                       fsm_arbiter_tx_state_rd_req_val;
    logic   [FLOWID_W-1:0]    fsm_arbiter_tx_state_rd_req_flowid;
    logic                       arbiter_fsm_tx_state_rd_req_grant;

    logic                       fsm_arbiter_rx_state_rd_req_val;
    logic   [FLOWID_W-1:0]    fsm_arbiter_rx_state_rd_req_flowid;
    logic                       arbiter_fsm_rx_state_rd_req_grant;

    logic                       est_arbiter_tx_state_rd_req_val;
    logic   [FLOWID_W-1:0]    est_arbiter_tx_state_rd_req_flowid;
    logic                       arbiter_est_tx_state_rd_req_grant;

    logic                       est_arbiter_rx_state_rd_req_val;
    logic   [FLOWID_W-1:0]    est_arbiter_rx_state_rd_req_flowid;
    logic                       arbiter_est_rx_state_rd_req_grant;
    
    logic                       arbiter_fsm_tx_state_rd_resp_val;
    tx_state_struct             arbiter_fsm_tx_state_rd_resp_data;
    logic                       fsm_arbiter_tx_state_rd_resp_rdy;

    logic                       arbiter_fsm_rx_state_rd_resp_val;
    recv_state_entry            arbiter_fsm_rx_state_rd_resp_data;
    logic                       fsm_arbiter_rx_state_rd_resp_rdy;
    
    logic                       arbiter_est_tx_state_rd_resp_val;
    tx_state_struct             arbiter_est_tx_state_rd_resp_data;
    logic                       est_arbiter_tx_state_rd_resp_rdy;

    logic                       arbiter_est_rx_state_rd_resp_val;
    recv_state_entry            arbiter_est_rx_state_rd_resp_data;
    logic                       est_arbiter_rx_state_rd_resp_rdy;
    
    logic                       issue_pipe_flowid_manager_flowid_req;
    logic                       flowid_manager_issue_pipe_flowid_avail;
    logic   [FLOWID_W-1:0]    flowid_manager_issue_pipe_flowid;
    
    logic                       rx_store_buf_q_wr_req_val;
    rx_store_buf_q_struct       rx_store_buf_q_wr_req_data;
    logic                       rx_store_buf_q_full;
    
    assign rx_send_queue_enq_req_val = fsm_send_pkt_enqueue_val & ~send_queue_rx_full;
    assign rx_send_queue_entry.flowid = fsm_send_pkt_enqueue_flowid;
    assign rx_send_queue_entry.src_ip = fsm_send_pkt_enqueue_src_ip;
    assign rx_send_queue_entry.dst_ip = fsm_send_pkt_enqueue_dst_ip;
    assign rx_send_queue_entry.tcp_hdr = fsm_send_pkt_enqueue_hdr;
    assign rx_send_queue_enq_req_data = rx_send_queue_entry;
    assign fsm_send_pkt_enqueue_rdy = ~send_queue_rx_full;

    assign new_flow_val = tcp_fsm_new_flow_val;
    assign new_flow_flow_id = tcp_fsm_new_flow_flowid;
    assign new_flow_lookup_entry = tcp_fsm_new_flow_lookup_entry;
    assign new_flow_tx_state = tcp_fsm_new_flow_tx_state;
    assign new_flow_rx_state = tcp_fsm_new_flow_rx_state;

    assign tcp_fsm_new_flow_state_rdy = new_flow_rdy;

    flowid_manager flowid_manager (
         .clk   (clk)
        ,.rst   (rst)

        ,.flowid_ret_val    (1'b0)
        ,.flowid_ret_id     ('0)
        ,.flowid_ret_rdy    ()

        ,.flowid_req        (issue_pipe_flowid_manager_flowid_req   )
        ,.flowid_avail      (flowid_manager_issue_pipe_flowid_avail )
        ,.flowid            (flowid_manager_issue_pipe_flowid       )
    );
    
    rx_issue_pipe issue_pipe (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.recv_src_ip                       (recv_src_ip                        )
        ,.recv_dst_ip                       (recv_dst_ip                        )
        ,.recv_tcp_hdr_val                  (recv_tcp_hdr_val                   )
        ,.recv_tcp_hdr                      (recv_tcp_hdr                       )
        ,.recv_hdr_rdy                      (recv_hdr_rdy                       )

        ,.recv_payload_val                  (recv_payload_val                   )
        ,.recv_payload_entry                (recv_payload_entry                 )
    
        ,.tcp_fsm_clear_flowid_val          (1'b0)
        ,.tcp_fsm_clear_flowid_tag          ('0)
        ,.tcp_fsm_clear_flowid_flowid       ('0)

        ,.issue_pipe_flowid_manager_flowid_req  (issue_pipe_flowid_manager_flowid_req   )
        ,.flowid_manager_issue_pipe_flowid_avail(flowid_manager_issue_pipe_flowid_avail )
        ,.flowid_manager_issue_pipe_flowid      (flowid_manager_issue_pipe_flowid       )

        ,.tcp_fsm_update_tcp_state_val      (tcp_fsm_update_tcp_state_val       )
        ,.tcp_fsm_update_tcp_state_flowid   (tcp_fsm_update_tcp_state_flowid    )
        ,.tcp_fsm_update_tcp_state_data     (tcp_fsm_update_tcp_state_data      )
        ,.tcp_fsm_update_tcp_state_rdy      (tcp_fsm_update_tcp_state_rdy       )
    
        ,.fsm_tcp_state_rd_req_val          (fsm_tcp_state_rd_req_val           )
        ,.fsm_tcp_state_rd_req_flowid       (fsm_tcp_state_rd_req_flowid        )
        ,.tcp_state_fsm_rd_req_rdy          (tcp_state_fsm_rd_req_rdy           )
                                                                        
        ,.tcp_state_fsm_rd_resp_val         (tcp_state_fsm_rd_resp_val          )
        ,.tcp_state_fsm_rd_resp_data        (tcp_state_fsm_rd_resp_data         )
        ,.fsm_tcp_state_rd_resp_rdy         (fsm_tcp_state_rd_resp_rdy          )

        ,.est_hdr_val                       (issue_merger_est_hdr_val           )
        ,.est_tcp_hdr                       (issue_merger_est_tcp_hdr           )
        ,.est_flowid                        (issue_merger_est_flowid            )
        ,.est_payload_val                   (issue_merger_est_payload_val       )
        ,.est_payload_entry                 (issue_merger_est_payload_entry     )
        ,.est_pipe_rdy                      (merger_issue_est_pipe_rdy          )
        
        ,.fsm_hdr_val                       (issue_fsm_q_hdr_val                )
        ,.fsm_hdr_src_ip                    (issue_fsm_q_hdr_src_ip             )
        ,.fsm_hdr_dst_ip                    (issue_fsm_q_hdr_dst_ip             )
        ,.fsm_tcp_hdr                       (issue_fsm_q_tcp_hdr                )
        ,.fsm_payload_val                   (issue_fsm_q_payload_val            )
        ,.fsm_payload_entry                 (issue_fsm_q_payload_entry          )
        ,.fsm_new_flow                      (issue_fsm_q_new_flow               )
        ,.fsm_flowid                        (issue_fsm_q_flowid                 )
        ,.fsm_pipe_rdy                      (fsm_q_issue_rdy                    )
    );

    est_pipe_input_merger est_pipe_input_merger (
         .issue_merger_est_hdr_val              (issue_merger_est_hdr_val               )
        ,.issue_merger_est_tcp_hdr              (issue_merger_est_tcp_hdr               )
        ,.issue_merger_est_flowid               (issue_merger_est_flowid                )
        ,.issue_merger_est_payload_val          (issue_merger_est_payload_val           )
        ,.issue_merger_est_payload_entry        (issue_merger_est_payload_entry         )
        ,.merger_issue_est_pipe_rdy             (merger_issue_est_pipe_rdy              )

        ,.merger_fsm_reinject_q_deq_req_val     (merger_fsm_reinject_q_deq_req_val      )
        ,.fsm_reinject_q_merger_deq_resp_data   (fsm_reinject_q_merger_deq_resp_data    )
        ,.fsm_reinject_q_merger_empty           (fsm_reinject_q_merger_empty            )

        ,.est_hdr_val                           (est_hdr_val                            )
        ,.est_tcp_hdr                           (est_tcp_hdr                            )
        ,.est_flowid                            (est_flowid                             )
        ,.est_payload_val                       (est_payload_val                        )
        ,.est_payload_entry                     (est_payload_entry                      )
        ,.est_pipe_rdy                          (est_pipe_rdy                           )
    );
    
    // reinject queue
    fifo_1r1w #(
         .width_p    (FSM_REINJECT_QUEUE_STRUCT_W)
        ,.log2_els_p (2)
    ) reinject_queue (
         .clk       (clk)
        ,.rst       (rst)

        ,.rd_req    (merger_fsm_reinject_q_deq_req_val      )
        ,.rd_data   (fsm_reinject_q_merger_deq_resp_data    )
        ,.empty     (fsm_reinject_q_merger_empty            )           

        ,.wr_req    (fsm_reinject_q_enq_req_val             )
        ,.wr_data   (fsm_reinject_q_enq_req_data            )
        ,.full      (fsm_reinject_q_full                    )
    );
    
    est_pipe est_flow_pipe (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.est_hdr_val                       (est_hdr_val                        )
        ,.est_tcp_hdr                       (est_tcp_hdr                        )
        ,.est_flowid                        (est_flowid                         )
        ,.est_payload_val                   (est_payload_val                    )
        ,.est_payload_entry                 (est_payload_entry                  )
        ,.est_pipe_rdy                      (est_pipe_rdy                       )
    
        ,.est_pipe_rx_state_rd_req_val      (est_arbiter_rx_state_rd_req_val    )
        ,.est_pipe_rx_state_rd_req_flowid   (est_arbiter_rx_state_rd_req_flowid )
        ,.rx_state_est_pipe_rd_req_rdy      (arbiter_est_rx_state_rd_req_grant  )

        ,.rx_state_est_pipe_rd_resp_val     (arbiter_est_rx_state_rd_resp_val   )
        ,.rx_state_est_pipe_rd_resp_data    (arbiter_est_rx_state_rd_resp_data  )
        ,.est_pipe_rx_state_rd_resp_rdy     (est_arbiter_rx_state_rd_resp_rdy   )

        ,.est_pipe_tx_state_rd_req_val      (est_arbiter_tx_state_rd_req_val    )
        ,.est_pipe_tx_state_rd_req_flowid   (est_arbiter_tx_state_rd_req_flowid )
        ,.tx_state_est_pipe_rd_req_rdy      (arbiter_est_tx_state_rd_req_grant  )

        ,.tx_state_est_pipe_rd_resp_val     (arbiter_est_tx_state_rd_resp_val   )
        ,.tx_state_est_pipe_rd_resp_data    (arbiter_est_tx_state_rd_resp_data  )
        ,.est_pipe_tx_state_rd_resp_rdy     (est_arbiter_tx_state_rd_resp_rdy   )

        ,.next_recv_state_wr_req_val        (next_recv_state_wr_req_val         )
        ,.next_recv_state_wr_req_addr       (next_recv_state_wr_req_addr        )
        ,.next_recv_state_wr_req_data       (next_recv_state_wr_req_data        )
        ,.next_recv_state_wr_req_rdy        (next_recv_state_wr_req_rdy         )

        ,.rx_pipe_tx_state_wr_req_val       (rx_pipe_tx_state_wr_req_val        )
        ,.rx_pipe_tx_state_wr_req_flowid    (rx_pipe_tx_state_wr_req_flowid     )
        ,.rx_pipe_tx_state_wr_req_data      (rx_pipe_tx_state_wr_req_data       )
        ,.tx_state_rx_pipe_wr_req_rdy       (tx_state_rx_pipe_wr_req_rdy        )

        ,.set_rt_flag_val                   (rx_pipe_rt_store_set_rt_flag_val   )
        ,.set_rt_flag_flowid                (rx_pipe_rt_store_set_rt_flag_flowid)
    
        ,.rx_pipe_tx_head_ptr_wr_req_val    (rx_pipe_tx_head_ptr_wr_req_val     )
        ,.rx_pipe_tx_head_ptr_wr_req_flowid (rx_pipe_tx_head_ptr_wr_req_flowid  )
        ,.rx_pipe_tx_head_ptr_wr_req_data   (rx_pipe_tx_head_ptr_wr_req_data    )
        ,.tx_head_ptr_rx_pipe_wr_req_rdy    (tx_head_ptr_rx_pipe_wr_req_rdy     )
    
        ,.rx_pipe_rx_head_ptr_rd_req_val    (rx_pipe_rx_head_ptr_rd_req_val     )
        ,.rx_pipe_rx_head_ptr_rd_req_addr   (rx_pipe_rx_head_ptr_rd_req_addr    )
        ,.rx_head_ptr_rx_pipe_rd_req_rdy    (rx_head_ptr_rx_pipe_rd_req_rdy     )
                                                                                
        ,.rx_head_ptr_rx_pipe_rd_resp_val   (rx_head_ptr_rx_pipe_rd_resp_val    )
        ,.rx_head_ptr_rx_pipe_rd_resp_data  (rx_head_ptr_rx_pipe_rd_resp_data   )
        ,.rx_pipe_rx_head_ptr_rd_resp_rdy   (rx_pipe_rx_head_ptr_rd_resp_rdy    )
                                                                                
        ,.rx_pipe_rx_tail_ptr_wr_req_val    (rx_pipe_rx_tail_ptr_wr_req_val     )
        ,.rx_pipe_rx_tail_ptr_wr_req_addr   (rx_pipe_rx_tail_ptr_wr_req_addr    )
        ,.rx_pipe_rx_tail_ptr_wr_req_data   (rx_pipe_rx_tail_ptr_wr_req_data    )
        ,.rx_tail_ptr_rx_pipe_wr_req_rdy    (rx_tail_ptr_rx_pipe_wr_req_rdy     )
                                                                                
        ,.rx_pipe_rx_tail_ptr_rd_req_val    (rx_pipe_rx_tail_ptr_rd_req_val     )
        ,.rx_pipe_rx_tail_ptr_rd_req_addr   (rx_pipe_rx_tail_ptr_rd_req_addr    )
        ,.rx_tail_ptr_rx_pipe_rd_req_rdy    (rx_tail_ptr_rx_pipe_rd_req_rdy     )
                                                                                
        ,.rx_tail_ptr_rx_pipe_rd_resp_val   (rx_tail_ptr_rx_pipe_rd_resp_val    )
        ,.rx_tail_ptr_rx_pipe_rd_resp_data  (rx_tail_ptr_rx_pipe_rd_resp_data   )
        ,.rx_pipe_rx_tail_ptr_rd_resp_rdy   (rx_pipe_rx_tail_ptr_rd_resp_rdy    )

        ,.rx_store_buf_q_wr_req_val         (rx_store_buf_q_wr_req_val          )
        ,.rx_store_buf_q_wr_req_data        (rx_store_buf_q_wr_req_data         )
        ,.rx_store_buf_q_full               (rx_store_buf_q_full                )
    );

    
    fifo_1r1w #(
         .width_p   (RX_STORE_BUF_Q_STRUCT_W)
        ,.log2_els_p(5)
    ) rx_store_buf_q (
         .clk       (clk    )
        ,.rst       (rst    )
        
        ,.wr_req    (rx_store_buf_q_wr_req_val  )
        ,.wr_data   (rx_store_buf_q_wr_req_data )
        ,.full      (rx_store_buf_q_full        )

        ,.rd_req    (rx_store_buf_q_rd_req_val  )
        ,.rd_data   (rx_store_buf_q_rd_req_data )
        ,.empty     (rx_store_buf_q_empty       )
    );

    assign fsm_q_issue_rdy = ~fsm_q_issue_full;
    assign issue_fsm_q_enq_req_val = issue_fsm_q_hdr_val & ~fsm_q_issue_full;

    assign issue_fsm_q_enq_req_data.src_ip = issue_fsm_q_hdr_src_ip;
    assign issue_fsm_q_enq_req_data.dst_ip = issue_fsm_q_hdr_dst_ip;
    assign issue_fsm_q_enq_req_data.tcp_hdr = issue_fsm_q_tcp_hdr;
    assign issue_fsm_q_enq_req_data.payload_val = issue_fsm_q_payload_val;
    assign issue_fsm_q_enq_req_data.payload_entry = issue_fsm_q_payload_entry;
    assign issue_fsm_q_enq_req_data.new_flow = issue_fsm_q_new_flow;
    assign issue_fsm_q_enq_req_data.flowid = issue_fsm_q_flowid;
    
    // fsm_pipe_queue
    fifo_1r1w #(
         .width_p    (FSM_INPUT_QUEUE_STRUCT_W)
        ,.log2_els_p (2)
    ) fsm_queue (
         .clk       (clk)
        ,.rst       (rst)

        ,.rd_req    (fsm_pipe_fsm_q_deq_req_val     )
        ,.empty     (fsm_q_fsm_pipe_empty           )
        ,.rd_data   (fsm_q_fsm_pipe_deq_resp_data   )

        ,.wr_req    (issue_fsm_q_enq_req_val        )
        ,.wr_data   (issue_fsm_q_enq_req_data       )
        ,.full      (fsm_q_issue_full               )
    );

    assign fsm_q_fsm_pipe_hdr_val = ~fsm_q_fsm_pipe_empty;
    assign fsm_pipe_fsm_q_deq_req_val = fsm_pipe_fsm_q_rdy & ~fsm_q_fsm_pipe_empty;

    assign fsm_q_fsm_pipe_hdr_src_ip = fsm_q_fsm_pipe_deq_resp_data.src_ip;
    assign fsm_q_fsm_pipe_hdr_dst_ip = fsm_q_fsm_pipe_deq_resp_data.dst_ip;
    assign fsm_q_fsm_pipe_tcp_hdr = fsm_q_fsm_pipe_deq_resp_data.tcp_hdr;
    assign fsm_q_fsm_pipe_payload_val = fsm_q_fsm_pipe_deq_resp_data.payload_val;
    assign fsm_q_fsm_pipe_payload_entry = fsm_q_fsm_pipe_deq_resp_data.payload_entry;
    assign fsm_q_fsm_pipe_new_flow = fsm_q_fsm_pipe_deq_resp_data.new_flow;
    assign fsm_q_fsm_pipe_flowid = fsm_q_fsm_pipe_deq_resp_data.flowid;


    rx_fsm_pipe fsm_pipe (
         .clk   (clk)
        ,.rst   (rst)

        ,.fsm_hdr_val                   (fsm_q_fsm_pipe_hdr_val             )
        ,.fsm_hdr_src_ip                (fsm_q_fsm_pipe_hdr_src_ip          )
        ,.fsm_hdr_dst_ip                (fsm_q_fsm_pipe_hdr_dst_ip          )
        ,.fsm_tcp_hdr                   (fsm_q_fsm_pipe_tcp_hdr             )
        ,.fsm_payload_val               (fsm_q_fsm_pipe_payload_val         )
        ,.fsm_payload_entry             (fsm_q_fsm_pipe_payload_entry       )
        ,.fsm_new_flow                  (fsm_q_fsm_pipe_new_flow            )
        ,.fsm_flowid                    (fsm_q_fsm_pipe_flowid              )
        ,.fsm_hdr_rdy                   (fsm_pipe_fsm_q_rdy                 )

        ,.fsm_tcp_state_rd_req_val      (fsm_tcp_state_rd_req_val           )
        ,.fsm_tcp_state_rd_req_flowid   (fsm_tcp_state_rd_req_flowid        )
        ,.tcp_state_fsm_rd_req_rdy      (tcp_state_fsm_rd_req_rdy           )
                                                                            
        ,.tcp_state_fsm_rd_resp_val     (tcp_state_fsm_rd_resp_val          )
        ,.tcp_state_fsm_rd_resp_data    (tcp_state_fsm_rd_resp_data         )
        ,.fsm_tcp_state_rd_resp_rdy     (fsm_tcp_state_rd_resp_rdy          )

        ,.fsm_rx_state_rd_req_val       (fsm_arbiter_rx_state_rd_req_val    )
        ,.fsm_rx_state_rd_req_flowid    (fsm_arbiter_rx_state_rd_req_flowid )
        ,.rx_state_fsm_rd_req_rdy       (arbiter_fsm_rx_state_rd_req_grant  )

        ,.rx_state_fsm_rd_resp_val      (arbiter_fsm_rx_state_rd_resp_val   )
        ,.rx_state_fsm_rd_resp_data     (arbiter_fsm_rx_state_rd_resp_data  )
        ,.fsm_rx_state_rd_resp_rdy      (fsm_arbiter_rx_state_rd_resp_rdy   )

        ,.fsm_tx_state_rd_req_val       (fsm_arbiter_tx_state_rd_req_val    )
        ,.fsm_tx_state_rd_req_flowid    (fsm_arbiter_tx_state_rd_req_flowid )
        ,.tx_state_fsm_rd_req_rdy       (arbiter_fsm_tx_state_rd_req_grant  )

        ,.tx_state_fsm_rd_resp_val      (arbiter_fsm_tx_state_rd_resp_val   )
        ,.tx_state_fsm_rd_resp_data     (arbiter_fsm_tx_state_rd_resp_data  )
        ,.fsm_tx_state_rd_resp_rdy      (fsm_arbiter_tx_state_rd_resp_rdy   )
    
        ,.fsm_reinject_q_enq_req_val    (fsm_reinject_q_enq_req_val         )
        ,.fsm_reinject_q_enq_req_data   (fsm_reinject_q_enq_req_data        )
        ,.fsm_reinject_q_full           (fsm_reinject_q_full                )

        ,.fsm_send_pkt_enqueue_val      (fsm_send_pkt_enqueue_val           )
        ,.fsm_send_pkt_enqueue_flowid   (fsm_send_pkt_enqueue_flowid        )
        ,.fsm_send_pkt_enqueue_src_ip   (fsm_send_pkt_enqueue_src_ip        )
        ,.fsm_send_pkt_enqueue_dst_ip   (fsm_send_pkt_enqueue_dst_ip        )
        ,.fsm_send_pkt_enqueue_hdr      (fsm_send_pkt_enqueue_hdr           )
        ,.fsm_send_pkt_enqueue_rdy      (fsm_send_pkt_enqueue_rdy           )

        ,.next_flow_state_wr_req_val    (tcp_fsm_update_tcp_state_val       )
        ,.next_flow_state_wr_req_data   (tcp_fsm_update_tcp_state_data      )
        ,.next_flow_state_wr_req_flowid (tcp_fsm_update_tcp_state_flowid    )
        ,.next_flow_state_rdy           (tcp_fsm_update_tcp_state_rdy       )

        ,.app_new_flow_notif_val        (app_new_flow_notif_val             )
        ,.app_new_flow_flowid           (app_new_flow_flowid                )
        ,.app_new_flow_entry            (app_new_flow_entry                 )
        ,.app_new_flow_notif_rdy        (app_new_flow_notif_rdy             )

        ,.new_flow_val                  (tcp_fsm_new_flow_val               )
        ,.new_flow_flowid               (tcp_fsm_new_flow_flowid            )
        ,.new_flow_lookup_entry         (tcp_fsm_new_flow_lookup_entry      )
        ,.new_flow_rx_state             (tcp_fsm_new_flow_rx_state          )
        ,.new_flow_tx_state             (tcp_fsm_new_flow_tx_state          )
        ,.tcp_fsm_clear_flowid_val      (tcp_fsm_clear_flowid_val           )
        ,.tcp_fsm_clear_flowid_tag      (tcp_fsm_clear_flowid_tag           )
        ,.new_flow_rdy                  (tcp_fsm_new_flow_state_rdy         )
    );

    fsm_est_arbiter fsm_est_pipe_arbiter (
         .clk   (clk)
        ,.rst   (rst)

        ,.fsm_arbiter_tx_state_rd_req_val       (fsm_arbiter_tx_state_rd_req_val    )
        ,.fsm_arbiter_tx_state_rd_req_flowid    (fsm_arbiter_tx_state_rd_req_flowid )
        ,.arbiter_fsm_tx_state_rd_req_grant     (arbiter_fsm_tx_state_rd_req_grant  )
                                                                                    
        ,.fsm_arbiter_rx_state_rd_req_val       (fsm_arbiter_rx_state_rd_req_val    )
        ,.fsm_arbiter_rx_state_rd_req_flowid    (fsm_arbiter_rx_state_rd_req_flowid )
        ,.arbiter_fsm_rx_state_rd_req_grant     (arbiter_fsm_rx_state_rd_req_grant  )
                                                                                    
        ,.est_arbiter_tx_state_rd_req_val       (est_arbiter_tx_state_rd_req_val    )
        ,.est_arbiter_tx_state_rd_req_flowid    (est_arbiter_tx_state_rd_req_flowid )
        ,.arbiter_est_tx_state_rd_req_grant     (arbiter_est_tx_state_rd_req_grant  )
                                                                                    
        ,.est_arbiter_rx_state_rd_req_val       (est_arbiter_rx_state_rd_req_val    )
        ,.est_arbiter_rx_state_rd_req_flowid    (est_arbiter_rx_state_rd_req_flowid )
        ,.arbiter_est_rx_state_rd_req_grant     (arbiter_est_rx_state_rd_req_grant  )

        ,.curr_recv_state_rd_req_val            (curr_recv_state_rd_req_val         )
        ,.curr_recv_state_rd_req_flowid         (curr_recv_state_rd_req_addr        )
        ,.curr_recv_state_rd_req_rdy            (curr_recv_state_rd_req_rdy         )
                                                                                     
        ,.curr_recv_state_rd_resp_val           (curr_recv_state_rd_resp_val        )
        ,.curr_recv_state_rd_resp_data          (curr_recv_state_rd_resp_data       )
        ,.curr_recv_state_rd_resp_rdy           (curr_recv_state_rd_resp_rdy        )

        ,.curr_tx_state_rd_req_val              (curr_tx_state_rd_req_val           )
        ,.curr_tx_state_rd_req_flowid           (curr_tx_state_rd_req_flowid        )
        ,.curr_tx_state_rd_req_rdy              (curr_tx_state_rd_req_rdy           )
                                                                                     
        ,.curr_tx_state_rd_resp_val             (curr_tx_state_rd_resp_val          )
        ,.curr_tx_state_rd_resp_data            (curr_tx_state_rd_resp_data         )
        ,.curr_tx_state_rd_resp_rdy             (curr_tx_state_rd_resp_rdy          )

        ,.arbiter_fsm_tx_state_rd_resp_val      (arbiter_fsm_tx_state_rd_resp_val   )
        ,.arbiter_fsm_tx_state_rd_resp_data     (arbiter_fsm_tx_state_rd_resp_data  )
        ,.fsm_arbiter_tx_state_rd_resp_rdy      (fsm_arbiter_tx_state_rd_resp_rdy   )
                                                                                    
        ,.arbiter_fsm_rx_state_rd_resp_val      (arbiter_fsm_rx_state_rd_resp_val   )
        ,.arbiter_fsm_rx_state_rd_resp_data     (arbiter_fsm_rx_state_rd_resp_data  )
        ,.fsm_arbiter_rx_state_rd_resp_rdy      (fsm_arbiter_rx_state_rd_resp_rdy   )
                                                                                    
        ,.arbiter_est_tx_state_rd_resp_val      (arbiter_est_tx_state_rd_resp_val   )
        ,.arbiter_est_tx_state_rd_resp_data     (arbiter_est_tx_state_rd_resp_data  )
        ,.est_arbiter_tx_state_rd_resp_rdy      (est_arbiter_tx_state_rd_resp_rdy   )
                                                                                    
        ,.arbiter_est_rx_state_rd_resp_val      (arbiter_est_rx_state_rd_resp_val   )
        ,.arbiter_est_rx_state_rd_resp_data     (arbiter_est_rx_state_rd_resp_data  )
        ,.est_arbiter_rx_state_rd_resp_rdy      (est_arbiter_rx_state_rd_resp_rdy   )
    );

endmodule
