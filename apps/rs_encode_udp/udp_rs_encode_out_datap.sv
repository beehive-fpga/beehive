`include "udp_rs_encode_defs.svh"
module udp_rs_encode_out_datap #(
     parameter SRC_X=-1
    ,parameter SRC_Y=-1
)(
     input clk
    ,input rst
    
    ,input  logic   [`IP_ADDR_W-1:0]                in_out_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]                in_out_dst_ip
    ,input  logic   [`PORT_NUM_W-1:0]               in_out_src_port
    ,input  logic   [`PORT_NUM_W-1:0]               in_out_dst_port
    ,input  logic   [`UDP_LENGTH_W-1:0]             in_out_data_len 
    ,input  logic   [CLIENT_NUM_REQ_BLOCKS_W-1:0]   in_out_num_blocks
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]           udp_app_out_noc0_vrtoc_data
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           stream_encoder_noc_out_resp_data
    
    ,input  logic                                   out_ctrl_out_datap_store_meta
    ,input  udp_rs_tx_flit_e                        out_ctrl_out_datap_out_sel
    ,input  logic                                   out_ctrl_out_datap_incr_data_flit

    ,output logic                                   out_datap_out_ctrl_last_data_flit
    ,output logic   [`UDP_LENGTH_W-1:0]             out_datap_out_ctrl_data_len
);
    
    logic   [`IP_ADDR_W-1:0]            src_ip_reg;
    logic   [`IP_ADDR_W-1:0]            dst_ip_reg;
    logic   [`PORT_NUM_W-1:0]           src_port_reg;
    logic   [`PORT_NUM_W-1:0]           dst_port_reg;
    logic   [`UDP_LENGTH_W-1:0]         data_len_reg;
    logic   [`IP_ADDR_W-1:0]            src_ip_next;
    logic   [`IP_ADDR_W-1:0]            dst_ip_next;
    logic   [`PORT_NUM_W-1:0]           src_port_next;
    logic   [`PORT_NUM_W-1:0]           dst_port_next;
    logic   [`UDP_LENGTH_W-1:0]         data_len_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_cnt_next;

    logic   [CLIENT_NUM_REQ_BLOCKS_W:0] num_req_blocks_reg;
    logic   [CLIENT_NUM_REQ_BLOCKS_W:0] num_req_blocks_next;

    logic   [`UDP_LENGTH_W-1:0]     resp_len;
    logic   [`UDP_LENGTH_W-1:0]     parity_len;

    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;

    udp_noc_hdr_flit                hdr_cast;
    udp_tx_metadata_flit            meta_cast;

    assign out_datap_out_ctrl_data_len = data_len_reg;

    assign parity_len = num_req_blocks_reg << $clog2(RS_T);

    // subtract off the header
    assign resp_len = data_len_reg + parity_len - `NOC_DATA_BYTES;

    assign num_data_flits = resp_len[`NOC_DATA_BYTES_W-1:0] == 0
                            ? resp_len >> `NOC_DATA_BYTES_W
                            : (resp_len >> `NOC_DATA_BYTES_W) + 1'b1;

    assign out_datap_out_ctrl_last_data_flit = flits_cnt_reg == (num_data_flits - 1'b1);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            num_req_blocks_reg <= '0;
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            src_port_reg <= '0;
            dst_port_reg <= '0;
            data_len_reg <= '0;
            flits_cnt_reg <= '0;
        end
        else begin
            num_req_blocks_reg <= num_req_blocks_next;
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            src_port_reg <= src_port_next;
            dst_port_reg <= dst_port_next;
            data_len_reg <= data_len_next;
            flits_cnt_reg <= flits_cnt_next;
        end
    end

    assign flits_cnt_next = out_ctrl_out_datap_store_meta
                            ? '0
                            : out_ctrl_out_datap_incr_data_flit
                                ? flits_cnt_reg + 1'b1
                                : flits_cnt_reg;
    
    always_comb begin
        if (out_ctrl_out_datap_store_meta) begin
            src_ip_next = in_out_src_ip;
            dst_ip_next = in_out_dst_ip;
            src_port_next = in_out_src_port;
            dst_port_next = in_out_dst_port;
            data_len_next = in_out_data_len;
            num_req_blocks_next = in_out_num_blocks;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            src_port_next = src_port_reg;
            dst_port_next = dst_port_reg;
            data_len_next = data_len_reg;
            num_req_blocks_next = num_req_blocks_reg;
        end
    end
    
    always_comb begin
        if (out_ctrl_out_datap_out_sel == udp_rs_encode_pkg::HDR) begin
            udp_app_out_noc0_vrtoc_data = hdr_cast;
        end
        else if (out_ctrl_out_datap_out_sel == udp_rs_encode_pkg::META) begin
            udp_app_out_noc0_vrtoc_data = meta_cast;
        end
        else begin
            udp_app_out_noc0_vrtoc_data = stream_encoder_noc_out_resp_data;
        end
    end
    
    always_comb begin
        hdr_cast = '0;

        // we always send thru IP
        hdr_cast.core.dst_x_coord = UDP_TX_TILE_X[`XY_WIDTH-1:0];
        hdr_cast.core.dst_y_coord = UDP_TX_TILE_Y[`XY_WIDTH-1:0];

        // there's one metadata flit and then some number of data flits
        hdr_cast.core.msg_len = 1 + num_data_flits;
        hdr_cast.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_cast.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_cast.core.metadata_flits = 1;
        hdr_cast.core.msg_type = UDP_TX_SEGMENT;
    end

    always_comb begin
        meta_cast = '0;
        meta_cast.src_ip = dst_ip_reg;
        meta_cast.dst_ip = src_ip_reg;
        meta_cast.src_port = dst_port_reg;
        meta_cast.dst_port = src_port_reg;
        meta_cast.data_length = resp_len;
    end
endmodule
