`include "noc_defs.vh"
module wr_circ_buf 
import tcp_pkg::*;
import mem_msg_pkg::*;
#(
     parameter BUF_PTR_W=-1
    ,parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
)(
     input clk
    ,input rst

    ,output logic                               wr_buf_noc_req_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       wr_buf_noc_req_noc_data
    ,input  logic                               noc_wr_buf_req_noc_rdy
    
    ,input  logic                               noc_wr_buf_resp_noc_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_wr_buf_resp_noc_data
    ,output logic                               wr_buf_noc_resp_noc_rdy

    ,input                                      src_wr_buf_req_val
    ,input  vaddr_t                             src_wr_buf_req_base_addr
    ,input          [BUF_PTR_W-1:0]             src_wr_buf_req_wr_ptr
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]  src_wr_buf_req_size
    ,output logic                               wr_buf_src_req_rdy

    ,input                                      src_wr_buf_req_data_val
    ,input          [`NOC_DATA_WIDTH-1:0]       src_wr_buf_req_data
    ,output logic                               wr_buf_src_req_data_rdy
    
    ,output logic                               wr_buf_src_req_done
    ,input  logic                               src_wr_buf_done_rdy
);
    logic                               wr_buf_wr_mem_req_val;
    logic                               wr_mem_wr_buf_req_rdy;
    mem_req_struct                      datapath_mem_req_struct;
    
    logic                               wr_buf_wr_mem_wr_req_done_rdy;
    logic                               wr_mem_wr_buf_wr_req_done;
    
    logic   [`NOC_DATA_WIDTH-1:0]       wr_buf_wr_mem_req_data;
    logic                               wr_buf_wr_mem_req_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   wr_buf_wr_mem_req_data_padbytes;
    logic                               wr_buf_wr_mem_req_data_val;
    logic                               wr_mem_wr_buf_req_data_rdy;
    
    logic                               store_req_metadata;
    logic                               update_wr_req_metadata;

    logic                               init_curr_req_rem_bytes;
    logic                               update_curr_req_rem_bytes;
    
    logic                               store_save_reg;
    logic                               store_save_reg_shift;
    logic                               clear_save_reg_shift;

    logic                               split_req;
    logic                               save_reg_has_unused;
    logic                               datap_ctrl_need_input;

    wr_circ_buf_datapath #(
        .BUF_PTR_W  (BUF_PTR_W)
    ) datapath (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_wr_buf_req_base_addr          (src_wr_buf_req_base_addr           )
        ,.src_wr_buf_req_wr_ptr             (src_wr_buf_req_wr_ptr              )
        ,.src_wr_buf_req_size               (src_wr_buf_req_size                )

        ,.src_wr_buf_req_data               (src_wr_buf_req_data                )

        ,.wr_buf_wr_mem_req_data            (wr_buf_wr_mem_req_data             )
        ,.wr_buf_wr_mem_req_data_last       (wr_buf_wr_mem_req_data_last        )
        ,.wr_buf_wr_mem_req_data_padbytes   (wr_buf_wr_mem_req_data_padbytes    )

        ,.store_req_metadata                (store_req_metadata                 )
        ,.update_wr_req_metadata            (update_wr_req_metadata             )
                                                                      
        ,.init_curr_req_rem_bytes           (init_curr_req_rem_bytes            )
        ,.update_curr_req_rem_bytes         (update_curr_req_rem_bytes          )
                                                                      
        ,.split_req                         (split_req                          )
        ,.save_reg_has_unused               (save_reg_has_unused                )
        ,.datap_ctrl_need_input             (datap_ctrl_need_input              )
        
        ,.store_save_reg                (store_save_reg                 )
        ,.store_save_reg_shift          (store_save_reg_shift           )
        ,.clear_save_reg_shift          (clear_save_reg_shift           )
                                                                      
        ,.datapath_mem_req_struct           (datapath_mem_req_struct            )
    );

    wr_circ_buf_ctrl control (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_wr_buf_req_val            (src_wr_buf_req_val             )
        ,.wr_buf_src_req_rdy            (wr_buf_src_req_rdy             )

        ,.src_wr_buf_req_data_val       (src_wr_buf_req_data_val        )
        ,.wr_buf_src_req_data_rdy       (wr_buf_src_req_data_rdy        )
    
        ,.wr_buf_src_wr_req_done        (wr_buf_src_req_done            )
        ,.src_wr_buf_wr_req_done_rdy    (src_wr_buf_done_rdy            )

        ,.wr_buf_wr_mem_req_val         (wr_buf_wr_mem_req_val          )
        ,.wr_mem_wr_buf_req_rdy         (wr_mem_wr_buf_req_rdy          )

        ,.wr_buf_wr_mem_req_data_val    (wr_buf_wr_mem_req_data_val     )
        ,.wr_mem_wr_buf_req_data_rdy    (wr_mem_wr_buf_req_data_rdy     )
    
        ,.wr_buf_wr_mem_wr_req_done_rdy (wr_buf_wr_mem_wr_req_done_rdy  )
        ,.wr_mem_wr_buf_wr_req_done     (wr_mem_wr_buf_wr_req_done      )
                                                                    
        ,.split_req                     (split_req                      )
        ,.save_reg_has_unused           (save_reg_has_unused            )
        ,.datap_ctrl_need_input         (datap_ctrl_need_input          )
                                                                    
        ,.store_req_metadata            (store_req_metadata             )
        ,.update_wr_req_metadata        (update_wr_req_metadata         )
                                                                    
        ,.init_curr_req_rem_bytes       (init_curr_req_rem_bytes        )
        ,.update_curr_req_rem_bytes     (update_curr_req_rem_bytes      )
    
        ,.store_save_reg                (store_save_reg                 )
        ,.store_save_reg_shift          (store_save_reg_shift           )
        ,.clear_save_reg_shift          (clear_save_reg_shift           )

        ,.datap_ctrl_last_wr            (wr_buf_wr_mem_req_data_last    )
    );


    wr_mem_noc_module_usr #(
         .SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.DST_DRAM_X    (DST_DRAM_X )
        ,.DST_DRAM_Y    (DST_DRAM_Y )
        ,.FBITS         (FBITS      )
    ) wr_mem_noc (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.wr_mem_noc_req_noc0_val       (wr_buf_noc_req_noc_val             )
        ,.wr_mem_noc_req_noc0_data      (wr_buf_noc_req_noc_data            )
        ,.noc_wr_mem_req_noc0_rdy       (noc_wr_buf_req_noc_rdy             )
                                                                   
        ,.noc_wr_mem_resp_noc0_val      (noc_wr_buf_resp_noc_val            )
        ,.noc_wr_mem_resp_noc0_data     (noc_wr_buf_resp_noc_data           )
        ,.wr_mem_noc_resp_noc0_rdy      (wr_buf_noc_resp_noc_rdy            )

        ,.src_wr_mem_req_val            (wr_buf_wr_mem_req_val              )
        ,.src_wr_mem_req_entry          (datapath_mem_req_struct            )
        ,.wr_mem_src_req_rdy            (wr_mem_wr_buf_req_rdy              )

        ,.src_wr_mem_req_data_val       (wr_buf_wr_mem_req_data_val         )
        ,.src_wr_mem_req_data           (wr_buf_wr_mem_req_data             )
        ,.src_wr_mem_req_data_last      (wr_buf_wr_mem_req_data_last        )
        ,.src_wr_mem_req_data_padbytes  (wr_buf_wr_mem_req_data_padbytes    )
        ,.wr_mem_src_req_data_rdy       (wr_mem_wr_buf_req_data_rdy         )

        ,.wr_req_done                   (wr_mem_wr_buf_wr_req_done          )
        ,.wr_req_done_rdy               (wr_buf_wr_mem_wr_req_done_rdy      )
    );


endmodule
