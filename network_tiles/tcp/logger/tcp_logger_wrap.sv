`include "tcp_logger_record_defs.svh"
`include "tcp_logger_read_defs.svh"
module tcp_logger_wrap #(
     parameter LOG_ENTRIES_LOG_2 = -1
    ,parameter LOG_ADDR_W = LOG_ENTRIES_LOG_2 
    ,parameter LOG_CLIENT_ADDR_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter FORWARD_X = -1
    ,parameter FORWARD_Y = -1
    ,parameter NOC1_DATA_W = -1
    ,parameter NOC2_DATA_W = -1
)(
     input clk
    ,input rst

    ,input  logic                           noc0_logger_record_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_logger_record_data
    ,output logic                           logger_record_noc0_rdy
    
    ,output logic                           logger_record_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   logger_record_noc0_data
    ,input  logic                           noc0_logger_record_rdy
    
    ,input  logic                           noc_logger_read_val
    ,input  logic   [NOC1_DATA_W-1:0]       noc_logger_read_data
    ,output logic                           logger_read_noc_rdy

    ,output logic                           logger_read_noc_val
    ,output logic   [NOC2_DATA_W-1:0]       logger_read_noc_data
    ,input  logic                           noc_logger_read_rdy
);
    
    logic                           wr_logger_mem_val;
    logic   [LOG_ADDR_W-1:0]        wr_logger_mem_addr;
    log_entry_struct                wr_logger_mem_entry;
    logic                           wr_logger_mem_rdy;
    
    logic   [LOG_ADDR_W:0]          recorder_read_curr_addr;
    
    logic                           rd_req_logger_mem_val;
    logic   [LOG_ADDR_W-1:0]        rd_req_logger_mem_addr;
    logic                           rd_req_logger_mem_rdy;

    logic                           rd_resp_logger_mem_val;
    log_entry_struct                rd_resp_logger_mem_entry;
    logic                           rd_resp_logger_mem_rdy;
    
    logic                           noc_ctd_logger_read_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc_ctd_logger_read_data;
    logic                           logger_read_noc_ctd_rdy;
    
    logic                           logger_read_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   logger_read_noc_dtc_data;
    logic                           noc_dtc_logger_read_rdy;

    tcp_logger_record_top #(
         .LOG_ENTRIES_LOG_2 (LOG_ENTRIES_LOG_2  )
        ,.FORWARD_X         (FORWARD_X          )
        ,.FORWARD_Y         (FORWARD_Y          )
    ) logger_record (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_logger_record_val    (noc0_logger_record_val     )
        ,.noc0_logger_record_data   (noc0_logger_record_data    )
        ,.logger_record_noc0_rdy    (logger_record_noc0_rdy     )
                                                                
        ,.logger_record_noc0_val    (logger_record_noc0_val     )
        ,.logger_record_noc0_data   (logger_record_noc0_data    )
        ,.noc0_logger_record_rdy    (noc0_logger_record_rdy     )
                                                                
        ,.wr_logger_mem_val         (wr_logger_mem_val          )
        ,.wr_logger_mem_addr        (wr_logger_mem_addr         )
        ,.wr_logger_mem_entry       (wr_logger_mem_entry        )
        ,.wr_logger_mem_rdy         (wr_logger_mem_rdy          )
                                                                
        ,.recorder_read_curr_addr   (recorder_read_curr_addr    )
    );

generate
    if (`NOC_DATA_WIDTH != NOC1_DATA_W) begin
        noc_ctrl_to_data ctd (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_noc_ctd_val   (noc_logger_read_val        )
            ,.src_noc_ctd_data  (noc_logger_read_data       )
            ,.noc_ctd_src_rdy   (logger_read_noc_rdy        )
        
            ,.noc_ctd_dst_val   (noc_ctd_logger_read_val    )
            ,.noc_ctd_dst_data  (noc_ctd_logger_read_data   )
            ,.dst_noc_ctd_rdy   (logger_read_noc_ctd_rdy    )
        );
    end
    else begin
        assign noc_ctd_logger_read_val = noc_logger_read_val;
        assign noc_ctd_logger_read_data = noc_logger_read_data;
        assign logger_read_noc_rdy = logger_read_noc_ctd_rdy;
    end
endgenerate


    tcp_logger_read_top #(
         .LOG_ENTRIES_LOG_2 (LOG_ENTRIES_LOG_2  )
        ,.LOG_CLIENT_ADDR_W (LOG_CLIENT_ADDR_W  )
        ,.SRC_X             (SRC_X              )
        ,.SRC_Y             (SRC_Y              )
    ) logger_read (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc_logger_read_val       (noc_ctd_logger_read_val    )
        ,.noc_logger_read_data      (noc_ctd_logger_read_data   )
        ,.logger_read_noc_rdy       (logger_read_noc_ctd_rdy    )
                                                                 
        ,.logger_read_noc_val       (logger_read_noc_dtc_val    )
        ,.logger_read_noc_data      (logger_read_noc_dtc_data   )
        ,.noc_logger_read_rdy       (noc_dtc_logger_read_rdy    )
                                                                
        ,.rd_req_logger_mem_val     (rd_req_logger_mem_val      )
        ,.rd_req_logger_mem_addr    (rd_req_logger_mem_addr     )
        ,.rd_req_logger_mem_rdy     (rd_req_logger_mem_rdy      )
                                                                
        ,.rd_resp_logger_mem_val    (rd_resp_logger_mem_val     )
        ,.rd_resp_logger_mem_entry  (rd_resp_logger_mem_entry   )
        ,.rd_resp_logger_mem_rdy    (rd_resp_logger_mem_rdy     )
                                                                
        ,.recorder_read_curr_addr   (recorder_read_curr_addr    )
    );

generate
    if (`NOC_DATA_WIDTH != NOC2_DATA_W) begin
        noc_data_to_ctrl dtc (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_noc_dtc_val   (logger_read_noc_dtc_val    )
            ,.src_noc_dtc_data  (logger_read_noc_dtc_data   )
            ,.noc_dtc_src_rdy   (noc_dtc_logger_read_rdy    )
        
            ,.noc_dtc_dst_val   (logger_read_noc_val        )
            ,.noc_dtc_dst_data  (logger_read_noc_data       )
            ,.dst_noc_dtc_rdy   (noc_logger_read_rdy        )
        );
    end
    else begin
        assign logger_read_noc_val = logger_read_noc_dtc_val;
        assign logger_read_noc_data = logger_read_noc_dtc_data;
        assign noc_dtc_logger_read_rdy = noc_logger_read_rdy;
    end
endgenerate

    ram_1r1w_sync_backpressure #(
         .width_p   (LOG_ENTRY_STRUCT_W     )
        ,.els_p     (2 ** LOG_ENTRIES_LOG_2 )
    ) log_ram (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (wr_logger_mem_val          )
        ,.wr_req_addr   (wr_logger_mem_addr         )
        ,.wr_req_data   (wr_logger_mem_entry        )
        ,.wr_req_rdy    (wr_logger_mem_rdy          )
    
        ,.rd_req_val    (rd_req_logger_mem_val      )
        ,.rd_req_addr   (rd_req_logger_mem_addr     )
        ,.rd_req_rdy    (rd_req_logger_mem_rdy      )
    
        ,.rd_resp_val   (rd_resp_logger_mem_val     )
        ,.rd_resp_data  (rd_resp_logger_mem_entry   )
        ,.rd_resp_rdy   (rd_resp_logger_mem_rdy     )
    );

endmodule
