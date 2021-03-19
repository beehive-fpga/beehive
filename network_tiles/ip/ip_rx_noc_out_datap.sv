`include "ip_rx_tile_defs.svh"
module ip_rx_noc_out_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input  ip_pkt_hdr                              ip_format_ip_rx_out_rx_ip_hdr
    ,input          [MSG_TIMESTAMP_W-1:0]           ip_format_ip_rx_out_rx_timestamp

    ,input  logic   [`MAC_INTERFACE_W-1:0]          ip_format_ip_rx_out_rx_data
    ,input  logic                                   ip_format_ip_rx_out_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]           ip_format_ip_rx_out_rx_padbytes
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]           ip_rx_out_noc0_vrtoc_data
    
    ,input  ip_rx_tile_pkg::noc_out_flit_mux_sel    ctrl_datap_flit_sel
    ,input  logic                                   ctrl_datap_store_inputs
    
    ,output logic                                   datap_ctrl_last_output

    ,output logic   [`PROTOCOL_W-1:0]               datap_cam_rd_tag
    ,input  logic   [(2 * `XY_WIDTH)-1:0]           cam_datap_rd_data
);

    ip_pkt_hdr ip_hdr_reg;
    ip_pkt_hdr ip_hdr_next;

    logic   [MSG_TIMESTAMP_W-1:0]   timestamp_reg;
    logic   [MSG_TIMESTAMP_W-1:0]   timestamp_next;

    beehive_noc_hdr_flit    hdr_flit;
    ip_rx_metadata_flit     meta_flit;

    logic   [`TOT_LEN_W-1:0]    data_size;
    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;

    logic   [`XY_WIDTH-1:0] dst_x;
    logic   [`XY_WIDTH-1:0] dst_y;
    logic                   cam_hit;

    logic   [`MAC_INTERFACE_W-1:0]  masked_data;

    assign datap_cam_rd_tag = ip_hdr_next.protocol_no;

    assign {dst_x, dst_y} = cam_datap_rd_data;

    assign data_size = ip_hdr_next.tot_len - (ip_hdr_next.ip_hdr_len << 2);
    assign num_data_flits = data_size[`NOC_DATA_BYTES_W-1:0] == 0
                            ? data_size >> `NOC_DATA_BYTES_W
                            : (data_size >> `NOC_DATA_BYTES_W) + 1'b1;

    assign ip_hdr_next = ctrl_datap_store_inputs
                        ? ip_format_ip_rx_out_rx_ip_hdr
                        : ip_hdr_reg;

    assign timestamp_next = ctrl_datap_store_inputs
                            ? ip_format_ip_rx_out_rx_timestamp
                            : timestamp_reg;
    assign datap_ctrl_last_output = ip_format_ip_rx_out_rx_last;

    always_ff @(posedge clk) begin
        if (rst) begin
            ip_hdr_reg <= '0;
            timestamp_reg <= '0;
        end
        else begin
            ip_hdr_reg = ip_hdr_next;
            timestamp_reg <= timestamp_next;
        end
    end

    
    data_masker #(
        .width_p    (`MAC_INTERFACE_W)
    ) masker (  
         .unmasked_data (ip_format_ip_rx_out_rx_data        )
        ,.padbytes      (ip_format_ip_rx_out_rx_padbytes    )
        ,.last          (ip_format_ip_rx_out_rx_last        )
    
        ,.masked_data   (masked_data)
    );

    always_comb begin
        if (ctrl_datap_flit_sel == ip_rx_tile_pkg::SEL_HDR_FLIT) begin
            ip_rx_out_noc0_vrtoc_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == ip_rx_tile_pkg::SEL_META_FLIT) begin
            ip_rx_out_noc0_vrtoc_data = meta_flit;
        end
        else begin
            ip_rx_out_noc0_vrtoc_data = masked_data;
        end
    end
    
    always_comb begin
        hdr_flit = '0;

        hdr_flit.core.dst_x_coord = dst_x;
        hdr_flit.core.dst_y_coord = dst_y;
        hdr_flit.core.dst_fbits = PKT_IF_FBITS;

        // there's one metadata flit and then some number of data flits
        hdr_flit.core.msg_len = 1 + num_data_flits;
        hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.src_fbits = PKT_IF_FBITS;
        hdr_flit.core.metadata_flits = 1;

        hdr_flit.core.msg_type = (ip_hdr_next.protocol_no == `IPPROTO_TCP)
                            ? TCP_RX_SEGMENT
                            : '0;
    end

    always_comb begin
        meta_flit = '0;
        meta_flit.src_ip = ip_hdr_reg.source_addr;
        meta_flit.dst_ip = ip_hdr_reg.dest_addr;
        meta_flit.data_payload_len = data_size;
        meta_flit.protocol = ip_hdr_reg.protocol_no;
        meta_flit.timestamp = timestamp_reg;
    end
endmodule
