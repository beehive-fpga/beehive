`include "noc_defs.vh"
import tcp_logger_pkg::*;
module tcp_logger_param_checker (input clk);
    generate
        if (TCP_LOG_CLIENT_ADDR_W < TCP_LOG_ENTRIES_LOG_2) begin
            $error("The num entries response must be at least as large as the number of log entries");
        end

        // check that the number of entries response is actually a number of bytes
        if ((TCP_LOG_CLIENT_ADDR_W % 8) != 0) begin
            $error("Make sure the num entries response is an integral number of bytes");
        end
    endgenerate
    
    // check widths
    generate
        if ($bits(log_rd_resp_struct) > `NOC_DATA_WIDTH) begin
            $error("Log response too wide: %d", $bits(log_rd_resp_struct));
        end
        if ($bits(log_rd_req_struct) > `NOC_DATA_WIDTH) begin
            $error("Log request too wide: %d", $bits(log_rd_req_struct));
        end
    endgenerate

    generate
        if ($bits(log_rd_req_flit) != `NOC_DATA_WIDTH) begin
            $error("Log request flit wrong side: %d", $bits(log_rd_req_flit));
        end
        if ($bits(log_rd_resp_flit) != `NOC_DATA_WIDTH) begin
            $error("Log response flit wrong size: %d", $bits(log_rd_resp_flit));
        end
    endgenerate
endmodule
