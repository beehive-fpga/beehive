`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager_tx_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_ip_rewrite_manager_tx_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]       ip_rewrite_manager_tx_noc0_vrtoc_data

    ,input  logic   [`FLOW_ID_W-1:0]            in_datap_out_datap_resp_flowid
    ,input  logic   [`PAYLOAD_PTR_W:0]          in_datap_out_datap_resp_offset

    ,input  logic                               out_ctrl_out_datap_store_inputs
    ,input  ip_manager_tx_noc_sel               out_ctrl_out_datap_noc_sel
    ,input  logic                               out_ctrl_out_datap_store_notif
    ,input  ip_manager_tx_tile_sel              out_ctrl_out_datap_tile_sel

    ,output logic   [`FLOW_ID_W-1:0]            out_datap_wr_tx_buf_flowid
    ,output logic   [`PAYLOAD_PTR_W-1:0]        out_datap_wr_tx_buf_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  out_datap_wr_tx_buf_size

    ,output logic   [`NOC_DATA_WIDTH-1:0]       out_datap_wr_tx_buf_data
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   out_datap_wr_tx_buf_data_padbytes
);
    tcp_noc_hdr_flit hdr_flit_cast;
    tcp_noc_hdr_flit req_flit_cast;

    ip_rewrite_network_resp resp_cast;
    
    logic   [`FLOW_ID_W-1:0]        flowid_reg;
    logic   [`FLOW_ID_W-1:0]        flowid_next;

    logic   [`PAYLOAD_PTR_W:0]      rx_ptr_reg;
    logic   [`PAYLOAD_PTR_W:0]      rx_ptr_next;

    logic   [`PAYLOAD_PTR_W:0]      tx_ptr_reg;
    logic   [`PAYLOAD_PTR_W:0]      tx_ptr_next;
    
    assign hdr_flit_cast = noc0_ctovr_ip_rewrite_manager_tx_data;

    assign ip_rewrite_manager_tx_noc0_vrtoc_data = req_flit_cast;

    assign out_datap_wr_tx_buf_flowid = flowid_reg;
    assign out_datap_wr_tx_buf_offset = tx_ptr_reg;
    assign out_datap_wr_tx_buf_size = IP_REWRITE_NETWORK_RESP_BYTES;

    assign out_datap_wr_tx_buf_data = resp_cast;
    assign out_datap_wr_tx_buf_data_padbytes = '0;

    always_comb begin
        resp_cast = '0;
        resp_cast.status = OK;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            rx_ptr_reg <= '0;
            tx_ptr_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            rx_ptr_reg <= rx_ptr_next;
            tx_ptr_reg <= tx_ptr_next;
        end
    end

    assign flowid_next = out_ctrl_out_datap_store_inputs
                        ? in_datap_out_datap_resp_flowid
                        : flowid_reg;
    assign rx_ptr_next = out_ctrl_out_datap_store_inputs
                        ? in_datap_out_datap_resp_offset
                        : rx_ptr_reg;

    assign tx_ptr_next = out_ctrl_out_datap_store_notif
                        ? hdr_flit_cast.tail_ptr
                        : tx_ptr_reg;

    always_comb begin
        req_flit_cast = '0;
        if (out_ctrl_out_datap_noc_sel == TCP_TX_REQ) begin
            req_flit_cast.core.dst_x_coord = TCP_TX_TILE_X;
            req_flit_cast.core.dst_y_coord = TCP_TX_TILE_Y;
            req_flit_cast.core.dst_fbits = TCP_TX_APP_PTR_IF_FBITS;
            req_flit_cast.core.msg_type = TCP_TX_MSG_REQ;
            req_flit_cast.length = IP_REWRITE_NETWORK_RESP_BYTES;
        end
        else begin
            if (out_ctrl_out_datap_tile_sel == TCP_RX_APP_PTR_IF_FBITS) begin
                req_flit_cast.core.dst_x_coord = TCP_RX_TILE_X;
                req_flit_cast.core.dst_y_coord = TCP_RX_TILE_Y;
                req_flit_cast.core.dst_fbits = TCP_RX_APP_PTR_IF_FBITS;
                req_flit_cast.core.msg_type = TCP_RX_ADJUST_PTR;
                req_flit_cast.head_ptr = rx_ptr_reg + IP_REWRITE_NETWORK_REQ_BYTES;
            end
            else begin
                req_flit_cast.core.dst_x_coord = TCP_TX_TILE_X;
                req_flit_cast.core.dst_y_coord = TCP_TX_TILE_Y;
                req_flit_cast.core.dst_fbits = TCP_TX_APP_PTR_IF_FBITS;
                req_flit_cast.core.msg_type = TCP_TX_ADJUST_PTR;
                req_flit_cast.tail_ptr = tx_ptr_reg + IP_REWRITE_NETWORK_RESP_BYTES;
            end
        end

        req_flit_cast.core.msg_len = '0;
        req_flit_cast.core.src_x_coord = SRC_X;
        req_flit_cast.core.src_y_coord = SRC_Y;
        req_flit_cast.core.src_fbits = IP_REWRITE_MANAGER_TX_FBITS;
        req_flit_cast.flowid = flowid_reg;
    end

endmodule
