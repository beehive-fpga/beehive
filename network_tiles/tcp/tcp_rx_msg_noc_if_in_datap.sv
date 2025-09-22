`include "noc_defs.vh"
module tcp_rx_msg_noc_if_in_datap 
import apiary_noc_msg::*;
import beehive_tcp_msg::*;
import tcp_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_tcp_rx_ptr_if_data
    
    ,output logic   [FLOWID_W-1:0]              noc_if_poller_msg_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      noc_if_poller_msg_req_len
    ,output logic   [`MSG_SRC_X_WIDTH-1:0]      noc_if_poller_msg_dst_x
    ,output logic   [`MSG_SRC_Y_WIDTH-1:0]      noc_if_poller_msg_dst_y
    ,output logic   [`MSG_SRC_FBITS_WIDTH-1:0]  noc_if_poller_msg_dst_fbits

    ,output logic   [FLOWID_W-1:0]              app_rx_head_ptr_wr_req_addr
    ,output logic   [RX_PAYLOAD_PTR_W:0]        app_rx_head_ptr_wr_req_data

    ,input  logic                               ctrl_datap_store_hdr_flit
    ,input  logic                               ctrl_datap_store_body_flit

    ,output logic   [`MSG_TYPE_WIDTH-1:0]       datap_ctrl_msg_type
);

    apiary_hdr_flit hdr_flit_reg;
    apiary_hdr_flit hdr_flit_next;

    tcp_noc_body_flit body_flit_reg;
    tcp_noc_body_flit body_flit_next;

    assign app_rx_head_ptr_wr_req_addr = body_flit_reg.flowid;
    assign app_rx_head_ptr_wr_req_data = body_flit_reg.head_ptr;
    
    assign datap_ctrl_msg_type = hdr_flit_reg.core.msg_type;

    assign noc_if_poller_msg_req_flowid = body_flit_reg.flowid;
    assign noc_if_poller_msg_req_len = body_flit_reg.length;
    assign noc_if_poller_msg_dst_x = hdr_flit_reg.core.src_x_coord;
    assign noc_if_poller_msg_dst_y = hdr_flit_reg.core.src_y_coord;
    assign noc_if_poller_msg_dst_fbits = hdr_flit_reg.core.src_fbits;

    always_ff @(posedge clk) begin
        hdr_flit_reg <= hdr_flit_next;
        body_flit_reg <= body_flit_next;
    end

    assign hdr_flit_next = ctrl_datap_store_hdr_flit
                        ? noc_tcp_rx_ptr_if_data
                        : hdr_flit_reg;

    assign body_flit_next = ctrl_datap_store_body_flit
                        ? noc_tcp_rx_ptr_if_data
                        : body_flit_reg;


endmodule
