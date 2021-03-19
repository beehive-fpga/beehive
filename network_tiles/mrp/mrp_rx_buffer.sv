`include "mrp_defs.svh"
module mrp_rx_buffer (
     input clk
    ,input rst 
    
    ,input                                      mrp_rx_buffer_outstream_meta_val
    ,input          [CONN_ID_W-1:0]             mrp_rx_buffer_outstream_conn_id
    ,input                                      mrp_rx_buffer_outstream_start
    ,input                                      mrp_rx_buffer_outstream_msg_done
    ,output logic                               rx_buffer_mrp_outstream_meta_rdy

    ,input                                      mrp_rx_buffer_outstream_val
    ,input          mrp_stream                  mrp_rx_buffer_outstream
    ,output logic                               rx_buffer_mrp_outstream_rdy

    ,output logic                               rx_buffer_dst_meta_val
    ,output logic   [CONN_ID_W-1:0]             rx_buffer_dst_conn_id
    ,output logic   [RX_CONN_BUF_ADDR_W-1:0]    rx_buffer_dst_msg_len
    ,input                                      dst_rx_buffer_meta_rdy

    ,output logic                               rx_buffer_dst_outstream_val
    ,output         mrp_stream                  rx_buffer_dst_outstream
    ,input  logic                               dst_rx_buffer_outstream_rdy
);
    
    logic                           input_ctrl_rx_buf_wr_req;
    logic                           input_ctrl_rx_ptr_rd_req;
    logic                           input_ctrl_rx_ptr_wr_req;

    logic                           input_ctrl_input_datap_store_meta;
    logic                           input_ctrl_input_datap_store_rx_ptrs;
    rx_ptr_mux_sel_e                 input_ctrl_input_datap_rx_ptrs_sel;
    logic                           input_ctrl_input_datap_incr_head_ptr;

    logic                           input_datap_input_ctrl_ptrs_stored;

    logic                          input_ctrl_fifo_enq_msg_desc_req;
    logic                          fifo_input_ctrl_enq_msg_desc_rdy;
    
    logic   [RX_BUF_ADDR_W-1:0]     input_datap_rx_buf_wr_addr;
    logic   [RX_BUF_LINE_ADDR_W-1:0]    rx_buf_wr_line;
    logic   [`MAC_INTERFACE_W-1:0]  input_datap_rx_buf_wr_data;

    logic   [CONN_ID_W-1:0]         input_datap_rx_ptr_rd_addr;

    rx_ptrs_struct                  rx_ptr_input_datap_rd_data;

    logic   [CONN_ID_W-1:0]         input_datap_rx_ptr_wr_addr;
    rx_ptrs_struct                  input_datap_rx_ptr_wr_data;

    output_ctrl_enq_struct          input_datap_fifo_enq_msg_desc;
    
    logic                           fifo_output_ctrl_msg_desc_avail;
    output_ctrl_enq_struct          fifo_output_datap_msg_desc;
    logic                           output_ctrl_fifo_msg_desc_req;

    logic                           output_ctrl_rx_buf_rd_req_val;
    
    logic                           output_ctrl_output_datap_init_state;
    logic                           output_ctrl_output_datap_incr_rd_addr;
    logic                           output_datap_output_ctrl_last_rd;
    

    logic   [RX_BUF_ADDR_W-1:0]     output_datap_rx_buf_rd_req_addr;
    logic   [RX_BUF_LINE_ADDR_W-1:0]    rx_buf_rd_req_line_addr;
    logic   [`MAC_INTERFACE_W-1:0]  rx_buf_output_datap_rd_resp;

    logic   [`MAC_INTERFACE_W-1:0]  rx_buffer_dst_data;
    logic                           rx_buffer_dst_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   rx_buffer_dst_data_padbytes;

    mrp_rx_buffer_input_ctrl input_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.mrp_rx_buffer_outstream_meta_val      (mrp_rx_buffer_outstream_meta_val       )
        ,.mrp_rx_buffer_outstream_start         (mrp_rx_buffer_outstream_start          )
        ,.mrp_rx_buffer_outstream_msg_done      (mrp_rx_buffer_outstream_msg_done       )
        ,.rx_buffer_mrp_outstream_meta_rdy      (rx_buffer_mrp_outstream_meta_rdy       )
   
        ,.mrp_rx_buffer_outstream_data_val      (mrp_rx_buffer_outstream_val            )
        ,.mrp_rx_buffer_outstream_last          (mrp_rx_buffer_outstream.last           )
        ,.rx_buffer_mrp_outstream_data_rdy      (rx_buffer_mrp_outstream_rdy            )

        ,.input_ctrl_rx_buf_wr_req              (input_ctrl_rx_buf_wr_req               )
        ,.input_ctrl_rx_ptr_rd_req              (input_ctrl_rx_ptr_rd_req               )
        ,.input_ctrl_rx_ptr_wr_req              (input_ctrl_rx_ptr_wr_req               )

        ,.input_ctrl_input_datap_store_meta     (input_ctrl_input_datap_store_meta      )
        ,.input_ctrl_input_datap_store_rx_ptrs  (input_ctrl_input_datap_store_rx_ptrs   )
        ,.input_ctrl_input_datap_rx_ptrs_sel    (input_ctrl_input_datap_rx_ptrs_sel     )
        ,.input_ctrl_input_datap_incr_head_ptr  (input_ctrl_input_datap_incr_head_ptr   )

        ,.input_datap_input_ctrl_ptrs_stored    (input_datap_input_ctrl_ptrs_stored     )

        ,.input_ctrl_fifo_enq_msg_desc_req      (input_ctrl_fifo_enq_msg_desc_req       )
        ,.fifo_input_ctrl_enq_msg_desc_rdy      (fifo_input_ctrl_enq_msg_desc_rdy       )
    );

    mrp_rx_buffer_input_datap input_datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.mrp_rx_buffer_outstream_conn_id       (mrp_rx_buffer_outstream_conn_id        )

        ,.mrp_rx_buffer_outstream_data          (mrp_rx_buffer_outstream.data           )
        ,.mrp_rx_buffer_outstream_data_last     (mrp_rx_buffer_outstream.last           )
        ,.mrp_rx_buffer_outstream_data_padbytes (mrp_rx_buffer_outstream.padbytes       )
        
        ,.input_datap_rx_buf_wr_addr            (input_datap_rx_buf_wr_addr             )
        ,.input_datap_rx_buf_wr_data            (input_datap_rx_buf_wr_data             )
                                                                                        
        ,.input_datap_rx_ptr_rd_addr            (input_datap_rx_ptr_rd_addr             )
                                                                                        
        ,.rx_ptr_input_datap_rd_data            (rx_ptr_input_datap_rd_data             )
                                                                                        
        ,.input_datap_rx_ptr_wr_addr            (input_datap_rx_ptr_wr_addr             )
        ,.input_datap_rx_ptr_wr_data            (input_datap_rx_ptr_wr_data             )
                                                                                        
        ,.input_ctrl_input_datap_store_meta     (input_ctrl_input_datap_store_meta      )
        ,.input_ctrl_input_datap_store_rx_ptrs  (input_ctrl_input_datap_store_rx_ptrs   )
        ,.input_ctrl_input_datap_rx_ptrs_sel    (input_ctrl_input_datap_rx_ptrs_sel     )
        ,.input_ctrl_input_datap_incr_head_ptr  (input_ctrl_input_datap_incr_head_ptr   )
                                                                                        
        ,.input_datap_input_ctrl_ptrs_stored    (input_datap_input_ctrl_ptrs_stored     )
                                                                                        
        ,.input_datap_fifo_enq_msg_desc         (input_datap_fifo_enq_msg_desc          )
    );

    assign rx_buf_wr_line = input_datap_rx_buf_wr_addr[RX_BUF_ADDR_W-1:`MAC_INTERFACE_BYTES_W];
    assign rx_buf_rd_req_line_addr = output_datap_rx_buf_rd_req_addr[RX_BUF_ADDR_W-1:`MAC_INTERFACE_BYTES_W];

    bsg_mem_1r1w_sync #(
         .width_p   (`MAC_INTERFACE_W   )
        ,.els_p     (RX_BUF_LINES       )
    ) rx_bufs_mem (
         .clk_i     (clk    )
        ,.reset_i   (rst    )

        ,.w_v_i     (input_ctrl_rx_buf_wr_req       )
        ,.w_addr_i  (rx_buf_wr_line                 )
        ,.w_data_i  (input_datap_rx_buf_wr_data     )

        ,.r_v_i     (output_ctrl_rx_buf_rd_req_val  )
        ,.r_addr_i  (rx_buf_rd_req_line_addr        )

        ,.r_data_o  (rx_buf_output_datap_rd_resp    )
    );
    
    bsg_mem_1r1w_sync #(
         .width_p   (RX_PTRS_STRUCT_W   )
        ,.els_p     (MAX_CONNS          )
    ) rx_ptrs_mem (
         .clk_i     (clk    )
        ,.reset_i   (rst    )

        ,.w_v_i     (input_ctrl_rx_ptr_wr_req   )
        ,.w_addr_i  (input_datap_rx_ptr_wr_addr )
        ,.w_data_i  (input_datap_rx_ptr_wr_data )

        ,.r_v_i     (input_ctrl_rx_ptr_rd_req   )
        ,.r_addr_i  (input_datap_rx_ptr_rd_addr )

        ,.r_data_o  (rx_ptr_input_datap_rd_data )
    );

    logic   output_ctrl_fifo_full;
    logic   output_ctrl_fifo_empty;
    assign fifo_input_ctrl_enq_msg_desc_rdy = ~output_ctrl_fifo_full;
    assign fifo_output_ctrl_msg_desc_avail = ~output_ctrl_fifo_empty;
    fifo_1r1w #(
         .width_p       (OUTPUT_CTRL_ENQ_STRUCT_W)
        ,.log2_els_p    (3)
    ) input_ctrl_output_ctrl_fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_req    (output_ctrl_fifo_msg_desc_req      )
        ,.rd_data   (fifo_output_datap_msg_desc         )
        ,.empty     (output_ctrl_fifo_empty             )
    
        ,.wr_req    (input_ctrl_fifo_enq_msg_desc_req   )
        ,.wr_data   (input_datap_fifo_enq_msg_desc      )
        ,.full      (output_ctrl_fifo_full              )
    );

    mrp_rx_buffer_output_ctrl output_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.fifo_output_ctrl_msg_desc_avail       (fifo_output_ctrl_msg_desc_avail        )
        ,.output_ctrl_fifo_msg_desc_req         (output_ctrl_fifo_msg_desc_req          )
                                                                                
        ,.output_ctrl_rx_buf_rd_req_val         (output_ctrl_rx_buf_rd_req_val          )
    
        ,.rx_buffer_dst_meta_val                (rx_buffer_dst_meta_val                 )
        ,.dst_rx_buffer_meta_rdy                (dst_rx_buffer_meta_rdy                 )
                                                                        
        ,.rx_buffer_dst_data_val                (rx_buffer_dst_outstream_val            )
        ,.dst_rx_buffer_data_rdy                (dst_rx_buffer_outstream_rdy            )
    
        ,.output_ctrl_output_datap_init_state   (output_ctrl_output_datap_init_state    )
        ,.output_ctrl_output_datap_incr_rd_addr (output_ctrl_output_datap_incr_rd_addr  )
        ,.output_datap_output_ctrl_last_rd      (output_datap_output_ctrl_last_rd       )
    );

    mrp_rx_buffer_output_datap output_datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.fifo_output_datap_msg_desc            (fifo_output_datap_msg_desc             )
                                                                                        
        ,.output_datap_rx_buf_rd_req_addr       (output_datap_rx_buf_rd_req_addr        )
        ,.rx_buf_output_datap_rd_resp           (rx_buf_output_datap_rd_resp            )
                                                                                        
        ,.rx_buffer_dst_conn_id                 (rx_buffer_dst_conn_id                  )
        ,.rx_buffer_dst_msg_len                 (rx_buffer_dst_msg_len                  )
                                                                                        
        ,.rx_buffer_dst_data                    (rx_buffer_dst_data                     )
        ,.rx_buffer_dst_data_last               (rx_buffer_dst_data_last                )
        ,.rx_buffer_dst_data_padbytes           (rx_buffer_dst_data_padbytes            )
                                                                                        
        ,.output_ctrl_output_datap_init_state   (output_ctrl_output_datap_init_state    )
        ,.output_ctrl_output_datap_incr_rd_addr (output_ctrl_output_datap_incr_rd_addr  )
        ,.output_datap_output_ctrl_last_rd      (output_datap_output_ctrl_last_rd       )
    );

    assign rx_buffer_dst_outstream.data = rx_buffer_dst_data;
    assign rx_buffer_dst_outstream.padbytes = rx_buffer_dst_data_padbytes;
    assign rx_buffer_dst_outstream.last = rx_buffer_dst_data_last;

endmodule
