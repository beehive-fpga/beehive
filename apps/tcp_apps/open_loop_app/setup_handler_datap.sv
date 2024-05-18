`include "noc_defs.vh"
module setup_handler_datap 
import tcp_pkg::*;
import setup_open_loop_pkg::*;
import open_loop_pkg::*;
import tx_open_loop_pkg::*;
import beehive_tcp_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input  logic   [FLOWID_W-1:0]              setup_q_handler_flowid
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       setup_noc_vrtoc_data
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_ctovr_setup_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       setup_ptr_if_ctrl_noc_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       ctrl_noc_setup_ptr_if_data

    ,output logic   [FLOWID_W-1:0]              setup_rd_buf_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      setup_rd_buf_req_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  setup_rd_buf_req_size
    
    ,output logic   [FLOWID_W-1:0]              setup_wr_buf_req_flowid
    ,output logic   [RX_PAYLOAD_PTR_W-1:0]      setup_wr_buf_req_offset
    ,output logic   [`MSG_DATA_SIZE_WIDTH-1:0]  setup_wr_buf_req_size
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       setup_wr_buf_req_data

    ,input  logic   [`NOC_DATA_WIDTH-1:0]       rd_buf_setup_resp_data
    ,input  logic                               rd_buf_setup_resp_data_last
    ,input  logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_buf_setup_resp_padbytes

    ,output         app_cntxt_struct            setup_app_mem_wr_data
    ,output logic   [FLOWID_W-1:0]              setup_app_mem_wr_addr

    ,output send_q_struct                       setup_send_loop_q_wr_data
    
    ,output logic   [FLOWID_W-1:0]              setup_recv_loop_q_wr_flowid

    ,input  logic                               ctrl_datap_store_flowid
    ,input  logic                               ctrl_datap_store_notif
    ,input  logic                               ctrl_datap_store_hdr
    ,input          buf_mux_sel_e               ctrl_datap_buf_mux_sel
    ,input  logic                               ctrl_datap_send_setup_confirm
    
    ,input  logic                               ctrl_datap_incr_bytes_written
    ,input  logic                               ctrl_datap_reset_bytes_written
    
    ,input  logic                               ctrl_datap_save_conn

    ,output         client_dir_e                datap_ctrl_dir
    ,output                                     datap_ctrl_last_conn_recv
    ,output flag_e                              datap_ctrl_should_copy
    ,output logic                               datap_ctrl_last_line
);

    localparam CURR_REQ_W = $bits(setup_app_mem_wr_data.curr_reqs);
    localparam CURR_REQ_BYTES = CURR_REQ_W/8;
    localparam LINE_REP_COUNT = `NOC_DATA_BYTES/CURR_REQ_BYTES;
    localparam BUFFER_BYTES = 1 << TX_PAYLOAD_PTR_W;

    tcp_noc_hdr_flit        hdr_flit_cast;
    tcp_noc_hdr_flit        req_hdr_flit;

    logic   [FLOWID_W-1:0]  flowid_reg;
    logic   [FLOWID_W-1:0]  flowid_next;

    logic   [FLOWID_W-1:0]  bench_conn_reg;
    logic   [FLOWID_W-1:0]  bench_conn_next;

    notif_struct            notif_reg;
    notif_struct            notif_next;

    setup_hdr_struct        setup_hdr_reg;
    setup_hdr_struct        setup_hdr_next;
    setup_hdr_data          setup_hdr_cast;
    
    logic   [TX_PAYLOAD_PTR_W:0]    bytes_written_reg;
    logic   [TX_PAYLOAD_PTR_W:0]    bytes_written_next;
    logic   [CURR_REQ_W-1:0]          lines_written;

    assign lines_written = bytes_written_reg >> `NOC_DATA_BYTES_W;

    assign datap_ctrl_last_line = bytes_written_next >= BUFFER_BYTES;

    always_ff @(posedge clk) begin
        if (rst) begin
            bench_conn_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            bench_conn_reg <= bench_conn_next;
            notif_reg <= notif_next;
            setup_hdr_reg <= setup_hdr_next;
            bytes_written_reg <= bytes_written_next;
        end
    end
    
    always_comb begin
        if (ctrl_datap_reset_bytes_written) begin
            bytes_written_next = '0;
        end
        else if (ctrl_datap_incr_bytes_written) begin
            bytes_written_next = bytes_written_reg + `NOC_DATA_BYTES;
        end
        else begin
            bytes_written_next = bytes_written_reg;
        end
    end

    assign datap_ctrl_last_conn_recv = bench_conn_reg == setup_hdr_reg.num_conns;
    
    assign setup_rd_buf_req_flowid = flowid_reg;
    assign setup_rd_buf_req_offset = notif_reg.ptr[RX_PAYLOAD_PTR_W-1:0];
    assign setup_rd_buf_req_size = SETUP_HDR_BYTES;

    assign setup_wr_buf_req_flowid = flowid_reg;
    assign setup_wr_buf_req_offset = '0;
    assign setup_wr_buf_req_size = 1 << TX_PAYLOAD_PTR_W;
    assign setup_wr_buf_req_data = {(LINE_REP_COUNT){lines_written}};

    assign setup_app_mem_wr_addr = flowid_reg;
    assign setup_send_loop_q_wr_data.cmd = ctrl_datap_send_setup_confirm
                                        ? CTRL_RESP
                                        : BENCH;
    assign setup_send_loop_q_wr_data.flowid = flowid_reg;
    assign setup_recv_loop_q_wr_flowid = flowid_reg;

    assign hdr_flit_cast = ctrl_noc_setup_ptr_if_data;

    assign setup_noc_vrtoc_data = req_hdr_flit;
    assign setup_ptr_if_ctrl_noc_data = req_hdr_flit;
    assign datap_ctrl_dir = setup_hdr_reg.dir;

    assign flowid_next = ctrl_datap_store_flowid | ctrl_datap_save_conn
                        ? setup_q_handler_flowid
                        : flowid_reg;

    assign setup_hdr_cast = rd_buf_setup_resp_data;
    assign setup_hdr_next = ctrl_datap_store_hdr
                            ? setup_hdr_cast.setup_hdr
                            : setup_hdr_reg;

    assign bench_conn_next = ctrl_datap_save_conn
                            ? bench_conn_reg + 1'b1
                            : bench_conn_reg;

    assign datap_ctrl_should_copy = setup_hdr_reg.should_copy;
    
    always_comb begin
        setup_app_mem_wr_data = '0;
        setup_app_mem_wr_data.total_reqs = setup_hdr_reg.num_reqs;
        setup_app_mem_wr_data.bufsize = setup_hdr_reg.bufsize;
        setup_app_mem_wr_data.should_copy = setup_hdr_reg.should_copy;
        setup_app_mem_wr_data.curr_reqs = '0;
    end
    
    always_comb begin
        notif_next = notif_reg;
        if (ctrl_datap_store_notif) begin
            notif_next.ptr = hdr_flit_cast.inner.head_ptr;
            notif_next.len = SETUP_HDR_BYTES;
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
        req_hdr_flit.core.src_fbits = SETUP_IF_FBITS;

        req_hdr_flit.inner.flowid = flowid_reg;

        req_hdr_flit.inner.length = SETUP_HDR_BYTES;
        
        if (ctrl_datap_buf_mux_sel == setup_open_loop_pkg::PTR_UPDATE) begin
            req_hdr_flit.core.msg_type = TCP_RX_ADJUST_PTR;
            req_hdr_flit.inner.head_ptr = notif_reg.ptr + SETUP_HDR_BYTES;
        end
        else begin
            req_hdr_flit.core.msg_type = TCP_RX_MSG_REQ;
        end
    end
endmodule
