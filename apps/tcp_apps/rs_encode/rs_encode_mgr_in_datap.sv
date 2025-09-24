`include "noc_defs.vh"
module rs_encode_mgr_in_datap 
import tcp_pkg::*;
import rs_encode_pkg::*;
import tcp_rs_encode_pkg::*;
(
     input  clk
    ,input  rst
    
    ,input  logic   [FLOWID_W-1:0]                  active_q_encode_in_rd_data

    ,output tcp_msg_req                             encode_in_msg_req_req_data

    ,input  tcp_msg_resp                            msg_req_encode_in_rsp_data
    
    ,output vaddr_t                                 encode_in_rd_buf_req_base_addr
    ,output         [PAYLOAD_PTR_W-1:0]             encode_in_rd_buf_req_offset
    ,output         [`MSG_DATA_SIZE_WIDTH-1:0]      encode_in_rd_buf_req_size

    ,input  logic   [`NOC_DATA_WIDTH-1:0]           rd_buf_encode_in_data
    ,input  logic                                   rd_buf_encode_in_data_last
    ,input  logic   [`NOC_DATA_BYTES_W-1:0]         rd_buf_encode_in_data_padbytes
    
    ,output         [ENCODER_NUM_REQ_BLOCKS-1:0]    encode_in_stream_encoder_req_num_blocks

    ,output         [`NOC_DATA_WIDTH-1:0]           encode_in_stream_encoder_req_data

    ,output logic   [FLOWID_W-1:0]                  encode_in_rx_cap_rd_req_addr

    ,input  logic   [CAP_TABLE_INDEX_W-1:0]         rx_cap_encode_in_rd_rsp_data

    ,output tcp_rs_metadata                         in_out_meta_data
    
    ,input  logic                                   ctrl_datap_store_flowid
    ,input  logic                                   ctrl_datap_store_offset
    ,input  logic                                   ctrl_datap_store_cap_id
    ,input  logic                                   ctrl_datap_store_req
    ,input  cmd_type_e                              ctrl_datap_msg_req_cmd

);

    logic   [FLOWID_W-1:0]  flowid_reg;
    logic   [FLOWID_W-1:0]  flowid_next;

    logic   [PAYLOAD_PTR_W:0]   offset_reg;
    logic   [PAYLOAD_PTR_W:0]   offset_next;

    logic   [CAP_TABLE_INDEX_W-1:0] rx_cap_id_reg;
    logic   [CAP_TABLE_INDEX_W-1:0] rx_cap_id_next;

    tcp_rs_metadata                 req_reg;
    tcp_rs_metadata                 req_next;

    always_ff @(posedge clk) begin
        flowid_reg <= flowid_next;
        offset_reg <= offset_next;
        rx_cap_id_reg <= rx_cap_id_next;
        req_reg <= req_next;
    end

    assign flowid_next = ctrl_datap_store_flowid
                        ? active_q_encode_in_rd_data
                        : flowid_reg;

    assign offset_next = ctrl_datap_store_offset
                        ? msg_req_encode_in_rsp_data.head_ptr
                        : offset_reg;
    
    assign rx_cap_id_next = ctrl_datap_store_cap_id
                            ? rx_cap_encode_in_rd_rsp_data
                            : rx_cap_id_reg;
    
    assign req_next = ctrl_datap_store_req
                    ? rd_buf_encode_in_data
                    : req_reg;

    assign encode_in_rx_cap_rd_req_addr = flowid_reg;

    assign in_out_meta_data.flowid = flowid_reg;
    assign in_out_meta_data.req_size = req_reg.req_size;
    assign in_out_meta_data.resp_size = req_reg.resp_size;

    assign encode_in_msg_req_req_data.flowid = flowid_reg;
    assign encode_in_msg_req_req_data.size = req_reg.size;
    assign encode_in_msg_req_req.head_ptr = req_reg.head_ptr + req_reg.req_size;
    assign encode_in_msg_req_req_data.tail_ptr = tail_ptr;
    assign encode_in_msg_req_req_data.cmd = ctrl_datap_msg_req_cmd;


    always_comb begin
        encode_in_rd_buf_req_base_addr = 0;
        encode_in_rd_buf_req_base_addr.index = rx_cap_id_reg;
    end

    assign encode_in_rd_buf_req_offset = offset_reg;
    assign encode_in_rd_buf_req_size = req_reg.req_size;

    assign encoder_in_stream_encoder_req_num_blocks = req_reg.num_req_blocks;

    assign encoder_in_stream_encoder_req_data = rd_buf_encode_in_data;


endmodule