`include "udp_tx_tile_defs.svh"
module udp_tx_noc_in_datap 
    import tracker_pkg::*;
(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_udp_tx_in_data
    
    ,output logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_src_ip_addr
    ,output logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_dst_ip_addr
    ,output udp_pkt_hdr                     udp_tx_in_udp_to_stream_udp_hdr
    ,output tracker_stats_struct            udp_tx_in_udp_to_stream_timestamp
    
    ,output logic   [`MAC_INTERFACE_W-1:0]  udp_tx_in_udp_to_stream_data
    ,output logic                           udp_tx_in_udp_to_stream_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   udp_tx_in_udp_to_stream_data_padbytes
    
    ,input  logic   ctrl_datap_store_hdr_flit
    ,input  logic   ctrl_datap_store_meta_flit
    ,input  logic   ctrl_datap_init_num_flits
    ,input  logic   ctrl_datap_decr_num_flits

    ,output logic   datap_ctrl_last_flit
);
    beehive_noc_hdr_flit                hdr_flit_reg;
    beehive_noc_hdr_flit                hdr_flit_next;

    udp_tx_metadata_flit                 meta_flit_reg;
    udp_tx_metadata_flit                 meta_flit_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_remaining_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_remaining_next;
    logic   [`MAC_PADBYTES_W:0]         padbytes_calc;

    udp_pkt_hdr udp_pkt_hdr_cast;

    assign udp_tx_in_udp_to_stream_udp_hdr = udp_pkt_hdr_cast;
    assign udp_tx_in_udp_to_stream_src_ip_addr = meta_flit_next.src_ip;
    assign udp_tx_in_udp_to_stream_dst_ip_addr = meta_flit_next.dst_ip;
    assign udp_tx_in_udp_to_stream_timestamp.packet_id = hdr_flit_reg.core.packet_id;
    assign udp_tx_in_udp_to_stream_timestamp.timestamp = hdr_flit_reg.core.timestamp;

    always_comb begin
        udp_pkt_hdr_cast = '0;
        udp_pkt_hdr_cast.src_port = meta_flit_next.src_port;
        udp_pkt_hdr_cast.dst_port = meta_flit_next.dst_port;
        udp_pkt_hdr_cast.length = meta_flit_next.data_length + UDP_HDR_BYTES;
    end

    assign udp_tx_in_udp_to_stream_data = noc0_ctovr_udp_tx_in_data;
    assign udp_tx_in_udp_to_stream_data_last = datap_ctrl_last_flit;

    assign padbytes_calc = meta_flit_reg.data_length[`NOC_DATA_BYTES_W-1:0] == 0
                    ?'0
                    : `NOC_DATA_BYTES - meta_flit_reg.data_length[`NOC_DATA_BYTES_W-1:0];

    assign udp_tx_in_udp_to_stream_data_padbytes = udp_tx_in_udp_to_stream_data_last
                                                ? padbytes_calc[`NOC_DATA_BYTES_W-1:0]
                                                : '0;

    assign datap_ctrl_last_flit = flits_remaining_reg == 1;

    assign hdr_flit_next = ctrl_datap_store_hdr_flit
                            ? noc0_ctovr_udp_tx_in_data
                            : hdr_flit_reg;

    assign meta_flit_next = ctrl_datap_store_meta_flit
                            ? noc0_ctovr_udp_tx_in_data
                            : meta_flit_reg;

    always_comb begin
        if (ctrl_datap_init_num_flits) begin
            flits_remaining_next = hdr_flit_next.core.core.msg_len;
        end
        else if (ctrl_datap_decr_num_flits) begin
            flits_remaining_next = flits_remaining_reg - 1'b1;
        end
        else begin
            flits_remaining_next = flits_remaining_reg;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_reg <= '0;
            meta_flit_reg <= '0;
            flits_remaining_reg <= '0;
        end
        else begin
            hdr_flit_reg <= hdr_flit_next;
            meta_flit_reg <= meta_flit_next;
            flits_remaining_reg <= flits_remaining_next;
        end
    end

endmodule
