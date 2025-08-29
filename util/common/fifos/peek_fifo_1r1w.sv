// this is only appropriate for very small FIFO sizes. it's more of a weird pipeline than a FIFO 
module peek_fifo_1r1w #(
     parameter DATA_W = -1
    ,parameter ELS = -1
    ,parameter ELS_W = $clog2(ELS)
)(
     input clk
    ,input rst

    ,input                          rd_req
    ,output logic   [DATA_W-1:0]    rd_data
    ,output logic   [DATA_W-1:0]    rd_data_next
    ,output logic   [ELS_W:0]       num_els

    ,input                          wr_req
    ,input          [DATA_W-1:0]    wr_data
    ,output logic                   full
    ,input                          clear_fifo
);

    localparam SIZE_SUB_OFF = (2 ** ELS_W) - ELS;

    logic   [ELS_W-1:0] wr_ptr_reg;
    logic   [ELS_W-1:0] wr_ptr_next;
    logic               wr_wrap_bit_reg;
    logic               wr_wrap_bit_next;
    
    logic   [ELS_W-1:0] rd_ptr_reg;
    logic   [ELS_W-1:0] rd_ptr_next;
    logic   [ELS_W-1:0] peek_ptr;
    logic               rd_wrap_bit_reg;
    logic               rd_wrap_bit_next;
    
    logic   [DATA_W-1:0]    fifo_mem [ELS-1:0];

    assign rd_data = fifo_mem[rd_ptr_reg];
    assign rd_data_next = fifo_mem[peek_ptr];

    assign full = (wr_wrap_bit_reg != rd_wrap_bit_reg) && (wr_ptr_reg == rd_ptr_reg);

    always_comb begin
        if (rd_ptr_reg == ELS - 1) begin
            peek_ptr = '0;
        end
        else begin
            peek_ptr = rd_ptr_reg + 1'b1;
        end
    end

    always_comb begin
        if (wr_wrap_bit_reg == rd_wrap_bit_reg) begin
            num_els = wr_ptr_reg - rd_ptr_reg;
        end
        else begin
            num_els = {wr_wrap_bit_reg, wr_ptr_reg} - {rd_wrap_bit_reg, rd_ptr_reg} - SIZE_SUB_OFF;
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr_reg <= '0;
            rd_ptr_reg <= '0;
            wr_wrap_bit_reg <= '0;
            rd_wrap_bit_reg <= '0;
        end
        else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
            wr_wrap_bit_reg <= wr_wrap_bit_next; 
            rd_wrap_bit_reg <= rd_wrap_bit_next;
        end
    end

    always_comb begin
        wr_ptr_next = wr_ptr_reg;
        wr_wrap_bit_next = wr_wrap_bit_reg;
        if (clear_fifo) begin
            wr_wrap_bit_next = '0;
            wr_ptr_next = '0;
        end
        else if (wr_req) begin
            if (wr_ptr_reg == ELS-1) begin
                wr_wrap_bit_next = ~wr_wrap_bit_reg;
                wr_ptr_next = '0;
            end
            else begin
                wr_ptr_next = wr_ptr_reg + 1'b1;
            end
        end
    end

    always_comb begin
        rd_ptr_next = rd_ptr_reg;
        rd_wrap_bit_next = rd_wrap_bit_reg;
        if (clear_fifo) begin
            rd_wrap_bit_next = '0;
            rd_ptr_next = '0;
        end
        else if (rd_req) begin
            if (rd_ptr_reg == ELS-1) begin
                rd_wrap_bit_next = ~rd_wrap_bit_reg;
                rd_ptr_next = '0;
            end
            else begin
                rd_ptr_next = rd_ptr_reg + 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (wr_req) begin
            fifo_mem[wr_ptr_reg] <= wr_data;
        end
    end


endmodule
