module flit_hdr_strip 
import beehive_noc_msg::*;
(
     input clk
    ,input rst

    ,input  logic                           src_strip_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   src_strip_data
    ,output logic                           strip_src_rdy
    
    ,output logic                           strip_dst_hdr_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   strip_dst_hdr_data
    ,output logic                           strip_dst_hdr_last
    ,input  logic                           dst_strip_hdr_rdy

    ,output logic                           strip_dst_data_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   strip_dst_data
    ,output logic                           strip_dst_last
    ,input  logic                           dst_strip_data_rdy
);

    assign strip_dst_hdr_data = src_strip_data;
    assign strip_dst_data = src_strip_data;

    typedef enum logic[1:0] {
        HDR_FLIT = 2'd0,
        META_FLITS = 2'd1,
        DATA_FLITS = 2'd2,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   [`MSG_LENGTH_WIDTH-1:0]     msg_flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     msg_flit_cnt_next;
    logic                               store_msg_flit_cnt;
    logic                               decr_msg_flit_cnt;

    logic   [MSG_METADATA_FLITS_W-1:0]  meta_flit_cnt_reg;
    logic   [MSG_METADATA_FLITS_W-1:0]  meta_flit_cnt_next;
    logic                               store_meta_flit_cnt;
    logic                               decr_meta_flit_cnt;

    beehive_noc_hdr_flit hdr_flit_cast;
    
    assign hdr_flit_cast = src_strip_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR_FLIT;
        end
        else begin
            state_reg <= state_next;
            msg_flit_cnt_reg <= msg_flit_cnt_next;
            meta_flit_cnt_reg <= meta_flit_cnt_next;
        end
    end

    assign msg_flit_cnt_next = store_msg_flit_cnt
                            ? hdr_flit_cast.core.core.msg_len
                            : decr_msg_flit_cnt
                                ? msg_flit_cnt_reg - 1'b1
                                : msg_flit_cnt_reg;

    assign meta_flit_cnt_next = store_msg_flit_cnt
                                ? hdr_flit_cast.core.metadata_flits
                                : decr_meta_flit_cnt
                                    ? meta_flit_cnt_reg - 1'b1
                                    : meta_flit_cnt_reg;

    assign strip_dst_last = msg_flit_cnt_reg == 1;

    always_comb begin
        strip_dst_hdr_val = 1'b0;
        strip_dst_hdr_last = 1'b0;
        strip_dst_data_val = 1'b0;
        strip_src_rdy = 1'b0;

        store_msg_flit_cnt = 1'b0;
        store_meta_flit_cnt = 1'b0;
        decr_msg_flit_cnt = 1'b0;
        decr_meta_flit_cnt = 1'b0;
    
        state_next = state_reg;
        case (state_reg)
            HDR_FLIT: begin
                strip_dst_hdr_val = src_strip_val;
                strip_src_rdy = dst_strip_hdr_rdy;
                store_msg_flit_cnt = 1'b1;
                store_meta_flit_cnt = 1'b1;
                if (src_strip_val & dst_strip_hdr_rdy) begin
                    // if there's more than a header flit
                    if (hdr_flit_cast.core.core.msg_len != 0) begin
                        // if there are metadata flits
                        if (hdr_flit_cast.core.metadata_flits != 0) begin
                            state_next = META_FLITS;
                        end
                        else begin
                            strip_dst_hdr_last = 1'b1;
                            state_next = DATA_FLITS;
                        end
                    end
                end
            end
            META_FLITS: begin
                strip_dst_hdr_val = src_strip_val;
                strip_src_rdy = dst_strip_hdr_rdy;

                if (src_strip_val & dst_strip_hdr_rdy) begin
                    decr_msg_flit_cnt = 1'b1;
                    decr_meta_flit_cnt = 1'b1;
                    // if this is the last body flit
                    if (msg_flit_cnt_reg == 1) begin
                        strip_dst_hdr_last = 1'b1;
                        state_next = HDR_FLIT;
                    end
                    // if this is the last metadata flit
                    else if (meta_flit_cnt_reg == 1) begin
                        strip_dst_hdr_last = 1'b1;
                        state_next = DATA_FLITS;
                    end
                end
            end
            DATA_FLITS: begin
                strip_dst_data_val = src_strip_val;
                strip_src_rdy = dst_strip_data_rdy;

                if (src_strip_val & dst_strip_data_rdy) begin
                    decr_msg_flit_cnt = 1'b1;
                    if (msg_flit_cnt_reg == 1) begin
                        state_next = HDR_FLIT;
                    end
                end
            end
            default: begin
                strip_dst_hdr_val = 'X;
                strip_src_rdy = 'X;

                store_msg_flit_cnt = 'X;
                store_meta_flit_cnt = 'X;
                decr_msg_flit_cnt = 'X;
                decr_meta_flit_cnt = 'X;
    
                state_next = UND;
            end
        endcase
    end
endmodule
