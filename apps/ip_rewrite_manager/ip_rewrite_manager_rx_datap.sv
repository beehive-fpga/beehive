`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager_rx_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_ip_rewrite_manager_rx_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       ip_rewrite_manager_rx_noc0_vrtoc_data
    
    ,input  logic                               in_ctrl_in_datap_store_flow_notif
    ,input  ip_manager_noc_sel                  in_ctrl_in_datap_noc_sel
    ,input  ip_manager_tile_sel                 in_ctrl_in_datap_tile_sel
    ,input  ip_manager_if_sel                   in_ctrl_in_datap_if_sel
    ,input  logic                               in_ctrl_in_datap_store_req_notif
    ,input  logic                               in_ctrl_in_datap_store_rewrite_req
   
    ,output logic   [`FLOW_ID_W-1:0]            in_datap_rd_rx_buf_flowid
    ,output logic   [`RX_PAYLOAD_PTR_W-1:0]     in_datap_rd_rx_buf_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  in_datap_rd_rx_buf_size

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       rd_rx_buf_resp_data

    ,output logic   [`FLOW_ID_W-1:0]            in_datap_out_datap_resp_flowid
    ,output logic   [`PAYLOAD_PTR_W:0]          in_datap_out_datap_resp_offset
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_rewrite_ctrl_in_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]       rewrite_ctrl_noc_out_data
);

    tcp_noc_hdr_flit hdr_flit_cast;

    tcp_noc_hdr_flit tcp_req_hdr_flit;
    beehive_noc_hdr_flit rewrite_hdr_flit;
    ip_rewrite_table_flit rewrite_body_flit;

    logic   [`FLOW_ID_W-1:0]    flowid_reg;
    logic   [`FLOW_ID_W-1:0]    flowid_next;

    logic   [`PAYLOAD_PTR_W:0]  rx_ptr_reg;
    logic   [`PAYLOAD_PTR_W:0]  rx_ptr_next;

    ip_rewrite_network_req      req_cast;
    ip_rewrite_table_req        rewrite_req_reg;
    ip_rewrite_table_req        rewrite_req_next;

    assign hdr_flit_cast = noc0_ctovr_ip_rewrite_manager_rx_data;
    assign req_cast = rd_rx_buf_resp_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            rx_ptr_reg <= '0;
            rewrite_req_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            rx_ptr_reg <= rx_ptr_next;
            rewrite_req_reg <= rewrite_req_next;
        end
    end

    assign in_datap_rd_rx_buf_flowid = flowid_reg;
    assign in_datap_rd_rx_buf_offset = rx_ptr_reg;
    assign in_datap_rd_rx_buf_size = IP_REWRITE_NETWORK_REQ_BYTES;

    assign flowid_next = in_ctrl_in_datap_store_flow_notif
                        ? hdr_flit_cast.flowid
                        : flowid_reg;

    assign in_datap_out_datap_resp_flowid = flowid_reg;
    assign in_datap_out_datap_resp_offset = rx_ptr_reg;

    assign rewrite_req_next = in_ctrl_in_datap_store_rewrite_req
        ? req_cast.rewrite_req
        : rewrite_req_reg;

    assign rx_ptr_next = in_ctrl_in_datap_store_req_notif
                        ? hdr_flit_cast.head_ptr
                        : rx_ptr_reg;

    always_comb begin
        tcp_req_hdr_flit = '0;
        tcp_req_hdr_flit.core.dst_x_coord = TCP_RX_TILE_X;
        tcp_req_hdr_flit.core.dst_y_coord = TCP_RX_TILE_Y;
        tcp_req_hdr_flit.core.dst_fbits = TCP_RX_APP_PTR_IF_FBITS;
        tcp_req_hdr_flit.core.msg_len = '0;
        tcp_req_hdr_flit.core.src_x_coord = SRC_X;
        tcp_req_hdr_flit.core.src_y_coord = SRC_Y;
        tcp_req_hdr_flit.core.src_fbits = IP_REWRITE_MANAGER_RX_FBITS;
        if (in_ctrl_in_datap_if_sel == TCP_RX_PTR_UPDATE) begin
            tcp_req_hdr_flit.core.msg_type = TCP_RX_ADJUST_PTR;
            tcp_req_hdr_flit.head_ptr = rx_ptr_reg + IP_REWRITE_NETWORK_REQ_BYTES;
        end
        else begin
            tcp_req_hdr_flit.core.msg_type = TCP_RX_MSG_REQ;
        end
        tcp_req_hdr_flit.flowid = flowid_reg;

        tcp_req_hdr_flit.length = IP_REWRITE_NETWORK_REQ_BYTES;
    end

    always_comb begin
        rewrite_hdr_flit = '0;
        rewrite_hdr_flit.core.dst_fbits = IP_REWRITE_TABLE_CTRL_FBITS;
        rewrite_hdr_flit.core.msg_len = `MSG_LENGTH_WIDTH'd1;
        rewrite_hdr_flit.core.src_x_coord = SRC_X;
        rewrite_hdr_flit.core.src_y_coord = SRC_Y;
        rewrite_hdr_flit.core.src_fbits = IP_REWRITE_TABLE_CTRL_FBITS;
        rewrite_hdr_flit.core.msg_type = IP_REWRITE_ADJUST_TABLE;

        if (in_ctrl_in_datap_tile_sel == RX_REWRITE) begin
            rewrite_hdr_flit.core.dst_x_coord = IP_REWRITE_RX_TILE_X;
            rewrite_hdr_flit.core.dst_y_coord = IP_REWRITE_RX_TILE_Y;
        end
        else begin
            rewrite_hdr_flit.core.dst_x_coord = IP_REWRITE_TX_TILE_X;
            rewrite_hdr_flit.core.dst_y_coord = IP_REWRITE_TX_TILE_Y;
        end
    end

    always_comb begin
        rewrite_body_flit = '0;
        rewrite_body_flit.req = rewrite_req_reg;
        // we need to flip this, because we'll be seeing the old address on the
        // transmit path and we want to write with the new address
        if (in_ctrl_in_datap_tile_sel == TX_REWRITE) begin
            rewrite_body_flit.req.their_ip = rewrite_req_reg.rewrite_addr;
            rewrite_body_flit.req.rewrite_addr = rewrite_req_reg.their_ip;
        end
    end
        
    assign ip_rewrite_manager_rx_noc0_vrtoc_data = tcp_req_hdr_flit;



    always_comb begin
        if (in_ctrl_in_datap_noc_sel == REWRITE_NOTIF_HDR) begin
            rewrite_ctrl_noc_out_data = rewrite_hdr_flit;
        end
        else begin
            rewrite_ctrl_noc_out_data = rewrite_body_flit;
        end
    end


endmodule
