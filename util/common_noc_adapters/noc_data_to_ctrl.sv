`include "noc_datactrl_convert.svh"
module noc_data_to_ctrl (
     input clk
    ,input rst

    ,input                                  src_noc_dtc_val
    ,input          [`NOC_DATA_WIDTH-1:0]   src_noc_dtc_data
    ,output logic                           noc_dtc_src_rdy

    ,output logic                           noc_dtc_dst_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] noc_dtc_dst_data
    ,input                                  dst_noc_dtc_rdy
);

    localparam FLIT_MULTIPLES = `NOC_DATA_WIDTH/`CTRL_NOC1_DATA_W; 
    localparam FLIT_SHIFT = $clog2(FLIT_MULTIPLES);

    typedef enum logic[1:0] {
        READY = 2'd0,
        MISC_HDR_FLIT = 2'd1,
        PASS_DATA_FLITS = 2'd2,
        DRAIN = 2'd3,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        HDR_FLIT_1,
        HDR_FLIT_2,
        DATA
    } flit_mux_sel_e;

    state_e state_reg;
    state_e state_next;

    beehive_noc_hdr_flit    wide_hdr_flit;
    beehive_noc_hdr_flit    wide_hdr_flit_reg;
    beehive_noc_hdr_flit    wide_hdr_flit_next;
    routing_hdr_flit        narrow_hdr_flit_1;
    misc_hdr_flit           narrow_hdr_flit_2;

    flit_mux_sel_e          mux_sel;

    logic                           store_count;
    logic                           decr_count;
    logic   [`MSG_LENGTH_WIDTH-1:0] count_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] count_next;

    logic                           store_hdr_flit;

    logic                           wide_val;
    logic                           wide_last;
    logic                           wide_rdy;

    logic                           narrow_val;
    logic                           narrow_last;
    logic   [`CTRL_NOC1_DATA_W-1:0] narrow_data;
    logic                           narrow_rdy;

    assign wide_hdr_flit = src_noc_dtc_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            wide_hdr_flit_reg <= wide_hdr_flit_next;
            count_reg <= count_next;
        end
    end

    assign wide_hdr_flit_next = store_hdr_flit
                            ? src_noc_dtc_data
                            : wide_hdr_flit_reg;

    assign count_next = store_count
                        ? wide_hdr_flit_next.core.msg_len
                        : decr_count
                            ? count_reg - 1'b1
                            : count_reg;

    always_comb begin
        store_hdr_flit = 1'b0;

        store_count = 1'b0;
        decr_count = 1'b0;

        noc_dtc_dst_val = 1'b0;
        noc_dtc_src_rdy = 1'b0;

        wide_val = 1'b0;
        wide_last = 1'b0;
        narrow_rdy = 1'b0;

        mux_sel = HDR_FLIT_1;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                store_count = 1'b1;
                store_hdr_flit = 1'b1;
                noc_dtc_dst_val = src_noc_dtc_val;
                noc_dtc_src_rdy = dst_noc_dtc_rdy;
                mux_sel = HDR_FLIT_1;

                if (src_noc_dtc_val & dst_noc_dtc_rdy) begin
                    state_next = MISC_HDR_FLIT;
                end
            end
            MISC_HDR_FLIT: begin
                mux_sel = HDR_FLIT_2;
                noc_dtc_dst_val = 1'b1;

                if (dst_noc_dtc_rdy) begin
                    // if we only have header flits. This is 0 (as opposed to
                    // 1 when passing data flits), because count will be 0 if
                    // we only have header flits
                    if (count_reg == 0) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = PASS_DATA_FLITS;
                    end
                end
            end
            PASS_DATA_FLITS: begin
                mux_sel = DATA;

                // assign the output to pass as necessary
                noc_dtc_dst_val = narrow_val;
                narrow_rdy = dst_noc_dtc_rdy;

                wide_val = src_noc_dtc_val;
                noc_dtc_src_rdy = wide_rdy;

                if (src_noc_dtc_val & wide_rdy) begin
                    decr_count = 1'b1;
                    if (count_reg == 1) begin
                        wide_last = 1'b1;
                        state_next = DRAIN;
                    end
                end
            end
            DRAIN: begin
                mux_sel = DATA;
                noc_dtc_dst_val = narrow_val;
                narrow_rdy = dst_noc_dtc_rdy;

                if (narrow_val & dst_noc_dtc_rdy) begin
                    if (narrow_last) begin
                        state_next = READY;
                    end
                end
            end
        endcase
    end

    wide_to_narrow #(
         .OUT_DATA_W    (`CTRL_NOC1_DATA_W  )
        ,.IN_DATA_ELS   (FLIT_MULTIPLES     )
    ) wtn (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_w_to_n_val    (wide_val           )
        ,.src_w_to_n_data   (src_noc_dtc_data   )
        ,.src_w_to_n_keep   ('1)
        ,.src_w_to_n_last   (wide_last          )
        ,.w_to_n_src_rdy    (wide_rdy           )
    
        ,.w_to_n_dst_val    (narrow_val         )
        ,.w_to_n_dst_data   (narrow_data        )
        ,.w_to_n_dst_keep   ()
        ,.w_to_n_dst_last   (narrow_last        )
        ,.dst_w_to_n_rdy    (narrow_rdy         )
    );

    always_comb begin
        if (mux_sel == HDR_FLIT_1) begin
            noc_dtc_dst_data = narrow_hdr_flit_1;
        end
        else if (mux_sel == HDR_FLIT_2) begin
            noc_dtc_dst_data = narrow_hdr_flit_2;
        end
        else begin
            noc_dtc_dst_data = narrow_data;
        end
    end

    always_comb begin
        narrow_hdr_flit_1 = wide_hdr_flit[`NOC_DATA_WIDTH-1 -: `CTRL_NOC1_DATA_W];
        // plus one for the extra hdr flit
        narrow_hdr_flit_1.msg_len = (wide_hdr_flit.core.msg_len << FLIT_SHIFT) + 1;
    end

    always_comb begin
        narrow_hdr_flit_2 = '0;
        narrow_hdr_flit_2.src_chip_id = wide_hdr_flit_reg.core.src_chip_id;
        narrow_hdr_flit_2.src_x_coord = wide_hdr_flit_reg.core.src_x_coord;
        narrow_hdr_flit_2.src_y_coord = wide_hdr_flit_reg.core.src_y_coord;
        narrow_hdr_flit_2.src_fbits = wide_hdr_flit_reg.core.src_fbits;
        narrow_hdr_flit_2.metadata_flits = wide_hdr_flit_reg.core.metadata_flits << FLIT_SHIFT;
    end
endmodule
