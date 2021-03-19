/* This module handles turning a read request into NoC packets.
 * Note that it doesn't check for alignment requirements having to do with
 * data sizes/addresses. Instead, it expects the requesting module to break
 * up its requests appropriately
 */
`include "noc_defs.vh"

module rd_mem_noc_module 
import mem_noc_helper_pkg::*;
import beehive_noc_msg::*;
#(
     parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
) (
     input clk
    ,input rst

    ,output logic                               rd_mem_noc_req_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       rd_mem_noc_req_noc0_data
    ,input  logic                               noc_rd_mem_req_noc0_rdy

    ,input  logic                               noc_rd_mem_resp_noc0_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       noc_rd_mem_resp_noc0_data
    ,output logic                               rd_mem_noc_resp_noc0_rdy

    ,input  logic                               src_rd_mem_req_val
    ,input  mem_req_struct                      src_rd_mem_req_entry
    ,output logic                               rd_mem_src_req_rdy

    ,output logic                               rd_mem_src_resp_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       rd_mem_src_resp_data
    ,output logic                               rd_mem_src_resp_last
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   rd_mem_src_resp_padbytes
    ,input  logic                               src_rd_mem_resp_rdy
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        SEND_RD_REQ = 2'd1,
        WAIT_RD_RESP = 2'd2,
        RECV_RD_RESP = 2'd3,
        UND = 'X
    } states_e;

    states_e state_reg;
    states_e state_next;
    
    mem_req_struct  req_entry_next;
    mem_req_struct  req_entry_reg;
   
    dram_noc_hdr_flit                   hdr_flit;
    dram_noc_hdr_flit                   rd_req_flit;
    dram_noc_hdr_flit                   rd_resp_flit_cast;
    dram_noc_hdr_flit                   rd_resp_flit_next;
    dram_noc_hdr_flit                   rd_resp_flit_reg;

    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_recv_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_recv_next;
    
    logic   [`NOC_PADBYTES_WIDTH-1:0]   last_padbytes;

    assign rd_resp_flit_cast = noc_rd_mem_resp_noc0_data;
    assign last_padbytes = req_entry_reg.mem_req_size[`NOC_PADBYTES_WIDTH-1:0] == 0
                         ? '0
                         : (`NOC_DATA_BYTES - req_entry_reg.mem_req_size[`NOC_PADBYTES_WIDTH-1:0]);

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            req_entry_reg <= '0;
            rd_resp_flit_reg <= '0;
            flits_recv_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            req_entry_reg <= req_entry_next;
            rd_resp_flit_reg <= rd_resp_flit_next;
            flits_recv_reg <= flits_recv_next;
        end
    end

    assign rd_mem_noc_req_noc0_data = hdr_flit;
    assign rd_mem_src_resp_data = noc_rd_mem_resp_noc0_data;

    always_comb begin
        state_next = state_reg;
        req_entry_next = req_entry_reg;
        rd_resp_flit_next = rd_resp_flit_reg;
        flits_recv_next = flits_recv_reg;

        rd_mem_src_req_rdy = 1'b0;
        rd_mem_noc_req_noc0_val = 1'b0;
        rd_mem_noc_resp_noc0_rdy = 1'b0;
        rd_mem_src_resp_val = 1'b0;
        rd_mem_src_resp_last = 1'b0;
        rd_mem_src_resp_padbytes = '0;

        case (state_reg)
            READY: begin
                rd_mem_src_req_rdy = 1'b1;
                if (src_rd_mem_req_val) begin
                    req_entry_next = src_rd_mem_req_entry;
                    flits_recv_next = '0;
                    state_next = SEND_RD_REQ;
                end
                else begin
                    state_next = READY;
                end
            end
            SEND_RD_REQ: begin
                rd_mem_noc_req_noc0_val = 1'b1;
                if (noc_rd_mem_req_noc0_rdy) begin
                    state_next = WAIT_RD_RESP;
                end
                else begin
                    state_next = SEND_RD_REQ;
                end
            end
            WAIT_RD_RESP: begin
                rd_mem_noc_resp_noc0_rdy = 1'b1;

                if (noc_rd_mem_resp_noc0_val) begin
                    rd_resp_flit_next = noc_rd_mem_resp_noc0_data;
                    state_next = RECV_RD_RESP;
                end
                else begin
                    state_next = WAIT_RD_RESP;
                end
            end
            RECV_RD_RESP: begin
                rd_mem_noc_resp_noc0_rdy = src_rd_mem_resp_rdy;
                rd_mem_src_resp_val = noc_rd_mem_resp_noc0_val;

                if (src_rd_mem_resp_rdy & noc_rd_mem_resp_noc0_val) begin
                    flits_recv_next = flits_recv_reg + 1'b1;
                    if (flits_recv_reg == (rd_resp_flit_reg.core.msg_len - 1'b1)) begin
                        rd_mem_src_resp_last = 1'b1;
                        rd_mem_src_resp_padbytes = last_padbytes;
                        state_next = READY;
                    end
                    else begin
                        state_next = RECV_RD_RESP;
                    end
                end
                else begin
                    state_next = RECV_RD_RESP;
                end
            end
            default: begin
                state_next = UND;
                req_entry_next = 'X;
                rd_resp_flit_next = 'X;
                flits_recv_next = 'X;

                rd_mem_src_req_rdy = 'X;
                rd_mem_noc_req_noc0_val = 'X;
                rd_mem_noc_resp_noc0_rdy = 'X;
                rd_mem_src_resp_val = 'X;
                rd_mem_src_resp_last = 'X;
                rd_mem_src_resp_padbytes = 'X;
            end
        endcase
    end

    always_comb begin
        hdr_flit = '0;
        hdr_flit.core.dst_chip_id = '0;
        hdr_flit.core.dst_x_coord = DST_DRAM_X[`MSG_DST_X_WIDTH-1:0];
        hdr_flit.core.dst_y_coord = DST_DRAM_Y[`MSG_DST_Y_WIDTH-1:0];
        hdr_flit.core.dst_fbits = '0;
        hdr_flit.core.msg_len = '0;
        hdr_flit.core.msg_type = `MSG_TYPE_LOAD_MEM;

        hdr_flit.req.addr = req_entry_reg.mem_req_addr;
        hdr_flit.req.data_size = req_entry_reg.mem_req_size;
        
        hdr_flit.core.src_chip_id = 'b0;
        hdr_flit.core.src_x_coord = SRC_X[`MSG_SRC_X_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`MSG_SRC_Y_WIDTH-1:0];
        hdr_flit.core.src_fbits = FBITS;
    end

endmodule
