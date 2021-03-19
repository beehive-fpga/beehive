`include "tcp_logger_read_defs.svh"
module tcp_logger_read_top #(
     parameter LOG_ENTRIES_LOG_2 = -1
    ,parameter LOG_ADDR_W = LOG_ENTRIES_LOG_2 
    ,parameter LOG_CLIENT_ADDR_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input  logic                           noc_logger_read_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_logger_read_data
    ,output logic                           logger_read_noc_rdy

    ,output logic                           logger_read_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   logger_read_noc_data
    ,input  logic                           noc_logger_read_rdy
    
    ,output logic                           rd_req_logger_mem_val
    ,output logic   [LOG_ADDR_W-1:0]        rd_req_logger_mem_addr
    ,input  logic                           rd_req_logger_mem_rdy

    ,input  logic                           rd_resp_logger_mem_val
    ,input  log_entry_struct                rd_resp_logger_mem_entry
    ,output logic                           rd_resp_logger_mem_rdy

    ,input          [LOG_ADDR_W:0]          recorder_read_curr_addr
);
    
    logic                           ctrl_datap_store_meta_flit;
    logic                           ctrl_datap_store_log_req;
    logic                           ctrl_datap_store_log_resp;
    logger_mux_out_sel              ctrl_datap_mux_out_sel;
    logger_data_mux_sel             ctrl_datap_data_mux_sel;
    logic                           datap_ctrl_read_metadata;

    tcp_logger_read_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.noc_logger_read_val           (noc_logger_read_val        )
        ,.logger_read_noc_rdy           (logger_read_noc_rdy        )

        ,.logger_read_noc_val           (logger_read_noc_val        )
        ,.noc_logger_read_rdy           (noc_logger_read_rdy        )

        ,.rd_req_logger_mem_val         (rd_req_logger_mem_val      )
        ,.rd_req_logger_mem_rdy         (rd_req_logger_mem_rdy      )

        ,.rd_resp_logger_mem_val        (rd_resp_logger_mem_val     )
        ,.rd_resp_logger_mem_rdy        (rd_resp_logger_mem_rdy     )

        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit )
        ,.ctrl_datap_store_log_req      (ctrl_datap_store_log_req   )
        ,.ctrl_datap_store_log_resp     (ctrl_datap_store_log_resp  )
        ,.ctrl_datap_mux_out_sel        (ctrl_datap_mux_out_sel     )
        ,.ctrl_datap_data_mux_sel       (ctrl_datap_data_mux_sel    )

        ,.datap_ctrl_read_metadata      (datap_ctrl_read_metadata   )
    );

    tcp_logger_read_datap #(
         .SRC_X             (SRC_X              )
        ,.SRC_Y             (SRC_Y              )
        ,.LOG_ADDR_W        (LOG_ADDR_W         )
        ,.LOG_CLIENT_ADDR_W (LOG_CLIENT_ADDR_W  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc_logger_read_data          (noc_logger_read_data      )

        ,.logger_read_noc_data          (logger_read_noc_data      )

        ,.rd_req_logger_mem_addr        (rd_req_logger_mem_addr     )

        ,.rd_resp_logger_mem_entry      (rd_resp_logger_mem_entry   )

        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit )
        ,.ctrl_datap_store_log_req      (ctrl_datap_store_log_req   )
        ,.ctrl_datap_store_log_resp     (ctrl_datap_store_log_resp  )
        ,.ctrl_datap_mux_out_sel        (ctrl_datap_mux_out_sel     )
        ,.ctrl_datap_data_mux_sel       (ctrl_datap_data_mux_sel    )

        ,.datap_ctrl_read_metadata      (datap_ctrl_read_metadata   )

        ,.recorder_read_curr_addr       (recorder_read_curr_addr    )
    );
endmodule
