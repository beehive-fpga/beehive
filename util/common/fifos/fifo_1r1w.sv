module fifo_1r1w #(
     parameter width_p = -1
    ,parameter log2_els_p = -1
)(
     input clk
    ,input rst

    ,input                          rd_req
    ,output logic   [width_p-1:0]   rd_data
    ,output logic                   empty

    ,input                          wr_req
    ,input          [width_p-1:0]   wr_data
    ,output logic                   full
);

    localparam els_p = 2 ** log2_els_p;

    // Pointers all have an extra bit for wrapping
    // write pointer points to the next EMPTY slot, unless the queue is full
    logic   [log2_els_p:0]      wr_ptr_reg;
    logic   [log2_els_p:0]      wr_ptr_next;
    
    // read pointer points to the next OCCUPIED slot, unless the queue is empty
    logic   [log2_els_p:0]      rd_ptr_reg;
    logic   [log2_els_p:0]      rd_ptr_next;
    
    logic                       fifo_wr_val;
    logic   [log2_els_p-1:0]    fifo_wr_addr;
    logic   [width_p-1:0]       fifo_wr_data;

    logic                       fifo_rd_val;
    logic   [log2_els_p-1:0]    fifo_rd_addr;
    logic   [width_p-1:0]       fifo_rd_data;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr_reg <= '0;
            rd_ptr_reg <= '0;
        end
        else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
        end
    end
    
    assign fifo_wr_val = wr_req;
    assign fifo_wr_addr = wr_ptr_reg[log2_els_p-1:0];
    assign fifo_wr_data = wr_data;

    assign fifo_rd_val = 1'b1;
    assign fifo_rd_addr = rd_ptr_next[log2_els_p-1:0];
    assign rd_data = fifo_rd_data;
    
    // we're empty (for the sake of reading) if the rd ptr is equal to the commit pointer and
    // they're on the same wrap
    assign empty = (rd_ptr_reg[log2_els_p-1:0] == wr_ptr_reg[log2_els_p-1:0]) &
                   (rd_ptr_reg[log2_els_p] == wr_ptr_reg[log2_els_p]);
    // we're full (for the sake of writing) if the wr ptr is equal to the rd pointer and they're
    // on different wraps
    assign full = (rd_ptr_reg[log2_els_p-1:0] == wr_ptr_reg[log2_els_p-1:0]) &
                  (rd_ptr_reg[log2_els_p] != wr_ptr_reg[log2_els_p]);
    
    always_comb begin
        wr_ptr_next = wr_ptr_reg;
        if (wr_req) begin
            wr_ptr_next = wr_ptr_reg + 1'b1;
        end
        else begin
            wr_ptr_next = wr_ptr_reg;
        end
    end
    
    always_comb begin
        rd_ptr_next = rd_ptr_reg;
        if (rd_req) begin
            rd_ptr_next = rd_ptr_reg + 1'b1;
        end
        else begin
            rd_ptr_next = rd_ptr_reg;
        end
    end
    
    ram_1r1w_sync_backpressure #(
         .width_p   (width_p)
        ,.els_p     (els_p  )
    ) fifo_mem (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.wr_req_val    (fifo_wr_val    )
        ,.wr_req_addr   (fifo_wr_addr   )
        ,.wr_req_data   (fifo_wr_data   )
        ,.wr_req_rdy    ()

        ,.rd_req_val    (fifo_rd_val    )
        ,.rd_req_addr   (fifo_rd_addr   )
        ,.rd_req_rdy    ()

        ,.rd_resp_val   ()
        ,.rd_resp_data  (fifo_rd_data   )
        ,.rd_resp_rdy   (1'b1)
    );

endmodule
