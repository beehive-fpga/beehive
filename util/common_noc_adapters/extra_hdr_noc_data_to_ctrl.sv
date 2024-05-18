module extra_hdr_noc_data_to_ctrl 
import beehive_noc_msg::*;
import beehive_ctrl_noc_msg::*;
#(
    parameter EXTRA_W = -1
)(
     input clk
    ,input rst

    ,input                                  src_noc_dtc_val
    ,input          [`NOC_DATA_WIDTH-1:0]   src_noc_dtc_data
    ,output logic                           noc_dtc_src_rdy

    ,output logic                           noc_dtc_dst_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] noc_dtc_dst_data
    ,input                                  dst_noc_dtc_rdy
);

    localparam CTRL_NOC_DATA_W_W = $clog2(`CTRL_NOC1_DATA_W);
    localparam EXTRA_FLITS = EXTRA_W[CTRL_NOC_DATA_W_W-1:0] == 0
                            ? EXTRA_W >> CTRL_NOC_DATA_W_W
                            : (EXTRA_W >> CTRL_NOC_DATA_W_W) + 1;
    localparam EXTRA_FLITS_W = $clog2(EXTRA_FLITS);
    localparam SAVE_W = EXTRA_FLITS * `CTRL_NOC1_DATA_W;
    localparam PADDING_W = SAVE_W - EXTRA_W;
    
    logic   [`MSG_LENGTH_WIDTH-1:0] debug_extra_flits;
    assign debug_extra_flits = EXTRA_FLITS;
    
    logic   [EXTRA_FLITS-1:0][`CTRL_NOC1_DATA_W-1:0]    extra_data_padded; 

    logic   [EXTRA_FLITS_W-1:0] extra_flit_index_reg;
    logic   [EXTRA_FLITS_W-1:0] extra_flit_index_next;
    logic                       reset_extra_flit;
    logic                       decr_extra_flit;

    typedef enum logic [1:0] {
        READY = 2'd0,
        MISC_HDR_FLIT = 2'd1,
        REM_FLITS = 2'd2,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        HDR_FLIT_1,
        HDR_FLIT_2,
        EXTRAS
    } flit_mux_sel_e;

    state_e state_reg;
    state_e state_next;

    logic store_hdr;

    beehive_noc_hdr_flit hdr_flit_reg;
    beehive_noc_hdr_flit hdr_flit_next;

    routing_hdr_flit        narrow_hdr_flit_1;
    misc_hdr_flit        narrow_hdr_flit_2;

    flit_mux_sel_e          mux_sel;

    generate
        if (PADDING_W == 0) begin
            assign extra_data_padded = hdr_flit_reg[`NOC_DATA_WIDTH-BASE_FLIT_W-1 -: EXTRA_W];
        end
        else begin
            assign extra_data_padded = {hdr_flit_reg[`NOC_DATA_WIDTH-BASE_FLIT_W-1 -: EXTRA_W],
                {(PADDING_W){1'b0}}};
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            extra_flit_index_reg <= extra_flit_index_next;
            hdr_flit_reg <= hdr_flit_next;
        end
    end

    assign extra_flit_index_next = reset_extra_flit
                                ? EXTRA_FLITS - 1
                                : decr_extra_flit
                                    ? extra_flit_index_reg - 1'b1
                                    : extra_flit_index_reg;

    assign hdr_flit_next = store_hdr
                        ? src_noc_dtc_data
                        : hdr_flit_reg;

    always_comb begin
        reset_extra_flit = 1'b0;
        decr_extra_flit = 1'b0;
        store_hdr = 1'b0;

        noc_dtc_dst_val = 1'b0;
        noc_dtc_src_rdy = 1'b0;

        mux_sel = HDR_FLIT_1;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                reset_extra_flit = 1'b1;
                store_hdr = 1'b1;
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
                    state_next = REM_FLITS;
                end
            end
            REM_FLITS: begin
                mux_sel = EXTRAS;

                noc_dtc_dst_val = 1'b1;

                if (dst_noc_dtc_rdy) begin
                    decr_extra_flit = 1'b1;

                    if (extra_flit_index_reg == 0) begin
                        state_next = READY;
                    end
                end
            end
            default: begin
                reset_extra_flit = 'X;
                decr_extra_flit = 'X;
                store_hdr = 'X;

                noc_dtc_dst_val = 'X;
                noc_dtc_src_rdy = 'X;

                mux_sel = HDR_FLIT_1;

                state_next = state_reg;
            end
        endcase
    end

    always_comb begin
        if (mux_sel == HDR_FLIT_1) begin
            noc_dtc_dst_data = narrow_hdr_flit_1;
        end
        else if (mux_sel == HDR_FLIT_2) begin
            noc_dtc_dst_data = narrow_hdr_flit_2;
        end
        else begin
            noc_dtc_dst_data = extra_data_padded[extra_flit_index_reg];
        end
    end

    always_comb begin
        narrow_hdr_flit_1 = hdr_flit_next[`NOC_DATA_WIDTH-1 -: `CTRL_NOC1_DATA_W];
        // plus one for the extra hdr flit
        narrow_hdr_flit_1.msg_len = 1 + EXTRA_FLITS;
    end

    always_comb begin
        narrow_hdr_flit_2 = '0;
        narrow_hdr_flit_2.src_chip_id = hdr_flit_reg.core.core.src_chip_id;
        narrow_hdr_flit_2.src_x_coord = hdr_flit_reg.core.core.src_x_coord;
        narrow_hdr_flit_2.src_y_coord = hdr_flit_reg.core.core.src_y_coord;
        narrow_hdr_flit_2.src_fbits = hdr_flit_reg.core.core.src_fbits;
        narrow_hdr_flit_2.metadata_flits = '0;
    end

endmodule
