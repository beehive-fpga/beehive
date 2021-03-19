`include "tcp_logger_record_defs.svh"
module tcp_logger_record_top #(
     parameter LOG_ENTRIES_LOG_2 = -1
    ,parameter LOG_ADDR_W = LOG_ENTRIES_LOG_2 
    ,parameter FORWARD_X = -1
    ,parameter FORWARD_Y = -1
)(
     input clk
    ,input rst

    ,input  logic                           noc0_logger_record_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_logger_record_data
    ,output logic                           logger_record_noc0_rdy
    
    ,output logic                           logger_record_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   logger_record_noc0_data
    ,input  logic                           noc0_logger_record_rdy

    ,output logic                           wr_logger_mem_val
    ,output logic   [LOG_ADDR_W-1:0]        wr_logger_mem_addr
    ,output log_entry_struct                wr_logger_mem_entry
    ,input  logic                           wr_logger_mem_rdy 

    ,output logic   [LOG_ADDR_W:0]          recorder_read_curr_addr
);
    logic                           ctrl_datap_store_len;
    logic                           ctrl_datap_incr_addr;
    logic                           ctrl_datap_incr_num_flits;
    logic                           ctrl_datap_store_hdr;
    logic                           ctrl_datap_mod_hdr_flit;

    logic                           datap_ctrl_last_flit;
    logic                           datap_ctrl_log_full;

    tcp_logger_record_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_logger_record_val    (noc0_logger_record_val     )
        ,.logger_record_noc0_rdy    (logger_record_noc0_rdy     )
                                                         
        ,.logger_record_noc0_val    (logger_record_noc0_val     )
        ,.noc0_logger_record_rdy    (noc0_logger_record_rdy     )
                                                                
        ,.wr_logger_mem_val         (wr_logger_mem_val          )
        ,.wr_logger_mem_rdy         (wr_logger_mem_rdy          )
                                                                
        ,.ctrl_datap_store_len      (ctrl_datap_store_len       )
        ,.ctrl_datap_incr_addr      (ctrl_datap_incr_addr       )
        ,.ctrl_datap_incr_num_flits (ctrl_datap_incr_num_flits  )
        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_mod_hdr_flit   (ctrl_datap_mod_hdr_flit    )

        ,.datap_ctrl_last_flit      (datap_ctrl_last_flit       )
        ,.datap_ctrl_log_full       (datap_ctrl_log_full        )
    );

    tcp_logger_record_datap #(
         .LOG_ENTRIES_LOG_2 (LOG_ENTRIES_LOG_2  )
        ,.FORWARD_X         (FORWARD_X          )
        ,.FORWARD_Y         (FORWARD_Y          )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_logger_record_data   (noc0_logger_record_data    )
                                                         
        ,.logger_record_noc0_data   (logger_record_noc0_data    )
                                                                
        ,.wr_logger_mem_addr        (wr_logger_mem_addr         )
        ,.wr_logger_mem_entry       (wr_logger_mem_entry        )
                                                                
        ,.ctrl_datap_store_len      (ctrl_datap_store_len       )
        ,.ctrl_datap_incr_addr      (ctrl_datap_incr_addr       )
        ,.ctrl_datap_incr_num_flits (ctrl_datap_incr_num_flits  )
        ,.ctrl_datap_store_hdr      (ctrl_datap_store_hdr       )
        ,.ctrl_datap_mod_hdr_flit   (ctrl_datap_mod_hdr_flit    )
                                                                
        ,.datap_ctrl_last_flit      (datap_ctrl_last_flit       )
        ,.datap_ctrl_log_full       (datap_ctrl_log_full        )

        ,.recorder_read_curr_addr   (recorder_read_curr_addr    )
    );
endmodule
