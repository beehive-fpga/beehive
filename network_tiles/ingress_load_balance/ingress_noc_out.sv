`include "ingress_load_balance_defs.svh"
module ingress_noc_out 
import beehive_noc_msg::*;
import beehive_eth_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input                                      src_noc_out_val
    ,input          [`XY_WIDTH-1:0]             src_noc_out_x
    ,input          [`XY_WIDTH-1:0]             src_noc_out_y
    ,output logic                               noc_out_src_rdy

    ,input                                      src_noc_out_data_val
    ,input          [`NOC_DATA_WIDTH-1:0]       src_noc_out_data
    ,input                                      src_noc_out_start
    ,input                                      src_noc_out_last
    ,input          [`NOC_PADBYTES_WIDTH-1:0]   src_noc_out_padbytes
    ,input          [`MTU_SIZE_W-1:0]           src_noc_out_framesize
    ,output logic                               noc_out_src_data_rdy

    ,output logic                               ingress_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       ingress_noc_data
    ,input                                      noc_ingress_rdy
);

    typedef enum logic[1:0] {
        HDR = 2'd0,
        DATA = 2'd1,
        UND = 'X
    } state_e;

    typedef enum logic {
        HDR_FLIT = 1'd0,
        DATA_FLITS = 1'd1
    } out_mux_sel_e;

    state_e state_reg;
    state_e state_next;

    eth_rx_hdr_flit    hdr_flit_cast;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     num_data_flits;
    out_mux_sel_e                       out_mux_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        noc_out_src_rdy = 1'b0;
        ingress_noc_val = 1'b0;
        noc_out_src_data_rdy = 1'b0;

        out_mux_sel = HDR_FLIT;

        state_next = state_reg;
        case (state_reg)
            HDR: begin
                out_mux_sel = HDR_FLIT;
                if (src_noc_out_val & src_noc_out_data_val & noc_ingress_rdy) begin
                    // we wait to actually consume the data line until the body of the flit, but we do need
                    // the frame size
                    noc_out_src_rdy = 1'b1;
                    ingress_noc_val = 1'b1;

                    state_next = DATA;
                end
            end
            DATA: begin
                noc_out_src_data_rdy = noc_ingress_rdy;
                ingress_noc_val = src_noc_out_data_val;

                out_mux_sel = DATA_FLITS;
                if (noc_ingress_rdy & src_noc_out_data_val & src_noc_out_last) begin
                    state_next = HDR;
                end
            end
            default: begin
                noc_out_src_rdy = 'X;
                ingress_noc_val = 'X;
                noc_out_src_data_rdy = 'X;

                out_mux_sel = HDR_FLIT;

                state_next = UND;
            end
        endcase
    end
    
    // if there's an even number of data flits, just divide. Otherwise, divide and add 1
    assign num_data_flits = src_noc_out_framesize[`NOC_DATA_BYTES_W-1:0] == 0
                          ? src_noc_out_framesize >> `NOC_DATA_BYTES_W
                          : (src_noc_out_framesize >> `NOC_DATA_BYTES_W) + 1'b1;

    always_comb begin
        hdr_flit_cast = '0;
        hdr_flit_cast.core.dst_x_coord = src_noc_out_x;
        hdr_flit_cast.core.dst_y_coord = src_noc_out_y;
        hdr_flit_cast.core.dst_fbits = PKT_IF_FBITS;
        hdr_flit_cast.core.msg_len = num_data_flits;
        hdr_flit_cast.core.msg_type = ETH_RX_FRAME;
        hdr_flit_cast.core.src_x_coord = SRC_X;
        hdr_flit_cast.core.src_y_coord = SRC_Y;
        hdr_flit_cast.core.src_fbits = PKT_IF_FBITS;
        hdr_flit_cast.core.metadata_flits = '0;
        hdr_flit_cast.frame_size = src_noc_out_framesize;
    end

    always_comb begin
        ingress_noc_data = src_noc_out_data;
        if (out_mux_sel == HDR_FLIT) begin
            ingress_noc_data = hdr_flit_cast;
        end
        else begin
            ingress_noc_data = src_noc_out_data;
        end
    end


endmodule
