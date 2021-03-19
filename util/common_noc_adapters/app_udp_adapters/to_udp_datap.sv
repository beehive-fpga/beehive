`include "noc_defs.vh"
module to_udp_datap 
import beehive_udp_msg::*;
import app_udp_adapter_pkg::*;
import beehive_noc_msg::*;
#(
     parameter NOC_DATA_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter SRC_FBITS = -1
)(
     input clk
    ,input rst
    
    ,input  udp_info                        src_to_udp_meta_info

    ,input  logic   [NOC_DATA_W-1:0]        src_to_udp_data

    ,output logic   [NOC_DATA_W-1:0]        to_udp_noc_vrtoc_data

    ,input  logic   [`XY_WIDTH-1:0]         src_to_udp_dst_x
    ,input  logic   [`XY_WIDTH-1:0]         src_to_udp_dst_y
    ,input  logic   [`NOC_FBITS_WIDTH-1:0]  src_to_udp_dst_fbits
    
    ,input  to_udp_mux_out_e                ctrl_datap_data_mux_sel
    ,input  logic                           ctrl_datap_init_state
    ,input  logic                           ctrl_datap_cnt_flit

    ,output logic                           datap_ctrl_last_flit
);

    localparam  NOC_DATA_BYTES = NOC_DATA_W/8;
    localparam  NOC_DATA_BYTES_W = $clog2(NOC_DATA_BYTES);

    udp_noc_hdr_flit        out_hdr_flit;
    udp_tx_metadata_flit    out_meta_flit;

    udp_info info_reg;
    udp_info info_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] total_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] total_flits_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;


    always_ff @(posedge clk) begin
        info_reg <= info_next;
        total_flits_reg <= total_flits_next;
        flit_cnt_reg <= flit_cnt_next;
    end

    assign datap_ctrl_last_flit = flit_cnt_reg == (total_flits_reg - 1'b1);

    assign num_data_flits = info_next.data_length[NOC_DATA_BYTES_W-1:0] == 0
                        ? info_next.data_length >> NOC_DATA_BYTES_W
                        : (info_next.data_length >> NOC_DATA_BYTES_W) + 1'b1;

    assign info_next = ctrl_datap_init_state
                    ? src_to_udp_meta_info
                    : info_reg;

    assign total_flits_next = ctrl_datap_init_state
                            // plus 1 for a metadata flit
                            ? num_data_flits + 1'b1
                            : total_flits_reg;

    assign flit_cnt_next = ctrl_datap_init_state
                        ? '0
                        : ctrl_datap_cnt_flit
                            ? flit_cnt_reg + 1'b1
                            : flit_cnt_reg;

    always_comb begin
        to_udp_noc_vrtoc_data = src_to_udp_data;
        if (ctrl_datap_data_mux_sel == HDR_OUT) begin
            to_udp_noc_vrtoc_data = out_hdr_flit;
        end
        else if (ctrl_datap_data_mux_sel == META_OUT) begin
            to_udp_noc_vrtoc_data = out_meta_flit;
        end
        else begin
            to_udp_noc_vrtoc_data = src_to_udp_data;
        end
    end

    always_comb begin
        out_hdr_flit = '0;

        out_hdr_flit.core.dst_x_coord = src_to_udp_dst_x;
        out_hdr_flit.core.dst_y_coord = src_to_udp_dst_y;
        out_hdr_flit.core.dst_fbits = src_to_udp_dst_fbits;

        out_hdr_flit.core.msg_len = total_flits_reg;

        out_hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        out_hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        out_hdr_flit.core.src_fbits = PKT_IF_FBITS;

        out_hdr_flit.core.metadata_flits = 1;

        out_hdr_flit.core.msg_type = UDP_TX_SEGMENT;
    end

    always_comb begin
        out_meta_flit = '0;
        out_meta_flit.src_ip = info_reg.src_ip;
        out_meta_flit.dst_ip = info_reg.dst_ip;
        out_meta_flit.src_port = info_reg.src_port;
        out_meta_flit.dst_port = info_reg.dst_port;
        out_meta_flit.data_length = info_reg.data_length;
    end

endmodule
