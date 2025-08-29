`include "bsg_defines.v"
module ram_2r1w_sync_backpressure #(
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

    ,input                          rd0_req_val
    ,input          [addr_w_p-1:0]  rd0_req_addr
    ,output logic                   rd0_req_rdy

    ,output logic                   rd0_resp_val
    ,output logic   [addr_w_p-1:0]  rd0_resp_addr
    ,output logic   [width_p-1:0]   rd0_resp_data 
    ,input                          rd0_resp_rdy
    
    ,input                          rd1_req_val
    ,input          [addr_w_p-1:0]  rd1_req_addr
    ,output logic                   rd1_req_rdy

    ,output logic                   rd1_resp_val
    ,output logic   [addr_w_p-1:0]  rd1_resp_addr
    ,output logic   [width_p-1:0]   rd1_resp_data 
    ,input                          rd1_resp_rdy
);
    
    logic                   mem_wr_req_val_byp;
    logic   [addr_w_p-1:0]  mem_wr_req_addr_byp;
    logic   [width_p-1:0]   mem_wr_req_data_byp;

    logic                   mem_rd0_req_val_byp;
    logic   [addr_w_p-1:0]  mem_rd0_req_addr_byp;

    logic                   mem_rd1_req_val_byp;
    logic   [addr_w_p-1:0]  mem_rd1_req_addr_byp;

    logic                   mem_wr_req_val;
    logic   [addr_w_p-1:0]  mem_wr_req_addr;
    logic   [width_p-1:0]   mem_wr_req_data;

    logic                   mem_rd0_req_val;
    logic   [addr_w_p-1:0]  mem_rd0_req_addr;
    logic   [width_p-1:0]   mem_rd0_resp_data;
    
    logic                   mem_rd1_req_val;
    logic   [addr_w_p-1:0]  mem_rd1_req_addr;
    logic   [width_p-1:0]   mem_rd1_resp_data;
    
    logic                   mem_wr_req_val_reg;
    logic   [addr_w_p-1:0]  mem_wr_req_addr_reg;
    logic   [width_p-1:0]   mem_wr_req_data_reg;

    logic                   mem_rd0_req_val_reg;
    logic   [addr_w_p-1:0]  mem_rd0_req_addr_reg;
    
    logic                   mem_rd1_req_val_reg;
    logic   [addr_w_p-1:0]  mem_rd1_req_addr_reg;
    
    assign wr_req_rdy = 1'b1;
    assign rd0_req_rdy = rd0_resp_rdy | ~rd0_resp_val;
    assign rd1_req_rdy = rd1_resp_rdy | ~rd1_resp_val;
    
    assign mem_wr_req_val = wr_req_val;
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
            mem_rd0_req_val_reg <= '0;
            mem_rd0_req_addr_reg <= '0;
        end
        else begin
            if (rd0_req_rdy) begin
                mem_rd0_req_val_reg <= mem_rd0_req_val;
                mem_rd0_req_addr_reg <= mem_rd0_req_addr;
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            mem_rd1_req_val_reg <= '0;
            mem_rd1_req_addr_reg <= '0;
        end
        else begin
            if (rd1_req_rdy) begin
                mem_rd1_req_val_reg <= mem_rd1_req_val;
                mem_rd1_req_addr_reg <= mem_rd1_req_addr;
            end
        end
    end
    
    // if we're currently backpressuring, we need to reissue from the registers
    assign mem_rd0_req_val = (rd0_resp_val & ~rd0_resp_rdy)
                            ? mem_rd0_req_val_reg
                            : rd0_req_val;
    assign mem_rd0_req_addr = (rd0_resp_val & ~rd0_resp_rdy) 
                             ? mem_rd0_req_addr_reg
                             : rd0_req_addr;
    
    assign mem_rd1_req_val = (rd1_resp_val & ~rd1_resp_rdy)
                            ? mem_rd1_req_val_reg
                            : rd1_req_val;
    assign mem_rd1_req_addr = (rd1_resp_val & ~rd1_resp_rdy) 
                             ? mem_rd1_req_addr_reg
                             : rd1_req_addr;
    
    // set valid signals for bypassing
    always_comb begin
        if (mem_rd0_req_val & mem_wr_req_val & 
            (mem_rd0_req_addr == mem_wr_req_addr)) begin
            mem_rd0_req_val_byp = 1'b0;
        end
        else begin
            mem_rd0_req_val_byp = mem_rd0_req_val;
        end
    end
    
    always_comb begin
        if (mem_rd1_req_val & mem_wr_req_val & 
            (mem_rd1_req_addr == mem_wr_req_addr)) begin
            mem_rd1_req_val_byp = 1'b0;
        end
        else begin
            mem_rd1_req_val_byp = mem_rd1_req_val;
        end
    end

    assign mem_rd0_req_addr_byp = mem_rd0_req_addr;
    assign mem_rd1_req_addr_byp = mem_rd1_req_addr;

    assign mem_wr_req_val_byp = mem_wr_req_val;
    assign mem_wr_req_addr_byp = mem_wr_req_addr;
    assign mem_wr_req_data_byp = mem_wr_req_data;
    
    bsg_mem_2r1w_sync #(
         .width_p   (width_p)
        ,.els_p     (els_p  )
   ) memory (
         .clk_i     (clk)
        ,.reset_i   (rst)

        ,.w_v_i     (mem_wr_req_val_byp     )
        ,.w_addr_i  (mem_wr_req_addr_byp    )
        ,.w_data_i  (mem_wr_req_data_byp    )

        ,.r0_v_i    (mem_rd0_req_val_byp    )
        ,.r0_addr_i (mem_rd0_req_addr_byp   )
        ,.r0_data_o (mem_rd0_resp_data      )

        ,.r1_v_i    (mem_rd1_req_val_byp    )
        ,.r1_addr_i (mem_rd1_req_addr_byp   )
        ,.r1_data_o (mem_rd1_resp_data      )
    );
    
    assign rd0_resp_val = mem_rd0_req_val_reg;
    assign rd1_resp_val = mem_rd1_req_val_reg;

    assign rd0_resp_addr = mem_rd0_req_addr_reg;
    assign rd1_resp_addr = mem_rd1_req_addr_reg;

    // bypass write outputs if necessary
    always_comb begin
        if (mem_wr_req_val_reg & mem_rd0_req_val_reg & 
            (mem_wr_req_addr_reg == mem_rd0_req_addr_reg)) begin
            rd0_resp_data = mem_wr_req_data_reg;
        end
        else begin
            rd0_resp_data = mem_rd0_resp_data;
        end
    end
    
    always_comb begin
        if (mem_wr_req_val_reg & mem_rd1_req_val_reg & 
            (mem_wr_req_addr_reg == mem_rd1_req_addr_reg)) begin
            rd1_resp_data = mem_wr_req_data_reg;
        end
        else begin
            rd1_resp_data = mem_rd1_resp_data;
        end
    end
    
endmodule
