`include "eth_rx_tile_defs.svh"
module eth_rx_noc_out_datap 
import beehive_noc_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,output logic   [`NOC_DATA_WIDTH-1:0]           eth_rx_out_noc0_vrtoc_data
    
    ,input  eth_hdr                                 eth_format_eth_rx_out_eth_hdr
    ,input  logic   [`MTU_SIZE_W-1:0]               eth_format_eth_rx_out_data_size

    ,input  logic   [`MAC_INTERFACE_W-1:0]          eth_format_eth_rx_out_data
    ,input  logic                                   eth_format_eth_rx_out_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]           eth_format_eth_rx_out_data_padbytes

    ,input  eth_rx_tile_pkg::noc_out_flit_mux_sel   ctrl_datap_flit_sel
    ,input                                          ctrl_datap_store_inputs

    ,output logic   [`ETH_TYPE_W-1:0]               datap_cam_rd_tag
    ,input  logic   [(2 * `XY_WIDTH)-1:0]           cam_datap_rd_data
);
    eth_hdr hdr_cast;
    eth_hdr hdr_next;
    eth_hdr hdr_reg;
    beehive_noc_hdr_flit hdr_flit;
    eth_rx_metadata_flit meta_flit;

    logic   [`XY_WIDTH-1:0] dst_x;
    logic   [`XY_WIDTH-1:0] dst_y;

    logic   [`MAC_INTERFACE_W-1:0]  masked_data;

    logic   [`MSG_LENGTH_WIDTH-1:0]     num_data_flits;

    logic   [`MTU_SIZE_W-1:0]           data_size_reg;
    logic   [`MTU_SIZE_W-1:0]           data_size_next;

    logic   [MSG_TIMESTAMP_W-1:0]       timestamp_reg;

    assign {dst_x, dst_y} = cam_datap_rd_data;

    assign datap_cam_rd_tag = hdr_next.eth_type;

    assign hdr_cast = eth_format_eth_rx_out_eth_hdr;
    
    data_masker #(
        .width_p    (`MAC_INTERFACE_W)
    ) masker (  
         .unmasked_data (eth_format_eth_rx_out_data             )
        ,.padbytes      (eth_format_eth_rx_out_data_padbytes    )
        ,.last          (eth_format_eth_rx_out_data_last        )
    
        ,.masked_data   (masked_data)
    );

    // if there's an even number of data flits, just divide. Otherwise, divide and add 1
    assign num_data_flits = data_size_next[`NOC_DATA_BYTES_W-1:0] == 0
                          ? data_size_next >> `NOC_DATA_BYTES_W
                          : (data_size_next >> `NOC_DATA_BYTES_W) + 1'b1;

    always_comb begin
        if (ctrl_datap_flit_sel == eth_rx_tile_pkg::SEL_HDR_FLIT) begin
            eth_rx_out_noc0_vrtoc_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == eth_rx_tile_pkg::SEL_META_FLIT) begin
            eth_rx_out_noc0_vrtoc_data = meta_flit;
        end
        else begin
            eth_rx_out_noc0_vrtoc_data = masked_data;
        end
    end



    assign hdr_next = ctrl_datap_store_inputs
                    ? eth_format_eth_rx_out_eth_hdr
                    : hdr_reg;

    assign data_size_next = ctrl_datap_store_inputs
                          ? eth_format_eth_rx_out_data_size
                          : data_size_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_reg <= '0;
            data_size_reg <= '0;
            timestamp_reg <= '0;
        end
        else begin
            hdr_reg <= hdr_next;
            data_size_reg <= data_size_next;
            timestamp_reg <= timestamp_reg + 1'b1;
        end
    end

    /* NoC header flit */
    always_comb begin
        hdr_flit = '0;

        hdr_flit.core.dst_x_coord = dst_x;
        hdr_flit.core.dst_y_coord = dst_y;
        hdr_flit.core.dst_fbits = PKT_IF_FBITS;
        // there's one metadata flit and then however many data flits
        hdr_flit.core.msg_len = 1 + (num_data_flits);
        hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.metadata_flits = 1;
        
        hdr_flit.core.msg_type = (hdr_next.eth_type == `ETH_TYPE_IPV4)
                          ? IP_RX_DATAGRAM
                          : '0;
    end

    /* ETH metadata flit */
    always_comb begin
        meta_flit = '0;
        meta_flit.eth_dst = hdr_reg.dst;
        meta_flit.eth_src = hdr_reg.src;
        meta_flit.eth_data_len = data_size_reg;
        meta_flit.timestamp =  timestamp_reg;
    end


endmodule
