module udp_echo_app_stats_read (
     input clk
    ,input rst

    ,input                                  noc0_ctovr_udp_stats_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_stats_in_data
    ,output logic                           udp_stats_in_noc0_ctovr_rdy
    
    ,output logic                           udp_stats_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_stats_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_udp_stats_out_rdy

    ,output logic                           log_rd_req_val
    ,output logic   [STATS_DEPTH_LOG2-1:0]  log_rd_req_addr

    ,input  logic                           log_rd_resp_val
    ,input          udp_app_stats_struct    log_rd_resp_data

    ,input  logic   [STATS_DEPTH_LOG2-1:0]  curr_wr_addr
    ,input  logic                           has_wrapped
);
    logic               ctrl_datap_store_hdr;
    logic               ctrl_datap_store_meta;
    logic               ctrl_datap_store_req;
    logic               ctrl_datap_store_log_resp;
    udp_log_resp_sel_e  ctrl_datap_output_flit_sel;

    logic               datap_ctrl_rd_meta;

    udp_echo_app_stats_read_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_ctovr_udp_stats_in_val   (noc0_ctovr_udp_stats_in_val    )
        ,.udp_stats_in_noc0_ctovr_rdy   (udp_stats_in_noc0_ctovr_rdy    )
                                                                        
        ,.udp_stats_out_noc0_vrtoc_val  (udp_stats_out_noc0_vrtoc_val   )
        ,.noc0_vrtoc_udp_stats_out_rdy  (noc0_vrtoc_udp_stats_out_rdy   )
                                                                        
        ,.log_rd_req_val                (log_rd_req_val                 )
                                                                        
        ,.log_rd_resp_val               (log_rd_resp_val                )
                                                                        
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req           )
        ,.ctrl_datap_store_log_resp     (ctrl_datap_store_log_resp      )
        ,.ctrl_datap_output_flit_sel    (ctrl_datap_output_flit_sel     )
                                                                        
        ,.datap_ctrl_rd_meta            (datap_ctrl_rd_meta             )
    );

    udp_echo_app_stats_read_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_stats_in_data  (noc0_ctovr_udp_stats_in_data   )
                                                                        
        ,.udp_stats_out_noc0_vrtoc_data (udp_stats_out_noc0_vrtoc_data  )
                                                                        
        ,.log_rd_req_addr               (log_rd_req_addr                )
                                                                        
        ,.log_rd_resp_data              (log_rd_resp_data               )
                                                                        
        ,.curr_wr_addr                  (curr_wr_addr                   )
        ,.has_wrapped                   (has_wrapped                    )
                                                                        
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req           )
        ,.ctrl_datap_store_log_resp     (ctrl_datap_store_log_resp      )
        ,.ctrl_datap_output_flit_sel    (ctrl_datap_output_flit_sel     )
                                                                        
        ,.datap_ctrl_rd_meta            (datap_ctrl_rd_meta             )
    );


endmodule
