`include "tcp_msg_poller_defs.svh"
module tcp_msg_ptr_poller #(
     parameter CHK_SPACE_EMPTY = 0
    ,parameter POLLER_PTR_W = 0
)(
     input clk
    ,input rst

    ,input                                  msg_req_q_poll_ctrl_empty
    ,input          [FLOWID_W-1:0]          msg_req_q_poll_data_rd_data
    ,output logic                           poll_ctrl_msg_req_q_rd_req_val

    ,output logic                           poll_ctrl_msg_req_q_wr_req_val
    ,output logic   [FLOWID_W-1:0]          poll_data_msg_req_q_wr_data
    ,input                                  msg_req_q_poll_ctrl_wr_req_rdy

    ,output logic                           poll_ctrl_msg_req_mem_rd_req_val
    ,output logic   [FLOWID_W-1:0]          poll_data_msg_req_mem_rd_req_addr
    ,input                                  msg_req_mem_poll_ctrl_rd_req_rdy

    ,input                                  msg_req_mem_poll_ctrl_rd_resp_val
    ,input          msg_req_mem_struct      msg_req_mem_poll_data_rd_resp_data
    ,output logic                           poll_ctrl_msg_req_mem_rd_resp_rdy

    ,output logic                           poll_active_bitvec_clear_req_val
    ,output logic   [FLOWID_W-1:0]          poll_active_bitvec_clear_req_flowid
    
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
    
    logic                           data_ctrl_msg_satis;
    logic                           ctrl_data_store_req_data;
    logic                           ctrl_data_store_ptrs;
    logic                           ctrl_data_store_flowid;

    tcp_msg_ptr_poller_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.msg_req_q_poll_ctrl_empty         (msg_req_q_poll_ctrl_empty          )
        ,.poll_ctrl_msg_req_q_rd_req_val    (poll_ctrl_msg_req_q_rd_req_val     )
                                                                                
        ,.poll_ctrl_msg_req_q_wr_req_val    (poll_ctrl_msg_req_q_wr_req_val     )
        ,.msg_req_q_poll_ctrl_wr_req_rdy    (msg_req_q_poll_ctrl_wr_req_rdy     )
                                                                                
        ,.poll_ctrl_msg_req_mem_rd_req_val  (poll_ctrl_msg_req_mem_rd_req_val   )
        ,.msg_req_mem_poll_ctrl_rd_req_rdy  (msg_req_mem_poll_ctrl_rd_req_rdy   )
                                                                                
        ,.msg_req_mem_poll_ctrl_rd_resp_val (msg_req_mem_poll_ctrl_rd_resp_val  )
        ,.poll_ctrl_msg_req_mem_rd_resp_rdy (poll_ctrl_msg_req_mem_rd_resp_rdy  )
                                                                                
        ,.poller_msg_dst_meta_val           (poller_msg_dst_meta_val            )
        ,.dst_poller_msg_meta_rdy           (dst_poller_msg_meta_rdy            )
                                                                                
        ,.app_base_ptr_rd_req_val           (app_base_ptr_rd_req_val            )
        ,.base_ptr_app_rd_req_rdy           (base_ptr_app_rd_req_rdy            )
                                                                                
        ,.base_ptr_app_rd_resp_val          (base_ptr_app_rd_resp_val           )
        ,.app_base_ptr_rd_resp_rdy          (app_base_ptr_rd_resp_rdy           )
                                                                                
        ,.app_end_ptr_rd_req_val            (app_end_ptr_rd_req_val             )
        ,.end_ptr_app_rd_req_rdy            (end_ptr_app_rd_req_rdy             )
                                                                                    
        ,.end_ptr_app_rd_resp_val           (end_ptr_app_rd_resp_val            )
        ,.app_end_ptr_rd_resp_rdy           (app_end_ptr_rd_resp_rdy            )
                                                                                
        ,.poll_active_bitvec_clear_req_val  (poll_active_bitvec_clear_req_val   )
                                                                                
        ,.data_ctrl_msg_satis               (data_ctrl_msg_satis                )
        ,.ctrl_data_store_req_data          (ctrl_data_store_req_data           )
        ,.ctrl_data_store_ptrs              (ctrl_data_store_ptrs               )
        ,.ctrl_data_store_flowid            (ctrl_data_store_flowid             )
    );

    tcp_msg_ptr_poller_datap #(
         .CHK_SPACE_EMPTY   (CHK_SPACE_EMPTY)
        ,.POLLER_PTR_W      (POLLER_PTR_W   )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.msg_req_q_poll_data_rd_data           (msg_req_q_poll_data_rd_data            )
                                                                                        
        ,.poll_data_msg_req_q_wr_data           (poll_data_msg_req_q_wr_data            )
                                                                                        
        ,.poll_data_msg_req_mem_rd_req_addr     (poll_data_msg_req_mem_rd_req_addr      )
                                                                                        
        ,.msg_req_mem_poll_data_rd_resp_data    (msg_req_mem_poll_data_rd_resp_data     )
                                                                                        
        ,.poller_msg_dst_flowid                 (poller_msg_dst_flowid                  )
        ,.poller_msg_dst_base_ptr               (poller_msg_dst_base_ptr                )
        ,.poller_msg_dst_len                    (poller_msg_dst_len                     )
        ,.poller_msg_dst_dst_x                  (poller_msg_dst_dst_x                   )
        ,.poller_msg_dst_dst_y                  (poller_msg_dst_dst_y                   )
        ,.poller_msg_dst_dst_fbits              (poller_msg_dst_dst_fbits               )
                                                                                        
        ,.app_base_ptr_rd_req_addr              (app_base_ptr_rd_req_addr               )
                                                                                        
        ,.base_ptr_app_rd_resp_data             (base_ptr_app_rd_resp_data              )
                                                                                        
        ,.app_end_ptr_rd_req_addr               (app_end_ptr_rd_req_addr                )
                                                                                        
        ,.end_ptr_app_rd_resp_data              (end_ptr_app_rd_resp_data               )
                                                                                        
        ,.poll_active_bitvec_clear_req_flowid   (poll_active_bitvec_clear_req_flowid    )
                                                                                        
        ,.data_ctrl_msg_satis                   (data_ctrl_msg_satis                    )
        ,.ctrl_data_store_req_data              (ctrl_data_store_req_data               )
        ,.ctrl_data_store_ptrs                  (ctrl_data_store_ptrs                   )
        ,.ctrl_data_store_flowid                (ctrl_data_store_flowid                 )
    );
endmodule
