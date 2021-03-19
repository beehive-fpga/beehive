`include "echo_app_defs.svh"
module echo_app_tx_msg_if_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       tx_app_noc_vrtoc_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_tx_app_data

    ,input          tx_msg_struct               rx_if_tx_if_msg_data
    
    ,output logic   [FLOWID_W-1:0]              datap_wr_buf_req_flowid
    ,output logic   [TX_PAYLOAD_PTR_W:0]        datap_wr_buf_req_wr_ptr
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_wr_buf_req_size

    ,output logic   [`NOC_DATA_WIDTH-1:0]       datap_wr_buf_req_data
    ,output logic                               datap_wr_buf_req_data_last
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   datap_wr_buf_req_data_padbytes
    
    ,input  logic                               ctrl_datap_store_inputs
    ,input  logic                               ctrl_datap_decr_bytes_left
    ,input          buf_mux_sel_e               ctrl_datap_buf_mux_sel
    ,input  logic                               ctrl_datap_store_notif
    
    ,output logic                               datap_ctrl_last_wr

);

    localparam LINE_REP_COUNT = `NOC_DATA_WIDTH/256;
    tx_msg_struct msg_reg;
    tx_msg_struct msg_next;

    tcp_noc_hdr_flit    hdr_flit_cast;
    tcp_noc_hdr_flit    notif_hdr_flit_cast;

    notif_struct notif_reg;
    notif_struct notif_next;

    logic   [15:0]  wr_bytes_left_reg;
    logic   [15:0]  wr_bytes_left_next;
    
    logic   [`NOC_PADBYTES_WIDTH:0]   padbytes_calc;

    assign tx_app_noc_vrtoc_data = hdr_flit_cast;
    assign notif_hdr_flit_cast = noc_ctovr_tx_app_data;

    assign datap_wr_buf_req_flowid = msg_reg.flowid;
    assign datap_wr_buf_req_wr_ptr = notif_reg.ptr;
    assign datap_wr_buf_req_size = msg_reg.msg_len;
    assign datap_wr_buf_req_data = {(LINE_REP_COUNT){256'h41424344_45464748_494a4b4c_4d4e4f50_51525354_55565758_595a5b5c_5d5e5f60}};
    assign datap_wr_buf_req_data_last = datap_ctrl_last_wr;
    assign datap_wr_buf_req_data_padbytes = datap_ctrl_last_wr
                                        ? padbytes_calc[`NOC_PADBYTES_WIDTH-1:0]
                                        : '0;

    assign datap_ctrl_last_wr = wr_bytes_left_reg <= `NOC_DATA_BYTES;

    assign padbytes_calc = msg_reg.msg_len[`NOC_PADBYTES_WIDTH-1:0] == 0
                        ? '0
                        : 32 - msg_reg.msg_len[`NOC_PADBYTES_WIDTH-1:0];

    always_ff @(posedge clk) begin
        if (rst) begin
            msg_reg <= '0;
            wr_bytes_left_reg <= '0;
            notif_reg <= '0;
        end
        else begin
            msg_reg <= msg_next;
            wr_bytes_left_reg <= wr_bytes_left_next;
            notif_reg <= notif_next;
        end
    end

    always_comb begin
        notif_next = notif_reg;
        if (ctrl_datap_store_notif) begin
            notif_next.ptr = notif_hdr_flit_cast.tail_ptr;
            notif_next.len = notif_hdr_flit_cast.length; 
        end
        else begin
            notif_next = notif_reg;
        end
    end

    assign msg_next = ctrl_datap_store_inputs
                    ? rx_if_tx_if_msg_data
                    : msg_reg;

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            wr_bytes_left_next = msg_next.msg_len;
        end
        else if (ctrl_datap_decr_bytes_left) begin
            wr_bytes_left_next = wr_bytes_left_reg - `NOC_DATA_BYTES;
        end
        else begin
            wr_bytes_left_next = wr_bytes_left_reg;
        end
    end

    always_comb begin
        hdr_flit_cast = '0;
        hdr_flit_cast.core.dst_x_coord = TCP_TX_TILE_X;
        hdr_flit_cast.core.dst_y_coord = TCP_TX_TILE_Y;
        hdr_flit_cast.core.dst_fbits = TCP_TX_APP_PTR_IF_FBITS;
        hdr_flit_cast.core.msg_len = '0;
        hdr_flit_cast.core.msg_type = (ctrl_datap_buf_mux_sel == PTR_UPDATE)
                                    ? TCP_TX_ADJUST_PTR
                                    : TCP_TX_MSG_REQ;
        hdr_flit_cast.core.src_x_coord = SRC_X;
        hdr_flit_cast.core.src_y_coord = SRC_Y;
        hdr_flit_cast.core.src_fbits = TX_CTRL_IF_FBITS;

        hdr_flit_cast.flowid = msg_reg.flowid;
        hdr_flit_cast.length = msg_reg.msg_len;
        hdr_flit_cast.tail_ptr = notif_reg.ptr + msg_reg.msg_len;
    end
                                
endmodule
