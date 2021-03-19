`include "echo_app_stats_defs.svh"
module echo_app_stats_record (
     input clk
    ,input rst
    
    ,input                              echo_app_incr_req_done

    ,output logic                       log_wr_req_val
    ,output echo_app_stats_struct       log_wr_req_data
    
);

    logic   [echo_app_stats_pkg::TIMESTAMP_W-1:0]   timestamp_reg;

    logic   [echo_app_stats_pkg::TIMESTAMP_W-1:0]   countup_reg;
    logic   [echo_app_stats_pkg::TIMESTAMP_W-1:0]   countup_next;

    logic   [REQS_DONE_W-1:0]   reqs_done_reg;
    logic   [REQS_DONE_W-1:0]   reqs_done_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
            countup_reg <= '0;
            reqs_done_reg <= '0;
        end
        else begin
            timestamp_reg <= timestamp_reg + 1;
            countup_reg <= countup_next;
            reqs_done_reg <= reqs_done_next;
        end
    end

    assign log_wr_req_val = countup_reg == 1;
    assign log_wr_req_data.timestamp = timestamp_reg;
    assign log_wr_req_data.reqs_done = reqs_done_reg;

    assign countup_next = countup_reg == 1
                        ? '0
                        : echo_app_incr_req_done
                            ? countup_reg + 1'b1
                            : countup_reg;

    assign reqs_done_next = echo_app_incr_req_done
                            ? reqs_done_reg + 1'b1
                            : reqs_done_reg;
    
endmodule
