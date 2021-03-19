// This is a hacky stopgap until we make the TCP engine app IF natively 64 big buses. 
// This is ONLY for use with the TCP control interface and will not handle anything with
// payload properly. Use the normal noc_data_to_ctrl if you can

`include "noc_defs.vh"
module tcp_app_if_noc_dtc 
    import beehive_noc_msg::*;
    import beehive_ctrl_noc_msg::*;
    import beehive_tcp_msg::*;
(
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
    localparam EXTRA_FLITS = TCP_EXTRA_W[CTRL_NOC_DATA_W_W-1:0] == 0
                             ? TCP_EXTRA_W >> CTRL_NOC_DATA_W_W
                             : (TCP_EXTRA_W >> CTRL_NOC_DATA_W_W) + 1;
    localparam EXTRA_FLITS_W = $clog2(EXTRA_FLITS);
    localparam TCP_SAVE_W = EXTRA_FLITS * `CTRL_NOC1_DATA_W;
    localparam PADDING_W = TCP_SAVE_W - TCP_EXTRA_W;

    logic   [`MSG_LENGTH_WIDTH-1:0] debug_extra_flits;
    assign debug_extra_flits = EXTRA_FLITS;

    logic   [EXTRA_FLITS-1:0][`CTRL_NOC1_DATA_W-1:0]    tcp_extra_padded;    

    logic   [EXTRA_FLITS_W-1:0] extra_flit_index_reg;
    logic   [EXTRA_FLITS_W-1:0] extra_flit_index_next;
    logic                       reset_extra_flit;
    logic                       decr_extra_flit;

    typedef enum logic[1:0] {
        READY = 2'd0,
        MISC_HDR_FLIT = 2'd1,
        TCP_EXTRA_FLITS = 2'd2,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        HDR_FLIT_1,
        HDR_FLIT_2,
        TCP_EXTRA
    } flit_mux_sel_e;
    
    state_e state_reg;
    state_e state_next;

    logic store_hdr;
    tcp_noc_hdr_flit hdr_flit_reg;
    tcp_noc_hdr_flit hdr_flit_next;
    routing_hdr_flit        narrow_hdr_flit_1;
    misc_hdr_flit           narrow_hdr_flit_2;
    
    flit_mux_sel_e          mux_sel;

    generate
        if (PADDING_W == 0) begin
            assign tcp_extra_padded = hdr_flit_reg[`NOC_DATA_WIDTH-BASE_FLIT_W-1 -: TCP_EXTRA_W];
        end
        else begin
            assign tcp_extra_padded = {hdr_flit_reg[`NOC_DATA_WIDTH-BASE_FLIT_W-1 -: TCP_EXTRA_W],
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
                    state_next = TCP_EXTRA_FLITS;
                end
            end
            TCP_EXTRA_FLITS: begin
                mux_sel = TCP_EXTRA;

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

                state_next = UND;
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
            noc_dtc_dst_data = tcp_extra_padded[extra_flit_index_reg];
        end
    end

    always_comb begin
        narrow_hdr_flit_1 = hdr_flit_next[`NOC_DATA_WIDTH-1 -: `CTRL_NOC1_DATA_W];
        // plus one for the extra hdr flit
        narrow_hdr_flit_1.msg_len = 1 + EXTRA_FLITS;
    end

    always_comb begin
        narrow_hdr_flit_2 = '0;
        narrow_hdr_flit_2.src_chip_id = hdr_flit_reg.core.src_chip_id;
        narrow_hdr_flit_2.src_x_coord = hdr_flit_reg.core.src_x_coord;
        narrow_hdr_flit_2.src_y_coord = hdr_flit_reg.core.src_y_coord;
        narrow_hdr_flit_2.src_fbits = hdr_flit_reg.core.src_fbits;
        narrow_hdr_flit_2.metadata_flits = '0;
    end
endmodule
