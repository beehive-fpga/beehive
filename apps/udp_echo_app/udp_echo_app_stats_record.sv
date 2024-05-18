`include "udp_echo_app_stats_defs.svh"
module udp_echo_app_stats_record #(
    parameter NUM_BYTES_W = `NOC_DATA_BYTES_W
)(
     input clk
    ,input rst

    ,input                                  app_stats_do_log
    ,input                                  app_stats_incr_bytes_sent
    ,input          [NUM_BYTES_W:0]         app_stats_num_bytes_sent

    ,output logic                           log_wr_req_val
    ,output         udp_app_stats_struct    log_wr_req_data
);

    logic   [MSG_TIMESTAMP_W-1:0]   timestamp_reg;
    logic   [MSG_TIMESTAMP_W-1:0]   countup_reg;
    logic   [MSG_TIMESTAMP_W-1:0]   countup_next;
    logic                           incr_countup;

    logic   [BYTES_RECV_W-1:0]      bytes_recv_reg;
    logic   [BYTES_RECV_W-1:0]      bytes_recv_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
            countup_reg <= '0;
            bytes_recv_reg <= '0;
        end
        else begin
            timestamp_reg <= timestamp_reg + 1;
            countup_reg <= countup_next;
            bytes_recv_reg <= bytes_recv_next;
        end
    end

    assign log_wr_req_val = (countup_reg == (RECORD_PERIOD-1)) & app_stats_do_log;
    assign log_wr_req_data.timestamp = timestamp_reg;
    assign log_wr_req_data.bytes_recv = bytes_recv_reg;

    assign countup_next = countup_reg == (RECORD_PERIOD-1)
                        ? '0
                        : countup_reg + 1'b1;

    assign bytes_recv_next = app_stats_incr_bytes_sent
                            ? bytes_recv_reg + app_stats_num_bytes_sent
                            : bytes_recv_reg;



endmodule
