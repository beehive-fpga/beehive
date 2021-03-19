`include "noc_defs.vh"
module from_udp_datap 
import beehive_udp_msg::*;
#(
     parameter NOC_DATA_W = -1
    ,parameter NOC_PADBYTES = NOC_DATA_W/8
    ,parameter NOC_PADBYTES_W = $clog2(NOC_PADBYTES)
)(
     input clk
    ,input rst
    
    ,input  logic   [NOC_DATA_W-1:0]        noc_ctovr_fr_udp_data

    ,output udp_info                        fr_udp_dst_meta_info

    ,output logic   [NOC_DATA_W-1:0]        fr_udp_dst_data
    ,output logic   [NOC_PADBYTES_W-1:0]    fr_udp_dst_data_padbytes
    
    ,input  logic                           ctrl_datap_store_hdr_data
    ,input  logic                           ctrl_datap_store_meta_data
    ,input  logic                           ctrl_datap_cnt_flit

    ,output logic                           datap_ctrl_last_data
);

    udp_noc_hdr_flit        hdr_flit_cast;
    udp_rx_metadata_flit    meta_flit_cast;
    udp_info                udp_info_reg;
    udp_info                udp_info_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] total_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] total_flits_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_next;

    assign fr_udp_dst_data = noc_ctovr_fr_udp_data;
    assign hdr_flit_cast = noc_ctovr_fr_udp_data;
    assign meta_flit_cast = noc_ctovr_fr_udp_data;

    assign fr_udp_dst_meta_info = udp_info_reg;

    assign fr_udp_dst_data_padbytes = datap_ctrl_last_data
                                    ? udp_info_reg.data_length[NOC_PADBYTES_W-1:0]
                                    : '0;

    always_ff @(posedge clk) begin
        total_flits_reg <= total_flits_next;
        flit_cnt_reg <= flit_cnt_next;
        udp_info_reg <= udp_info_next;
    end

    assign total_flits_next = ctrl_datap_store_hdr_data 
                              ? hdr_flit_cast.core.msg_len
                              : total_flits_reg;

    assign flit_cnt_next = ctrl_datap_store_hdr_data
                        ? '0
                        : ctrl_datap_cnt_flit
                            ? flit_cnt_reg + 1'b1
                            : flit_cnt_reg;

    assign datap_ctrl_last_data = flit_cnt_reg == (total_flits_reg - 1);

    always_comb begin
        udp_info_next = udp_info_reg;
        if (ctrl_datap_store_meta_data) begin
            udp_info_next.src_ip = meta_flit_cast.src_ip;
            udp_info_next.dst_ip = meta_flit_cast.dst_ip;
            udp_info_next.src_port = meta_flit_cast.src_port;
            udp_info_next.dst_port = meta_flit_cast.dst_port;
            udp_info_next.data_length = meta_flit_cast.data_length;
        end
    end
    
endmodule
