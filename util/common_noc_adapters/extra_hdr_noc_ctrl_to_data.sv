module extra_hdr_noc_ctrl_to_data 
    import beehive_noc_msg::*;
    import beehive_ctrl_noc_msg::*;
#(
    parameter EXTRA_W = -1
)(
     input clk
    ,input rst
    
    ,input                                  src_noc_ctd_val
    ,input          [`CTRL_NOC1_DATA_W-1:0] src_noc_ctd_data
    ,output logic                           noc_ctd_src_rdy

    ,output logic                           noc_ctd_dst_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   noc_ctd_dst_data
    ,input                                  dst_noc_ctd_rdy
);
    localparam CTRL_NOC_DATA_W_W = $clog2(`CTRL_NOC1_DATA_W);
    localparam EXTRA_FLITS = EXTRA_W[CTRL_NOC_DATA_W_W-1:0] == 0
                            ? EXTRA_W >> CTRL_NOC_DATA_W_W
                            : (EXTRA_W >> CTRL_NOC_DATA_W_W) + 1;
    localparam EXTRA_FLITS_W = $clog2(EXTRA_FLITS);
    localparam SAVE_W = EXTRA_FLITS * `CTRL_NOC1_DATA_W;
    localparam PADDING_W = SAVE_W - EXTRA_W;

    logic store_extra;
    logic   [EXTRA_FLITS-1:0][`CTRL_NOC1_DATA_W-1:0]    extra_padded_reg;
    logic   [EXTRA_FLITS-1:0][`CTRL_NOC1_DATA_W-1:0]    extra_padded_next;
    logic   [EXTRA_FLITS_W-1:0]                         extra_flit_index_reg;
    logic   [EXTRA_FLITS_W-1:0]                         extra_flit_index_next;
    logic                                               reset_extra_flit;
    logic                                               decr_extra_flit;
    logic   [SAVE_W-1:0]                                extra_flit;

    routing_hdr_flit    hdr_flit_1_reg;
    misc_hdr_flit       hdr_flit_2_reg;
    routing_hdr_flit    hdr_flit_1_next;
    misc_hdr_flit       hdr_flit_2_next;
    logic               store_hdr_1;
    logic               store_hdr_2;

    beehive_noc_hdr_flit wide_hdr_flit;

    typedef enum logic[1:0] {
        READY = 2'd0,
        HDR_1 = 2'd1,
        REM_FLITS = 2'd2,
        HDR_OUT = 2'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;

            extra_padded_reg <= extra_padded_next;
            extra_flit_index_reg <= extra_flit_index_next;
            hdr_flit_1_reg <= hdr_flit_1_next;
            hdr_flit_2_reg <= hdr_flit_2_next;
        end
    end

    assign noc_ctd_dst_data = wide_hdr_flit;

    assign extra_flit = extra_padded_reg;

    assign hdr_flit_1_next = store_hdr_1
                            ? src_noc_ctd_data
                            : hdr_flit_1_reg;
    assign hdr_flit_2_next = store_hdr_2
                            ? src_noc_ctd_data
                            : hdr_flit_2_reg;

    assign extra_flit_index_next = reset_extra_flit
                                ? EXTRA_FLITS - 1
                                : decr_extra_flit
                                    ? extra_flit_index_reg - 1'b1
                                    : extra_flit_index_reg;


    always_comb begin
        extra_padded_next = extra_padded_reg;
        if (store_extra) begin
            extra_padded_next[extra_flit_index_reg] = src_noc_ctd_data;
        end
        else begin
            extra_padded_next[extra_flit_index_reg] = extra_padded_reg[extra_flit_index_reg];
        end
    end

    always_comb begin
        store_hdr_1 = 1'b0;
        store_hdr_2 = 1'b0;
        store_extra = 1'b0;

        reset_extra_flit = 1'b0;
        decr_extra_flit = 1'b0;

        noc_ctd_dst_val = 1'b0;
        noc_ctd_src_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                store_hdr_1 = 1'b1;
                reset_extra_flit = 1'b1;
                noc_ctd_src_rdy = 1'b1;

                if (src_noc_ctd_val) begin
                    state_next = HDR_1;
                end
            end
            HDR_1: begin
                store_hdr_2 = 1'b1;
                noc_ctd_src_rdy = 1'b1;

                if (src_noc_ctd_val) begin
                    state_next = REM_FLITS;
                end
            end
            REM_FLITS: begin
                noc_ctd_src_rdy = 1'b1;
                store_extra = 1'b1;

                if (src_noc_ctd_val) begin
                    decr_extra_flit = 1'b1;
                    if (extra_flit_index_reg == 0) begin
                        state_next = HDR_OUT;
                    end
                end
            end
            HDR_OUT: begin
                noc_ctd_dst_val = 1'b1;

                if (dst_noc_ctd_rdy) begin
                    state_next = READY;
                end
            end
            default: begin
                store_hdr_1 = 'X;
                store_hdr_2 = 'X;
                store_extra = 'X;

                reset_extra_flit = 'X;
                decr_extra_flit = 'X;

                noc_ctd_dst_val = 'X;
                noc_ctd_src_rdy = 'X;

                state_next = state_reg;
            end
        endcase
    end

    always_comb begin
        wide_hdr_flit = '0;
        wide_hdr_flit[`NOC_DATA_WIDTH-1 -: (2 * `CTRL_NOC1_DATA_W)] = {hdr_flit_1_reg, hdr_flit_2_reg};
        wide_hdr_flit[`NOC_DATA_WIDTH-BASE_FLIT_W-1 -: EXTRA_W] = extra_flit[SAVE_W-1 -: EXTRA_W];
        wide_hdr_flit.core.core.msg_len = '0;
        wide_hdr_flit.core.metadata_flits = '0;
    end

endmodule
