// A synchronous read ram that won't let you read if there is a read address collision
// You can also backpressure the output though. 
// Be warned that the behavior around this saved output is a little weird in
// that it will not grab new written data and pass it to the output even if the
// read being transferred out is for the same address
module ram_1r1w_sync_no_collision #(
	 parameter DATA_W = -1
	,parameter DEPTH = -1
	,parameter ADDR_W = $clog2(DEPTH)
)(
     input clk
    ,input rst
    
    ,input                          wr_en_a
    ,input          [ADDR_W-1:0]    wr_addr_a
    ,input          [DATA_W-1:0]    wr_data_a
    ,output logic                   wr_rdy_a

    ,input                          rd_req_en_a
    ,input          [ADDR_W-1:0]    rd_req_addr_a
    ,output logic                   rd_req_rdy_a
    
    ,output logic                   rd_resp_val_a
    ,output logic   [DATA_W-1:0]    rd_resp_data_a
    ,input                          rd_resp_rdy_a
);
    logic                   addr_collision_i;
    logic                   wr_mem_val_i;
    logic   [ADDR_W-1:0]    wr_mem_addr_i;
    logic   [DATA_W-1:0]    wr_mem_data_i;

    logic                   rd_req_mem_val_i;
    logic   [ADDR_W-1:0]    rd_req_mem_addr_i;

    logic   [DATA_W-1:0]    rd_resp_mem_data_o;

    logic                   stall_o;
    logic                   rd_resp_val_reg_o;
    logic                   rd_req_val_reg_o;
    logic   [DATA_W-1:0]    rd_resp_data_reg_o;
    logic                   use_saved_o;


    assign addr_collision_i = wr_en_a & (wr_addr_a == rd_req_addr_a);
    assign rd_req_rdy_a = ~stall_o & ~addr_collision_i;

    assign wr_rdy_a = 1'b1;

    assign rd_req_mem_val_i = rd_req_rdy_a & rd_req_en_a;
    assign rd_req_mem_addr_i = rd_req_addr_a;

    assign wr_mem_val_i = wr_en_a;
    assign wr_mem_addr_i = wr_addr_a;
    assign wr_mem_data_i = wr_data_a;

    ram_1r1w_sync #(
         .DATA_W    (DATA_W )
        ,.DEPTH     (DEPTH  )
        ,.ADDR_W    (ADDR_W )
    ) ram (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_en_a   (wr_mem_val_i       )
        ,.wr_addr_a (wr_mem_addr_i      )
        ,.wr_data_a (wr_mem_data_i      )
    
        ,.rd_en_a   (rd_req_mem_val_i   )
        ,.rd_addr_a (rd_req_mem_addr_i  )
    
        ,.rd_data_a (rd_resp_mem_data_o )
    );

    /****************************************************
     * (I)nput -> (O)utput
     ***************************************************/
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_resp_val_reg_o <= '0;
            rd_req_val_reg_o <= '0;
        end
        else begin
            rd_req_val_reg_o <= rd_req_mem_val_i;
            if (~stall_o) begin
                rd_resp_val_reg_o <= rd_req_mem_val_i;
            end
        end
    end
    /****************************************************
     * (O)utput stage
     ***************************************************/
    // if we actually made a read request in the last cycle, then save that
    // output
    always_ff @(posedge clk) begin
        if (rd_req_val_reg_o) begin
            rd_resp_data_reg_o <= rd_resp_mem_data_o;
        end
    end
    
    // if we actually made a request in the cycle before, use that response
    // otherwise, use whatever we have saved
    assign use_saved_o = ~rd_req_val_reg_o;

    assign stall_o = rd_resp_val_reg_o & ~rd_resp_rdy_a;
    assign rd_resp_val_a = rd_resp_val_reg_o;
    assign rd_resp_data_a = use_saved_o
                            ? rd_resp_data_reg_o
                            : rd_resp_mem_data_o;


endmodule
