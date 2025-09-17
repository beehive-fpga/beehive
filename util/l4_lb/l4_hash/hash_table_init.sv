module hash_table_init 
import hash_pkg::*;
#(
     parameter TABLE_ELS = -1
    ,parameter TABLE_ADDR_W = $clog2(TABLE_ELS) == 0 ? 1 : $clog2(TABLE_ELS)
	,parameter INIT_TABLE_ELS = -1
    ,parameter INIT_TABLE_ADDR_W = $clog2(INIT_TABLE_ELS) == 0 ? 1 : $clog2(INIT_TABLE_ELS)
)(
     input clk
    ,input rst

    ,output logic   reset_done

    ,output logic                           wr_req_val
    ,output logic   [TABLE_ADDR_W-1:0]      wr_req_addr
    ,output         hash_table_data         wr_req_data

	,output	logic						    init_table_rd
	,output logic   [INIT_TABLE_ADDR_W-1:0] init_table_addr
    ,input          hash_table_data         init_table_rd_data
);

    typedef enum logic [1:0] {
        READY = 2'd0,
        RD_FIRST_DATA = 2'd1,
        WRITING = 2'd2,
        FIN = 2'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   [TABLE_ADDR_W-1:0]      wr_addr_reg;
    logic   [TABLE_ADDR_W-1:0]      wr_addr_next;
    logic                           incr_wr_addr;

    logic                           set_reset_done;
    logic                           reset_done_reg;

    logic   [INIT_TABLE_ADDR_W-1:0] rd_addr_reg;
    logic   [INIT_TABLE_ADDR_W-1:0] rd_addr_next;
    logic                           incr_rd_addr;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            wr_addr_reg <= '0;
            rd_addr_reg <= '0;
            reset_done_reg <= 1'b0;
        end
        else begin
            state_reg <= state_next;
            wr_addr_reg <= wr_addr_next;
            rd_addr_reg <= rd_addr_next;

            if (set_reset_done) begin
                reset_done_reg <= 1'b1;
            end
        end
    end

    assign reset_done = reset_done_reg;

    assign wr_req_addr = wr_addr_reg;

    assign wr_addr_next = incr_wr_addr
                        ? wr_addr_reg + 1'b1
                        : wr_addr_reg;

    assign rd_addr_next = incr_rd_addr
                        ? rd_addr_reg == (INIT_TABLE_ELS - 1)
                            ? '0
                            : rd_addr_reg + 1'b1
                        : rd_addr_reg;

    assign init_table_addr = rd_addr_reg;
    assign wr_req_data = init_table_rd_data;

    assign init_table_rd = 1'b1;
    always_comb begin
        wr_req_val = 1'b0;
        set_reset_done = 1'b0;
        incr_wr_addr = 1'b0;
        incr_rd_addr = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                state_next = RD_FIRST_DATA;
            end
            RD_FIRST_DATA: begin
                incr_rd_addr = 1'b1;
                state_next = WRITING;
            end
            WRITING: begin
                wr_req_val = 1'b1;
                incr_rd_addr = 1'b1;
                incr_wr_addr = 1'b1;

                if (wr_req_addr == (TABLE_ELS-1)) begin
                    set_reset_done = 1'b1;
                    state_next = FIN;
                end
            end
            FIN: begin
                state_next = FIN;
            end
            default: begin
                wr_req_val = 'X;
                set_reset_done = 'X;
                incr_wr_addr = 'X;
                incr_rd_addr = 'X;

                state_next = UND;
            end
        endcase
   end

    
endmodule

