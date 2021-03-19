`include "masked_mem_defs.svh"
module masked_mem_datap #(
     parameter MEM_DATA_W = -1
    ,parameter MEM_DATA_BYTES = MEM_DATA_W/8
    ,parameter MEM_ADDR_W = -1
    ,parameter MEM_WR_MASK_W = MEM_DATA_BYTES
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_controller_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]   controller_noc0_vrtoc_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]   wr_resp_noc_vrtoc_data

    ,input          [`NOC_DATA_WIDTH-1:0]   noc_ctovr_rd_req_data

    ,output logic   [MEM_ADDR_W-1:0]        controller_mem_addr
    ,output logic   [MEM_DATA_W-1:0]        controller_mem_wr_data
    ,output logic   [MEM_WR_MASK_W-1:0]     controller_mem_byte_en
    ,output logic   [7-1:0]                 controller_mem_burst_cnt

    ,input          [MEM_DATA_W-1:0]        mem_controller_rd_data
    
    ,input  logic                           rd_ctrl_datap_store_state
    ,input  logic                           rd_ctrl_datap_update_state
    ,input  logic                           rd_ctrl_datap_store_rem_reg
    ,input  logic                           rd_ctrl_datap_shift_regs
    ,input  logic                           rd_ctrl_datap_hdr_flit_out
    ,input  logic                           rd_ctrl_datap_incr_sent_flits

    ,output logic                           datap_rd_ctrl_last_read
    ,output logic                           datap_rd_ctrl_last_flit
    ,output logic                           datap_rd_ctrl_first_read
    ,output logic                           datap_rd_ctrl_read_aligned

    ,input  logic                           wr_ctrl_datap_store_state
    ,input  logic                           wr_ctrl_datap_update_state
    ,input  logic                           wr_ctrl_datap_hdr_flit_out
    ,input  logic                           wr_ctrl_datap_store_rem_reg
    ,input  logic                           wr_ctrl_datap_shift_regs
    ,input  logic                           wr_ctrl_datap_incr_recv_flits
    ,input  logic                           wr_ctrl_datap_first_wr
    
    ,output logic                           datap_wr_ctrl_last_flit
    ,output logic                           datap_wr_ctrl_last_write
    ,output logic                           datap_wr_ctrl_wr_aligned
);

    typedef struct packed {
        logic   [`MSG_DST_X_WIDTH-1:0]      src_x_coord;
        logic   [`MSG_DST_Y_WIDTH-1:0]      src_y_coord;
        logic   [`MSG_DST_FBITS_WIDTH-1:0]  src_fbits;
        logic   [`MSG_LENGTH_WIDTH-1:0]     msg_len;
        logic   [`MSG_TYPE_WIDTH-1:0]       msg_type;
        logic   [`MSG_ADDR_WIDTH-1:0]       addr;
        logic   [`MSG_DATA_SIZE_WIDTH-1:0]  data_size;
    } req_state_struct;

    localparam BLOCK_ADDR_W = `NOC_DATA_BYTES_W;
    localparam MASK_SHIFT_W = $clog2(MEM_DATA_BYTES);
    localparam DATA_SHIFT_W = $clog2(`NOC_DATA_WIDTH);

    dram_noc_hdr_flit hdr_flit_in_cast;
    dram_noc_hdr_flit hdr_flit_out_cast;

    req_state_struct req_state_reg;
    req_state_struct req_state_next;
        
    logic   [(`NOC_DATA_WIDTH*2)-1:0]   shifted_read_data;
    logic   [(`NOC_DATA_WIDTH*2)-1:0]   shifted_write_data;

    logic   [`MSG_ADDR_WIDTH-1:0]       curr_addr_reg;
    logic   [`MSG_ADDR_WIDTH-1:0]       curr_addr_next;

    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_read_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_read_next;
    
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_to_write_reg;
    logic   [`MSG_DATA_SIZE_WIDTH-1:0]  bytes_to_write_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_recv_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_recv_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_sent_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_sent_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_to_send_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_to_send_next;

    logic   [`NOC_DATA_BYTES_W:0]       mem_op_len;

    logic   [`NOC_DATA_WIDTH-1:0]       rd_rem_reg;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_rem_next;
    
    logic   [`NOC_DATA_WIDTH-1:0]       rd_line_reg;
    logic   [`NOC_DATA_WIDTH-1:0]       rd_line_next;

    logic   [`NOC_DATA_WIDTH-1:0]       wr_rem_reg;
    logic   [`NOC_DATA_WIDTH-1:0]       wr_rem_next;
    
    logic   [`NOC_DATA_WIDTH-1:0]       wr_line_reg;
    logic   [`NOC_DATA_WIDTH-1:0]       wr_line_next;

    logic   [DATA_SHIFT_W-1:0]          rd_data_shift_bytes;
    logic   [DATA_SHIFT_W-1:0]          rd_data_shift_bits;

    logic   [BLOCK_ADDR_W-1:0]          block_addr;
    logic   [MASK_SHIFT_W-1:0]          mask_data_shift;
    logic   [MEM_WR_MASK_W-1:0]         bytes_mask;
    logic   [DATA_SHIFT_W:0]            wr_data_shift_bytes;
    logic   [DATA_SHIFT_W:0]            wr_data_shift_bits;
    logic   [DATA_SHIFT_W:0]            addr_shift_bits;

    assign block_addr = curr_addr_reg[BLOCK_ADDR_W-1:0];
    
    assign controller_mem_addr = curr_addr_reg[BLOCK_ADDR_W +: MEM_ADDR_W];

    assign rd_data_shift_bits = rd_data_shift_bytes << 3;
    // if we're aligned, we don't have to shift any bytes out. Otherwise, we
    // used some of the m in the previous cycle
    assign wr_data_shift_bytes = req_state_reg.addr[BLOCK_ADDR_W-1:0] == 0
                                ? '0
                                : wr_ctrl_datap_first_wr
                                ? '0
                                : req_state_reg.addr[BLOCK_ADDR_W-1:0];
    assign wr_data_shift_bits = wr_data_shift_bytes << 3;
    assign addr_shift_bits = block_addr << 3;

    assign shifted_read_data = {rd_rem_reg, rd_line_reg} << rd_data_shift_bits;
    assign shifted_write_data = {wr_rem_reg, wr_line_reg} >> wr_data_shift_bits;

    assign hdr_flit_in_cast = rd_ctrl_datap_store_state
                            ? noc_ctovr_rd_req_data
                            : noc0_ctovr_controller_data;
    assign controller_noc0_vrtoc_data = (rd_ctrl_datap_hdr_flit_out | 
                                         wr_ctrl_datap_hdr_flit_out)
                        ? hdr_flit_out_cast
                        : shifted_read_data[(`NOC_DATA_WIDTH*2)-1 -: `NOC_DATA_WIDTH];
    assign wr_resp_noc_vrtoc_data = hdr_flit_out_cast;
    assign rd_data_shift_bytes = req_state_reg.addr[BLOCK_ADDR_W-1:0];

//    assign data_shift_bytes = req_state_reg.addr[BLOCK_ADDR_W-1:0] == 0
//                            ? `NOC_DATA_BYTES
//                            : req_state_reg.addr[BLOCK_ADDR_W-1:0];

    assign controller_mem_burst_cnt = 6'd1;

    // are we aligned?
    assign mem_op_len = curr_addr_reg[`NOC_DATA_BYTES_W-1:0] == 0
                            ? `NOC_DATA_BYTES
                            : `NOC_DATA_BYTES - curr_addr_reg[`NOC_DATA_BYTES_W-1:0];

    assign datap_rd_ctrl_first_read = curr_addr_reg == req_state_reg.addr;

    // if our first line was aligned, we can output the result immediately
    assign datap_rd_ctrl_read_aligned = req_state_reg.addr[`NOC_DATA_BYTES_W-1:0] == 0;


    assign datap_rd_ctrl_last_flit = flits_sent_reg == (flits_to_send_reg - 1'b1);
    assign datap_rd_ctrl_last_read = bytes_read_reg >= req_state_reg.data_size;

    assign datap_wr_ctrl_last_flit = flits_recv_reg == (req_state_reg.msg_len - 1'b1);
    assign datap_wr_ctrl_last_write = bytes_to_write_reg <= (MEM_DATA_BYTES - block_addr);
    assign datap_wr_ctrl_wr_aligned = req_state_reg.addr[`NOC_DATA_BYTES_W-1:0] == 0;

    assign controller_mem_byte_en = bytes_mask >> block_addr;

    assign bytes_mask = {(MEM_WR_MASK_W){1'b1}} << mask_data_shift;

    assign mask_data_shift = bytes_to_write_reg >= MEM_DATA_BYTES
                            ? '0
                            : MEM_DATA_BYTES - bytes_to_write_reg;

    assign controller_mem_wr_data = 
        (shifted_write_data[MEM_DATA_W-1:0]) >> addr_shift_bits;

    always_ff @(posedge clk) begin
        if (rst) begin
            curr_addr_reg <= '0;
            rd_rem_reg <= '0;
            rd_line_reg <= '0;
            flits_sent_reg <= '0;
            flits_to_send_reg <= '0;
            bytes_read_reg <= '0;
            bytes_to_write_reg <= '0;
            wr_rem_reg <= '0;
            wr_line_reg <= '0;
            flits_recv_reg <= '0;
            req_state_reg <= '0;
        end
        else begin
            curr_addr_reg <= curr_addr_next;
            rd_rem_reg <= rd_rem_next;
            rd_line_reg <= rd_line_next;
            flits_sent_reg <= flits_sent_next;
            flits_to_send_reg <= flits_to_send_next;
            bytes_read_reg <= bytes_read_next;
            bytes_to_write_reg <= bytes_to_write_next;
            wr_rem_reg <= wr_rem_next;
            wr_line_reg <= wr_line_next;
            flits_recv_reg <= flits_recv_next;
            req_state_reg <= req_state_next;
        end
    end

    always_comb begin
        req_state_next = req_state_reg;
        if (rd_ctrl_datap_store_state | wr_ctrl_datap_store_state) begin
            req_state_next.src_x_coord = hdr_flit_in_cast.core.src_x_coord;
            req_state_next.src_y_coord = hdr_flit_in_cast.core.src_y_coord;
            req_state_next.src_fbits = hdr_flit_in_cast.core.src_fbits;
            req_state_next.msg_len = hdr_flit_in_cast.core.msg_len;
            req_state_next.msg_type = hdr_flit_in_cast.core.msg_type;
            req_state_next.addr = hdr_flit_in_cast.addr;
            req_state_next.data_size = hdr_flit_in_cast.data_size;
        end
        else begin
            req_state_next = req_state_reg;
        end
    end

    assign flits_to_send_next = rd_ctrl_datap_store_state
                            ? hdr_flit_in_cast.data_size[`NOC_DATA_BYTES_W-1:0] == 0
                                ? hdr_flit_in_cast.data_size >> `NOC_DATA_BYTES_W
                                : (hdr_flit_in_cast.data_size >> `NOC_DATA_BYTES_W) + 1
                            : flits_to_send_reg;

    assign flits_recv_next = wr_ctrl_datap_store_state
                            ? '0
                            : wr_ctrl_datap_incr_recv_flits
                                ? flits_recv_reg + 1'b1
                                : flits_recv_reg;

    assign flits_sent_next = rd_ctrl_datap_store_state
                            ? '0
                            : rd_ctrl_datap_incr_sent_flits
                                ? flits_sent_reg + 1'b1
                                : flits_sent_reg;

    assign bytes_read_next = rd_ctrl_datap_store_state
                            ? '0
                            : rd_ctrl_datap_update_state
                                ? bytes_read_reg + mem_op_len
                                : bytes_read_reg;

    assign bytes_to_write_next = wr_ctrl_datap_store_state
                            ? hdr_flit_in_cast.data_size
                            : wr_ctrl_datap_update_state
                                ? bytes_to_write_reg - mem_op_len
                                : bytes_to_write_reg;

    assign curr_addr_next = (rd_ctrl_datap_store_state | wr_ctrl_datap_store_state)
                        ? hdr_flit_in_cast.addr
                        : (rd_ctrl_datap_update_state | wr_ctrl_datap_update_state)
                            ? curr_addr_reg + mem_op_len
                            : curr_addr_reg;

    assign rd_rem_next = rd_ctrl_datap_store_rem_reg
                        ? mem_controller_rd_data
                        : rd_ctrl_datap_shift_regs
                            ? rd_line_reg
                            : rd_rem_reg;
    assign rd_line_next = rd_ctrl_datap_shift_regs
                            ? mem_controller_rd_data
                            : rd_line_reg;

    assign wr_rem_next = wr_ctrl_datap_store_rem_reg
                        ? noc0_ctovr_controller_data
                        : wr_ctrl_datap_shift_regs
                            ? wr_line_reg
                            : wr_rem_reg;

    assign wr_line_next = wr_ctrl_datap_shift_regs
                        ? noc0_ctovr_controller_data
                        : wr_line_reg;
    
    // response flit crafting
    always_comb begin
        hdr_flit_out_cast = '0; 
        hdr_flit_out_cast.core.dst_x_coord = req_state_reg.src_x_coord;
        hdr_flit_out_cast.core.dst_y_coord = req_state_reg.src_y_coord;
        hdr_flit_out_cast.core.dst_fbits = req_state_reg.src_fbits;
        hdr_flit_out_cast.data_size = req_state_reg.data_size;

        hdr_flit_out_cast.core.src_chip_id = '0;
        hdr_flit_out_cast.core.src_x_coord = SRC_X[`MSG_SRC_X_WIDTH-1:0];
        hdr_flit_out_cast.core.src_y_coord = SRC_Y[`MSG_SRC_Y_WIDTH-1:0];
        hdr_flit_out_cast.core.src_fbits = PKT_IF_FBITS;

        if (req_state_reg.msg_type == `MSG_TYPE_STORE_MEM) begin
            hdr_flit_out_cast.core.msg_len = '0;
            hdr_flit_out_cast.core.msg_type = `MSG_TYPE_STORE_MEM_ACK;
        end
        else if (req_state_reg.msg_type == `MSG_TYPE_LOAD_MEM) begin
            hdr_flit_out_cast.core.msg_len = flits_to_send_reg;
            hdr_flit_out_cast.core.msg_type = `MSG_TYPE_LOAD_MEM_ACK;
        end
    end

endmodule
