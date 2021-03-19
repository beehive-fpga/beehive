// TODO: test with random memory operation latencies

module masked_mem_wrap_valrdy #(
     parameter MEM_ADDR_W = -1
    ,parameter MEM_DATA_W = -1
    ,parameter MEM_WR_MASK_W = MEM_DATA_W/8
    // the number of reads that can be in-flight
    ,parameter SKID_SIZE = -1
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
);

    logic                       mem_rd_req_val_reg;
    logic   [MEM_DATA_W-1:0]    mem_rd_resp_data_reg;
    
    logic                       mem_rd_req_val_next;
    logic   [MEM_DATA_W-1:0]    mem_rd_resp_data_next;
    
    logic                       rd_backp;

    logic                       skid_fifo_wr;
    logic                       skid_fifo_rd;
    logic                       skid_fifo_rd_val;
    logic   [MEM_DATA_W-1:0]    skid_fifo_rd_data;

    assign wrap_mem_write_en = controller_wrap_write_en;
    assign wrap_mem_addr = controller_wrap_addr;
    assign wrap_mem_wr_data = controller_wrap_wr_data;
    assign wrap_mem_byte_en = controller_wrap_byte_en;
    assign wrap_mem_burst_cnt = controller_wrap_burst_cnt;
    assign wrap_mem_read_en = ~rd_backp & controller_wrap_read_en;

    assign rd_backp = (wrap_controller_rd_data_val & ~controller_wrap_rd_data_rdy) | skid_fifo_rd_val;

    assign wrap_controller_rdy = ~rd_backp & mem_wrap_rdy;

    always_ff @(posedge clk) begin
        if (rst) begin
            mem_rd_req_val_reg <= '0;
        end
        else begin
            mem_rd_req_val_reg <= mem_rd_req_val_next;
            mem_rd_resp_data_reg <= mem_rd_resp_data_next;
        end
    end
    
    // if we're currently backpressuring, we need to just chill

    // if there's data available, we should grab it
    // if the read is backpressuring, we should save whatever value we have
    // otherwise, clear the valid
    assign wrap_controller_rd_data_val = skid_fifo_rd_val | mem_wrap_rd_data_val;

    assign wrap_controller_rd_data = skid_fifo_rd_val
                                    ? skid_fifo_rd_data
                                    : mem_wrap_rd_data;

    assign skid_fifo_wr = mem_wrap_rd_data_val & (~controller_wrap_rd_data_rdy | skid_fifo_rd_val);
    assign skid_fifo_rd = skid_fifo_rd_val & controller_wrap_rd_data_rdy;

    bsg_fifo_1r1w_small #( 
         .width_p   (MEM_DATA_W )
        ,.els_p     (SKID_SIZE  )
    ) skid_fifo ( 
         .clk_i     (clk    )
        ,.reset_i   (rst    )
    
        ,.v_i       (skid_fifo_wr       )
        ,.ready_o   ()
        ,.data_i    (mem_wrap_rd_data   )
    
        ,.v_o       (skid_fifo_rd_val   )
        ,.data_o    (skid_fifo_rd_data  )
        ,.yumi_i    (skid_fifo_rd       )
    );

endmodule
