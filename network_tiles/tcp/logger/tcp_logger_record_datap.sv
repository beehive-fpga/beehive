`include "tcp_logger_record_defs.svh"
module tcp_logger_record_datap #(
     parameter LOG_ENTRIES_LOG_2 = -1
    ,parameter LOG_ADDR_W = LOG_ENTRIES_LOG_2 
    ,parameter FORWARD_X = -1
    ,parameter FORWARD_Y = -1
)(
     input clk
    ,input rst

    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_logger_record_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]   logger_record_noc0_data

    ,output logic   [LOG_ADDR_W-1:0]        wr_logger_mem_addr
    ,output log_entry_struct                wr_logger_mem_entry

    ,input  logic                           ctrl_datap_store_len
    ,input  logic                           ctrl_datap_incr_addr
    ,input  logic                           ctrl_datap_incr_num_flits
    ,input  logic                           ctrl_datap_store_hdr
    ,input  logic                           ctrl_datap_mod_hdr_flit

    ,output logic                           datap_ctrl_last_flit

    ,output logic                           datap_ctrl_log_full

    ,output logic   [LOG_ADDR_W:0]          recorder_read_curr_addr
);
    beehive_noc_hdr_flit hdr_cast;
    beehive_noc_hdr_flit mod_hdr_cast;
    ip_rx_metadata_flit meta_cast;
    log_entry_struct log_entry_cast;
    tcp_pkt_hdr tcp_hdr_cast;

    logic   [tcp_logger_pkg::TIMESTAMP_W-1:0]   timestamp_reg;
    logic   [LOG_ADDR_W:0]    log_addr_reg;
    logic   [LOG_ADDR_W:0]    log_addr_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] flits_read_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flits_read_next;
    logic   [`MSG_LENGTH_WIDTH-1:0] num_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] num_flits_next;

    logic   [`TOT_LEN_W-1:0]    pkt_len_reg;
    logic   [`TOT_LEN_W-1:0]    pkt_len_next;

    assign hdr_cast = noc0_logger_record_data;
    assign meta_cast = noc0_logger_record_data;
    assign tcp_hdr_cast = noc0_logger_record_data[`NOC_DATA_WIDTH-1 -: TCP_HDR_W];

    assign log_entry_cast.timestamp = timestamp_reg;
    assign log_entry_cast.pkt_len = pkt_len_reg;
    assign log_entry_cast.log_pkt_hdr = tcp_hdr_cast;

    assign wr_logger_mem_entry = log_entry_cast;
    assign wr_logger_mem_addr = log_addr_reg[LOG_ADDR_W-1:0];

    assign recorder_read_curr_addr = log_addr_reg;

    assign datap_ctrl_log_full = log_addr_reg == {1'b1, {LOG_ADDR_W{1'b0}}};

    assign log_addr_next = ctrl_datap_incr_addr
                        ? log_addr_reg + 1'b1
                        : log_addr_reg;
    assign pkt_len_next = ctrl_datap_store_len
                        ? meta_cast.data_payload_len
                        : pkt_len_reg;

    assign num_flits_next = ctrl_datap_store_hdr
                        ? hdr_cast.core.msg_len
                        : num_flits_reg;

    assign datap_ctrl_last_flit = flits_read_reg == (num_flits_reg - 1'b1);

    always_comb begin
        mod_hdr_cast = hdr_cast;
        mod_hdr_cast.core.dst_x_coord = FORWARD_X;
        mod_hdr_cast.core.dst_y_coord = FORWARD_Y;
    end

    always_comb begin
        if (ctrl_datap_mod_hdr_flit) begin
            logger_record_noc0_data = mod_hdr_cast;
        end
        else begin
            logger_record_noc0_data = noc0_logger_record_data;
        end
    end

    always_comb begin
        if (ctrl_datap_store_hdr) begin
            flits_read_next = '0;
        end
        else if (ctrl_datap_incr_num_flits) begin
            flits_read_next = flits_read_reg + 1'b1;
        end
        else begin
            flits_read_next = flits_read_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            timestamp_reg <= '0;
            log_addr_reg <= '0;
        end
        else begin
            timestamp_reg <= timestamp_reg + 1;
            log_addr_reg <= log_addr_next;
            flits_read_reg <= flits_read_next;
            num_flits_reg <= num_flits_next;
            pkt_len_reg <= pkt_len_next;
        end
    end
endmodule
