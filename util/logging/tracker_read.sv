module tracker_read 
    import beehive_noc_msg::*;
    import tracker_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter REQ_NOC_W = -1
    ,parameter RESP_NOC_W = -1
    ,parameter ADDR_W = -1
)(
     input clk
    ,input rst
    
    ,input                                      noc_reader_in_val
    ,input          [REQ_NOC_W-1:0]             noc_reader_in_data
    ,output logic                               reader_in_noc_rdy
    
    ,output logic                               reader_out_noc_val
    ,output logic   [RESP_NOC_W-1:0]            reader_out_noc_data
    ,input                                      noc_reader_out_rdy

    ,output logic                               log_rd_req_val
    ,output logic   [ADDR_W-1:0]                log_rd_req_addr
    
    ,input  logic                               log_rd_resp_val
    ,input  logic   [RESP_DATA_STRUCT_W-1:0]    log_rd_resp_data

    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped
);
    localparam FLITS_PER_LINE = RESP_DATA_STRUCT_W % RESP_NOC_W == 0
                            ? RESP_DATA_STRUCT_W/RESP_NOC_W
                            : (RESP_DATA_STRUCT_W/RESP_NOC_W) + 1'b1;

    logic                               ctrl_datap_incr_rd_addr;
    logic                               ctrl_datap_store_req;
    logic                               ctrl_datap_store_flit_2;
    flit_sel_e                          ctrl_datap_output_flit_sel;

    tracker_req_type                    datap_ctrl_req_type;
    logic                               datap_ctrl_last_entry;

    logic                               width_fix_out_ctrl_val;
    logic   [RESP_NOC_W-1:0]            width_fix_out_datap_data;
    logic                               width_fix_out_ctrl_last;
    logic                               width_fix_in_ctrl_rdy;
    logic                               width_fix_in_ctrl_last;
    
    tracker_read_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_reader_in_val             (noc_reader_in_val          )
        ,.reader_in_noc_rdy             (reader_in_noc_rdy          )
                                                                    
        ,.reader_out_noc_val            (reader_out_noc_val         )
        ,.noc_reader_out_rdy            (noc_reader_out_rdy         )
                                                                    
        ,.log_rd_req_val                (log_rd_req_val             )
                                                                    
        ,.log_rd_resp_val               (log_rd_resp_val            )
                                                                    
        ,.ctrl_datap_incr_rd_addr       (ctrl_datap_incr_rd_addr    )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req       )
        ,.ctrl_datap_store_flit_2       (ctrl_datap_store_flit_2    )
        ,.ctrl_datap_output_flit_sel    (ctrl_datap_output_flit_sel )
                                                                    
        ,.datap_ctrl_req_type           (datap_ctrl_req_type        )
        ,.datap_ctrl_last_entry         (datap_ctrl_last_entry      )
                                                                    
        ,.width_fix_out_ctrl_val        (width_fix_out_ctrl_val     )
        ,.width_fix_in_ctrl_rdy         (width_fix_in_ctrl_rdy      )
        ,.width_fix_out_ctrl_last       (width_fix_out_ctrl_last    )
        ,.width_fix_in_ctrl_last        (width_fix_in_ctrl_last     )
    );

    tracker_read_datap #(
         .SRC_X                 (SRC_X              )
        ,.SRC_Y                 (SRC_Y              )
        ,.ADDR_W                (ADDR_W             )
        ,.RESP_DATA_STRUCT_W    (RESP_DATA_STRUCT_W )
        ,.REQ_NOC_W             (REQ_NOC_W          )
        ,.RESP_NOC_W            (RESP_NOC_W         )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
         
        ,.noc_reader_in_data            (noc_reader_in_data         )
                                                                    
        ,.reader_out_noc_data           (reader_out_noc_data        )
                                                                    
        ,.log_rd_req_addr               (log_rd_req_addr            )
                                                                    
        ,.width_fix_datap_data          (width_fix_out_datap_data   )
                                                                    
        ,.curr_wr_addr                  (curr_wr_addr               )
        ,.has_wrapped                   (has_wrapped                )
                                                                    
        ,.ctrl_datap_incr_rd_addr       (ctrl_datap_incr_rd_addr    )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req       )
        ,.ctrl_datap_store_flit_2       (ctrl_datap_store_flit_2    )
        ,.ctrl_datap_output_flit_sel    (ctrl_datap_output_flit_sel )
                                                                    
        ,.datap_ctrl_req_type           (datap_ctrl_req_type        )
        ,.datap_ctrl_last_entry         (datap_ctrl_last_entry      )
    );

    wide_to_narrow #(
         .OUT_DATA_W    (RESP_NOC_W     )
        ,.IN_DATA_ELS   (FLITS_PER_LINE )
    ) wtn (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_w_to_n_val    (log_rd_resp_val            )
        ,.src_w_to_n_data   (log_rd_resp_data           )
        ,.src_w_to_n_keep   ('1)
        ,.src_w_to_n_last   (width_fix_in_ctrl_last     )
        ,.w_to_n_src_rdy    (width_fix_in_ctrl_rdy      )
    
        ,.w_to_n_dst_val    (width_fix_out_ctrl_val     )
        ,.w_to_n_dst_data   (width_fix_out_datap_data   )
        ,.w_to_n_dst_keep   ()
        ,.w_to_n_dst_last   (width_fix_out_ctrl_last    )
        ,.dst_w_to_n_rdy    (noc_reader_out_rdy         )
    );
endmodule
