`include "noc_defs.vh"
module stats_manager_datap 
    import tcp_pkg::*;
    import beehive_tcp_msg::*;
    import stats_manager_pkg::*;
    import tracker_pkg::*;
#(
     parameter NOC0_DATA_W = -1
    ,parameter NOC1_DATA_W = -1
    ,parameter NOC0_DATA_BYTES = NOC0_DATA_W/8
    ,parameter NOC0_PADBYTES_W = $clog2(NOC0_DATA_BYTES)
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input  logic   [NOC0_DATA_W-1:0]           in_manager_noc0_data

    ,input  logic   [NOC0_DATA_W-1:0]           in_manager_notif_noc1_data

    ,output logic   [NOC0_DATA_W-1:0]           manager_out_notif_noc1_data

    ,input  logic                               ctrl_datap_store_new_flow
    ,input  logic                               ctrl_datap_store_notif
    ,input  logic                               ctrl_datap_store_req
    ,input  logic                               ctrl_datap_store_meta
    ,input  logic                               ctrl_datap_rx_notif_req
    ,input  logic                               ctrl_datap_make_req
    ,input  tracker_req_type                    ctrl_datap_req_type
    ,input  logic                               ctrl_datap_output_len
    
    ,output requester_input                     datap_requester_req

    ,input  logic   [NOC0_DATA_W-1:0]           requester_datap_resp_data
    ,input  logic                               requester_datap_resp_data_last

    ,output logic   [FLOWID_W-1:0]              datap_rd_buf_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      datap_rd_buf_req_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_rd_buf_req_size
    
    ,input  logic   [NOC0_DATA_W-1:0]           rd_buf_datap_resp_data
    ,input  logic                               rd_buf_datap_resp_data_last
    ,input  logic   [NOC0_PADBYTES_W-1:0]       rd_buf_datap_resp_data_padbytes
    
    ,output logic   [FLOWID_W-1:0]              datap_wr_buf_req_flowid
    ,output logic   [TX_PAYLOAD_PTR_W-1:0]      datap_wr_buf_req_wr_ptr
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  datap_wr_buf_req_size

    ,output logic   [NOC0_DATA_W-1:0]           datap_wr_buf_req_data
);
    localparam TRACKER_STATS_BYTES_SHIFT = $clog2(TRACKER_STATS_BYTES);
    localparam HDR_PADDING = NOC0_DATA_W - TRACKER_ADDR_W;
    logic   [FLOWID_W-1:0]  manager_flowid_reg;
    logic   [FLOWID_W-1:0]  manager_flowid_next;
    
    logic   [TRACKER_ADDR_W:0] num_entries;
    logic                       has_wrapped;


    tracker_flit    meta_flit_reg;
    tracker_flit    meta_flit_next;

    tracker_req_pkt req_reg;
    tracker_req_pkt req_next;

    tcp_flit_inner    notif_reg;
    tcp_flit_inner    notif_next;

    tcp_flit_inner      notif_req_cast;

    tcp_noc_hdr_flit tcp_hdr_flit_cast;
    tcp_noc_hdr_flit notif_flit_cast;

    tcp_noc_hdr_flit notif_recv_flit_cast;

    assign manager_out_notif_noc1_data = notif_flit_cast;

    assign tcp_hdr_flit_cast = in_manager_noc0_data;
    assign notif_recv_flit_cast = in_manager_notif_noc1_data;

    assign datap_rd_buf_req_flowid = manager_flowid_reg;
    assign datap_rd_buf_req_offset = notif_reg.head_ptr;
    assign datap_rd_buf_req_size = TRACKER_REQ_PKT_BYTES;

    assign datap_wr_buf_req_flowid = manager_flowid_reg;
    assign datap_wr_buf_req_wr_ptr = notif_reg.tail_ptr;

    // an extra line for the length
    assign datap_wr_buf_req_size = (num_entries << TRACKER_STATS_BYTES_SHIFT) + NOC0_DATA_BYTES;
    assign datap_wr_buf_req_data = ctrl_datap_output_len
                                ? {{HDR_PADDING{1'b0}},
                                    num_entries << TRACKER_STATS_BYTES_SHIFT}
                                : requester_datap_resp_data;
    assign datap_wr_buf_req_data_last = requester_datap_resp_data_last;

    always_comb begin
        datap_requester_req = '0;
        datap_requester_req.dst_x = req_reg.x_coord;
        datap_requester_req.dst_y = req_reg.y_coord;
        datap_requester_req.dst_fbits = TRACKER_FBITS;
        datap_requester_req.req_type = ctrl_datap_req_type;
        datap_requester_req.start_addr = meta_flit_reg.start_addr;
        datap_requester_req.end_addr = meta_flit_reg.end_addr;
    end

    always_ff @(posedge clk) begin
        manager_flowid_reg <= manager_flowid_next;
        meta_flit_reg <= meta_flit_next;
        notif_reg <= notif_next;
        req_reg <= req_next;
    end

    assign manager_flowid_next = ctrl_datap_store_new_flow
                                ? tcp_hdr_flit_cast.inner.flowid
                                : manager_flowid_reg;

    assign meta_flit_next = ctrl_datap_store_meta
                              ? requester_datap_resp_data[NOC0_DATA_W-1 -: TRACKER_FLIT_W]
                              : meta_flit_reg;

    assign req_next = ctrl_datap_store_req
                    ? rd_buf_datap_resp_data[NOC0_DATA_W-1 -: TRACKER_REQ_PKT_W]
                    : req_reg;

    assign notif_next = ctrl_datap_store_notif
                        ? notif_recv_flit_cast.inner
                        : notif_reg;

    assign has_wrapped = meta_flit_reg.end_addr + 1'b1 == meta_flit_reg.start_addr;
    assign num_entries = {has_wrapped, meta_flit_reg.end_addr} - {1'b0, meta_flit_reg.start_addr};
    
    logic   [MAX_PAYLOAD_PTR_W-1:0] payload_len;

    assign payload_len = (num_entries << TRACKER_STATS_BYTES_SHIFT) + NOC0_DATA_BYTES;

    always_comb begin
        notif_req_cast = '0;
        notif_req_cast.flowid = manager_flowid_reg;
        notif_req_cast.head_ptr = notif_reg.head_ptr + TRACKER_REQ_PKT_BYTES;
        notif_req_cast.tail_ptr = notif_reg.tail_ptr + payload_len;
        if (ctrl_datap_rx_notif_req) begin
            notif_req_cast.length = TRACKER_REQ_PKT_BYTES;
        end
        else begin
            notif_req_cast.length = payload_len;
        end
    end


    always_comb begin
        notif_flit_cast = '0;
        notif_flit_cast.core.msg_len = '0;
        notif_flit_cast.core.src_x_coord = SRC_X;
        notif_flit_cast.core.src_y_coord = SRC_Y;
        notif_flit_cast.core.src_fbits = PTR_IF_FBITS;
        notif_flit_cast.inner = notif_req_cast;

        if (ctrl_datap_rx_notif_req) begin
            notif_flit_cast.core.dst_x_coord = TCP_RX_TILE_X;
            notif_flit_cast.core.dst_y_coord = TCP_RX_TILE_Y;
            notif_flit_cast.core.dst_fbits = TCP_RX_APP_PTR_IF_FBITS;
            notif_flit_cast.core.msg_len = '0;
            notif_flit_cast.core.msg_type = ctrl_datap_make_req
                                            ? TCP_RX_MSG_REQ
                                            : TCP_RX_ADJUST_PTR;
        end
        else begin
            notif_flit_cast.core.dst_x_coord = TCP_TX_TILE_X;
            notif_flit_cast.core.dst_y_coord = TCP_TX_TILE_Y;
            notif_flit_cast.core.dst_fbits = TCP_TX_APP_PTR_IF_FBITS;
            notif_flit_cast.core.msg_type = ctrl_datap_make_req
                                        ? TCP_TX_MSG_REQ
                                        : TCP_TX_ADJUST_PTR;
        end
    end

    // do some parameter verification
    initial begin
        if (TRACKER_STATS_BYTES & (TRACKER_STATS_BYTES-1) != 0) begin
            $error("Tracker stats struct is not a power of 2 bytes. Check multiplication");
        end
    end

endmodule
