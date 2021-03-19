`include "soc_defs.vh"
`include "eth_latency_stats_defs.svh"
module eth_no_noc_log_record (
     input clk
    ,input rst

    ,input  logic                           eth_lat_wr_val
    ,input  logic   [`PKT_TIMESTAMP_W-1:0]  eth_lat_wr_timestamp

    ,output logic                           eth_lat_wr_log
    ,output eth_latency_stats_struct        eth_lat_wr_entry
);

    logic   [`PKT_TIMESTAMP_W-1:0] timestamp_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
        end
        else begin
            timestamp_reg <= timestamp_reg + 1'b1;
        end
    end

    assign eth_lat_wr_log = eth_lat_wr_val;

    assign eth_lat_wr_entry.start_timestamp = eth_lat_wr_timestamp;
    assign eth_lat_wr_entry.end_timestamp = timestamp_reg;
endmodule
