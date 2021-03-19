`include "masked_mem_defs.svh"
module tb_mem_controller #(
     parameter MEM_DATA_W = 512
    ,parameter MEM_ADDR_W = 14
    ,parameter MEM_WR_MASK_W = MEM_DATA_W/8
    ,parameter SRC_X = 2
    ,parameter SRC_Y = 2
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_controller_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_controller_data
    ,output logic                           controller_noc0_ctovr_rdy

    ,output logic                           controller_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   controller_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_controller_rdy
    
    ,output logic                           wr_resp_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   wr_resp_noc_vrtoc_data
    ,input                                  noc_wr_resp_vrtoc_rdy

);
    logic                           controller_wrap_write_en;
    logic   [MEM_ADDR_W-1:0]        controller_wrap_addr;
    logic   [MEM_DATA_W-1:0]        controller_wrap_wr_data;
    logic   [MEM_WR_MASK_W-1:0]     controller_wrap_byte_en;
    logic                           wrap_controller_rdy;

    logic                           controller_wrap_read_en;
    logic                           wrap_controller_rd_data_val;
    logic   [MEM_DATA_W-1:0]        wrap_controller_rd_data;
    logic                           controller_wrap_rd_data_rdy;
    
    logic                           wrap_mem_write_en;
    logic   [MEM_ADDR_W-1:0]        wrap_mem_addr;
    logic   [MEM_DATA_W-1:0]        wrap_mem_wr_data;
    logic   [MEM_WR_MASK_W-1:0]     wrap_mem_byte_en;
    logic                           mem_wrap_rdy;

    logic                           wrap_mem_read_en;
    logic                           mem_wrap_rd_data_val;
    logic   [MEM_DATA_W-1:0]        mem_wrap_rd_data;

    logic   [`NOC_DATA_WIDTH-1:0]   controller_noc0_vrtoc_data_unmasked;

    // a hack to crush any uninitialized bits
    
    assign controller_noc0_vrtoc_data = ~((~controller_noc0_vrtoc_data_unmasked) & ({(MEM_DATA_W){1'b1}}));

    masked_mem_controller_rd_pipe #(
         .MEM_DATA_W    (MEM_DATA_W )
        ,.MEM_ADDR_W    (MEM_ADDR_W )
        ,.SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.SIM_TEST      (1)
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_controller_val     (noc0_ctovr_controller_val  )
        ,.noc0_ctovr_controller_data    (noc0_ctovr_controller_data )
        ,.controller_noc0_ctovr_rdy     (controller_noc0_ctovr_rdy  )
                                                                    
        ,.controller_noc0_vrtoc_val     (controller_noc0_vrtoc_val  )
        ,.controller_noc0_vrtoc_data    (controller_noc0_vrtoc_data_unmasked)
        ,.noc0_vrtoc_controller_rdy     (noc0_vrtoc_controller_rdy  )
    
        ,.wr_resp_noc_vrtoc_val         (wr_resp_noc_vrtoc_val      )
        ,.wr_resp_noc_vrtoc_data        (wr_resp_noc_vrtoc_data     )
        ,.noc_wr_resp_vrtoc_rdy         (noc_wr_resp_vrtoc_rdy      )
                                                                    
        ,.controller_mem_write_en       (controller_wrap_write_en   )
        ,.controller_mem_addr           (controller_wrap_addr       )
        ,.controller_mem_wr_data        (controller_wrap_wr_data    )
        ,.controller_mem_byte_en        (controller_wrap_byte_en    )
        ,.controller_mem_burst_cnt      ()
        ,.mem_controller_rdy            (wrap_controller_rdy        )

        ,.controller_mem_read_en        (controller_wrap_read_en    )
        ,.mem_controller_rd_data_val    (wrap_controller_rd_data_val)
        ,.mem_controller_rd_data        (wrap_controller_rd_data    )
        ,.controller_mem_rd_data_rdy    (controller_wrap_rd_data_rdy)
    );

    masked_mem_wrap_valrdy #(
         .MEM_ADDR_W    (MEM_ADDR_W )
        ,.MEM_DATA_W    (MEM_DATA_W )
        ,.SKID_SIZE     (2)         
    ) wrap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.wrap_controller_rdy           (wrap_controller_rdy            )
                                                                        
        ,.controller_wrap_write_en      (controller_wrap_write_en       )
        ,.controller_wrap_addr          (controller_wrap_addr           )
        ,.controller_wrap_wr_data       (controller_wrap_wr_data        )
        ,.controller_wrap_byte_en       (controller_wrap_byte_en        )
        ,.controller_wrap_burst_cnt     ()
                                                                        
        ,.controller_wrap_read_en       (controller_wrap_read_en        )
                                                                        
        ,.wrap_controller_rd_data_val   (wrap_controller_rd_data_val    )
        ,.wrap_controller_rd_data       (wrap_controller_rd_data        )
        ,.controller_wrap_rd_data_rdy   (controller_wrap_rd_data_rdy    )
    
        ,.wrap_mem_write_en             (wrap_mem_write_en              )
        ,.wrap_mem_addr                 (wrap_mem_addr                  )
        ,.wrap_mem_wr_data              (wrap_mem_wr_data               )
        ,.wrap_mem_byte_en              (wrap_mem_byte_en               )
        ,.wrap_mem_burst_cnt            ()
        ,.mem_wrap_rdy                  (mem_wrap_rdy                   )
                                                                        
        ,.wrap_mem_read_en              (wrap_mem_read_en               )
        ,.mem_wrap_rd_data_val          (mem_wrap_rd_data_val           )
        ,.mem_wrap_rd_data              (mem_wrap_rd_data               )
    );

    assign mem_wrap_rdy = 1'b1;
    ram_1rw_byte_mask_out_reg_wrap #(
         .DATA_W(MEM_DATA_W         )
        ,.DEPTH (2 ** MEM_ADDR_W   )
    ) memA (
         .clk           (clk                    )
        ,.rst           (rst                    )
        ,.en_a          (wrap_mem_write_en | wrap_mem_read_en)
        ,.wr_en_a       (wrap_mem_write_en    )
        ,.addr_a        (wrap_mem_addr        )
        ,.din_a         (wrap_mem_wr_data     )
        ,.wr_mask_a     (wrap_mem_byte_en     )

        ,.dout_val_a    (mem_wrap_rd_data_val )
        ,.dout_a        (mem_wrap_rd_data)
    );
endmodule
