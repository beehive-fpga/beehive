module rx_engine_datap 
import tcp_pkg::*;
import open_loop_pkg::*;
import rx_open_loop_pkg::*;
import beehive_tcp_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)
(
     input clk
    ,input rst

    ,input  logic   [FLOWID_W-1:0]              recv_q_rd_data

    ,output logic   [FLOWID_W-1:0]              recv_q_wr_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]       rx_app_noc_vrtoc_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_rx_app_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       rx_engine_ctrl_noc_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       ctrl_noc_rx_engine_data
 
    ,output logic   [FLOWID_W-1:0]              rx_app_state_rd_flowid

    ,output app_cntxt_struct                    rx_app_state_wr_data
    ,output logic   [FLOWID_W-1:0]              rx_app_state_wr_flowid

    ,input  app_cntxt_struct                    app_state_rx_rd_data
    
    ,output logic   [FLOWID_W-1:0]              datap_rd_buf_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      datap_rd_buf_req_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_rd_buf_req_size
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       rd_buf_datap_resp_data
    ,input  logic                               rd_buf_datap_resp_data_last
    ,input  logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_buf_datap_resp_data_padbytes
    
    ,input  logic                               ctrl_datap_store_inputs
    ,input  logic                               ctrl_datap_store_app_state
    ,input  logic                               ctrl_datap_store_notif
    ,input  rx_out_mux_sel_e                    ctrl_datap_out_mux_sel

    ,output logic                               datap_ctrl_last_pkt
    ,output logic                               datap_ctrl_last_data
    ,output flag_e                              datap_ctrl_should_copy
);

    logic   [FLOWID_W-1:0]  recv_q_data_reg;
    logic   [FLOWID_W-1:0]  recv_q_data_next;

    app_cntxt_struct        flow_cntxt_reg;
    app_cntxt_struct        flow_cntxt_next;
    
    tcp_noc_hdr_flit        req_hdr_flit;
    tcp_noc_hdr_flit        notif_hdr_flit_cast;
    
    notif_struct            notif_reg;
    notif_struct            notif_next;

    assign recv_q_wr_data = recv_q_data_reg;

    assign rx_app_state_wr_flowid = recv_q_data_reg;
    assign rx_app_state_rd_flowid = recv_q_data_reg;

    assign notif_hdr_flit_cast = ctrl_noc_rx_engine_data;

    assign rx_app_noc_vrtoc_data = req_hdr_flit;
    assign rx_engine_ctrl_noc_data = req_hdr_flit;

    assign datap_rd_buf_req_flowid = recv_q_data_reg;
    assign datap_rd_buf_req_offset = notif_reg.ptr[RX_PAYLOAD_PTR_W-1:0];
    assign datap_rd_buf_req_size = flow_cntxt_reg.bufsize;

    assign datap_ctrl_last_pkt = flow_cntxt_reg.curr_reqs == (flow_cntxt_reg.total_reqs - 1);
    assign datap_ctrl_last_data = rd_buf_datap_resp_data_last;

    assign datap_ctrl_should_copy = flow_cntxt_reg.should_copy;

    always_ff @(posedge clk) begin
        recv_q_data_reg <= recv_q_data_next;
        flow_cntxt_reg <= flow_cntxt_next;
        notif_reg <= notif_next;
    end

    assign recv_q_data_next = ctrl_datap_store_inputs
                            ? recv_q_rd_data
                            : recv_q_data_reg;
    assign flow_cntxt_next = ctrl_datap_store_app_state
                            ? app_state_rx_rd_data
                            : flow_cntxt_reg;

    always_comb begin
        rx_app_state_wr_data = flow_cntxt_reg;
        rx_app_state_wr_data.curr_reqs = flow_cntxt_reg.curr_reqs + 1'b1;
    end

    always_comb begin
        notif_next = notif_reg;
        if (ctrl_datap_store_notif) begin
            notif_next.ptr = notif_hdr_flit_cast.head_ptr;
            notif_next.len = flow_cntxt_reg.bufsize;
        end
    end
    
    always_comb begin
        req_hdr_flit = '0;
        req_hdr_flit.core.dst_x_coord = TCP_RX_TILE_X;
        req_hdr_flit.core.dst_y_coord = TCP_RX_TILE_Y;
        req_hdr_flit.core.dst_fbits = TCP_RX_APP_PTR_IF_FBITS;
        req_hdr_flit.core.msg_len = '0;
        req_hdr_flit.core.src_x_coord = SRC_X;
        req_hdr_flit.core.src_y_coord = SRC_Y;
        req_hdr_flit.core.src_fbits = RX_IF_FBITS;

        req_hdr_flit.flowid = recv_q_data_reg;

        req_hdr_flit.length = flow_cntxt_reg.bufsize;
        
        if (ctrl_datap_out_mux_sel == PTR_UPDATE) begin
            req_hdr_flit.core.msg_type = TCP_RX_ADJUST_PTR;
            req_hdr_flit.head_ptr = notif_reg.ptr + flow_cntxt_reg.bufsize;
        end
        else begin
            req_hdr_flit.core.msg_type = TCP_RX_MSG_REQ;
        end
    end
endmodule
