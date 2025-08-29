`include "bsg_defines.v"
module ram_1r1w_sync_backpressure #(
     parameter width_p = -1
    ,parameter els_p = -1
    ,parameter addr_w_p = `BSG_SAFE_CLOG2(els_p)
)(
     input clk
    ,input rst

    ,input                          wr_req_val
    ,input          [addr_w_p-1:0]  wr_req_addr
    ,input          [width_p-1:0]   wr_req_data
    ,output                         wr_req_rdy

    ,input                          rd_req_val
    ,input          [addr_w_p-1:0]  rd_req_addr
    ,output logic                   rd_req_rdy

    ,output logic                   rd_resp_val
    ,output logic   [width_p-1:0]   rd_resp_data 
    ,input                          rd_resp_rdy
);
    logic                       mem_wr_req_val_byp;
    logic   [addr_w_p-1:0]      mem_wr_req_addr_byp;
    logic   [width_p-1:0]       mem_wr_req_data_byp;

    logic                       mem_rd_req_val_byp;
    logic   [addr_w_p-1:0]      mem_rd_req_addr_byp;

    logic                       mem_wr_req_val;
    logic   [addr_w_p-1:0]      mem_wr_req_addr;
    logic   [width_p-1:0]       mem_wr_req_data;

    logic                       mem_rd_req_val;
    logic   [addr_w_p-1:0]      mem_rd_req_addr;
    logic   [width_p-1:0]       mem_rd_resp_data;
    
    logic                       mem_wr_req_val_reg;
    logic   [addr_w_p-1:0]      mem_wr_req_addr_reg;
    logic   [width_p-1:0]       mem_wr_req_data_reg;

    logic                       mem_rd_req_val_reg;
    logic   [addr_w_p-1:0]      mem_rd_req_addr_reg;
    
    assign wr_req_rdy = 1'b1;
    assign rd_req_rdy = rd_resp_rdy | ~rd_resp_val;
    
    assign mem_wr_req_val = wr_req_val & wr_req_rdy;
    assign mem_wr_req_addr = wr_req_addr;
    assign mem_wr_req_data = wr_req_data;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            mem_wr_req_val_reg <= '0;
            mem_wr_req_addr_reg <= '0;
            mem_wr_req_data_reg <= '0;
        end
        else begin
            if (wr_req_rdy) begin
                mem_wr_req_val_reg <= mem_wr_req_val;
                mem_wr_req_addr_reg <= mem_wr_req_addr;
                mem_wr_req_data_reg <= mem_wr_req_data;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            mem_rd_req_val_reg <= '0;
            mem_rd_req_addr_reg <= '0;
        end
        else begin
            if (rd_req_rdy) begin
                mem_rd_req_val_reg <= mem_rd_req_val;
                mem_rd_req_addr_reg <= mem_rd_req_addr;
            end
        end
    end
    
    // if we're currently backpressuring, we need to reissue from the registers
    assign mem_rd_req_val = (rd_resp_val & ~rd_resp_rdy)
                            ? mem_rd_req_val_reg
                            : rd_req_val;
    assign mem_rd_req_addr = (rd_resp_val & ~rd_resp_rdy) 
                             ? mem_rd_req_addr_reg
                             : rd_req_addr;
    
    // set valid signals for bypassing
    always_comb begin
        if (mem_rd_req_val & mem_wr_req_val & 
            (mem_rd_req_addr == mem_wr_req_addr)) begin
            mem_rd_req_val_byp = 1'b0;
        end
        else begin
            mem_rd_req_val_byp = mem_rd_req_val;
        end
    end

    assign mem_rd_req_addr_byp = mem_rd_req_addr;

    assign mem_wr_req_val_byp = mem_wr_req_val;
    assign mem_wr_req_addr_byp = mem_wr_req_addr;
    assign mem_wr_req_data_byp = mem_wr_req_data;

    // TCP data mem
    bsg_mem_1r1w_sync #(
         .width_p   (width_p)
        ,.els_p     (els_p)
    ) tcp_data_mem (
         .clk_i     (clk    )
        ,.reset_i   (rst    )
        
        ,.w_v_i     (mem_wr_req_val_byp     )
        ,.w_addr_i  (mem_wr_req_addr_byp    )
        ,.w_data_i  (mem_wr_req_data_byp   )
        
        // currently unused
        ,.r_v_i     (mem_rd_req_val_byp     )
        ,.r_addr_i  (mem_rd_req_addr_byp    )
        
        ,.r_data_o  (mem_rd_resp_data       )
    );
    
    assign rd_resp_val = mem_rd_req_val_reg;

    // bypass write outputs if necessary
    always_comb begin
        if (mem_wr_req_val_reg & mem_rd_req_val_reg & 
            (mem_wr_req_addr_reg == mem_rd_req_addr_reg)) begin
            rd_resp_data = mem_wr_req_data_reg;
        end
        else begin
            rd_resp_data = mem_rd_resp_data;
        end
    end

endmodule
