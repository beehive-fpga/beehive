`include "noc_defs.vh"
module wr_circ_buf_datapath 
import tcp_pkg::*;
import mem_msg_pkg::*;
#(
     parameter BUF_PTR_W = 0
)(
     input clk
    ,input rst

    ,input  vaddr_t                             src_wr_buf_req_base_addr
    ,input          [BUF_PTR_W-1:0]             src_wr_buf_req_wr_ptr
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]  src_wr_buf_req_size

    ,input          [`NOC_DATA_WIDTH-1:0]       src_wr_buf_req_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       wr_buf_wr_mem_req_data
    ,output logic                               wr_buf_wr_mem_req_data_last
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   wr_buf_wr_mem_req_data_padbytes

    ,input                                      store_req_metadata
    ,input                                      update_wr_req_metadata

    ,input                                      init_curr_req_rem_bytes
    ,input                                      update_curr_req_rem_bytes

    ,input                                      store_save_reg
    ,input                                      store_save_reg_shift
    ,input                                      clear_save_reg_shift

    ,output                                     split_req
    ,output                                     save_reg_has_unused
    ,output                                     datap_ctrl_need_input

    ,output mem_req_struct                      datapath_mem_req_struct
);

    // store the overall request size
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  whole_req_size_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  whole_req_size_next;
    
    logic   [BUF_PTR_W-1:0]             whole_req_wr_ptr_reg;
    logic   [BUF_PTR_W-1:0]             whole_req_wr_ptr_next;

    vaddr_t base_addr_reg;
    vaddr_t base_addr_next;
    vaddr_t base_addr_index;
    logic   [VADDR_W-1:0]   vaddr_cast;
   
    // store the bytes left to send
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  curr_wr_req_rem_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  curr_wr_req_rem_next;
   
    // store the remaining bytes in the request
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  wr_bytes_rem_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  wr_bytes_rem_next;

    // store the wr pointer for the current request
    logic   [BUF_PTR_W-1:0]             curr_wr_req_ptr_reg;
    logic   [BUF_PTR_W-1:0]             curr_wr_req_ptr_next;

    logic   [BUF_PTR_W:0]               bytes_to_end;
    logic   [BUF_PTR_W:0]               next_bytes_to_end;

    logic   [`NOC_PADBYTES_WIDTH:0]     padbytes_calc;
    logic   [`NOC_PADBYTES_WIDTH:0]     unused_in_save_reg;

    logic                               split_next_req;

    logic   [`NOC_DATA_WIDTH-1:0]       save_line_reg;
    logic   [`NOC_DATA_WIDTH-1:0]       save_line_next;
    logic   [`NOC_DATA_BITS_W-1:0]      save_line_shift_reg;
    logic   [`NOC_DATA_BITS_W-1:0]      save_line_shift_next;
    logic   [(2*`NOC_DATA_WIDTH)-1:0]   shifted_data;

    mem_req_struct                      mem_req;

    assign datapath_mem_req_struct = mem_req;

    assign wr_buf_wr_mem_req_data = shifted_data[(2*`NOC_DATA_WIDTH)-1 -: `NOC_DATA_WIDTH];
    assign wr_buf_wr_mem_req_data_last = wr_bytes_rem_reg <= `NOC_DATA_BYTES;

    assign padbytes_calc = `NOC_DATA_BYTES - wr_bytes_rem_reg;
    assign wr_buf_wr_mem_req_data_padbytes = wr_buf_wr_mem_req_data_last
                                           ? padbytes_calc[`NOC_PADBYTES_WIDTH-1:0]
                                           : 0;

    assign save_reg_has_unused = save_line_shift_reg != 0;
    assign unused_in_save_reg = `NOC_DATA_BYTES - (save_line_shift_reg >> 3);
    assign datap_ctrl_need_input = wr_buf_wr_mem_req_data_last
                                    & save_reg_has_unused 
                                    & unused_in_save_reg < wr_bytes_rem_reg;

    assign shifted_data = {save_line_reg, src_wr_buf_req_data} << save_line_shift_reg;


    // did it loop back around
    assign split_req = curr_wr_req_rem_reg > bytes_to_end;

    assign bytes_to_end = {1'b1, {(BUF_PTR_W){1'b0}}} - curr_wr_req_ptr_reg;

    assign base_addr_index.index = base_addr_reg.index;
    assign base_addr_index.offset = base_addr_reg.offset;

    assign vaddr_cast = base_addr_index;
    assign mem_req.size = split_req ? bytes_to_end : curr_wr_req_rem_reg;
    assign mem_req.addr = base_addr_index + curr_wr_req_ptr_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            whole_req_size_reg <= '0;
            
            curr_wr_req_ptr_reg <= '0;
            curr_wr_req_rem_reg <= '0;

            whole_req_wr_ptr_reg <= '0;

            wr_bytes_rem_reg <= '0;

            save_line_reg <= '0;
            save_line_shift_reg <= '0;
        end
        else begin
            whole_req_size_reg <= whole_req_size_next;

            curr_wr_req_ptr_reg <= curr_wr_req_ptr_next;
            curr_wr_req_rem_reg <= curr_wr_req_rem_next;

            whole_req_wr_ptr_reg <= whole_req_wr_ptr_next;

            wr_bytes_rem_reg <= wr_bytes_rem_next;

            save_line_reg <= save_line_next;
            save_line_shift_reg <= save_line_shift_next;
            base_addr_reg <= base_addr_next;
        end
    end
    
    always_comb begin
        if (store_req_metadata) begin
            whole_req_size_next = src_wr_buf_req_size;
            whole_req_wr_ptr_next = src_wr_buf_req_wr_ptr;
            base_addr_next = src_wr_buf_req_base_addr;
        end
        else begin
            whole_req_size_next = whole_req_size_reg;
            whole_req_wr_ptr_next = whole_req_wr_ptr_reg;
            base_addr_next = base_addr_reg;
        end
    end

    always_comb begin
        if (store_req_metadata) begin
            curr_wr_req_rem_next = src_wr_buf_req_size;
            curr_wr_req_ptr_next = src_wr_buf_req_wr_ptr;
        end
        else if (update_wr_req_metadata) begin
            curr_wr_req_rem_next = curr_wr_req_rem_reg - mem_req.size;
            curr_wr_req_ptr_next = curr_wr_req_ptr_reg + mem_req.size;
        end
        else begin
            curr_wr_req_rem_next = curr_wr_req_rem_reg;
            curr_wr_req_ptr_next = curr_wr_req_ptr_reg;
        end
    end

    always_comb begin
        if (init_curr_req_rem_bytes) begin
            wr_bytes_rem_next = mem_req.size;
        end
        else if (update_curr_req_rem_bytes)
            wr_bytes_rem_next = wr_bytes_rem_reg - `NOC_DATA_BYTES;
        else begin
            wr_bytes_rem_next = wr_bytes_rem_reg;
        end
    end

    assign save_line_next = store_save_reg
                          ? src_wr_buf_req_data
                          : save_line_reg;
    
    always_comb begin
        if (clear_save_reg_shift) begin
            save_line_shift_next = '0;
        end
        else if (store_save_reg_shift) begin
            save_line_shift_next = wr_bytes_rem_reg << 3; 
        end
        else begin
            save_line_shift_next = save_line_shift_reg;
        end
    end


    
endmodule
