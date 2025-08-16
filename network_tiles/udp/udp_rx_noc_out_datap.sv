`include "udp_rx_tile_defs.svh"
`include "soc_defs.vh"
module udp_rx_noc_out_datap 
    import tracker_pkg::*;
    #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input          [`IP_ADDR_W-1:0]                udp_formatter_udp_rx_out_rx_src_ip
    ,input          [`IP_ADDR_W-1:0]                udp_formatter_udp_rx_out_rx_dst_ip
    ,input  udp_pkt_hdr                             udp_formatter_udp_rx_out_rx_udp_hdr
    ,input  tracker_stats_struct                     udp_formatter_udp_rx_out_rx_timestamp

    ,input          [`MAC_INTERFACE_W-1:0]          udp_formatter_udp_rx_out_rx_data
    ,input                                          udp_formatter_udp_rx_out_rx_last
    ,input          [`MAC_PADBYTES_W-1:0]           udp_formatter_udp_rx_out_rx_padbytes
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]           udp_rx_out_noc0_vrtoc_data
    
    ,input  udp_rx_tile_pkg::noc_out_flit_mux_sel   ctrl_datap_flit_sel
    ,input  logic                                   ctrl_datap_store_inputs
    
    ,output logic                                   datap_ctrl_last_output
    ,output logic                                   datap_ctrl_no_data

    ,output logic   [`PORT_NUM_W-1:0]               datap_cam_rd_tag
    ,input  udp_rx_cam_entry                        cam_datap_rd_data
);

    udp_pkt_hdr udp_hdr_reg;
    udp_pkt_hdr udp_hdr_next;

    logic   [`IP_ADDR_W-1:0]    src_ip_reg;
    logic   [`IP_ADDR_W-1:0]    src_ip_next;
    logic   [`IP_ADDR_W-1:0]    dst_ip_reg;
    logic   [`IP_ADDR_W-1:0]    dst_ip_next;

    tracker_stats_struct   pkt_timestamp_reg;
    tracker_stats_struct   pkt_timestamp_next;
    
    beehive_noc_hdr_flit    hdr_flit;
    udp_rx_metadata_flit    meta_flit;
    
    logic   [`UDP_LENGTH_W-1:0]     data_size;
    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;

    logic                   cam_hit;

    logic   [`MAC_INTERFACE_W-1:0]  masked_data;

    assign data_size = udp_hdr_next.length - UDP_HDR_BYTES;
    assign num_data_flits = data_size[`NOC_DATA_BYTES_W-1:0] == 0
                            ? data_size >> `NOC_DATA_BYTES_W
                            : (data_size >> `NOC_DATA_BYTES_W) + 1'b1;

    assign datap_cam_rd_tag = udp_hdr_next.dst_port;

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            udp_hdr_next = udp_formatter_udp_rx_out_rx_udp_hdr;
            src_ip_next = udp_formatter_udp_rx_out_rx_src_ip;
            dst_ip_next = udp_formatter_udp_rx_out_rx_dst_ip;
            pkt_timestamp_next = udp_formatter_udp_rx_out_rx_timestamp;
        end
        else begin
            udp_hdr_next = udp_hdr_reg;
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            pkt_timestamp_next = pkt_timestamp_reg;
        end
    end

    assign datap_ctrl_last_output = udp_formatter_udp_rx_out_rx_last;
    assign datap_ctrl_no_data = (udp_hdr_reg.length - UDP_HDR_BYTES) == '0;

    always_ff @(posedge clk) begin
        if (rst) begin
            udp_hdr_reg <= '0;
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            pkt_timestamp_reg <= '0;
        end
        else begin
            udp_hdr_reg <= udp_hdr_next;
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            pkt_timestamp_reg <= pkt_timestamp_next;
        end
    end
   
    data_masker #(
        .width_p    (`MAC_INTERFACE_W)
    ) masker (  
         .unmasked_data (udp_formatter_udp_rx_out_rx_data        )
        ,.padbytes      (udp_formatter_udp_rx_out_rx_padbytes    )
        ,.last          (udp_formatter_udp_rx_out_rx_last        )
    
        ,.masked_data   (masked_data)
    );
    
    always_comb begin
        if (ctrl_datap_flit_sel == udp_rx_tile_pkg::SEL_HDR_FLIT) begin
            udp_rx_out_noc0_vrtoc_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == udp_rx_tile_pkg::SEL_META_FLIT) begin
            udp_rx_out_noc0_vrtoc_data = meta_flit;
        end
        else begin
            udp_rx_out_noc0_vrtoc_data = masked_data;
        end
    end

    always_comb begin
        hdr_flit = '0;

        hdr_flit.core.core.dst_x_coord = cam_datap_rd_data.x_coord;
        hdr_flit.core.core.dst_y_coord = cam_datap_rd_data.y_coord;
        hdr_flit.core.core.dst_fbits = cam_datap_rd_data.fbits;

        // there's one metadata flit and then some number of data flits
        hdr_flit.core.core.msg_len = 1 + num_data_flits;
        hdr_flit.core.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.core.src_fbits = PKT_IF_FBITS;

        hdr_flit.core.core.msg_type = UDP_RX_SEGMENT; 

        hdr_flit.core.packet_id = pkt_timestamp_next.packet_id;
        hdr_flit.core.timestamp = pkt_timestamp_next.timestamp;
        
        hdr_flit.core.metadata_flits = 1;
    end
    
    always_comb begin
        meta_flit = '0;
        meta_flit.src_ip = src_ip_reg;
        meta_flit.dst_ip = dst_ip_reg;
        meta_flit.src_port = udp_hdr_reg.src_port;
        meta_flit.dst_port = udp_hdr_reg.dst_port;
        meta_flit.data_length = data_size;
    end


endmodule
