`include "noc_defs.vh"
`include "soc_defs.vh"
module rd_circ_buf_datap_new 
import mem_msg_pkg::*;
import tcp_pkg::*;
#(
    parameter BUF_PTR_W=-1
)(
     input clk
    ,input rst
    
    ,input  vaddr_t                                 src_rd_buf_req_base_addr
    ,input          [BUF_PTR_W-1:0]                 src_rd_buf_req_offset
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]      src_rd_buf_req_size

    ,output logic   [`MAC_INTERFACE_W-1:0]          rd_buf_src_resp_data
    ,output logic   [`MAC_PADBYTES_W-1:0]           rd_buf_src_resp_data_padbytes
    
    ,output mem_req_struct                          datap_rd_noc_req

    ,input          [`MAC_INTERFACE_W-1:0]          rd_noc_datap_resp_data
    ,input          [`MAC_PADBYTES_W-1:0]           rd_noc_datap_resp_data_padbytes
    
    ,input  logic                                   ctrl_datap_store_req_state
    ,input  logic                                   ctrl_datap_update_req_state
    ,input  logic                                   ctrl_datap_save_req
    ,input  logic                                   ctrl_datap_decr_bytes_out_reg
    ,input  logic                                   ctrl_datap_store_shift
    ,input  logic                                   ctrl_datap_write_upper
    ,input  logic                                   ctrl_datap_shift_regs
    ,input  logic                                   ctrl_datap_write_lower
    ,input  logic                                   ctrl_datap_use_shift
    ,input  logic                                   ctrl_datap_lower_zeros

    ,output logic                                   datap_ctrl_split_req
    ,output logic                                   datap_ctrl_last_data_out
);

    vaddr_t                  base_addr_reg;
    vaddr_t                  base_addr_next;

    logic   [`MSG_DATA_SIZE_WIDTH-1:0]      bytes_remain_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]      bytes_remain_next;
    logic   [BUF_PTR_W-1:0]                 curr_offset_reg;
    logic   [BUF_PTR_W-1:0]                 curr_offset_next;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]      bytes_left_out_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]      bytes_left_out_next;

    logic   [`MAC_PADBYTES_W-1:0]           shift_bytes_reg;
    logic   [`MAC_PADBYTES_W-1:0]           shift_bytes_next;
    logic   [`MAC_INTERFACE_BITS_W-1:0]     mem_data_shift_bits;

    mem_req_struct                          mem_req_reg;
    mem_req_struct                          mem_req_next;
    
    logic   [`MAC_INTERFACE_W-1:0]      shift_upper_reg;
    logic   [`MAC_INTERFACE_W-1:0]      shift_upper_next;
    logic   [`MAC_INTERFACE_W-1:0]      shift_lower_reg;
    logic   [`MAC_INTERFACE_W-1:0]      shift_lower_next;
    logic   [`MAC_INTERFACE_W-1:0]      shift_upper_data;
    logic   [(2*`MAC_INTERFACE_W)-1:0]  shifted_data;
    
    // This has to be 1 longer, because if we're at 0, we have to be able to store that there are
    // all the bytes left
    logic   [BUF_PTR_W:0]          space_to_end;
    assign space_to_end = {1'b1, {(BUF_PTR_W){1'b0}}} - curr_offset_next;

    // check if we need to issue two requests
    assign datap_ctrl_split_req = space_to_end < bytes_remain_next;

    assign datap_ctrl_last_data_out = bytes_left_out_reg <= `MAC_INTERFACE_BYTES;

    assign mem_data_shift_bits = ctrl_datap_use_shift
                                ? shift_bytes_reg << 3
                                : '0;

    // shift all the padbytes out of the upper reg
    assign shift_upper_data = shift_upper_reg >> mem_data_shift_bits;

    // now shift back to the right place, shifting in all the bits from the lower reg
    assign shifted_data = {shift_upper_data, shift_lower_reg} << mem_data_shift_bits;

    assign rd_buf_src_resp_data = shifted_data[(2*`MAC_INTERFACE_W)-1 -: `MAC_INTERFACE_W];
    assign rd_buf_src_resp_data_padbytes = datap_ctrl_last_data_out
                                        ? `MAC_INTERFACE_BYTES - bytes_left_out_reg
                                        : '0;

    assign shift_upper_next = ctrl_datap_write_upper
                            ? rd_noc_datap_resp_data
                            : ctrl_datap_shift_regs
    // we need to grab the shifted data, because when we realign after a wrap,
    // we use up part of the data in the lower reg
                                ? shifted_data[`MAC_INTERFACE_W-1:0]
                                : shift_upper_reg;
    assign shift_lower_next = ctrl_datap_shift_regs | ctrl_datap_write_lower
                            ? ctrl_datap_lower_zeros
                                ? '0
                                : rd_noc_datap_resp_data
                            : shift_lower_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            base_addr_reg <= '0;

            mem_req_reg <= '0;
            curr_offset_reg <= '0;
            bytes_remain_reg <= '0;
            bytes_left_out_reg <= '0;
            shift_bytes_reg <= '0;
            shift_upper_reg <= '0;
            shift_lower_reg <= '0;
        end
        else begin
            base_addr_reg <= base_addr_next;

            mem_req_reg <= mem_req_next;
            curr_offset_reg <= curr_offset_next;
            bytes_remain_reg <= bytes_remain_next;
            bytes_left_out_reg <= bytes_left_out_next;
            shift_bytes_reg <= shift_bytes_next;
            shift_upper_reg <= shift_upper_next;
            shift_lower_reg <= shift_lower_next;
        end
    end

    assign shift_bytes_next = ctrl_datap_store_req_state
                            ? '0
                            : ctrl_datap_store_shift
                                ? rd_noc_datap_resp_data_padbytes
                                : shift_bytes_reg;

    assign base_addr_next = ctrl_datap_store_req_state
                            ? src_rd_buf_req_base_addr
                            : base_addr_reg;

    assign curr_offset_next = ctrl_datap_store_req_state
                            ? src_rd_buf_req_offset
                            : ctrl_datap_update_req_state
                                ? curr_offset_reg + mem_req_reg.size
                                : curr_offset_reg;
    assign bytes_remain_next = ctrl_datap_store_req_state
                            ? src_rd_buf_req_size
                            : ctrl_datap_update_req_state
                                ? bytes_remain_reg - mem_req_reg.size
                                : bytes_remain_reg;

    assign bytes_left_out_next = ctrl_datap_store_req_state
                                ? src_rd_buf_req_size
                                : ctrl_datap_decr_bytes_out_reg
                                    ? bytes_left_out_reg - `MAC_INTERFACE_BYTES
                                    : bytes_left_out_reg;
    
    assign mem_req_next = ctrl_datap_save_req
                        ? datap_rd_noc_req
                        : mem_req_reg;

    logic   [VADDR_W-1:0]   base_addr_cast;

    assign base_addr_cast = base_addr_reg;
    always_comb begin
        datap_rd_noc_req = '0;
        datap_rd_noc_req.size = datap_ctrl_split_req
                                        ? space_to_end
                                        : bytes_remain_next;
        datap_rd_noc_req.addr = base_addr_reg + curr_offset_next;
    end
endmodule
