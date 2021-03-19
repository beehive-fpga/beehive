`include "echo_app_defs.svh"
module echo_app_rx_msg_if_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,output logic   [`NOC_DATA_WIDTH-1:0]       rx_app_noc_vrtoc_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_rx_app_data

    ,input  logic   [FLOWID_W-1:0]              active_q_msg_if_rd_data

    ,output logic   [FLOWID_W-1:0]              msg_if_active_q_wr_data
    
    ,output         tx_msg_struct               rx_if_tx_if_msg_data
    
    ,output logic   [FLOWID_W-1:0]              datap_rd_buf_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W:0]        datap_rd_buf_req_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_rd_buf_req_size

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       rd_buf_datap_resp_data
    ,input  logic                               rd_buf_datap_resp_data_last
    ,input  logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_buf_datap_resp_data_padbytes

    ,input  logic                               ctrl_datap_store_flowid
    ,input  logic                               ctrl_datap_store_hdr
    ,input  logic                               ctrl_datap_store_notif
    ,input          buf_mux_sel_e               ctrl_datap_buf_mux_sel

    ,output logic                               datap_ctrl_last_req
);

    tcp_noc_hdr_flit    hdr_flit_cast;
    tcp_noc_hdr_flit    req_hdr_flit;

    logic   [FLOWID_W-1:0]    flowid_reg;
    logic   [FLOWID_W-1:0]    flowid_next;

    app_hdr_struct hdr_reg;
    app_hdr_struct hdr_next;

    notif_struct notif_reg;
    notif_struct notif_next;

    assign hdr_flit_cast = noc_ctovr_rx_app_data;

    assign rx_app_noc_vrtoc_data = req_hdr_flit;

    assign msg_if_active_q_wr_data = flowid_reg;

    assign rx_if_tx_if_msg_data.msg_len = hdr_reg.wr_len;
    assign rx_if_tx_if_msg_data.flowid = flowid_reg;
    assign rx_if_tx_if_msg_data.head_ptr = notif_reg.ptr;

    assign datap_rd_buf_req_flowid = flowid_reg;
    assign datap_rd_buf_req_offset = notif_reg.ptr;
    assign datap_rd_buf_req_size = (ctrl_datap_buf_mux_sel == HDR_VALUES)
                                ? APP_HDR_STRUCT_BYTES
                                : hdr_reg.rd_len;

    assign datap_ctrl_last_req = hdr_reg.last;

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            hdr_reg <= '0;
            notif_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            hdr_reg <= hdr_next;
            notif_reg <= notif_next;
        end
    end

    assign flowid_next = ctrl_datap_store_flowid
                        ? active_q_msg_if_rd_data
                        : flowid_reg;
    assign hdr_next = ctrl_datap_store_hdr
                    ? rd_buf_datap_resp_data[`NOC_DATA_WIDTH-1 -: APP_HDR_STRUCT_W]
                    : hdr_reg;

    always_comb begin
        notif_next = notif_reg;
        if (ctrl_datap_store_notif) begin
            notif_next.ptr = hdr_flit_cast.head_ptr;
            notif_next.len = hdr_reg.rd_len;
        end
        else begin
            notif_next = notif_reg;
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
        req_hdr_flit.core.src_fbits = RX_CTRL_IF_FBITS;

        req_hdr_flit.flowid = flowid_reg;

        req_hdr_flit.length = (ctrl_datap_buf_mux_sel == HDR_VALUES)
                            ? APP_HDR_STRUCT_BYTES
                            // we need to request plus the app headers, because
                            // we don't consume it until the pointer update at
                            // the end
                            : hdr_reg.rd_len + APP_HDR_STRUCT_BYTES;
        
        if (ctrl_datap_buf_mux_sel == PTR_UPDATE) begin
            req_hdr_flit.core.msg_type = TCP_RX_ADJUST_PTR;
            req_hdr_flit.head_ptr = notif_reg.ptr + hdr_reg.rd_len + APP_HDR_STRUCT_BYTES;
        end
        else begin
            req_hdr_flit.core.msg_type = TCP_RX_MSG_REQ;
        end
    end

    
endmodule
