`include "rr_scheduler_defs.svh"
module rr_scheduler #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NUM_DSTS = -1
    ,parameter NUM_DSTS_W = (NUM_DSTS == 1) ? 1 : $clog2(NUM_DSTS)
)(
     input clk
    ,input rst
    
    ,input                                  src_rr_scheduler_val
    ,input          [`NOC_DATA_WIDTH-1:0]   src_rr_scheduler_data
    ,output logic                           rr_scheduler_src_rdy
    
    ,output logic                           rr_scheduler_dst_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rr_scheduler_dst_data
    ,input                                  dst_rr_scheduler_rdy

    ,output logic                           scheduler_table_read_val
    ,output logic   [NUM_DSTS_W-1:0]        scheduler_table_read_index
    ,input  logic                           table_scheduler_read_rdy

    ,input  logic                           table_scheduler_read_resp_val
    ,input  sched_table_struct              table_scheduler_read_resp_data
    ,output logic                           scheduler_table_read_resp_rdy
);

    logic   [NUM_DSTS_W-1:0]    index_reg;
    logic   [NUM_DSTS_W-1:0]    index_next;
    logic                       incr_index;

    logic                           store_len;
    logic   [`MSG_LENGTH_WIDTH-1:0] len_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] len_next;
    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_next;
    logic                           reset_flit_cnt;
    logic                           incr_flit_cnt;
    logic                           last_flit;

    logic                           use_hdr_out;


    beehive_noc_hdr_flit hdr_flit_cast;
    beehive_noc_hdr_flit hdr_out;

    assign hdr_flit_cast = src_rr_scheduler_data;
    assign last_flit = flit_cnt_reg == (len_reg - 1);

    assign scheduler_table_read_val = 1'b1;
    assign scheduler_table_read_index = index_next;
    assign scheduler_table_read_resp_rdy = 1'b1;

    assign rr_scheduler_dst_data = use_hdr_out
                                ? hdr_out
                                : src_rr_scheduler_data;

    typedef enum logic[1:0] {
        READY = 2'd0,
        PASS_BODY = 2'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            len_reg <= '0;
            flit_cnt_reg <= '0;
            index_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            len_reg <= len_next;
            flit_cnt_reg <= flit_cnt_next;
            index_reg <= index_next;
        end
    end

    assign len_next = store_len
                    ? hdr_flit_cast.core.core.msg_len
                    : len_reg;

    assign flit_cnt_next = reset_flit_cnt
                        ? '0
                        : incr_flit_cnt
                            ? flit_cnt_reg + 1'b1
                            : flit_cnt_reg;

    assign index_next = incr_index
                        ? index_reg == (NUM_DSTS-1)
                            ? '0
                            : index_reg + 1'b1
                        : index_reg;
                    

    always_comb begin
        rr_scheduler_src_rdy = 1'b0;
        rr_scheduler_dst_val = 1'b0;

        incr_index = 1'b0;
        reset_flit_cnt = 1'b0;
        incr_flit_cnt = 1'b0;
        store_len = 1'b0;

        use_hdr_out = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                rr_scheduler_src_rdy = dst_rr_scheduler_rdy;
                rr_scheduler_dst_val = src_rr_scheduler_val;

                reset_flit_cnt = 1'b1;
                use_hdr_out = 1'b1;
                store_len = 1'b1;
                if (src_rr_scheduler_val & dst_rr_scheduler_rdy) begin
                    // at the moment we don't have any zero length messages, but
                    // I suppose we might
                    if (hdr_flit_cast.core.core.msg_len == 0) begin
                        incr_index = 1'b1;
                        state_next =  READY;
                    end
                    else begin
                        state_next = PASS_BODY;
                    end
                end
            end
            PASS_BODY: begin
                rr_scheduler_src_rdy = dst_rr_scheduler_rdy;
                rr_scheduler_dst_val = src_rr_scheduler_val;
                if (src_rr_scheduler_val & dst_rr_scheduler_rdy) begin
                    incr_flit_cnt = 1'b1;
                    if (last_flit) begin
                        incr_index = 1'b1;
                        state_next = READY;
                    end
                end
            end
            default: begin
                rr_scheduler_src_rdy = 'X;
                rr_scheduler_dst_val = 'X;

                incr_index = 'X;
                reset_flit_cnt = 'X;
                incr_flit_cnt = 'X;

                state_next = UND;
            end
        endcase
    end

    always_comb begin
        hdr_out = hdr_flit_cast;

        hdr_out.core.core.dst_x_coord = table_scheduler_read_resp_data.dst_x;
        hdr_out.core.core.dst_y_coord = table_scheduler_read_resp_data.dst_y;
    end

endmodule
