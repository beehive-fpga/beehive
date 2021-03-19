`include "tcp_tx_tile_defs.svh"
module tcp_tx_noc_out_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_out_noc0_data    

    ,input  logic   [`IP_ADDR_W-1:0]        src_tcp_tx_out_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        src_tcp_tx_out_dst_ip
    ,input  logic   [`TOT_LEN_W-1:0]        src_tcp_tx_out_tcp_len
    ,input  logic   [`PROTOCOL_W-1:0]       src_tcp_tx_out_protocol

    ,input  logic   [`MAC_INTERFACE_W-1:0]  src_tcp_tx_out_data
    ,input  logic                           src_tcp_tx_out_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   src_tcp_tx_out_padbytes
    
    ,input  noc_out_flit_mux_sel            ctrl_datap_flit_sel
    ,input  logic                           ctrl_datap_store_inputs

    ,output logic                           datap_ctrl_last_output
);

    beehive_noc_hdr_flit    hdr_flit;
    ip_tx_metadata_flit     meta_flit;

    logic   [`IP_ADDR_W-1:0]    src_ip_reg;
    logic   [`IP_ADDR_W-1:0]    dst_ip_reg;
    logic   [`TOT_LEN_W-1:0]    tcp_len_reg;
    logic   [`PROTOCOL_W-1:0]   protocol_reg;
    logic   [`IP_ADDR_W-1:0]    src_ip_next;
    logic   [`IP_ADDR_W-1:0]    dst_ip_next;
    logic   [`TOT_LEN_W-1:0]    tcp_len_next;
    logic   [`PROTOCOL_W-1:0]   protocol_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;
    logic   [`TOT_LEN_W-1:0]        payload_size;

    assign datap_ctrl_last_output = src_tcp_tx_out_last;

    assign num_data_flits = tcp_len_next[`NOC_DATA_BYTES_W-1:0] == 0
                            ? tcp_len_next >> `NOC_DATA_BYTES_W
                            : (tcp_len_next >> `NOC_DATA_BYTES_W) + 1'b1;

    always_comb begin
        if (ctrl_datap_flit_sel == SEL_HDR_FLIT) begin
            tcp_tx_out_noc0_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == SEL_META_FLIT) begin
            tcp_tx_out_noc0_data = meta_flit;
        end
        else begin
            tcp_tx_out_noc0_data = src_tcp_tx_out_data;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            tcp_len_reg <= '0;
            protocol_reg <= '0;
        end
        else begin
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            tcp_len_reg <= tcp_len_next;
            protocol_reg <= protocol_next;
        end
    end

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            src_ip_next = src_tcp_tx_out_src_ip;
            dst_ip_next = src_tcp_tx_out_dst_ip;
            tcp_len_next = src_tcp_tx_out_tcp_len;
            protocol_next = src_tcp_tx_out_protocol;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = src_ip_reg;
            tcp_len_next = tcp_len_reg;
            protocol_next = protocol_reg;
        end
    end

    always_comb begin
        hdr_flit = '0;

        hdr_flit.core.dst_x_coord = IP_TX_X[`XY_WIDTH-1:0];
        hdr_flit.core.dst_y_coord = IP_TX_Y[`XY_WIDTH-1:0];
        hdr_flit.core.dst_fbits = PKT_IF_FBITS;

        hdr_flit.core.msg_len = 1 + num_data_flits;
        hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.src_fbits = PKT_IF_FBITS;
        hdr_flit.core.metadata_flits = 1;

        hdr_flit.core.msg_type = IP_TX_DATAGRAM;
    end

    always_comb begin
        meta_flit = '0;
        meta_flit.src_ip = src_ip_reg;
        meta_flit.dst_ip = dst_ip_reg;
        meta_flit.data_payload_len = tcp_len_reg;
        meta_flit.protocol = protocol_reg;
    end

endmodule
