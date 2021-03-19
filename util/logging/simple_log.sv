module simple_log #(
     parameter LOG_DATA_W = -1
    ,parameter MEM_DEPTH_LOG2 = -1
    ,parameter MEM_ADDR_W = MEM_DEPTH_LOG2
)(
     input clk
    ,input rst

    ,input                              wr_req_val
    ,input          [LOG_DATA_W-1:0]    wr_req_data 

    ,input                              rd_req_val
    ,input          [MEM_ADDR_W-1:0]    rd_req_addr

    ,output logic                       rd_resp_val
    ,output logic   [LOG_DATA_W-1:0]    rd_resp_data

    ,output logic   [MEM_ADDR_W-1:0]    curr_wr_addr
    ,output logic                       log_has_wrapped
);

    logic   [MEM_ADDR_W-1:0]    addr_reg;
    logic                       has_looped_reg;
    logic                       has_looped_next;

    assign curr_wr_addr = addr_reg;
    assign log_has_wrapped = has_looped_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            addr_reg <= '0;
            has_looped_reg <= '0;
        end
        else begin
            has_looped_reg <= has_looped_next;
            if (wr_req_val) begin
                addr_reg <= addr_reg + 1;
            end
        end
    end
    
    assign has_looped_next = has_looped_reg 
                             || (wr_req_val && (addr_reg == {MEM_ADDR_W{1'b1}}));
        
    ram_1r1w_sync_backpressure #(
         .width_p   (LOG_DATA_W         )
        ,.els_p     (2**MEM_DEPTH_LOG2  )
    ) log_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (wr_req_val     )
        ,.wr_req_addr   (addr_reg       )
        ,.wr_req_data   (wr_req_data    )
        ,.wr_req_rdy    ()
    
        ,.rd_req_val    (rd_req_val     )
        ,.rd_req_addr   (rd_req_addr    )
        ,.rd_req_rdy    ()
    
        ,.rd_resp_val   (rd_resp_val    )
        ,.rd_resp_data  (rd_resp_data   )
        ,.rd_resp_rdy   (1'b1)
    );
endmodule
