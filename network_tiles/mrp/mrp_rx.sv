`include "mrp_defs.svh"
module mrp_rx (
     input clk
    ,input rst

    ,input                                  src_mrp_rx_meta_val
    ,input  [`IP_ADDR_W-1:0]                src_mrp_rx_src_ip
    ,input  [`IP_ADDR_W-1:0]                src_mrp_rx_dst_ip
    ,input  [`PORT_NUM_W-1:0]               src_mrp_rx_src_port
    ,input  [`PORT_NUM_W-1:0]               src_mrp_rx_dst_port
    ,output                                 mrp_src_rx_meta_rdy

    ,input                                  src_mrp_rx_data_val
    ,input  [`MAC_INTERFACE_W-1:0]          src_mrp_rx_data
    ,input                                  src_mrp_rx_data_last
    ,input  [`MAC_PADBYTES_W-1:0]           src_mrp_rx_data_padbytes
    ,output logic                           mrp_src_rx_data_rdy
    
    ,output logic                           mrp_dst_rx_outstream_meta_val
    ,output logic                           mrp_dst_rx_outstream_start
    ,output logic                           mrp_dst_rx_outstream_msg_done
    ,output logic   [CONN_ID_W-1:0]         mrp_dst_rx_outstream_conn_id
    ,input   logic                          dst_mrp_rx_outstream_meta_rdy

    ,output logic                           mrp_dst_rx_outstream_val
    ,output         mrp_stream              mrp_dst_rx_outstream
    ,input  logic                           dst_mrp_rx_outstream_rdy

    ,output logic                           mrp_rx_conn_id_table_wr_val
    ,output logic   [CONN_ID_W-1:0]         mrp_rx_conn_id_table_wr_addr
    ,output         mrp_req_key             mrp_rx_conn_id_table_wr_data

    ,output logic                           mrp_rx_conn_id_table_rd_req_val
    ,output logic   [CONN_ID_W-1:0]         mrp_rx_conn_id_table_rd_req_addr

    ,input  logic                           conn_id_table_mrp_rx_rd_resp_val
    ,input          mrp_req_key             conn_id_table_mrp_rx_rd_resp_data
    
    ,input  logic                           mrp_tx_dealloc_msg_finalize_val
    ,input          mrp_req_key             mrp_tx_dealloc_msg_finalize_key
    ,input          [CONN_ID_W-1:0]         mrp_tx_dealloc_msg_finalize_conn_id
    ,output logic                           dealloc_mrp_tx_msg_finalize_rdy
    
    ,input                  rd_cmd_queue_empty
    ,output                 rd_cmd_queue_rd_req
    ,input          [63:0]  rd_cmd_queue_rd_data
    
    ,output                 rd_resp_val
    ,output logic   [63:0]  shell_reg_rd_data
);

    assign rd_cmd_queue_rd_req = 1'b0;
    assign shell_reg_rd_data = 1'b0;
    
    logic                           mrp_dst_outstream_val;
    logic                           mrp_dst_outstream_last;
    logic   [`MAC_INTERFACE_W-1:0]  mrp_dst_outstream_data;
    logic   [`MAC_PADBYTES_W-1:0]   mrp_dst_outstream_padbytes;
    logic                           dst_mrp_outstream_rdy;
   
    
    logic                               ctrl_cam_wr_cam;
    logic                               ctrl_cam_clear_entry;
    addr_mux_sel_e                      ctrl_addr_mux_sel;

    logic                               datap_ctrl_new_flow_val;

    logic                               ctrl_datap_store_meta;
    logic                               ctrl_datap_store_hdr;
    logic                               ctrl_datap_store_fifo_conn_id;
    logic                               ctrl_datap_store_cam_result;

    logic                               ctrl_datap_store_hold;

    logic                               datap_ctrl_pkt_expected;

    logic                               ctrl_state_rd_req_val;
    logic                               state_ctrl_rd_resp_val;

    logic                               ctrl_state_wr_req;

    logic                               ctrl_cam_rd_cam_val;
    logic                               ctrl_datap_save_cam_result;

    logic                               datap_ctrl_cam_hit;

    logic                               ctrl_set_timer_flag;
    logic                               ctrl_clear_timer_flag;


    logic                               ctrl_datap_store_padbytes;

    mrp_flags                           datap_ctrl_mrp_flags;
    
    logic                               conn_id_fifo_ctrl_id_avail;
    logic   [CONN_ID_W-1:0]             conn_id_fifo_datap_conn_id;
    logic                               ctrl_conn_id_fifo_id_req;

    logic                               ctrl_conn_id_fifo_wr_req;
    logic   [CONN_ID_W-1:0]             datap_conn_id_wr_conn_id;
    
    mrp_req_key                         datap_cam_wr_tag;
    logic   [CONN_ID_W-1:0]             datap_cam_wr_data;
    
    logic   [CONN_ID_W-1:0]             datap_state_rd_req_addr;
    mrp_rx_state                        state_datap_rd_resp_data;

    logic   [CONN_ID_W-1:0]             datap_state_wr_req_addr;
    mrp_rx_state                        datap_state_wr_req_data;

    mrp_req_key                         datap_cam_lookup_key;
    logic                               cam_datap_lookup_hit;
    logic   [CONN_ID_W-1:0]             cam_datap_conn_id;

    logic                               datap_ctrl_last_data;
    
    logic   [TIMESTAMP_W-1:0]           curr_time;
    logic   [CONN_ID_W-1:0]             update_timer_conn_id;
    logic   [TIMESTAMP_W-1:0]           update_timer_time;

    logic   [TIMESTAMP_W-1:0]           curr_time_reg;
    
    logic                               timeout_val;
    mrp_req_key                         timeout_conn_key;
    logic   [CONN_ID_W-1:0]             timeout_conn_id;
    logic                               timeout_rdy;

    logic   [31:0]                          pkts_recved_cnt;
    logic   [31:0]                          dropped_pkts_cnt;
    logic                                   ctrl_write_log;
    logic   [MRP_PKT_HDR_W-1:0]             datap_log_pkt_hdr;

    assign mrp_dst_rx_outstream_val = mrp_dst_outstream_val;
    assign dst_mrp_outstream_rdy = dst_mrp_rx_outstream_rdy;

    always_comb begin
        mrp_dst_rx_outstream = '0;
        mrp_dst_rx_outstream.data = mrp_dst_outstream_data;
        mrp_dst_rx_outstream.last = mrp_dst_outstream_last;
        mrp_dst_rx_outstream.padbytes = mrp_dst_outstream_padbytes;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            curr_time_reg <= '0;
        end
        else begin
            curr_time_reg <= curr_time_reg + 1'b1;
        end
    end

    mrp_rx_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_mrp_rx_meta_val           (src_mrp_rx_meta_val            )
        ,.mrp_src_rx_meta_rdy           (mrp_src_rx_meta_rdy            )
                                                                        
        ,.src_mrp_rx_data_val           (src_mrp_rx_data_val            )
        ,.src_mrp_rx_data_last          (src_mrp_rx_data_last           )
        ,.src_mrp_rx_data_padbytes      (src_mrp_rx_data_padbytes       )
        ,.mrp_src_rx_data_rdy           (mrp_src_rx_data_rdy            )
    
        ,.mrp_dst_rx_outstream_meta_val (mrp_dst_rx_outstream_meta_val  )
        ,.mrp_dst_rx_outstream_start    (mrp_dst_rx_outstream_start     )
        ,.mrp_dst_rx_outstream_msg_done (mrp_dst_rx_outstream_msg_done  )
        ,.dst_mrp_rx_outstream_meta_rdy (dst_mrp_rx_outstream_meta_rdy  )
    
        ,.mrp_dst_rx_outstream_val      (mrp_dst_outstream_val          )
        ,.mrp_dst_rx_outstream_last     (mrp_dst_outstream_last         )
        ,.dst_mrp_rx_outstream_rdy      (dst_mrp_outstream_rdy          )
                                                                        
        ,.ctrl_cam_wr_cam               (ctrl_cam_wr_cam                )
        ,.ctrl_cam_clear_entry          (ctrl_cam_clear_entry           )
        ,.ctrl_addr_mux_sel             (ctrl_addr_mux_sel              )
    
        ,.timeout_ctrl_val              (timeout_val                    )
        ,.ctrl_timeout_rdy              (timeout_rdy                    )
                                                                        
        ,.datap_ctrl_new_flow_val       (datap_ctrl_new_flow_val        )
                                                                        
        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_fifo_conn_id (ctrl_datap_store_fifo_conn_id  )
        ,.ctrl_datap_store_cam_result   (ctrl_datap_store_cam_result    )
                                                                        
        ,.ctrl_datap_store_hold         (ctrl_datap_store_hold          )
                                                                        
        ,.datap_ctrl_pkt_expected       (datap_ctrl_pkt_expected        )
                                                                        
        ,.ctrl_state_rd_req_val         (ctrl_state_rd_req_val          )
        ,.state_ctrl_rd_resp_val        (state_ctrl_rd_resp_val         )
                                                                        
        ,.ctrl_state_wr_req             (ctrl_state_wr_req              )
                                                                        
        ,.ctrl_cam_rd_cam_val           (ctrl_cam_rd_cam_val            )
                                                                        
        ,.datap_ctrl_cam_hit            (datap_ctrl_cam_hit             )
                                                                        
        ,.ctrl_set_timer_flag           (ctrl_set_timer_flag            )
        ,.ctrl_clear_timer_flag         (ctrl_clear_timer_flag          )
                                                                        
        ,.ctrl_datap_store_padbytes     (ctrl_datap_store_padbytes      )
                                                                        
        ,.datap_ctrl_mrp_flags          (datap_ctrl_mrp_flags           )
    
        ,.conn_id_fifo_ctrl_id_avail    (conn_id_fifo_ctrl_id_avail     )
        ,.ctrl_conn_id_fifo_id_req      (ctrl_conn_id_fifo_id_req       )
                                                                        
        ,.ctrl_conn_id_fifo_wr_req      (ctrl_conn_id_fifo_wr_req       )

        ,.mrp_rx_conn_id_table_wr_val   (mrp_rx_conn_id_table_wr_val    )
        
        ,.datap_ctrl_last_data          (datap_ctrl_last_data           )

        ,.pkts_recved_cnt               (pkts_recved_cnt                )
        ,.dropped_pkts_cnt              (dropped_pkts_cnt               )
        ,.ctrl_write_log                (ctrl_write_log                 )
    );

    mrp_rx_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_mrp_rx_src_ip             (src_mrp_rx_src_ip              )
        ,.src_mrp_rx_dst_ip             (src_mrp_rx_dst_ip              )
        ,.src_mrp_rx_src_port           (src_mrp_rx_src_port            )
        ,.src_mrp_rx_dst_port           (src_mrp_rx_dst_port            )
                                                                        
        ,.src_mrp_rx_data               (src_mrp_rx_data                )
        ,.src_mrp_rx_data_padbytes      (src_mrp_rx_data_padbytes       )
                                                                        
        ,.mrp_dst_rx_outstream_data     (mrp_dst_outstream_data         )
        ,.mrp_dst_rx_outstream_padbytes (mrp_dst_outstream_padbytes     )
        ,.mrp_dst_rx_outstream_last     (mrp_dst_outstream_last         )

        ,.mrp_dst_rx_outstream_id       (mrp_dst_rx_outstream_conn_id   )
                    
        ,.datap_cam_wr_tag              (datap_cam_wr_tag               )
        ,.datap_cam_wr_data             (datap_cam_wr_data              )
                                                                        
        ,.datap_ctrl_new_flow_val       (datap_ctrl_new_flow_val        )
                                                                        
        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_fifo_conn_id (ctrl_datap_store_fifo_conn_id  )
        ,.ctrl_datap_store_cam_result   (ctrl_datap_store_cam_result    )
                                                                        
        ,.ctrl_datap_store_hold         (ctrl_datap_store_hold          )
                                                                        
        ,.datap_ctrl_pkt_expected       (datap_ctrl_pkt_expected        )
                                                                        
        ,.datap_state_rd_req_addr       (datap_state_rd_req_addr        )
        ,.state_datap_rd_resp_data      (state_datap_rd_resp_data       )

        ,.datap_state_wr_req_addr       (datap_state_wr_req_addr        )
        ,.datap_state_wr_req_data       (datap_state_wr_req_data        )
                                                                        
        ,.datap_cam_lookup_key          (datap_cam_lookup_key           )
        ,.cam_datap_lookup_hit          (cam_datap_lookup_hit           )
        ,.cam_datap_conn_id             (cam_datap_conn_id              )
                                                                        
        ,.datap_ctrl_cam_hit            (datap_ctrl_cam_hit             )
                                                                        
        ,.curr_time                     (curr_time_reg                  )
        ,.update_timer_conn_id          (update_timer_conn_id           )
        ,.update_timer_time             (update_timer_time              )
                                                                        
        ,.ctrl_datap_store_padbytes     (ctrl_datap_store_padbytes      )
                                                                        
        ,.datap_ctrl_mrp_flags          (datap_ctrl_mrp_flags           )
    
        ,.conn_id_fifo_datap_conn_id    (conn_id_fifo_datap_conn_id     )
                                                                        
        ,.datap_conn_id_wr_conn_id      (datap_conn_id_wr_conn_id       )

        ,.datap_ctrl_last_data          (datap_ctrl_last_data           )

        ,.mrp_rx_conn_id_table_wr_addr  (mrp_rx_conn_id_table_wr_addr   )
        ,.mrp_rx_conn_id_table_wr_data  (mrp_rx_conn_id_table_wr_data   )

        ,.datap_log_pkt_hdr             (datap_log_pkt_hdr              )
    );

    ram_1r1w_sync_backpressure # (
         .width_p   (MRP_RX_STATE_W )
        ,.els_p     (MAX_CONNS      )
    ) rx_state_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (ctrl_state_wr_req          )
        ,.wr_req_addr   (datap_state_wr_req_addr    )
        ,.wr_req_data   (datap_state_wr_req_data    )
        ,.wr_req_rdy    ()
    
        ,.rd_req_val    (ctrl_state_rd_req_val      )
        ,.rd_req_addr   (datap_state_rd_req_addr            )
        ,.rd_req_rdy    ()
    
        ,.rd_resp_val   (state_ctrl_rd_resp_val             )
        ,.rd_resp_data  (state_datap_rd_resp_data   )
        ,.rd_resp_rdy   (1'b1)
    );


    logic   [MAX_CONNS-1:0] arbiter_cam_wr_val;
    logic                   arbiter_cam_wr_clear;
    mrp_req_key             arbiter_cam_wr_key;
    logic   [CONN_ID_W-1:0] arbiter_cam_wr_data;
    mrp_req_key mrp_rx_cam_wr_key;
    logic   [CONN_ID_W-1:0] mrp_rx_conn_id_fifo_wr_id;
    logic                   arbiter_conn_id_fifo_wr_req;
    logic   [CONN_ID_W-1:0] arbiter_conn_id_fifo_wr_data;

    assign mrp_rx_cam_wr_key = ctrl_addr_mux_sel == DATAP
                        ? datap_cam_wr_tag
                        : timeout_conn_key;
    assign mrp_rx_conn_id_fifo_wr_id = ctrl_addr_mux_sel == DATAP
                                        ? datap_conn_id_wr_conn_id
                                       : timeout_conn_id;

    dealloc_arbiter rx_dealloc_arbiter (
         .mrp_tx_dealloc_msg_finalize_val       (mrp_tx_dealloc_msg_finalize_val    )
        ,.mrp_tx_dealloc_msg_finalize_key       (mrp_tx_dealloc_msg_finalize_key    )
        ,.mrp_tx_dealloc_msg_finalize_conn_id   (mrp_tx_dealloc_msg_finalize_conn_id)
        ,.dealloc_mrp_tx_msg_finalize_rdy       (dealloc_mrp_tx_msg_finalize_rdy    )
    
        ,.mrp_rx_cam_wr_val                     (ctrl_cam_wr_cam                    )
        ,.mrp_rx_cam_wr_clear                   (ctrl_cam_clear_entry               )
        ,.mrp_rx_cam_wr_key                     (mrp_rx_cam_wr_key                  )
        ,.mrp_rx_cam_wr_data                    (datap_cam_wr_data                  )
        ,.mrp_rx_conn_id_fifo_wr_req            (ctrl_conn_id_fifo_wr_req           )
        ,.mrp_rx_conn_id_fifo_wr_data           (mrp_rx_conn_id_fifo_wr_id          )
    
        ,.arbiter_cam_wr_val                    (arbiter_cam_wr_val                 )
        ,.arbiter_cam_wr_clear                  (arbiter_cam_wr_clear               )
        ,.arbiter_cam_wr_key                    (arbiter_cam_wr_key                 )
        ,.arbiter_cam_wr_data                   (arbiter_cam_wr_data                )
        ,.arbiter_conn_id_fifo_wr_req           (arbiter_conn_id_fifo_wr_req        )
        ,.arbiter_conn_id_fifo_wr_data          (arbiter_conn_id_fifo_wr_data       )
    );

    bsg_cam_1r1w_unmanaged #(
        .els_p          (MAX_CONNS      )
       ,.tag_width_p    (MRP_REQ_KEY_W  )
       ,.data_width_p   (CONN_ID_W      )
    ) conn_id_cam (
         .clk_i     (clk    )
        ,.reset_i   (rst    )
        
        ,.w_v_i             (arbiter_cam_wr_val     )
        ,.w_set_not_clear_i (~arbiter_cam_wr_clear  )
        
        ,.w_tag_i           (arbiter_cam_wr_key     )
        ,.w_data_i          (arbiter_cam_wr_data    )
        
        ,.w_empty_o         ()
        
        ,.r_v_i             (ctrl_cam_rd_cam_val    )
        ,.r_tag_i           (datap_cam_lookup_key   )
    
        ,.r_data_o          (cam_datap_conn_id      )
        ,.r_v_o             (cam_datap_lookup_hit   )
    );

    logic   [CONN_ID_W-1:0] timer_flags_conn_id;

    assign timer_flags_conn_id = ctrl_addr_mux_sel == DATAP
                                ? update_timer_conn_id
                                : timeout_conn_id;

    timeout_engine #(
         .NUM_CONNS     (MAX_CONNS      )
        ,.CONN_ID_W     (CONN_ID_W      )
        ,.TIMESTAMP_W   (TIMESTAMP_W    ) 
    ) rx_timeouts (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_timeout_set_bit               (ctrl_set_timer_flag                )
        ,.src_timeout_clear_bit             (ctrl_clear_timer_flag              )
        ,.src_timeout_bit_addr              (timer_flags_conn_id                )
        ,.src_timeout_next_time             (update_timer_time                  )

        ,.timeout_conn_id_map_rd_req_val    (mrp_rx_conn_id_table_rd_req_val    )
        ,.timeout_conn_id_map_rd_req_addr   (mrp_rx_conn_id_table_rd_req_addr   )
    
        ,.conn_id_map_timeout_rd_resp_val   (conn_id_table_mrp_rx_rd_resp_val   )
        ,.conn_id_map_timeout_rd_resp_data  (conn_id_table_mrp_rx_rd_resp_data  )
    
        ,.curr_time                         (curr_time_reg                      )
    
        ,.timeout_val                       (timeout_val                        )
        ,.timeout_conn_key                  (timeout_conn_key                   )
        ,.timeout_conn_id                   (timeout_conn_id                    )
        ,.timeout_rdy                       (timeout_rdy                        )
    );  

    conn_id_fifo #(
        .CONN_ID_W  (CONN_ID_W)
    ) conn_id_fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.conn_id_ret_val   (arbiter_conn_id_fifo_wr_req    )
        ,.conn_id_ret_id    (arbiter_conn_id_fifo_wr_data   )
        ,.conn_id_ret_rdy   ()
    
        ,.conn_id_req       (ctrl_conn_id_fifo_id_req       )
        ,.conn_id_avail     (conn_id_fifo_ctrl_id_avail     )
        ,.conn_id           (conn_id_fifo_datap_conn_id     )
    );

//    mrp_logger #(
//        .LOG_DEPTH_LOG2 (8)
//    ) mrp_rx_logger (
//         .clk   (clk    )
//        ,.rst   (rst    )
//
//        ,.recv_mrp_hdr_val      (ctrl_write_log )
//        ,.mrp_pkts_recved       (pkts_recved_cnt)
//        ,.mrp_pkts_dropped      (dropped_pkts_cnt)
//        ,.recv_mrp_hdr          (datap_log_pkt_hdr)
//
//        ,.rd_cmd_queue_empty    (rd_cmd_queue_empty     )
//        ,.rd_cmd_queue_rd_req   (rd_cmd_queue_rd_req    )
//        ,.rd_cmd_queue_rd_data  (rd_cmd_queue_rd_data   )
//
//        ,.rd_resp_val           (rd_resp_val            )
//        ,.shell_reg_rd_data     (shell_reg_rd_data      )
//    );


endmodule
