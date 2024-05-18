module tracker_top 
    import tracker_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter TRACKER_DEPTH_LOG2 = -1
    ,parameter DATA_NOC_W=-1
    ,parameter REQ_NOC_W=-1
    ,parameter RESP_NOC_W=-1
)(
     input clk
    ,input rst
    
    ,input                                      ctovr_rd_tracker_in_val
    ,input          [REQ_NOC_W-1:0]             ctovr_rd_tracker_in_data
    ,output logic                               rd_tracker_in_ctovr_rdy
    
    ,output logic                               rd_tracker_out_vrtoc_val
    ,output logic   [RESP_NOC_W-1:0]            rd_tracker_out_vrtoc_data
    ,input                                      vrtoc_rd_tracker_out_rdy

    ,input  logic                               noc_wr_tracker_in_val
    ,input  logic   [DATA_NOC_W-1:0]            noc_wr_tracker_in_data
    ,output logic                               wr_tracker_noc_in_rdy
    
    ,output logic                               wr_tracker_noc_out_val
    ,output logic   [DATA_NOC_W-1:0]            wr_tracker_noc_out_data
    ,input                                      noc_wr_tracker_out_rdy
);
    localparam ADDR_W = TRACKER_DEPTH_LOG2;
    logic                               datap_ctrl_filter_val;
    logic                               datap_ctrl_filter_record;
    logic                               ctrl_datap_filter_rdy;

    logic                               datap_ctrl_last_flit;
    
    logic                               ctrl_datap_store_hdr;
    logic                               ctrl_datap_incr_flits;

    logic                               log_wr_req_val;
    tracker_stats_struct                log_wr_req_data;
    
    logic                               log_rd_req_val;
    logic   [ADDR_W-1:0]                log_rd_req_addr;
    
    logic                               log_rd_resp_val;
    tracker_stats_struct                log_rd_resp_data;

    logic   [ADDR_W-1:0]                curr_wr_addr;
    logic                               has_wrapped;

    tracker_record_ctrl record_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.noc_wr_tracker_in_val     (noc_wr_tracker_in_val      )
        ,.wr_tracker_noc_in_rdy     (wr_tracker_noc_in_rdy      )
                                                                
        ,.wr_tracker_noc_out_val    (wr_tracker_noc_out_val     )
        ,.noc_wr_tracker_out_rdy    (noc_wr_tracker_out_rdy     )
                                                                
        ,.datap_ctrl_filter_val     (datap_ctrl_filter_val      )
        ,.datap_ctrl_filter_record  (datap_ctrl_filter_record   )
        ,.ctrl_datap_filter_rdy     (ctrl_datap_filter_rdy      )
    
        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_incr_flits     (ctrl_datap_incr_flits      )
                                                                
        ,.datap_ctrl_last_flit      (datap_ctrl_last_flit       )
                                                                
        ,.log_wr_req_val            (log_wr_req_val             )
    );

    tracker_record_datap #(
        .DATA_NOC_W (DATA_NOC_W )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_wr_tracker_in_data    (noc_wr_tracker_in_data     )
                                                                
        ,.wr_tracker_noc_out_data   (wr_tracker_noc_out_data    )
                                                                
        ,.datap_ctrl_filter_val     (datap_ctrl_filter_val      )
        ,.datap_ctrl_filter_record  (datap_ctrl_filter_record   )
        ,.ctrl_datap_filter_rdy     (ctrl_datap_filter_rdy      )
                                                                
        ,.datap_ctrl_last_flit      (datap_ctrl_last_flit       )
                                                                
        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_incr_flits     (ctrl_datap_incr_flits      )
                                                                
        ,.log_wr_req_data           (log_wr_req_data            )
    );

    simple_log #(
         .LOG_DATA_W        (TRACKER_STATS_W    )
        ,.MEM_DEPTH_LOG2    (TRACKER_DEPTH_LOG2 )
    ) logger (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val        (log_wr_req_val     )
        ,.wr_req_data       (log_wr_req_data    )
    
        ,.rd_req_val        (log_rd_req_val     )
        ,.rd_req_addr       (log_rd_req_addr    )
    
        ,.rd_resp_val       (log_rd_resp_val    )
        ,.rd_resp_data      (log_rd_resp_data   )
    
        ,.curr_wr_addr      (curr_wr_addr       )
        ,.log_has_wrapped   (has_wrapped        )
    );

    tracker_read #(
         .SRC_X                 (SRC_X              )
        ,.SRC_Y                 (SRC_Y              )
        ,.RESP_DATA_STRUCT_W    (TRACKER_STATS_W    )
        ,.REQ_NOC_W             (REQ_NOC_W          )
        ,.RESP_NOC_W            (RESP_NOC_W         )
        ,.ADDR_W                (TRACKER_DEPTH_LOG2 )
    ) read (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_reader_in_val     (ctovr_rd_tracker_in_val    )
        ,.noc_reader_in_data    (ctovr_rd_tracker_in_data   )
        ,.reader_in_noc_rdy     (rd_tracker_in_ctovr_rdy    )
        
        ,.reader_out_noc_val    (rd_tracker_out_vrtoc_val   )
        ,.reader_out_noc_data   (rd_tracker_out_vrtoc_data  )
        ,.noc_reader_out_rdy    (vrtoc_rd_tracker_out_rdy   )
    
        ,.log_rd_req_val        (log_rd_req_val             )
        ,.log_rd_req_addr       (log_rd_req_addr            )
                                                            
        ,.log_rd_resp_val       (log_rd_resp_val            )
        ,.log_rd_resp_data      (log_rd_resp_data           )
                                                            
        ,.curr_wr_addr          (curr_wr_addr               )
        ,.has_wrapped           (has_wrapped                )
    );
endmodule
