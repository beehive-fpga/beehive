/* This module handles turning a write request into NoC packets.
 * Note that it doesn't check for alignment requirements having to do with
 * data sizes/addresses. Instead, it expects the requesting module to break
 * up its requests appropriately
 */
`include "noc_defs.vh"
module wr_mem_noc_module 
import beehive_noc_msg::*;
import mem_noc_helper_pkg::*;
#(
     parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
) (
     input clk
    ,input rst
    
    ,output logic                               wr_mem_noc_req_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       wr_mem_noc_req_noc0_data
    ,input  logic                               noc_wr_mem_req_noc0_rdy
    
    ,input  logic                               noc_wr_mem_resp_noc0_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_wr_mem_resp_noc0_data
    ,output logic                               wr_mem_noc_resp_noc0_rdy
    
    ,input  logic                               src_wr_mem_req_val
    ,input  mem_req_struct                      src_wr_mem_req_entry
    ,output logic                               wr_mem_src_req_rdy
    
    ,input  logic                               src_wr_mem_req_data_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       src_wr_mem_req_data
    ,input  logic                               src_wr_mem_req_data_last
    ,input  logic   [`NOC_PADBYTES_WIDTH-1:0]   src_wr_mem_req_data_padbytes
    ,output logic                               wr_mem_src_req_data_rdy

    ,output logic                               wr_req_done
    ,input  logic                               wr_req_done_rdy
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        SEND_WR_HDR = 3'd1,
        SEND_WR_PAYLOAD = 3'd2,
        WAIT_WR_RESP = 3'd3,
        OUTPUT_WR_DONE = 3'd4,
        UND = 'X
    } states_e;

    states_e state_reg;
    states_e state_next;

    mem_req_struct  req_entry_cast;
    mem_req_struct  req_entry_reg;
    mem_req_struct  req_entry_next;

    dram_noc_hdr_flit   hdr_flit;
    dram_noc_hdr_flit   wr_resp_flit_cast;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_to_send_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_to_send_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_sent_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_sent_next;

    assign req_entry_cast = src_wr_mem_req_entry;
    assign wr_resp_flit_cast = noc_wr_mem_resp_noc0_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            req_entry_reg <= '0;
            flits_to_send_reg <= '0;
            flits_sent_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            req_entry_reg <= req_entry_next;
            flits_to_send_reg <= flits_to_send_next;
            flits_sent_reg <= flits_sent_next;
        end
    end

    always_comb begin
        state_next = state_reg;
        req_entry_next = req_entry_reg;
        flits_to_send_next = flits_to_send_reg;
        flits_sent_next = flits_sent_reg;

        wr_mem_src_req_rdy = 1'b0;
        wr_mem_src_req_data_rdy = 1'b0;
        wr_mem_noc_req_noc0_val = 1'b0;
        wr_mem_noc_req_noc0_data = '0;
        wr_mem_noc_resp_noc0_rdy = 1'b0;
                
        wr_req_done = 1'b0;

        case (state_reg)
            READY: begin
                wr_mem_src_req_rdy = 1'b1;

                if (src_wr_mem_req_val) begin
                    req_entry_next = src_wr_mem_req_entry;
                    flits_to_send_next = req_entry_cast.mem_req_size[`NOC_DATA_BYTES_W-1:0] == 0
                              ? req_entry_cast.mem_req_size >> `NOC_DATA_BYTES_W
                              : (req_entry_cast.mem_req_size >> `NOC_DATA_BYTES_W) + 1;
                    flits_sent_next = '0;
                    state_next = SEND_WR_HDR;
                end
                else begin
                    state_next = READY;
                end
            end
            SEND_WR_HDR: begin
                wr_mem_noc_req_noc0_val = 1'b1;
                wr_mem_noc_req_noc0_data = hdr_flit;

                if (noc_wr_mem_req_noc0_rdy) begin
                    state_next = SEND_WR_PAYLOAD;
                end
                else begin
                    state_next = SEND_WR_HDR;
                end
            end
            SEND_WR_PAYLOAD: begin
                wr_mem_src_req_data_rdy = noc_wr_mem_req_noc0_rdy;
                wr_mem_noc_req_noc0_val = src_wr_mem_req_data_val;
                wr_mem_noc_req_noc0_data = src_wr_mem_req_data;

                if (noc_wr_mem_req_noc0_rdy & src_wr_mem_req_data_val) begin
                    flits_sent_next = flits_sent_reg + 1'b1;

                    if (flits_sent_reg == (flits_to_send_reg - 1'b1)) begin
                        state_next = WAIT_WR_RESP;
                    end
                    else begin
                        state_next = SEND_WR_PAYLOAD;
                    end
                end
                else begin
                    state_next = SEND_WR_PAYLOAD;
                end
            end
            WAIT_WR_RESP: begin
                wr_mem_noc_resp_noc0_rdy = 1'b1;
                
                if (noc_wr_mem_resp_noc0_val) begin
                    if (wr_resp_flit_cast.core.msg_type == `MSG_TYPE_STORE_MEM_ACK) begin
                        wr_req_done = 1'b1;
                        if (wr_req_done_rdy) begin
                            state_next = READY;
                        end
                        else begin
                            state_next = OUTPUT_WR_DONE;
                        end
                    end
                    else begin
                        state_next = UND;
                    end
                end
                else begin
                    state_next = WAIT_WR_RESP;
                end
            end
            OUTPUT_WR_DONE: begin
                wr_req_done = 1'b1;
                if (wr_req_done_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = OUTPUT_WR_DONE;
                end
            end
            default: begin
                state_next = UND;
                req_entry_next = 'X;
                flits_to_send_next = 'X;
                flits_sent_next = 'X;

                wr_mem_src_req_rdy = 'X;
                wr_mem_src_req_data_rdy = 'X;
                wr_mem_noc_req_noc0_val = 'X;
                wr_mem_noc_req_noc0_data = 'X;
                wr_mem_noc_resp_noc0_rdy = 'X;
            end
        endcase
    end

    always_comb begin
        hdr_flit = '0;

        hdr_flit.core.dst_chip_id = '0;
        hdr_flit.core.dst_x_coord = DST_DRAM_X[`MSG_DST_X_WIDTH-1:0];
        hdr_flit.core.dst_y_coord = DST_DRAM_Y[`MSG_DST_Y_WIDTH-1:0];
        hdr_flit.core.dst_fbits = '0;
        hdr_flit.core.msg_len = flits_to_send_reg;
        hdr_flit.core.msg_type = `MSG_TYPE_STORE_MEM;

        hdr_flit.req.addr = req_entry_reg.mem_req_addr;
        hdr_flit.req.data_size = req_entry_reg.mem_req_size;

        hdr_flit.core.src_chip_id = '0;
        hdr_flit.core.src_x_coord = SRC_X[`MSG_SRC_X_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`MSG_SRC_Y_WIDTH-1:0];
        hdr_flit.core.src_fbits = FBITS;
    end
endmodule
