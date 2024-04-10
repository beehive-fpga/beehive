`include "udp_tx_tile_defs.svh"
module udp_tx_noc_out_datap 
    import tracker_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]           udp_tx_out_noc0_vrtoc_data    
    
    ,input  logic   [`IP_ADDR_W-1:0]                udp_to_stream_udp_tx_out_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]                udp_to_stream_udp_tx_out_dst_ip
    ,input  logic   [`TOT_LEN_W-1:0]                udp_to_stream_udp_tx_out_udp_len
    ,input  logic   [`PROTOCOL_W-1:0]               udp_to_stream_udp_tx_out_protocol
    ,input  tracker_stats_struct                    udp_to_stream_udp_tx_out_timestamp

    ,input  logic   [`XY_WIDTH-1:0]                 src_udp_tx_out_dst_x
    ,input  logic   [`XY_WIDTH-1:0]                 src_udp_tx_out_dst_y
    
    ,input  logic   [`MAC_INTERFACE_W-1:0]          udp_to_stream_udp_tx_out_data
    ,input  logic                                   udp_to_stream_udp_tx_out_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]           udp_to_stream_udp_tx_out_padbytes
    
    ,input  udp_tx_tile_pkg::noc_out_flit_mux_sel   ctrl_datap_flit_sel
    ,input  logic                                   ctrl_datap_store_inputs

    ,output logic                                   datap_ctrl_last_output
);
    
    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;
    
    beehive_noc_hdr_flit    hdr_flit;
    ip_tx_metadata_flit     meta_flit;

    logic   [`IP_ADDR_W-1:0]        src_ip_reg;
    logic   [`IP_ADDR_W-1:0]        dst_ip_reg;
    logic   [`TOT_LEN_W-1:0]        udp_len_reg;
    logic   [`PROTOCOL_W-1:0]       protocol_reg;
    tracker_stats_struct            pkt_timestamp_reg;

    logic   [`IP_ADDR_W-1:0]        src_ip_next;
    logic   [`IP_ADDR_W-1:0]        dst_ip_next;
    logic   [`TOT_LEN_W-1:0]        udp_len_next;
    logic   [`PROTOCOL_W-1:0]       protocol_next;
    tracker_stats_struct            pkt_timestamp_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            src_ip_reg <= '0;
            dst_ip_reg <='0;
            udp_len_reg <= '0;
            protocol_reg <= '0;
            pkt_timestamp_reg <= '0;
        end
        else begin
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            udp_len_reg <= udp_len_next;
            protocol_reg <= protocol_next;
            pkt_timestamp_reg <= pkt_timestamp_next;
        end
    end
    
    assign num_data_flits = udp_len_next[`NOC_DATA_BYTES_W-1:0] == 0
                            ? udp_len_next >> `NOC_DATA_BYTES_W
                            : (udp_len_next >> `NOC_DATA_BYTES_W) + 1'b1;

    assign datap_ctrl_last_output = udp_to_stream_udp_tx_out_last;

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            src_ip_next = udp_to_stream_udp_tx_out_src_ip;
            dst_ip_next = udp_to_stream_udp_tx_out_dst_ip;
            udp_len_next = udp_to_stream_udp_tx_out_udp_len;
            protocol_next = udp_to_stream_udp_tx_out_protocol;
            pkt_timestamp_next = udp_to_stream_udp_tx_out_timestamp;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            udp_len_next = udp_len_reg;
            protocol_next = protocol_reg;
            pkt_timestamp_next = pkt_timestamp_reg;
        end
    end
    
    always_comb begin
        if (ctrl_datap_flit_sel == udp_tx_tile_pkg::SEL_HDR_FLIT) begin
            udp_tx_out_noc0_vrtoc_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == udp_tx_tile_pkg::SEL_META_FLIT) begin
            udp_tx_out_noc0_vrtoc_data = meta_flit;
        end
        else begin
            udp_tx_out_noc0_vrtoc_data = udp_to_stream_udp_tx_out_data;
        end
    end
    
    always_comb begin
        hdr_flit = '0;

        // we always send thru IP
        hdr_flit.core.core.dst_x_coord = src_udp_tx_out_dst_x;
        hdr_flit.core.core.dst_y_coord = src_udp_tx_out_dst_y;

        // there's one metadata flit and then some number of data flits
        hdr_flit.core.core.msg_len = 1 + num_data_flits;
        hdr_flit.core.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.core.msg_type = IP_TX_DATAGRAM;

        hdr_flit.core.packet_id = pkt_timestamp_reg.packet_id;
        hdr_flit.core.timestamp = pkt_timestamp_reg.timestamp;
        
        hdr_flit.core.metadata_flits = 1;
    end

    always_comb begin
        meta_flit = '0;
        meta_flit.src_ip = src_ip_reg;
        meta_flit.dst_ip = dst_ip_reg;
        meta_flit.data_payload_len = udp_len_reg;
        meta_flit.protocol = protocol_reg;
    end

endmodule
