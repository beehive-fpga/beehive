`include "tcp_msg_poller_defs.svh"
module tcp_msg_poller #(
     parameter CHK_SPACE_EMPTY = 0
    ,parameter POLLER_PTR_W = 0
)(
     input clk
    ,input rst
    
    ,input  logic                           src_poller_msg_req_val
    ,input  logic   [FLOWID_W-1:0]          src_poller_msg_req_flowid
    ,input  logic   [POLLER_PTR_W-1:0]      src_poller_msg_req_len
    ,input  logic   [`MSG_SRC_X_WIDTH-1:0]  src_poller_msg_dst_x
    ,input  logic   [`MSG_SRC_Y_WIDTH-1:0]  src_poller_msg_dst_y
    ,input  logic   [`NOC_FBITS_WIDTH-1:0]  src_poller_msg_dst_fbits
    ,output logic                           poller_src_msg_req_rdy

    ,output logic                           poller_msg_dst_meta_val
    ,output logic   [FLOWID_W-1:0]          poller_msg_dst_flowid
    ,output logic   [POLLER_PTR_W:0]        poller_msg_dst_base_ptr
    ,output logic   [POLLER_PTR_W-1:0]      poller_msg_dst_len
    ,output logic   [`XY_WIDTH-1:0]         poller_msg_dst_dst_x
    ,output logic   [`XY_WIDTH-1:0]         poller_msg_dst_dst_y
    ,output logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_dst_dst_fbits
    ,input  logic                           dst_poller_msg_meta_rdy

    ,output logic                           app_base_ptr_rd_req_val
    ,output logic   [FLOWID_W-1:0]          app_base_ptr_rd_req_addr
    ,input  logic                           base_ptr_app_rd_req_rdy
    
    ,input  logic                           base_ptr_app_rd_resp_val
    ,input  logic   [POLLER_PTR_W:0]        base_ptr_app_rd_resp_data
    ,output logic                           app_base_ptr_rd_resp_rdy

    ,output logic                           app_end_ptr_rd_req_val
    ,output logic   [FLOWID_W-1:0]          app_end_ptr_rd_req_addr
    ,input  logic                           end_ptr_app_rd_req_rdy

    ,input  logic                           end_ptr_app_rd_resp_val
    ,input  logic   [POLLER_PTR_W:0]        end_ptr_app_rd_resp_data
    ,output logic                           app_end_ptr_rd_resp_rdy
);
    logic                       meta_ctrl_msg_req_q_wr_req_val;
    logic   [FLOWID_W-1:0]      meta_data_msg_req_q_wr_req_data;
    logic                       msg_req_q_meta_ctrl_wr_req_rdy;

    logic                       active_bitvec_meta_ctrl_req_pending;
    logic                       meta_ctrl_active_bitvec_set_req_val;
    logic   [FLOWID_W-1:0]      meta_data_active_bitvec_set_req_flowid;

    logic                       meta_ctrl_msg_req_mem_wr_val;
    logic   [FLOWID_W-1:0]      meta_data_msg_req_mem_wr_addr;
    msg_req_mem_struct          meta_data_msg_req_mem_wr_data;
    logic                       msg_req_mem_meta_ctrl_wr_rdy;
    
    logic                       msg_req_q_poll_ctrl_empty;
    logic   [FLOWID_W-1:0]      msg_req_q_poll_data_rd_data;
    logic                       poll_ctrl_msg_req_q_rd_req_val;

    logic                       poll_ctrl_msg_req_q_wr_req_val;
    logic   [FLOWID_W-1:0]      poll_data_msg_req_q_wr_data;
    logic                       msg_req_q_poll_ctrl_wr_req_rdy;

    logic                       poll_ctrl_msg_req_mem_rd_req_val;
    logic   [FLOWID_W-1:0]      poll_data_msg_req_mem_rd_req_addr;
    logic                       msg_req_mem_poll_ctrl_rd_req_rdy;

    logic                       msg_req_mem_poll_ctrl_rd_resp_val;
    msg_req_mem_struct          msg_req_mem_poll_data_rd_resp_data;
    logic                       poll_ctrl_msg_req_mem_rd_resp_rdy;
    
    logic                       poll_active_bitvec_clear_req_val;
    logic   [FLOWID_W-1:0]      poll_active_bitvec_clear_req_flowid;

    logic   [MAX_FLOW_CNT-1:0]  meta_active_bitvec;

    // active bitvec stores which flows have requests outstanding
    valid_bitvector #(
         .BITVECTOR_SIZE    (MAX_FLOW_CNT)
    ) req_outstanding (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.set_val           (meta_ctrl_active_bitvec_set_req_val    )
        ,.set_index         (meta_data_active_bitvec_set_req_flowid )
    
        ,.clear_val         (poll_active_bitvec_clear_req_val       )
        ,.clear_index       (poll_active_bitvec_clear_req_flowid    )
    
        ,.valid_bitvector   (meta_active_bitvec                     )
    );
    
    // FIFO which has flowIDs of flows that have requests outstanding. This is an optimization; could just 
    // iterate over the active bitvec. Depends whether you expect the bitvec to be sparse
    
    logic                       msg_req_q_wr_req;
    logic   [FLOWID_W-1:0]    msg_req_q_wr_data;

    assign msg_req_q_wr_req = meta_ctrl_msg_req_q_wr_req_val | poll_ctrl_msg_req_q_wr_req_val;
    assign msg_req_q_wr_data = meta_ctrl_msg_req_q_wr_req_val
                            ? meta_data_msg_req_q_wr_req_data
                            : poll_data_msg_req_q_wr_data;

    assign msg_req_q_meta_ctrl_wr_req_rdy = 1'b1;
    assign msg_req_q_poll_ctrl_wr_req_rdy = ~meta_ctrl_msg_req_q_wr_req_val;

    fifo_1r1w #(
         .width_p       (FLOWID_W )
        ,.log2_els_p    ($clog2(MAX_FLOW_CNT))
    ) msg_req_q (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_req    (poll_ctrl_msg_req_q_rd_req_val )
        ,.rd_data   (msg_req_q_poll_data_rd_data    )
        ,.empty     (msg_req_q_poll_ctrl_empty      )
    
        ,.wr_req    (msg_req_q_wr_req               )
        ,.wr_data   (msg_req_q_wr_data              )
        ,.full      (/* this FIFO should have enough room to hold all possible flowIDs */)
    );
    
    // Mem which holds the message length requested. We do this here rather than storing in the FIFO
    // with the flowIDs so the message request could be updated

    ram_1r1w_sync_backpressure #(
         .width_p   (MSG_REQ_MEM_STRUCT_W   )
        ,.els_p     (MAX_FLOW_CNT           )
    ) msg_req_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (meta_ctrl_msg_req_mem_wr_val       )
        ,.wr_req_addr   (meta_data_msg_req_mem_wr_addr      )
        ,.wr_req_data   (meta_data_msg_req_mem_wr_data      )
        ,.wr_req_rdy    (msg_req_mem_meta_ctrl_wr_rdy       )
    
        ,.rd_req_val    (poll_ctrl_msg_req_mem_rd_req_val   )
        ,.rd_req_addr   (poll_data_msg_req_mem_rd_req_addr  )
        ,.rd_req_rdy    (msg_req_mem_poll_ctrl_rd_req_rdy   )
    
        ,.rd_resp_val   (msg_req_mem_poll_ctrl_rd_resp_val  )
        ,.rd_resp_data  (msg_req_mem_poll_data_rd_resp_data )
        ,.rd_resp_rdy   (poll_ctrl_msg_req_mem_rd_resp_rdy  )
    );

    tcp_msg_poller_meta #(
        .POLLER_PTR_W   (POLLER_PTR_W   )
    ) metadata_handler (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_poller_msg_req_val                    (src_poller_msg_req_val                 )
        ,.src_poller_msg_req_flowid                 (src_poller_msg_req_flowid              )
        ,.src_poller_msg_req_len                    (src_poller_msg_req_len                 )
        ,.src_poller_msg_dst_x                      (src_poller_msg_dst_x                   )
        ,.src_poller_msg_dst_y                      (src_poller_msg_dst_y                   )
        ,.src_poller_msg_dst_fbits                  (src_poller_msg_dst_fbits               )
        ,.poller_src_msg_req_rdy                    (poller_src_msg_req_rdy                 )
                                                                                            
        ,.meta_ctrl_msg_req_q_wr_req_val            (meta_ctrl_msg_req_q_wr_req_val         )
        ,.meta_data_msg_req_q_wr_req_data           (meta_data_msg_req_q_wr_req_data        )
        ,.msg_req_q_meta_ctrl_wr_req_rdy            (msg_req_q_meta_ctrl_wr_req_rdy         )
                                                                                            
        ,.meta_ctrl_active_bitvec_set_req_val       (meta_ctrl_active_bitvec_set_req_val    )
        ,.meta_data_active_bitvec_set_req_flowid    (meta_data_active_bitvec_set_req_flowid )
                                                                                            
        ,.meta_ctrl_msg_req_mem_wr_val              (meta_ctrl_msg_req_mem_wr_val           )
        ,.meta_data_msg_req_mem_wr_addr             (meta_data_msg_req_mem_wr_addr          )
        ,.meta_data_msg_req_mem_wr_data             (meta_data_msg_req_mem_wr_data          )
        ,.msg_req_mem_meta_ctrl_wr_rdy              (msg_req_mem_meta_ctrl_wr_rdy           )
                                                                                            
        ,.meta_active_bitvec                        (meta_active_bitvec                     )
    );

    tcp_msg_ptr_poller #(
         .CHK_SPACE_EMPTY   (CHK_SPACE_EMPTY)
        ,.POLLER_PTR_W      (POLLER_PTR_W   )
    ) ptr_poller (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.msg_req_q_poll_ctrl_empty             (msg_req_q_poll_ctrl_empty              )
        ,.msg_req_q_poll_data_rd_data           (msg_req_q_poll_data_rd_data            )
        ,.poll_ctrl_msg_req_q_rd_req_val        (poll_ctrl_msg_req_q_rd_req_val         )
                                                                                        
        ,.poll_ctrl_msg_req_q_wr_req_val        (poll_ctrl_msg_req_q_wr_req_val         )
        ,.poll_data_msg_req_q_wr_data           (poll_data_msg_req_q_wr_data            )
        ,.msg_req_q_poll_ctrl_wr_req_rdy        (msg_req_q_poll_ctrl_wr_req_rdy         )
                                                                                        
        ,.poll_ctrl_msg_req_mem_rd_req_val      (poll_ctrl_msg_req_mem_rd_req_val       )
        ,.poll_data_msg_req_mem_rd_req_addr     (poll_data_msg_req_mem_rd_req_addr      )
        ,.msg_req_mem_poll_ctrl_rd_req_rdy      (msg_req_mem_poll_ctrl_rd_req_rdy       )
                                                                                        
        ,.msg_req_mem_poll_ctrl_rd_resp_val     (msg_req_mem_poll_ctrl_rd_resp_val      )
        ,.msg_req_mem_poll_data_rd_resp_data    (msg_req_mem_poll_data_rd_resp_data     )
        ,.poll_ctrl_msg_req_mem_rd_resp_rdy     (poll_ctrl_msg_req_mem_rd_resp_rdy      )
                                                                                        
        ,.poll_active_bitvec_clear_req_val      (poll_active_bitvec_clear_req_val       )
        ,.poll_active_bitvec_clear_req_flowid   (poll_active_bitvec_clear_req_flowid    )
                                                                                        
        ,.poller_msg_dst_meta_val               (poller_msg_dst_meta_val                )
        ,.poller_msg_dst_flowid                 (poller_msg_dst_flowid                  )
        ,.poller_msg_dst_base_ptr               (poller_msg_dst_base_ptr                )
        ,.poller_msg_dst_len                    (poller_msg_dst_len                     )
        ,.poller_msg_dst_dst_x                  (poller_msg_dst_dst_x                   )
        ,.poller_msg_dst_dst_y                  (poller_msg_dst_dst_y                   )
        ,.poller_msg_dst_dst_fbits              (poller_msg_dst_dst_fbits               )
        ,.dst_poller_msg_meta_rdy               (dst_poller_msg_meta_rdy                )
                                                                                        
        ,.app_base_ptr_rd_req_val               (app_base_ptr_rd_req_val                )
        ,.app_base_ptr_rd_req_addr              (app_base_ptr_rd_req_addr               )
        ,.base_ptr_app_rd_req_rdy               (base_ptr_app_rd_req_rdy                )
                                                                                        
        ,.base_ptr_app_rd_resp_val              (base_ptr_app_rd_resp_val               )
        ,.base_ptr_app_rd_resp_data             (base_ptr_app_rd_resp_data              )
        ,.app_base_ptr_rd_resp_rdy              (app_base_ptr_rd_resp_rdy               )
                                                                                        
        ,.app_end_ptr_rd_req_val                (app_end_ptr_rd_req_val                 )
        ,.app_end_ptr_rd_req_addr               (app_end_ptr_rd_req_addr                )
        ,.end_ptr_app_rd_req_rdy                (end_ptr_app_rd_req_rdy                 )
        
        ,.end_ptr_app_rd_resp_val               (end_ptr_app_rd_resp_val                )
        ,.end_ptr_app_rd_resp_data              (end_ptr_app_rd_resp_data               )
        ,.app_end_ptr_rd_resp_rdy               (app_end_ptr_rd_resp_rdy                )
    );
endmodule
