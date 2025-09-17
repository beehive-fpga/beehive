`include "packet_defs.vh"
`include "state_defs.vh"
`include "noc_defs.vh"
`include "soc_defs.vh"
import noc_struct_pkg::*;
module rd_circ_buf_ctrl #(
     parameter BUF_PTR_W=-1
)(
     input clk
    ,input rst

    ,input                                          src_rd_buf_req_val
    ,input          [`FLOW_ID_W-1:0]                src_rd_buf_req_flowid
    ,input          [BUF_PTR_W-1:0]                 src_rd_buf_req_offset
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]      src_rd_buf_req_size
    ,output logic                                   rd_buf_src_req_rdy
    
    ,output logic                                   ctrl_datapath_rd_req_val
    ,output mem_req_struct                          ctrl_datapath_rd_req_data
    ,input  logic                                   datapath_ctrl_rd_req_rdy
    
    ,input  logic                                   datapath_ctrl_resp_data_val
    ,input  logic                                   datapath_ctrl_resp_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]           datapath_ctrl_resp_data_padbytes
    ,output logic                                   ctrl_datapath_resp_data_rdy
    
    ,output logic                                   rd_buf_src_data_val
    ,output logic                                   rd_buf_src_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]           rd_buf_src_data_padbytes
    ,input                                          src_rd_buf_data_rdy
    
    ,output logic   [`MAC_INTERFACE_BYTES_W-1:0]    mem_data_shift_bytes

    ,output logic                                   write_upper
    ,output logic                                   shift_upper
    ,output logic                                   shift_lower
    ,output logic                                   shift_lower_zeros

);

    typedef enum logic[2:0] {
        READY = 3'd0,
        SEND_WRAP_RD_REQ = 3'd1,
        WAIT_WRAP_RD_RESP = 3'd7,
        WAIT_RD_RESP = 3'd3,
        DATA_BUFFER = 3'd4,
        DATA_OUTPUT = 3'd5,
        OUTPUT_FOR_WRAP_RD = 3'd2,
        DATA_DRAIN = 3'd6,
        UND = 'X
    } state_e;
    
    typedef enum logic {
        INPUTS = 1'b0,
        REGS = 1'b1
    } part_req_data_src_e;

    state_e state_reg;
    state_e state_next;

    logic   store_part_req_entry;
    logic   update_curr_offset_reg;
    logic   init_curr_offset_reg;
    
    mem_req_struct part_req_entry;
    mem_req_struct part_req_entry_reg;
    mem_req_struct part_req_entry_next;

    part_req_data_src_e part_req_data_src;
  
    logic   [`FLOW_ID_W-1:0]            flowid_reg;
    logic   [`FLOW_ID_W-1:0]            flowid_next;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_remain_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_remain_next;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_left_to_output_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_left_to_output_next;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  req_size;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  req_size_mod32_check;
    logic   [BUF_PTR_W-1:0]        req_offset_reg;
    logic   [BUF_PTR_W-1:0]        req_offset_next;
    logic   [BUF_PTR_W-1:0]        curr_offset_reg;
    logic   [BUF_PTR_W-1:0]        curr_offset_next;
    // This has to be 1 longer, because if we're at 0, we have to be able to store that there are
    // all the bytes left
    logic   [BUF_PTR_W:0]          space_to_end;

    logic   [BUF_PTR_W-1:0]        curr_offset_mux;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_remain_mux;
    logic   [`FLOW_ID_W-1:0]            flowid_mux;
    logic   [BUF_PTR_W-1:0]        offset_mask;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  size_mask;

    assign ctrl_datapath_rd_req_data = part_req_entry;

    // this is to align to the multiple of 32 below the offset
    assign offset_mask = {{(BUF_PTR_W-`NOC_DATA_BYTES_W){1'b1}}, {(`NOC_DATA_BYTES_W){1'b0}}};
    assign size_mask = {{(`MSG_DATA_SIZE_WIDTH-`NOC_DATA_BYTES_W){1'b1}}, 
                        {(`NOC_DATA_BYTES_W){1'b0}}};
    
    assign space_to_end = {1'b1, {(BUF_PTR_W){1'b0}}} - 
                          {1'b0, curr_offset_mux};


    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            curr_offset_reg <= '0;
            part_req_entry_reg <= '0;
            req_offset_reg <= '0;
            bytes_remain_reg <= '0;
            bytes_left_to_output_reg <= '0;
            flowid_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            curr_offset_reg <= curr_offset_next;
            part_req_entry_reg <= part_req_entry_next;
            req_offset_reg <= req_offset_next;
            bytes_remain_reg <= bytes_remain_next;
            bytes_left_to_output_reg <= bytes_left_to_output_next;
            flowid_reg <= flowid_next;
        end
    end
    
    assign part_req_data_src = (state_reg == READY)
                             ? INPUTS
                             : REGS;

    assign curr_offset_mux = part_req_data_src == INPUTS
                           ? src_rd_buf_req_offset
                           : curr_offset_reg;

    assign bytes_remain_mux = part_req_data_src == INPUTS
                            ? src_rd_buf_req_size
                            : bytes_remain_reg;

    assign flowid_mux = part_req_data_src == INPUTS
                      ? src_rd_buf_req_flowid
                      : flowid_reg;
   
    // check whether we need 2 requests, because we roll over the end of the buffer
    always_comb begin
        if (space_to_end < bytes_remain_mux) begin
            req_size = space_to_end;
        end
        else begin
            req_size = bytes_remain_mux;
        end
    end

    assign req_size_mod32_check = (req_size + curr_offset_mux);
    always_comb begin
        // request for the nearest 32-byte address below the current offset
        part_req_entry.mem_req_addr = {flowid_mux, (curr_offset_mux & offset_mask)};
        // once we have a request size, we need to do some interesting math to get the right request size
        // if we're aligned properly in address and data size request...great! Use the req size we have
        if ((req_size[`NOC_DATA_BYTES_W-1:0] == 0) & (curr_offset_mux[`NOC_DATA_BYTES_W-1:0] == 0)) begin
            part_req_entry.mem_req_size = req_size;
        end
        else begin
            // if we happen to be ending on a multiple of 32, don't round up
            if (req_size_mod32_check[`NOC_DATA_BYTES_W-1:0] == 0) begin
                part_req_entry.mem_req_size = (req_size 
                                            + curr_offset_mux[`NOC_DATA_BYTES_W-1:0]);
            end
            // otherwise, we need to add on the shift that we made to get the right 
            // address alignment as well as an extra `NOC_DATA_BYTES and then round 
            // it all to `NOC_DATA_BYTES_ALIGNED
            else begin
                part_req_entry.mem_req_size = (req_size 
                                              + curr_offset_mux[`NOC_DATA_BYTES_W-1:0] 
                                              + `NOC_DATA_BYTES) & size_mask;
                
            end
        end
    end

    assign mem_data_shift_bytes = req_offset_reg[`MAC_INTERFACE_BYTES_W-1:0];

    always_comb begin
        state_next = state_reg;

        rd_buf_src_req_rdy = 1'b0;
        ctrl_datapath_rd_req_val = 1'b0;
        ctrl_datapath_resp_data_rdy = 1'b0;
        rd_buf_src_data_val = 1'b0;
        rd_buf_src_data_last = 1'b0;
        rd_buf_src_data_padbytes = '0;

        flowid_next = flowid_reg;
        bytes_remain_next = bytes_remain_reg;
        req_offset_next = req_offset_reg;
        bytes_left_to_output_next = bytes_left_to_output_reg;
        store_part_req_entry = 1'b0;
        update_curr_offset_reg = 1'b0;
        init_curr_offset_reg = 1'b0;

        write_upper = 1'b0;
        shift_upper = 1'b0;
        shift_lower = 1'b0;
        shift_lower_zeros = 1'b0;
        case (state_reg)
            READY: begin
                rd_buf_src_req_rdy = datapath_ctrl_rd_req_rdy;
                ctrl_datapath_rd_req_val = src_rd_buf_req_val;

                if (src_rd_buf_req_val & datapath_ctrl_rd_req_rdy) begin
                    flowid_next = src_rd_buf_req_flowid;
                    store_part_req_entry = 1'b1;
                    req_offset_next = src_rd_buf_req_offset;
                    bytes_remain_next = src_rd_buf_req_size - req_size;
                    bytes_left_to_output_next = src_rd_buf_req_size;
                    
                    state_next = WAIT_RD_RESP;
                end
                else begin
                    state_next = READY;
                end
            end
            SEND_WRAP_RD_REQ: begin
                ctrl_datapath_rd_req_val = 1'b1;
                if (datapath_ctrl_rd_req_rdy) begin
                    store_part_req_entry = 1'b1;
                    bytes_remain_next = bytes_remain_reg - req_size;
                    state_next = WAIT_WRAP_RD_RESP;
                end
                else begin
                    state_next = SEND_WRAP_RD_REQ;
                end
            end
            WAIT_WRAP_RD_RESP: begin
                ctrl_datapath_resp_data_rdy = 1'b1;
                init_curr_offset_reg = 1'b1;
                if (datapath_ctrl_resp_data_val) begin
                    shift_lower = 1'b1;
                    if (datapath_ctrl_resp_data_last) begin
                        state_next = DATA_DRAIN;
                    end
                    else begin
                        state_next = DATA_OUTPUT;
                    end
                end
                else begin
                    state_next = WAIT_WRAP_RD_RESP;
                end
            end
            WAIT_RD_RESP: begin
                ctrl_datapath_resp_data_rdy = 1'b1;
                init_curr_offset_reg = 1'b1;
                if (datapath_ctrl_resp_data_val) begin
                    if (datapath_ctrl_resp_data_last) begin
                        write_upper = 1'b1;
                        shift_lower_zeros = 1'b1;
                        if (bytes_remain_reg != 0) begin
                            state_next = SEND_WRAP_RD_REQ;
                        end
                        else begin
                            state_next = DATA_DRAIN;
                        end
                    end
                    else begin
                        shift_lower = 1'b1;
                        state_next = DATA_BUFFER;
                    end
                end
                else begin
                    state_next = WAIT_RD_RESP;
                end
            end
            DATA_BUFFER: begin
                ctrl_datapath_resp_data_rdy = 1'b1;
                if (datapath_ctrl_resp_data_val) begin
                    shift_upper = 1'b1;
                    shift_lower = 1'b1;
                    if (datapath_ctrl_resp_data_last) begin
                        if (bytes_remain_reg != 0) begin
                            state_next = OUTPUT_FOR_WRAP_RD;
                        end
                        else begin
                            state_next = DATA_DRAIN;
                        end
                    end
                    else begin
                        state_next = DATA_OUTPUT;
                    end
                end
                else begin
                    state_next = DATA_BUFFER;
                end
            end
            OUTPUT_FOR_WRAP_RD: begin
                rd_buf_src_data_val = 1'b1;
                if (src_rd_buf_data_rdy) begin
                    shift_upper = 1'b1;
                    bytes_left_to_output_next = bytes_left_to_output_reg - `MAC_INTERFACE_BYTES;
                    state_next = SEND_WRAP_RD_REQ;
                end
                else begin
                    state_next = OUTPUT_FOR_WRAP_RD;
                end
            end
            DATA_OUTPUT: begin
                rd_buf_src_data_val = datapath_ctrl_resp_data_val;
                ctrl_datapath_resp_data_rdy = src_rd_buf_data_rdy;

                if (datapath_ctrl_resp_data_val & src_rd_buf_data_rdy) begin
                    shift_upper = 1'b1;
                    shift_lower = 1'b1;
                    bytes_left_to_output_next = bytes_left_to_output_reg - `MAC_INTERFACE_BYTES;

                    if (datapath_ctrl_resp_data_last) begin
                        if (bytes_remain_reg != 0) begin
                            state_next = OUTPUT_FOR_WRAP_RD;
                        end
                        else begin
                            state_next = DATA_DRAIN;
                        end
                    end
                    else begin
                        state_next = DATA_OUTPUT;
                    end
                end
                else begin
                    state_next = DATA_OUTPUT;
                end

            end
            DATA_DRAIN: begin
                rd_buf_src_data_val = 1'b1;
                rd_buf_src_data_last = (bytes_left_to_output_reg <= (`MAC_INTERFACE_BYTES));
                rd_buf_src_data_padbytes = (bytes_left_to_output_reg <= (`MAC_INTERFACE_BYTES))
                                            ? `MAC_INTERFACE_BYTES - bytes_left_to_output_reg
                                            : '0;

                if (src_rd_buf_data_rdy) begin
                    if (bytes_left_to_output_reg > `MAC_INTERFACE_BYTES) begin
                        shift_upper = 1'b1;
                        shift_lower_zeros = 1'b1;

                        bytes_left_to_output_next = bytes_left_to_output_reg - `MAC_INTERFACE_BYTES;
                        state_next = DATA_DRAIN;
                    end
                    else begin
                        bytes_left_to_output_next = '0;
                        state_next = READY;
                    end
                end
                else begin
                    state_next = DATA_DRAIN;
                end
            end
            default: begin
                state_next = UND;

                rd_buf_src_req_rdy = 'X;
                ctrl_datapath_rd_req_val = 'X;
                ctrl_datapath_resp_data_rdy = 'X;
                rd_buf_src_data_val = 'X;
                rd_buf_src_data_last = 'X;
                rd_buf_src_data_padbytes = 'X;

                flowid_next = 'X;
                bytes_remain_next = 'X;
                req_offset_next = 'X;
                bytes_left_to_output_next = 'X;

                write_upper = 'X;
                shift_upper = 'X;
                shift_lower = 'X;
                shift_lower_zeros = 'X;
            end
        endcase
    end

    assign part_req_entry_next = store_part_req_entry
                                ? part_req_entry
                                : part_req_entry_reg;
    
    always_comb begin
        if (init_curr_offset_reg) begin
            curr_offset_next = part_req_entry_reg.mem_req_addr + 
                                part_req_entry_reg.mem_req_size;
        
        end
        else if (update_curr_offset_reg) begin
            curr_offset_next = curr_offset_reg + part_req_entry_reg.mem_req_size; 
        end
        else begin
            curr_offset_next = curr_offset_reg;
        end
    end
                                
endmodule
