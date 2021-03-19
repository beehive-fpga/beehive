module tb_mem_wrap_valrdy #(
     parameter MEM_ADDR_W = 10
    ,parameter MEM_DATA_W = 512
    ,parameter MEM_WR_MASK_W = MEM_DATA_W/8
)(
     input clk
    ,input rst
    
    ,output                                 wrap_controller_rdy

    ,input  logic                           controller_wrap_write_en
    ,input  logic   [MEM_ADDR_W-1:0]        controller_wrap_addr
    ,input  logic   [MEM_DATA_W-1:0]        controller_wrap_wr_data
    ,input  logic   [MEM_WR_MASK_W-1:0]     controller_wrap_byte_en
    ,input  logic   [7-1:0]                 controller_wrap_burst_cnt

    ,input  logic                           controller_wrap_read_en

    ,output                                 wrap_controller_rd_data_val
    ,output         [MEM_DATA_W-1:0]        wrap_controller_rd_data
    ,input                                  controller_wrap_rd_data_rdy
    
    ,output logic                           wrap_mem_write_en
    ,output logic   [MEM_ADDR_W-1:0]        wrap_mem_addr
    ,output logic   [MEM_DATA_W-1:0]        wrap_mem_wr_data
    ,output logic   [MEM_WR_MASK_W-1:0]     wrap_mem_byte_en
    ,output logic   [7-1:0]                 wrap_mem_burst_cnt
    ,input                                  mem_wrap_rdy

    ,output logic                           wrap_mem_read_en
    ,input                                  mem_wrap_rd_data_val
    ,input          [MEM_DATA_W-1:0]        mem_wrap_rd_data
    ,output logic                           wrap_mem_rd_data_rdy
);

    assign wrap_mem_rd_data_rdy = 1'b1;
    

    masked_mem_wrap_valrdy #(
         .MEM_ADDR_W    (MEM_ADDR_W )
        ,.MEM_DATA_W    (MEM_DATA_W )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.wrap_controller_rdy           (wrap_controller_rdy            )
                                                                        
        ,.controller_wrap_write_en      (controller_wrap_write_en       )
        ,.controller_wrap_addr          (controller_wrap_addr           )
        ,.controller_wrap_wr_data       (controller_wrap_wr_data        )
        ,.controller_wrap_byte_en       (controller_wrap_byte_en        )
        ,.controller_wrap_burst_cnt     (controller_wrap_burst_cnt      )
                                                                        
        ,.controller_wrap_read_en       (controller_wrap_read_en        )
                                                                        
        ,.wrap_controller_rd_data_val   (wrap_controller_rd_data_val    )
        ,.wrap_controller_rd_data       (wrap_controller_rd_data        )
        ,.controller_wrap_rd_data_rdy   (controller_wrap_rd_data_rdy    )
                                                                        
        ,.wrap_mem_write_en             (wrap_mem_write_en              )
        ,.wrap_mem_addr                 (wrap_mem_addr                  )
        ,.wrap_mem_wr_data              (wrap_mem_wr_data               )
        ,.wrap_mem_byte_en              (wrap_mem_byte_en               )
        ,.wrap_mem_burst_cnt            (wrap_mem_burst_cnt             )
        ,.mem_wrap_rdy                  (mem_wrap_rdy                   )
                                                                        
        ,.wrap_mem_read_en              (wrap_mem_read_en               )
        ,.mem_wrap_rd_data_val          (mem_wrap_rd_data_val           )
        ,.mem_wrap_rd_data              (mem_wrap_rd_data               )
    );
endmodule
