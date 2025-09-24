module notif_mgr_datap 
import mem_msg_pkg::*;
import tcp_pkg::*;
import apiary_noc_msg::*;
#(
    parameter MONITOR_DATA_W = -1
)(
     input clk
    ,input rst

    ,input  logic   [MONITOR_DATA_W-1:0]    src_notif_mgr_rx_data
    
    ,output logic   [CAP_TABLE_INDEX_W-1:0] datap_rx_index_wr_req_index
    ,output logic   [FLOWID_W-1:0]          datap_rx_index_wr_req_addr
    
    ,output logic   [CAP_TABLE_INDEX_W-1:0] datap_tx_index_wr_req_index
    ,output logic   [FLOWID_W-1:0]          datap_tx_index_wr_req_addr

    ,input  logic                           ctrl_datap_store_hdr
    ,input  logic                           ctrl_datap_store_index_line
    ,input  logic                           ctrl_datap_store_flow_info
    
    ,input  logic   [MAX_FLOW_CNT-1:0]      rx_index_vals
    ,input  logic   [MAX_FLOW_CNT-1:0]      tx_index_vals

    ,output buf_dir_e                       datap_ctrl_info_dir
    ,output logic                           datap_ctrl_bufs_valid

    ,output logic   [FLOWID_W-1:0]          datap_active_q_wr_req_data
);

    apiary_hdr_flit hdr_flit_reg;
    apiary_hdr_flit hdr_flit_next;

    logic   [MONITOR_DATA_W-1:0]    indices_line_reg;
    logic   [MONITOR_DATA_W-1:0]    indices_line_next;
    app_send_indices_line           indices_line_cast;

    logic   [CAP_TABLE_INDEX_W-1:0] first_index_cast;

    tcp_notif_flow_info             tcp_notif_info_reg;
    tcp_notif_flow_info             tcp_notif_info_next;

    assign first_index_cast = indices_line_reg[MONITOR_DATA_W-1-APP_SEND_INDICES_LINE_W -: CAP_TABLE_INDEX_W];

    assign datap_rx_index_wr_req_addr = tcp_notif_info_reg.flowid;
    assign datap_rx_index_wr_req_index = first_index_cast;
    assign datap_tx_index_wr_req_addr = tcp_notif_info_reg.flowid;
    assign datap_tx_index_wr_req_index = first_index_cast;

    assign datap_active_q_wr_req_data = tcp_notif_info_reg.flowid;

    assign datap_ctrl_info_dir = tcp_notif_info_reg.buf_dir;
    assign datap_ctrl_bufs_valid = rx_index_vals[tcp_notif_info_reg.flowid]
                                & tx_index_vals[tcp_notif_info_reg.flowid];



    assign indices_line_cast = indices_line_reg[MONITOR_DATA_W-1 -: APP_SEND_INDICES_LINE_W];

    always_ff @(posdege clk) begin
        hdr_flit_reg <= hdr_flit_next;
        indices_line_reg <= indices_line_next;
        tcp_notif_info_reg <= tcp_notif_info_next;
    end

    assign hdr_flit_next = ctrl_datap_store_index_line
                        ? src_notif_mgr_rx_data
                        : hdr_flit_reg;

    assign indices_line_next = ctrl_datap_store_index_line 
                            ? src_notif_mgr_rx_data
                            : indices_line_reg;

    assign tcp_notif_info_next = ctrl_datap_store_flow_info
                                ? src_notif_mgr_rx_data[MONITOR_DATA_W-1 -: TCP_NOTIF_FLOW_INFO_W]
                                : tcp_notif_info_reg;
endmodule