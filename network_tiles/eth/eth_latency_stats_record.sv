`include "eth_latency_stats_defs.svh"
module eth_latency_stats_record (
     input clk
    ,input rst

    ,input                                      eth_wr_log
    ,input          [MSG_TIMESTAMP_W-1:0]       eth_wr_log_start_timestamp

    ,output                                     log_wr_req_val
    ,output         eth_latency_stats_struct    log_wr_req_data
);

    logic   [MSG_TIMESTAMP_W-1:0]   timestamp_reg;

    eth_latency_stats_struct    log_entry_cast;

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
        end
        else begin
            timestamp_reg <= timestamp_reg + 1'b1;
        end
    end

    assign log_wr_req_val = eth_wr_log;
    assign log_wr_req_data = log_entry_cast;
    
    always_comb begin
        log_entry_cast = '0;
        log_entry_cast.start_timestamp = eth_wr_log_start_timestamp;
        log_entry_cast.end_timestamp = timestamp_reg;
    end
endmodule
