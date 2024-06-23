`include "udp_rs_encode_defs.svh"
module udp_rs_encode_in_datap (
     input clk
    ,input rst

    ,input          [`NOC_DATA_WIDTH-1:0]           noc0_ctovr_udp_app_in_data

    ,output logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   noc_in_stream_encoder_req_num_blocks

    ,output logic   [`NOC_DATA_WIDTH-1:0]           noc_in_stream_encoder_req_data

    ,output logic   [`IP_ADDR_W-1:0]                in_out_src_ip
    ,output logic   [`IP_ADDR_W-1:0]                in_out_dst_ip
    ,output logic   [`PORT_NUM_W-1:0]               in_out_src_port
    ,output logic   [`PORT_NUM_W-1:0]               in_out_dst_port
    ,output logic   [`UDP_LENGTH_W-1:0]             in_out_data_len 
    ,output logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   in_out_num_blocks

    ,input  logic                                   in_ctrl_in_datap_store_hdr
    ,input  logic                                   in_ctrl_in_datap_store_meta
    ,input  logic                                   in_ctrl_in_datap_store_req
    ,input  logic                                   in_ctrl_in_datap_incr_flits

    ,output logic                                   in_datap_in_ctrl_last_flit
);

    logic   [`MSG_LENGTH_WIDTH-1:0]     num_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     num_flits_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_cnt_next;

    logic   [CLIENT_NUM_REQ_BLOCKS_W:0] num_req_blocks_reg;
    logic   [CLIENT_NUM_REQ_BLOCKS_W:0] num_req_blocks_next;

    beehive_noc_hdr_flit    hdr_flit_cast;
    udp_rx_metadata_flit    meta_flit_cast;
    client_req_struct       req_cast;
    
    logic   [`IP_ADDR_W-1:0]        src_ip_reg;
    logic   [`IP_ADDR_W-1:0]        dst_ip_reg;
    logic   [`PORT_NUM_W-1:0]       src_port_reg;
    logic   [`PORT_NUM_W-1:0]       dst_port_reg;
    logic   [`UDP_LENGTH_W-1:0]     data_len_reg;
    logic   [`IP_ADDR_W-1:0]        src_ip_next;
    logic   [`IP_ADDR_W-1:0]        dst_ip_next;
    logic   [`PORT_NUM_W-1:0]       src_port_next;
    logic   [`PORT_NUM_W-1:0]       dst_port_next;
    logic   [`UDP_LENGTH_W-1:0]     data_len_next;

    assign hdr_flit_cast = noc0_ctovr_udp_app_in_data;
    assign meta_flit_cast = noc0_ctovr_udp_app_in_data;
    assign req_cast = noc0_ctovr_udp_app_in_data[`NOC_DATA_WIDTH-1 -: CLIENT_REQ_STRUCT_W];

    assign in_out_num_blocks = num_req_blocks_next;
    assign in_out_src_ip = src_ip_next;
    assign in_out_dst_ip = dst_ip_next;
    assign in_out_src_port = src_port_next;
    assign in_out_dst_port = dst_port_next;
    assign in_out_data_len = data_len_next;

    assign in_datap_in_ctrl_last_flit = flits_cnt_reg == (num_flits_reg - 1'b1);

    assign noc_in_stream_encoder_req_data = noc0_ctovr_udp_app_in_data;
    assign noc_in_stream_encoder_req_num_blocks = num_req_blocks_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            num_flits_reg <= '0;
            num_req_blocks_reg <= '0;
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            src_port_reg <= '0;
            dst_port_reg <= '0;
            data_len_reg <= '0;
            flits_cnt_reg <= '0;
        end
        else begin
            num_flits_reg <= num_flits_next;
            num_req_blocks_reg <= num_req_blocks_next;
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            src_port_reg <= src_port_next;
            dst_port_reg <= dst_port_next;
            data_len_reg <= data_len_next;
            flits_cnt_reg <= flits_cnt_next;
        end
    end

    assign num_flits_next = in_ctrl_in_datap_store_hdr
                            ? hdr_flit_cast.core.core.msg_len
                            : num_flits_reg;

    assign num_req_blocks_next = in_ctrl_in_datap_store_req
                                ? req_cast.num_req_blocks
                                : num_req_blocks_reg;

    always_comb begin
        if (in_ctrl_in_datap_store_meta) begin
            src_ip_next = meta_flit_cast.src_ip;
            dst_ip_next = meta_flit_cast.dst_ip;
            src_port_next = meta_flit_cast.src_port;
            dst_port_next = meta_flit_cast.dst_port;
            data_len_next = meta_flit_cast.data_length;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            src_port_next = src_port_reg;
            dst_port_next = dst_port_reg;
            data_len_next = data_len_reg;
        end
    end

    assign flits_cnt_next = in_ctrl_in_datap_store_hdr
                            ? '0
                            : in_ctrl_in_datap_incr_flits
                                ? flits_cnt_reg + 1'b1
                                : flits_cnt_reg;
    
endmodule
