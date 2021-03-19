`include "simple_log_udp_noc_read_defs.svh"
module simple_log_udp_noc_read_64 (
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter ADDR_W = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter CLIENT_ADDR_W = -1
    ,parameter NOC1_DATA_W=-1
    ,parameter NOC2_DATA_W=-1
)(
     input clk
    ,input rst
    
    ,input                                      ctovr_reader_in_val
    ,input          [NOC1_DATA_W-1:0]           ctovr_reader_in_data
    ,output logic                               reader_in_ctovr_rdy
    
    ,output logic                               reader_out_vrtoc_val
    ,output logic   [NOC2_DATA_W-1:0]           reader_out_vrtoc_data
    ,input                                      vrtoc_reader_out_rdy

    ,output logic                               log_rd_req_val
    ,output logic   [ADDR_W-1:0]                log_rd_req_addr
    
    ,input  logic                               log_rd_resp_val
    ,input  logic   [RESP_DATA_STRUCT_W-1:0]    log_rd_resp_data

    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped
);
endmodule
