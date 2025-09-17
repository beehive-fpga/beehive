`include "noc_defs.vh"
`include "soc_defs.vh"
module rd_circ_buf_new 
import tcp_pkg::*;
import mem_msg_pkg::*;
#(
     parameter BUF_PTR_W=-1
    ,parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
    ,parameter MONITOR_DATA_W = -1
)(
     input clk
    ,input rst
    
    ,output logic                                   rd_buf_monitor_val
    ,output logic   [MONITOR_DATA_W-1:0]            rd_buf_monitor_data
    ,input                                          monitor_rd_buf_rdy
   
    ,input                                          monitor_rd_buf_val
    ,input          [MONITOR_DATA_W-1:0]            monitor_rd_buf_data
    ,output logic                                   rd_buf_monitor_rdy

    ,input                                          src_rd_buf_req_val
    ,input  vaddr_t                                 src_rd_buf_req_base_addr
    ,input          [BUF_PTR_W-1:0]                 src_rd_buf_req_offset
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]      src_rd_buf_req_size
    ,output logic                                   rd_buf_src_req_rdy

    ,output logic                                   rd_buf_src_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]          rd_buf_src_data
    ,output logic                                   rd_buf_src_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]           rd_buf_src_data_padbytes
    ,input                                          src_rd_buf_data_rdy
);
    logic                                   ctrl_rd_noc_req_val;
    logic                                   rd_noc_ctrl_req_rdy;
    mem_req_struct                          datap_rd_noc_req;

    logic                                   rd_noc_ctrl_resp_data_val;
    logic                                   rd_noc_ctrl_resp_data_last;
    logic                                   ctrl_rd_noc_resp_data_rdy;
    logic   [`MAC_INTERFACE_W-1:0]          rd_noc_datap_resp_data;
    logic   [`MAC_PADBYTES_W-1:0]           rd_noc_datap_resp_data_padbytes;

    logic                                   ctrl_datap_store_req_state;
    logic                                   ctrl_datap_update_req_state;
    logic                                   ctrl_datap_save_req;
    logic                                   ctrl_datap_decr_bytes_out_reg;
    logic                                   ctrl_datap_store_shift;
    logic                                   ctrl_datap_write_upper;
    logic                                   ctrl_datap_shift_regs;
    logic                                   ctrl_datap_write_lower;
    logic                                   ctrl_datap_use_shift;
    logic                                   ctrl_datap_lower_zeros;

    logic                                   datap_ctrl_split_req;
    logic                                   datap_ctrl_last_data_out;

    rd_circ_buf_ctrl_new ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_rd_buf_req_val            (src_rd_buf_req_val             )
        ,.rd_buf_src_req_rdy            (rd_buf_src_req_rdy             )
                                                                        
        ,.ctrl_rd_noc_req_val           (ctrl_rd_noc_req_val            )
        ,.rd_noc_ctrl_req_rdy           (rd_noc_ctrl_req_rdy            )
                                                                        
        ,.rd_noc_ctrl_resp_data_val     (rd_noc_ctrl_resp_data_val      )
        ,.rd_noc_ctrl_resp_data_last    (rd_noc_ctrl_resp_data_last     )
        ,.ctrl_rd_noc_resp_data_rdy     (ctrl_rd_noc_resp_data_rdy      )
                                                                        
        ,.rd_buf_src_resp_data_val      (rd_buf_src_data_val            )
        ,.rd_buf_src_resp_data_last     (rd_buf_src_data_last           )
        ,.src_rd_buf_resp_data_rdy      (src_rd_buf_data_rdy            )
                                                                        
        ,.ctrl_datap_store_req_state    (ctrl_datap_store_req_state     )
        ,.ctrl_datap_update_req_state   (ctrl_datap_update_req_state    )
        ,.ctrl_datap_save_req           (ctrl_datap_save_req            )
        ,.ctrl_datap_decr_bytes_out_reg (ctrl_datap_decr_bytes_out_reg  )
        ,.ctrl_datap_store_shift        (ctrl_datap_store_shift         )
        ,.ctrl_datap_write_upper        (ctrl_datap_write_upper         )
        ,.ctrl_datap_shift_regs         (ctrl_datap_shift_regs          )
        ,.ctrl_datap_write_lower        (ctrl_datap_write_lower         )
        ,.ctrl_datap_use_shift          (ctrl_datap_use_shift           )
        ,.ctrl_datap_lower_zeros        (ctrl_datap_lower_zeros         )
                                                                        
        ,.datap_ctrl_split_req          (datap_ctrl_split_req           )
        ,.datap_ctrl_last_data_out      (datap_ctrl_last_data_out       )
    );

    rd_circ_buf_datap_new #(
        .BUF_PTR_W  (BUF_PTR_W  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_rd_buf_req_base_addr          (src_rd_buf_req_base_addr       )
        ,.src_rd_buf_req_offset             (src_rd_buf_req_offset          )
        ,.src_rd_buf_req_size               (src_rd_buf_req_size            )
    
        ,.rd_buf_src_resp_data              (rd_buf_src_data                )
        ,.rd_buf_src_resp_data_padbytes     (rd_buf_src_data_padbytes       )
                                                                            
        ,.datap_rd_noc_req                  (datap_rd_noc_req               )
                                                                            
        ,.rd_noc_datap_resp_data            (rd_noc_datap_resp_data         )
        ,.rd_noc_datap_resp_data_padbytes   (rd_noc_datap_resp_data_padbytes)
                                                                            
        ,.ctrl_datap_store_req_state        (ctrl_datap_store_req_state     )
        ,.ctrl_datap_update_req_state       (ctrl_datap_update_req_state    )
        ,.ctrl_datap_save_req               (ctrl_datap_save_req            )
        ,.ctrl_datap_decr_bytes_out_reg     (ctrl_datap_decr_bytes_out_reg  )
        ,.ctrl_datap_store_shift            (ctrl_datap_store_shift         )
        ,.ctrl_datap_write_upper            (ctrl_datap_write_upper         )
        ,.ctrl_datap_shift_regs             (ctrl_datap_shift_regs          )
        ,.ctrl_datap_write_lower            (ctrl_datap_write_lower         )
        ,.ctrl_datap_use_shift              (ctrl_datap_use_shift           )
        ,.ctrl_datap_lower_zeros            (ctrl_datap_lower_zeros         )
                                                                            
        ,.datap_ctrl_split_req              (datap_ctrl_split_req           )
        ,.datap_ctrl_last_data_out          (datap_ctrl_last_data_out       )
    );

    rd_mem_noc_module_usr #(
         .SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.DST_DRAM_X    (DST_DRAM_X )
        ,.DST_DRAM_Y    (DST_DRAM_Y )
        ,.FBITS         (FBITS      )
    ) rd_noc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_mem_noc_req_noc_val    (rd_buf_monitor_val                    )
        ,.rd_mem_noc_req_noc_data   (rd_buf_monitor_data                   )
        ,.noc_rd_mem_req_noc_rdy    (monitor_rd_buf_rdy                    )
    
        ,.noc_rd_mem_resp_noc_val   (monitor_rd_buf_val                    )
        ,.noc_rd_mem_resp_noc_data  (monitor_rd_buf_data                   )
        ,.rd_mem_noc_resp_noc_rdy   (rd_buf_monitor_rdy                    )
    
        ,.src_rd_mem_req_val        (ctrl_rd_noc_req_val                )
        ,.src_rd_mem_req_entry      (datap_rd_noc_req                   )
        ,.rd_mem_src_req_rdy        (rd_noc_ctrl_req_rdy                )
    
        ,.rd_mem_src_resp_val       (rd_noc_ctrl_resp_data_val          )
        ,.rd_mem_src_resp_data      (rd_noc_datap_resp_data             )
        ,.rd_mem_src_resp_last      (rd_noc_ctrl_resp_data_last         )
        ,.rd_mem_src_resp_padbytes  (rd_noc_datap_resp_data_padbytes    )
        ,.src_rd_mem_resp_rdy       (ctrl_rd_noc_resp_data_rdy          )
    );
endmodule
