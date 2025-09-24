module rs_encode_mgr_out_datap 
import tcp_pkg::*;
import mem_msg_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic   [FLOWID_W-1:0]          encode_out_active_q_wr_data

    ,output tcp_msg_req             encode_out_msg_req_req_data

    ,input  tcp_msg_resp            msg_req_encode_out_rsp_data
    
    ,output vaddr_t                             encode_out_wr_buf_req_base_addr
    ,output         [PAYLOAD_PTR_W-1:0]             encode_out_wr_buf_req_wr_ptr
    ,output         [`MSG_DATA_SIZE_WIDTH-1:0]  encode_out_wr_buf_req_size
    
    ,output         [`NOC_DATA_WIDTH-1:0]      encode_out_wr_buf_req_data
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       stream_encoder_out_resp_data
    
    ,output logic   [FLOWID_W-1:0]                  encode_out_tx_cap_rd_req_addr

    ,input  logic   [CAP_TABLE_INDEX_W-1:0]         tx_cap_encode_out_rd_rsp_data
    
    ,input  tcp_rs_metadata                         in_out_meta_data
    
    ,input  logic                                   ctrl_datap_store_meta
    ,input  logic                                   ctrl_datap_store_offset
    ,input  logic                                   ctrl_datap_store_cap_id
    ,input  cmd_type_e                              ctrl_datap_msg_req_cmd
);

    tcp_rs_metadata meta_state_reg;
    tcp_rs_metadata meta_state_next;

    tcp_msg_resp    tx_resp_reg;
    tcp_msg_resp    tx_resp_next;

    logic   [CAP_TABLE_INDEX_W-1:0] tx_cap_reg;
    logic   [CAP_TABLE_INDEX_W-1:0] tx_cap_next;

    always_ff @(posdege clk) begin
        meta_state_reg <= meta_state_next;
        tx_resp_reg <= tx_resp_next;
        tx_cap_reg <= tx_cap_next;
    end

    assign meta_state_next = ctrl_datap_store_meta
                            ? in_out_meta_data
                            : meta_state_reg;
    
    assign tx_resp_next = ctrl_datap_store_offset
                        ? msg_req_encode_out_rsp_data
                        : tx_resp_reg;

    assign tx_cap_next = ctrl_datap_store_cap_id
                        ? tx_cap_encode_out_rd_rsp_data
                        : tx_cap_reg;

    always_comb begin
        encode_out_wr_buf_req_base_addr = '0;
        encode_out_wr_buf_req_base_addr.index = tx_cap_reg;
    end
    assign encode_out_wr_buf_req_wr_ptr = tx_resp_reg.tail_ptr;
    assign encode_out_wr_buf_req_size = meta_state_reg.resp_size;

    assign encode_out_wr_buf_req_data = stream_encoder_out_resp_data;


    always_comb begin
        encode_out_msg_req_req_data = '0;
        encode_out_msg_req_req_data.flowid = meta_state_reg.flowid;
        encode_out_msg_req_req_data.size = meta_state.resp_size;
        encode_out_msg_req_req_data.tail_ptr = tx_resp_reg.tail_ptr + meta_state_reg.resp_size;

        encode_out_msg_req_req_data.cmd = ctrl_datap_msg_req_cmd;
    end
endmodule