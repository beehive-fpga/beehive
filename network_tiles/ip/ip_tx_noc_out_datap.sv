`include "ip_tx_tile_defs.svh"
module ip_tx_noc_out_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]           ip_tx_out_noc0_vrtoc_data    
    
    ,input  eth_hdr                                 ip_to_ethstream_ip_tx_out_eth_hdr
    ,input          [MSG_TIMESTAMP_W-1:0]           ip_to_ethstream_ip_tx_out_timestamp
    ,input  logic   [`TOT_LEN_W-1:0]                ip_to_ethstream_ip_tx_out_data_len

    ,input          [`XY_WIDTH-1:0]                 src_ip_tx_out_dst_x
    ,input          [`XY_WIDTH-1:0]                 src_ip_tx_out_dst_y

    ,input  logic   [`MAC_INTERFACE_W-1:0]          ip_to_ethstream_ip_tx_out_data
    ,input  logic                                   ip_to_ethstream_ip_tx_out_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]           ip_to_ethstream_ip_tx_out_data_padbytes

    ,input  ip_tx_tile_pkg::noc_out_flit_mux_sel    ctrl_datap_flit_sel
    ,input  logic                                   ctrl_datap_store_inputs

    ,output logic                                   datap_ctrl_last_output
);

    eth_hdr eth_hdr_reg;
    eth_hdr eth_hdr_next;
    
    logic   [`TOT_LEN_W-1:0]    data_size_reg;
    logic   [`TOT_LEN_W-1:0]    data_size_next;

    logic   [MSG_TIMESTAMP_W-1:0]   pkt_timestamp_reg;
    logic   [MSG_TIMESTAMP_W-1:0]   pkt_timestamp_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;

    beehive_noc_hdr_flit    hdr_flit;
    eth_tx_metadata_flit    meta_flit;


    assign num_data_flits = data_size_next[`NOC_DATA_BYTES_W-1:0] == 0
                            ? data_size_next >> `NOC_DATA_BYTES_W
                            : (data_size_next >> `NOC_DATA_BYTES_W) + 1'b1;
    assign eth_hdr_next = ctrl_datap_store_inputs
                        ? ip_to_ethstream_ip_tx_out_eth_hdr
                        : eth_hdr_reg;
    assign data_size_next = ctrl_datap_store_inputs
                            ? ip_to_ethstream_ip_tx_out_data_len
                            : data_size_reg;

    assign pkt_timestamp_next = ctrl_datap_store_inputs
                                ? ip_to_ethstream_ip_tx_out_timestamp
                                : pkt_timestamp_reg;


    assign datap_ctrl_last_output = ip_to_ethstream_ip_tx_out_data_last;

    always_comb begin
        if (ctrl_datap_flit_sel == ip_tx_tile_pkg::SEL_HDR_FLIT) begin
            ip_tx_out_noc0_vrtoc_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == ip_tx_tile_pkg::SEL_META_FLIT) begin
            ip_tx_out_noc0_vrtoc_data = meta_flit;
        end
        else begin
            ip_tx_out_noc0_vrtoc_data = ip_to_ethstream_ip_tx_out_data;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            eth_hdr_reg <= '0;
            data_size_reg <= '0;
            pkt_timestamp_reg <= '0;
        end
        else begin
            eth_hdr_reg <= eth_hdr_next;
            data_size_reg <= data_size_next;
            pkt_timestamp_reg <= pkt_timestamp_next;
        end
    end

    always_comb begin
        hdr_flit = '0;

        // we always send thru Ethernet
        hdr_flit.core.dst_x_coord = src_ip_tx_out_dst_x;
        hdr_flit.core.dst_y_coord = src_ip_tx_out_dst_y;
        hdr_flit.core.dst_fbits = PKT_IF_FBITS;

        // there's one metadata flit and then some number of data flits
        hdr_flit.core.msg_len = 1 + num_data_flits;
        hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.metadata_flits = 1;
        hdr_flit.core.msg_type = ETH_TX_FRAME;
    end

    always_comb begin
        meta_flit = '0;
        meta_flit.eth_dst = eth_hdr_reg.dst;
        meta_flit.eth_src = eth_hdr_reg.src;
        meta_flit.eth_type = eth_hdr_reg.eth_type;
        meta_flit.payload_size = data_size_reg;
        meta_flit.timestamp = pkt_timestamp_reg;
    end

endmodule
