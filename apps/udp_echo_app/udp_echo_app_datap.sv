`include "udp_echo_app_defs.svh"
module udp_echo_app_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_app_in_data

    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_app_out_noc0_vrtoc_data

    ,input          [`XY_WIDTH-1:0]         src_udp_app_out_dst_x
    ,input          [`XY_WIDTH-1:0]         src_udp_app_out_dst_y

    ,input                                  in_store_hdr_flit
    ,input                                  in_store_meta_flit

    ,input          udp_app_out_mux_sel_e   out_data_mux_sel
    
    ,output         [`MSG_LENGTH_WIDTH-1:0] total_flits
    ,output         [`UDP_LENGTH_W-1:0]     data_length
);
    
    beehive_noc_hdr_flit    hdr_flit_reg;
    beehive_noc_hdr_flit    hdr_flit_next;
    
    udp_rx_metadata_flit    meta_flit_reg;
    udp_rx_metadata_flit    meta_flit_next;
    
    beehive_noc_hdr_flit    out_hdr_flit;
    udp_tx_metadata_flit    out_meta_flit;

    assign total_flits = hdr_flit_reg.core.core.msg_len;
    assign data_length = meta_flit_reg.data_length;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_reg <= '0;
            meta_flit_reg <= '0;
        end
        else begin
            hdr_flit_reg <= hdr_flit_next;
            meta_flit_reg <= meta_flit_next;
        end
    end

    assign hdr_flit_next = in_store_hdr_flit
                        ? noc0_ctovr_udp_app_in_data
                        : hdr_flit_reg;

    assign meta_flit_next = in_store_meta_flit
                        ? noc0_ctovr_udp_app_in_data
                        : meta_flit_reg;

    always_comb begin
        if (out_data_mux_sel == HDR_FLIT) begin
            udp_app_out_noc0_vrtoc_data = out_hdr_flit;
        end
        else if (out_data_mux_sel == META_FLIT) begin
            udp_app_out_noc0_vrtoc_data = out_meta_flit;
        end
        else begin
            udp_app_out_noc0_vrtoc_data = noc0_ctovr_udp_app_in_data;
        end
    end
    
    always_comb begin
        out_hdr_flit = '0;

        out_hdr_flit.core.core.dst_x_coord = src_udp_app_out_dst_x;
        out_hdr_flit.core.core.dst_y_coord = src_udp_app_out_dst_y;
        out_hdr_flit.core.core.dst_fbits = PKT_IF_FBITS;

        // there's one metadata flit and then some number of data flits
        out_hdr_flit.core.core.msg_len = hdr_flit_reg.core.core.msg_len;
        out_hdr_flit.core.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        out_hdr_flit.core.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        out_hdr_flit.core.core.src_fbits = PKT_IF_FBITS;

        out_hdr_flit.core.core.msg_type = UDP_TX_SEGMENT; 

        out_hdr_flit.core.packet_id = hdr_flit_reg.core.packet_id;
        out_hdr_flit.core.timestamp = hdr_flit_reg.core.timestamp;
        
        out_hdr_flit.core.metadata_flits = 1;
    end
    
    always_comb begin
        out_meta_flit = '0;
        out_meta_flit.src_ip = meta_flit_reg.dst_ip;
        out_meta_flit.dst_ip = meta_flit_reg.src_ip;
        out_meta_flit.src_port = meta_flit_reg.dst_port;
        out_meta_flit.dst_port = meta_flit_reg.src_port;
        out_meta_flit.data_length = meta_flit_reg.data_length;
        out_meta_flit.timestamp = meta_flit_reg.timestamp;
    end



endmodule
