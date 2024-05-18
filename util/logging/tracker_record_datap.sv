module tracker_record_datap 
    import beehive_noc_msg::*;
    import tracker_pkg::*;
#(
    parameter DATA_NOC_W=-1
)(
     input clk
    ,input rst
    
    ,input  logic   [DATA_NOC_W-1:0]            noc_wr_tracker_in_data
    
    ,output logic   [DATA_NOC_W-1:0]            wr_tracker_noc_out_data
    
    ,output logic                               datap_ctrl_filter_val
    ,output logic                               datap_ctrl_filter_record
    ,input  logic                               ctrl_datap_filter_rdy

    ,output logic                               datap_ctrl_last_flit

    ,input                                      ctrl_datap_store_hdr
    ,input                                      ctrl_datap_incr_flits

    ,output tracker_stats_struct                log_wr_req_data
);

    beehive_noc_hdr_flit hdr_flit_cast;

    logic [`MSG_LENGTH_WIDTH-1:0]   total_flits_reg;
    logic [`MSG_LENGTH_WIDTH-1:0]   total_flits_next;

    logic [`MSG_LENGTH_WIDTH-1:0]   curr_flits_reg;
    logic [`MSG_LENGTH_WIDTH-1:0]   curr_flits_next;

    logic   [MSG_TIMESTAMP_W-1:0]   timestamp_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
        end
        else begin
            total_flits_reg <= total_flits_next;
            curr_flits_reg <= curr_flits_next;
            timestamp_reg <= timestamp_reg + 1'b1;
        end
    end

    assign wr_tracker_noc_out_data = noc_wr_tracker_in_data;

    assign total_flits_next = ctrl_datap_store_hdr
                            ? hdr_flit_cast.core.core.msg_len
                              : total_flits_reg;

    assign hdr_flit_cast = noc_wr_tracker_in_data;

    assign log_wr_req_data.packet_id = hdr_flit_cast.core.packet_id;
    assign log_wr_req_data.timestamp = timestamp_reg;

    assign curr_flits_next = ctrl_datap_store_hdr
                            ? '0
                            : ctrl_datap_incr_flits
                                ? curr_flits_reg + 1'b1
                                : curr_flits_reg;

    assign datap_ctrl_last_flit = curr_flits_next == total_flits_next;

    assign datap_ctrl_filter_val = 1'b1;
    assign datap_ctrl_filter_record = 1'b1;
endmodule
