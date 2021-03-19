`include "rs_encode_stats_defs.svh"
module rs_encode_stats_record #(
    parameter NUM_BYTES_W = `NOC_DATA_BYTES_W
)(
     input clk
    ,input rst
    
    ,input                                  rs_enc_incr_bytes_sent
    ,input          [NUM_BYTES_W:0]         rs_enc_num_bytes_sent
    ,input                                  rs_enc_incr_reqs_done
    
    ,output logic                           log_wr_req_val
    ,output rs_enc_stats_struct             log_wr_req_data
);

    logic   [TIMESTAMP_W-1:0]   timestamp_reg;
    logic   [TIMESTAMP_W-1:0]   timestamp_next;

    logic   [TIMESTAMP_W-1:0]   countup_reg;
    logic   [TIMESTAMP_W-1:0]   countup_next;

    logic                       incr_countup;

    logic   [BYTES_SENT_W-1:0]  bytes_sent_reg;
    logic   [BYTES_SENT_W-1:0]  bytes_sent_next;

    logic   [REQS_DONE_W-1:0]   reqs_done_reg;
    logic   [REQS_DONE_W-1:0]   reqs_done_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
            countup_reg <= '0;
            bytes_sent_reg <= '0;
            reqs_done_reg <= '0;
        end
        else begin
            timestamp_reg <= timestamp_reg + 1;
            countup_reg <= countup_next;
            bytes_sent_reg <= bytes_sent_next;
            reqs_done_reg <= reqs_done_next;
        end
    end

    assign log_wr_req_val = countup_reg == (RECORD_PERIOD-1);
    assign log_wr_req_data.timestamp = timestamp_reg;
    assign log_wr_req_data.bytes_sent = bytes_sent_reg;
    assign log_wr_req_data.reqs_done = reqs_done_reg;

    assign countup_next = countup_reg == (RECORD_PERIOD-1)
                        ? '0
                        : countup_reg + 1'b1;

    assign bytes_sent_next = rs_enc_incr_bytes_sent
                            ? bytes_sent_reg + rs_enc_num_bytes_sent
                            : bytes_sent_reg;

    assign reqs_done_next = rs_enc_incr_reqs_done
                            ? reqs_done_reg + 1'b1
                            : reqs_done_reg;


endmodule
