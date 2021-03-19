`include "mrp_defs.svh"
module mrp_tx (
     input clk
    ,input rst

    ,input  logic                           src_mrp_tx_meta_val
    ,input  logic   [`UDP_LENGTH_W-1:0]     src_mrp_tx_req_len
    ,input  logic   [CONN_ID_W-1:0]         src_mrp_tx_conn_id
    ,input  logic                           src_mrp_tx_msg_done
    ,output logic                           mrp_src_tx_meta_rdy

    ,input  logic                           src_mrp_tx_instream_val
    ,input          mrp_stream              src_mrp_tx_instream
    ,output logic                           mrp_src_tx_instream_rdy
    
    ,output logic                           mrp_dst_tx_meta_val
    ,output logic   [`IP_ADDR_W-1:0]        mrp_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]        mrp_dst_tx_dst_ip
    ,output logic   [`PORT_NUM_W-1:0]       mrp_dst_tx_src_port
    ,output logic   [`PORT_NUM_W-1:0]       mrp_dst_tx_dst_port
    ,output logic   [`UDP_LENGTH_W-1:0]     mrp_dst_tx_len
    ,input                                  dst_mrp_tx_meta_rdy

    ,output logic                           mrp_dst_tx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  mrp_dst_tx_data
    ,output logic                           mrp_dst_tx_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   mrp_dst_tx_data_padbytes
    ,input  logic                           dst_mrp_tx_data_rdy
    
    ,input  logic                           mrp_rx_mrp_tx_new_flow_val
    ,input  logic   [CONN_ID_W-1:0]         mrp_rx_mrp_tx_new_flow_conn_id
    
    ,output logic                           mrp_tx_dealloc_msg_finalize_val
    ,output         mrp_req_key             mrp_tx_dealloc_msg_finalize_key
    ,output         [CONN_ID_W-1:0]         mrp_tx_dealloc_msg_finalize_conn_id
    ,input  logic                           dealloc_mrp_tx_msg_finalize_rdy

    ,output logic                           mrp_tx_conn_id_table_rd_req_val
    ,output logic   [CONN_ID_W-1:0]         mrp_tx_conn_id_table_rd_req_addr

    ,input  logic                           conn_id_table_mrp_tx_rd_resp_val
    ,input          mrp_req_key             conn_id_table_mrp_tx_rd_resp_data

    ,output logic   [63:0]                  pkts_sent_cnt
);
    
    logic                                   ctrl_datap_store_meta;
    logic                                   ctrl_datap_store_conn_data;
    logic                                   ctrl_datap_update_pkt_data;
    logic                                   ctrl_datap_calc_pkt_len;
    logic                                   ctrl_datap_decr_bytes_rem;

    logic                                   ctrl_datap_store_hold;
    tx_hold_mux_sel_e                       ctrl_datap_hold_mux_sel;

    logic                                   datap_ctrl_drain_hold;
    logic                                   datap_ctrl_msg_end;
    logic                                   datap_ctrl_last_pkt_bytes;
    logic                                   datap_ctrl_last_pkt;
    logic                                   ctrl_datap_store_padbytes;
    tx_padbytes_mux_sel_e                   ctrl_datap_padbytes_mux_sel;

    logic   [CONN_ID_W-1:0]                 datap_tx_state_rd_req_addr;

    mrp_tx_state                            tx_state_datap_rd_resp_data;
    
    logic   [CONN_ID_W-1:0]                 datap_tx_state_wr_req_addr;
    mrp_tx_state                            datap_tx_state_wr_req_data;
    
    logic                                   ctrl_tx_state_rd_req_val;

    logic                                   tx_state_ctrl_rd_resp_val;

    logic                                   ctrl_tx_state_wr_req_val;
    logic                                   tx_state_ctrl_wr_req_rdy;

    logic                                   tx_state_wr_req_val;
    logic   [CONN_ID_W-1:0]                 tx_state_wr_req_addr;
    mrp_tx_state                            tx_state_wr_req_data;

    assign tx_state_wr_req_val = ctrl_tx_state_wr_req_val | mrp_rx_mrp_tx_new_flow_val;

    assign tx_state_ctrl_wr_req_rdy = ~mrp_rx_mrp_tx_new_flow_val;

    always_comb begin
        if (mrp_rx_mrp_tx_new_flow_val) begin
            tx_state_wr_req_data = '0;
            tx_state_wr_req_addr = mrp_rx_mrp_tx_new_flow_conn_id;
        end
        else begin
            tx_state_wr_req_data = datap_tx_state_wr_req_data;
            tx_state_wr_req_addr = datap_tx_state_wr_req_addr;
        end

    end
    ram_1r1w_sync_backpressure #(
         .width_p   (MRP_TX_STATE_W )
        ,.els_p     (MAX_CONNS      )
    ) tx_state_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (tx_state_wr_req_val        )
        ,.wr_req_addr   (tx_state_wr_req_addr       )
        ,.wr_req_data   (tx_state_wr_req_data       )
        ,.wr_req_rdy    ()
    
        ,.rd_req_val    (ctrl_tx_state_rd_req_val   )
        ,.rd_req_addr   (datap_tx_state_rd_req_addr )
        ,.rd_req_rdy    ()
    
        ,.rd_resp_val   (tx_state_ctrl_rd_resp_val  )
        ,.rd_resp_data  (tx_state_datap_rd_resp_data)
        ,.rd_resp_rdy   (1'b1)
    );

    mrp_tx_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.mrp_tx_conn_id_table_rd_req_addr      (mrp_tx_conn_id_table_rd_req_addr   )
    
        ,.conn_id_table_mrp_tx_rd_resp_data     (conn_id_table_mrp_tx_rd_resp_data  )
        
        ,.src_mrp_tx_instream_req_len           (src_mrp_tx_req_len                 )
        ,.src_mrp_tx_instream_msg_done          (src_mrp_tx_msg_done                )
        ,.src_mrp_tx_instream_conn_id           (src_mrp_tx_conn_id                 )
        ,.src_mrp_tx_instream_data              (src_mrp_tx_instream.data           )
        ,.src_mrp_tx_instream_padbytes          (src_mrp_tx_instream.padbytes       )
        
        ,.mrp_dst_tx_src_ip                     (mrp_dst_tx_src_ip                  )
        ,.mrp_dst_tx_dst_ip                     (mrp_dst_tx_dst_ip                  )
        ,.mrp_dst_tx_src_port                   (mrp_dst_tx_src_port                )
        ,.mrp_dst_tx_dst_port                   (mrp_dst_tx_dst_port                )
        ,.mrp_dst_tx_len                        (mrp_dst_tx_len                     )
    
        ,.mrp_dst_tx_data                       (mrp_dst_tx_data                    )
        ,.mrp_dst_tx_data_padbytes              (mrp_dst_tx_data_padbytes           )
        
        ,.ctrl_datap_store_meta                 (ctrl_datap_store_meta              )
        ,.ctrl_datap_store_conn_data            (ctrl_datap_store_conn_data         )
        ,.ctrl_datap_update_pkt_data            (ctrl_datap_update_pkt_data         )
        ,.ctrl_datap_calc_pkt_len               (ctrl_datap_calc_pkt_len            )
        ,.ctrl_datap_decr_bytes_rem             (ctrl_datap_decr_bytes_rem          )
                                                                                   
        ,.ctrl_datap_store_hold                 (ctrl_datap_store_hold              )
        ,.ctrl_datap_hold_mux_sel               (ctrl_datap_hold_mux_sel            )
                                                                                   
        ,.datap_ctrl_drain_hold                 (datap_ctrl_drain_hold              )
        ,.datap_ctrl_msg_end                    (datap_ctrl_msg_end                 )
        ,.datap_ctrl_last_pkt_bytes             (datap_ctrl_last_pkt_bytes          )
        ,.datap_ctrl_last_pkt                   (datap_ctrl_last_pkt                )
        ,.ctrl_datap_store_padbytes             (ctrl_datap_store_padbytes          )
        ,.ctrl_datap_padbytes_mux_sel           (ctrl_datap_padbytes_mux_sel        )
    
        ,.datap_tx_state_rd_req_addr            (datap_tx_state_rd_req_addr         )
                                                                                   
        ,.tx_state_datap_rd_resp_data           (tx_state_datap_rd_resp_data        )
                                                                                   
        ,.datap_tx_state_wr_req_addr            (datap_tx_state_wr_req_addr         )
        ,.datap_tx_state_wr_req_data            (datap_tx_state_wr_req_data         )
    
        ,.mrp_tx_dealloc_msg_finalize_key       (mrp_tx_dealloc_msg_finalize_key    )
        ,.mrp_tx_dealloc_msg_finalize_conn_id   (mrp_tx_dealloc_msg_finalize_conn_id)
    );

    mrp_tx_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.mrp_tx_conn_id_table_rd_req_val   (mrp_tx_conn_id_table_rd_req_val    )
        ,.conn_id_table_mrp_tx_rd_resp_val  (conn_id_table_mrp_tx_rd_resp_val   )
        
        ,.src_mrp_tx_meta_val               (src_mrp_tx_meta_val                )
        ,.mrp_src_tx_meta_rdy               (mrp_src_tx_meta_rdy                )
                                                                                
        ,.src_mrp_tx_instream_val           (src_mrp_tx_instream_val            )
        ,.src_mrp_tx_instream_last          (src_mrp_tx_instream.last           )
        ,.mrp_src_tx_instream_rdy           (mrp_src_tx_instream_rdy            )
                                                                                
        ,.mrp_dst_tx_meta_val               (mrp_dst_tx_meta_val                )
        ,.dst_mrp_tx_meta_rdy               (dst_mrp_tx_meta_rdy                )
                                                                                
        ,.mrp_dst_tx_data_val               (mrp_dst_tx_data_val                )
        ,.mrp_dst_tx_data_last              (mrp_dst_tx_data_last               )
        ,.dst_mrp_tx_data_rdy               (dst_mrp_tx_data_rdy                )
                                                                                
        ,.ctrl_datap_store_meta             (ctrl_datap_store_meta              )
        ,.ctrl_datap_store_conn_data        (ctrl_datap_store_conn_data         )
        ,.ctrl_datap_update_pkt_data        (ctrl_datap_update_pkt_data         )
        ,.ctrl_datap_calc_pkt_len           (ctrl_datap_calc_pkt_len            )
        ,.ctrl_datap_decr_bytes_rem         (ctrl_datap_decr_bytes_rem          )
                                                                                
        ,.ctrl_datap_store_hold             (ctrl_datap_store_hold              )
        ,.ctrl_datap_hold_mux_sel           (ctrl_datap_hold_mux_sel            )
        
        ,.datap_ctrl_drain_hold             (datap_ctrl_drain_hold              )
        ,.datap_ctrl_msg_end                (datap_ctrl_msg_end                 )
        ,.datap_ctrl_last_pkt_bytes         (datap_ctrl_last_pkt_bytes          )
        ,.datap_ctrl_last_pkt               (datap_ctrl_last_pkt                )
        ,.ctrl_datap_store_padbytes         (ctrl_datap_store_padbytes          )
        ,.ctrl_datap_padbytes_mux_sel       (ctrl_datap_padbytes_mux_sel        )
                                                                                
        ,.ctrl_tx_state_rd_req_val          (ctrl_tx_state_rd_req_val           )
                                                                                
        ,.tx_state_ctrl_rd_resp_val         (tx_state_ctrl_rd_resp_val          )
                                                                                
        ,.ctrl_tx_state_wr_req_val          (ctrl_tx_state_wr_req_val           )
        ,.tx_state_ctrl_wr_req_rdy          (tx_state_ctrl_wr_req_rdy           )
    
        ,.mrp_tx_dealloc_msg_finalize_val   (mrp_tx_dealloc_msg_finalize_val    )
        ,.dealloc_mrp_tx_msg_finalize_rdy   (dealloc_mrp_tx_msg_finalize_rdy    )

        ,.pkts_sent_cnt                     (pkts_sent_cnt                      )
    );
endmodule
