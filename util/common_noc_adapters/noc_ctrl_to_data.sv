`include "noc_datactrl_convert.svh"
module noc_ctrl_to_data (
     input clk
    ,input rst
    
    ,input                                  src_noc_ctd_val
    ,input          [`CTRL_NOC1_DATA_W-1:0] src_noc_ctd_data
    ,output logic                           noc_ctd_src_rdy

    ,output logic                           noc_ctd_dst_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   noc_ctd_dst_data
    ,input                                  dst_noc_ctd_rdy
);
    localparam FLIT_MULTIPLES = `NOC_DATA_WIDTH/`CTRL_NOC1_DATA_W; 
    localparam FLIT_SHIFT = $clog2(FLIT_MULTIPLES);

    typedef enum logic[2:0] {
        READY = 3'd0,
        HDR_1 = 3'd1,
        HDR_OUT = 3'd2,
        PASS_BODY_FLITS = 3'd3,
        DRAIN = 3'd4,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        HDR_FLIT_OUT,
        BODY_OUT
    } flit_mux_sel_e;

    state_e state_reg;
    state_e state_next;
    
    logic                           store_count;
    logic                           decr_count;
    logic   [`MSG_LENGTH_WIDTH-1:0] count_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] count_next;
    
    logic                   store_hdr_1;
    logic                   store_hdr_2;
    beehive_noc_hdr_flit    wide_hdr_flit;
    routing_hdr_flit        narrow_hdr_flit_1_reg;
    misc_hdr_flit           narrow_hdr_flit_2_reg;
    routing_hdr_flit        narrow_hdr_flit_1_next;
    misc_hdr_flit           narrow_hdr_flit_2_next;
    
    flit_mux_sel_e          mux_sel;

    logic                           narrow_val;
    logic                           narrow_last;
    logic                           narrow_rdy;

    logic                           wide_val;
    logic                           wide_last;
    logic   [`NOC_DATA_WIDTH-1:0]   wide_data;
    logic                           wide_rdy;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            narrow_hdr_flit_1_reg <= narrow_hdr_flit_1_next;
            narrow_hdr_flit_2_reg <= narrow_hdr_flit_2_next;
            count_reg <= count_next;
        end
    end

    assign narrow_hdr_flit_1_next = store_hdr_1
                                    ? src_noc_ctd_data
                                    : narrow_hdr_flit_1_reg;

    assign narrow_hdr_flit_2_next = store_hdr_2
                                    ? src_noc_ctd_data
                                    : narrow_hdr_flit_2_reg;

    assign count_next = store_count
                        ? narrow_hdr_flit_1_next.msg_len
                        : decr_count
                            ? count_reg - 1'b1
                            : count_reg;

    always_comb begin
        store_hdr_1 = 1'b0;
        store_hdr_2 = 1'b0;

        store_count = 1'b0;
        decr_count = 1'b0;

        noc_ctd_dst_val = 1'b0;
        noc_ctd_src_rdy = 1'b0;

        narrow_val = 1'b0;
        narrow_last = 1'b0;
        wide_rdy = 1'b0;

        mux_sel = HDR_FLIT_OUT;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                store_hdr_1 = 1'b1;
                store_count = 1'b1;
                noc_ctd_src_rdy = 1'b1;
                if (src_noc_ctd_val) begin
                    state_next = HDR_1;
                end
            end
            HDR_1: begin
                store_hdr_2 = 1'b1;
                noc_ctd_src_rdy = 1'b1;
                if (src_noc_ctd_val) begin
                    decr_count = 1'b1;
                    state_next = HDR_OUT;
                end
            end
            HDR_OUT: begin
                mux_sel = HDR_FLIT_OUT;
                noc_ctd_dst_val = 1'b1;
                if (dst_noc_ctd_rdy) begin
                    // if we only have header flits. This is 0 (as opposed to
                    // 1 when passing data flits), because we wait a cycle
                    // after decrementing to check it
                    if (count_reg == 0) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = PASS_BODY_FLITS;
                    end
                end
            end
            PASS_BODY_FLITS: begin
                mux_sel = BODY_OUT;
                noc_ctd_src_rdy = narrow_rdy;
                narrow_val = src_noc_ctd_val;

                noc_ctd_dst_val = wide_val;
                wide_rdy = dst_noc_ctd_rdy;

                if (narrow_rdy & src_noc_ctd_val) begin
                    decr_count = 1'b1;
                    if (count_reg == 1) begin
                        narrow_last = 1'b1;
                        if (wide_val & dst_noc_ctd_rdy & wide_last) begin
                            state_next = READY;
                        end
                        else begin
                            state_next = DRAIN;
                        end
                    end
                end
            end
            DRAIN: begin
                mux_sel = BODY_OUT;
                noc_ctd_dst_val = wide_val;
                wide_rdy = dst_noc_ctd_rdy;
                if (wide_val & dst_noc_ctd_rdy & wide_last) begin
                    state_next = READY;
                end
            end
        endcase
    end

    narrow_to_wide #(
         .IN_DATA_W     (`CTRL_NOC1_DATA_W  )
        ,.OUT_DATA_ELS  (FLIT_MULTIPLES     )
    ) ntw (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_w_val    (narrow_val         )
        ,.src_n_to_w_data   (src_noc_ctd_data   )
        ,.src_n_to_w_keep   ('1)
        ,.src_n_to_w_last   (narrow_last        )
        ,.n_to_w_src_rdy    (narrow_rdy         )
    
        ,.n_to_w_dst_val    (wide_val           )
        ,.n_to_w_dst_data   (wide_data          )
        ,.n_to_w_dst_keep   ()
        ,.n_to_w_dst_last   (wide_last          )
        ,.dst_n_to_w_rdy    (wide_rdy           )
    );

    always_comb begin
        if (mux_sel == HDR_FLIT_OUT) begin
            noc_ctd_dst_data = wide_hdr_flit;
        end
        else begin
            noc_ctd_dst_data = wide_data;
        end
    end

    always_comb begin
        wide_hdr_flit = '0;
        wide_hdr_flit[`NOC_DATA_WIDTH-1 -: (2 * `CTRL_NOC1_DATA_W)] = 
            {narrow_hdr_flit_1_reg, narrow_hdr_flit_2_reg};
        wide_hdr_flit.core.core.msg_len = (narrow_hdr_flit_1_reg.msg_len - 1) >> FLIT_SHIFT;
        wide_hdr_flit.core.metadata_flits = (narrow_hdr_flit_2_reg.metadata_flits) >> FLIT_SHIFT;
    end
endmodule
