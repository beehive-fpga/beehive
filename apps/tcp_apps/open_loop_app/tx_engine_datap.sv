module tx_engine_datap 
import tcp_pkg::*;
import open_loop_pkg::*;
import tx_open_loop_pkg::*;
import beehive_tcp_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input  send_q_struct                       send_q_rd_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]       tx_app_noc_vrtoc_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_tx_app_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       tx_ptr_if_ctrl_noc_data
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       ctrl_noc_tx_ptr_if_data

    ,output logic   [FLOWID_W-1:0]              datap_wr_buf_req_flowid
    ,output logic   [TX_PAYLOAD_PTR_W-1:0]      datap_wr_buf_req_wr_ptr
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_wr_buf_req_size

    ,output logic   [`NOC_DATA_WIDTH-1:0]       datap_wr_buf_req_data
    ,output logic                               datap_wr_buf_req_data_last
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   datap_wr_buf_req_data_padbytes

    ,output logic   [FLOWID_W-1:0]              tx_app_state_rd_flowid
    ,output logic   [FLOWID_W-1:0]              tx_app_state_wr_flowid

    ,input  app_cntxt_struct                    app_state_tx_rd_data
    ,output app_cntxt_struct                    tx_app_state_wr_data
    
    ,input  logic                               ctrl_datap_store_inputs
    ,input  logic                               ctrl_datap_store_app_state
    ,input  logic                               ctrl_datap_decr_bytes_left
    ,input  logic                               ctrl_datap_store_notif
    ,input  tx_out_mux_sel_e                    ctrl_datap_out_mux_sel
    
    ,output logic                               datap_ctrl_last_wr
    ,output logic                               datap_ctrl_last_pkt
    ,output flag_e                              datap_ctrl_should_copy
);
    
    localparam LINE_REP_COUNT = `NOC_DATA_WIDTH/$bits(flow_cntxt_reg.curr_reqs);
    
    send_q_struct send_q_data_reg;
    send_q_struct send_q_data_next;
    
    tcp_noc_hdr_flit    hdr_flit_cast;
    tcp_noc_hdr_flit    notif_hdr_flit_cast;
    
    notif_struct notif_reg;
    notif_struct notif_next;
    
    logic   [31:0]  wr_bytes_left_reg;
    logic   [31:0]  wr_bytes_left_next;
    
    logic   [`NOC_PADBYTES_WIDTH:0]   padbytes_calc;

    app_cntxt_struct    flow_cntxt_reg;
    app_cntxt_struct    flow_cntxt_next;

    logic   [`TOT_LEN_W-1:0] payload_len;

    assign notif_hdr_flit_cast = ctrl_noc_tx_ptr_if_data;
    assign tx_app_noc_vrtoc_data = hdr_flit_cast;
    assign tx_ptr_if_ctrl_noc_data = hdr_flit_cast;

    assign datap_wr_buf_req_wr_ptr = notif_reg.ptr[TX_PAYLOAD_PTR_W-1:0];
    assign datap_wr_buf_req_size = payload_len;

    assign datap_wr_buf_req_data = (send_q_data_reg.cmd == BENCH)
            ? {(LINE_REP_COUNT){flow_cntxt_reg.curr_reqs}}
            : `NOC_DATA_WIDTH'd1;
    assign datap_wr_buf_req_data_last = datap_ctrl_last_wr;
    assign datap_wr_buf_req_data_padbytes = datap_ctrl_last_wr
                    ? padbytes_calc[`NOC_PADBYTES_WIDTH-1:0]
                    : '0;

    assign tx_app_state_rd_flowid = send_q_data_reg.flowid;
    assign tx_app_state_wr_flowid = send_q_data_reg.flowid;
    assign datap_wr_buf_req_flowid = send_q_data_reg.flowid;

    assign datap_ctrl_last_pkt = flow_cntxt_reg.curr_reqs == (flow_cntxt_reg.total_reqs - 1);
    assign datap_ctrl_last_wr = wr_bytes_left_reg <= `NOC_DATA_BYTES;

    assign datap_ctrl_should_copy = flow_cntxt_reg.should_copy;

    assign padbytes_calc = (wr_bytes_left_reg[`NOC_PADBYTES_WIDTH-1:0] == 0)
                        ? '0
                        : 32 - wr_bytes_left_reg[`NOC_PADBYTES_WIDTH-1:0];
        
    assign payload_len = (send_q_data_reg.cmd == CTRL_RESP)
                            ? `NOC_DATA_BYTES
                            : flow_cntxt_reg.bufsize;

    assign wr_bytes_left_next = ctrl_datap_store_notif
                                ? payload_len
                                : ctrl_datap_decr_bytes_left
                                    ? wr_bytes_left_reg - `NOC_DATA_BYTES
                                    : wr_bytes_left_reg;

    always_ff @(posedge clk) begin
        send_q_data_reg <= send_q_data_next;
        notif_reg <= notif_next;
        flow_cntxt_reg <= flow_cntxt_next;
        wr_bytes_left_reg <= wr_bytes_left_next;
    end

    assign send_q_data_next = ctrl_datap_store_inputs
                            ? send_q_rd_data
                            : send_q_data_reg;

    assign flow_cntxt_next = ctrl_datap_store_app_state
                            ? app_state_tx_rd_data
                            : flow_cntxt_reg; 

    always_comb begin
        notif_next = notif_reg;
        if (ctrl_datap_store_notif) begin
            notif_next.ptr = notif_hdr_flit_cast.tail_ptr;
            notif_next.len = notif_hdr_flit_cast.length;
        end
    end

    always_comb begin
        tx_app_state_wr_data = flow_cntxt_reg;
        tx_app_state_wr_data.curr_reqs = flow_cntxt_reg.curr_reqs + 1'b1;
    end
    
    always_comb begin
        hdr_flit_cast = '0;
        hdr_flit_cast.core.dst_x_coord = TCP_TX_TILE_X;
        hdr_flit_cast.core.dst_y_coord = TCP_TX_TILE_Y;
        hdr_flit_cast.core.dst_fbits = TCP_TX_APP_PTR_IF_FBITS;
        hdr_flit_cast.core.msg_len = '0;
        hdr_flit_cast.core.msg_type = (ctrl_datap_out_mux_sel == PTR_UPDATE)
                                    ? TCP_TX_ADJUST_PTR
                                    : TCP_TX_MSG_REQ;
        hdr_flit_cast.core.src_x_coord = SRC_X;
        hdr_flit_cast.core.src_y_coord = SRC_Y;
        hdr_flit_cast.core.src_fbits = TX_IF_FBITS;

        hdr_flit_cast.flowid = send_q_data_reg.flowid;
        hdr_flit_cast.length = payload_len;
        hdr_flit_cast.tail_ptr = (ctrl_datap_out_mux_sel == PTR_UPDATE) 
                                ? notif_reg.ptr + payload_len
                                : '0;
    end
endmodule
