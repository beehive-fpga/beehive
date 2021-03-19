`include "ip_rx_tile_defs.svh"
module ip_rx_noc_in_datap (
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_ip_rx_in_data

    ,output logic   [`MAC_INTERFACE_W-1:0]      ip_rx_in_ip_format_rx_data
    ,output logic   [MSG_TIMESTAMP_W-1:0]       ip_rx_in_ip_format_rx_timestamp
    ,output logic                               ip_rx_in_ip_format_rx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       ip_rx_in_ip_format_rx_padbytes
    
    ,output logic                               datap_ctrl_last_flit
    ,output logic                               datap_ctrl_last_meta_flit
    
    ,input  logic                               ctrl_datap_init_data
    ,input  logic                               ctrl_datap_store_meta_flit
    ,input  logic                               ctrl_datap_decr_meta_flits
    ,input  logic                               ctrl_datap_decr_data_flits
);

    beehive_noc_hdr_flit    hdr_flit_reg;
    beehive_noc_hdr_flit    hdr_flit_next;

    eth_rx_metadata_flit    eth_metadata_flit_reg;
    eth_rx_metadata_flit    eth_metadata_flit_next;

    logic   [MSG_METADATA_FLITS_W-1:0] metadata_flits_reg;
    logic   [MSG_METADATA_FLITS_W-1:0] metadata_flits_next;

    logic   [`MSG_LENGTH_WIDTH-1:0]     data_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     data_flits_next;

    assign datap_ctrl_last_flit = data_flits_reg == 1;
    assign datap_ctrl_last_meta_flit = metadata_flits_reg == 1;

    assign ip_rx_in_ip_format_rx_data = noc0_ctovr_ip_rx_in_data;
    assign ip_rx_in_ip_format_rx_last = datap_ctrl_last_flit;
    assign ip_rx_in_ip_format_rx_padbytes = eth_metadata_flit_reg.eth_data_len[`NOC_DATA_BYTES_W-1:0] == '0
                                        ? '0
                                        : `NOC_DATA_BYTES - eth_metadata_flit_reg.eth_data_len[`NOC_DATA_BYTES_W-1:0];
    assign ip_rx_in_ip_format_rx_timestamp = eth_metadata_flit_reg.timestamp;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_reg <= '0;
            eth_metadata_flit_reg <= '0;
            metadata_flits_reg <= '0;
            data_flits_reg <= '0;
        end
        else begin
            hdr_flit_reg <= hdr_flit_next;
            eth_metadata_flit_reg <= eth_metadata_flit_next;
            metadata_flits_reg <= metadata_flits_next;
            data_flits_reg <= data_flits_next;
        end
    end

    assign hdr_flit_next = ctrl_datap_init_data
                         ? noc0_ctovr_ip_rx_in_data
                         : hdr_flit_reg;

    assign eth_metadata_flit_next = ctrl_datap_store_meta_flit
                                  ? noc0_ctovr_ip_rx_in_data
                                  : eth_metadata_flit_reg;

    always_comb begin
        if (ctrl_datap_init_data) begin
            metadata_flits_next = hdr_flit_next.core.metadata_flits;
        end
        else if (ctrl_datap_decr_meta_flits) begin
            metadata_flits_next = metadata_flits_reg - 1'b1;
        end
        else begin
            metadata_flits_next = metadata_flits_reg;
        end
    end 

    always_comb begin
        if (ctrl_datap_init_data) begin
            data_flits_next = hdr_flit_next.core.msg_len - hdr_flit_next.core.metadata_flits;
        end
        else if (ctrl_datap_decr_data_flits) begin
            data_flits_next = data_flits_reg - 1'b1;
        end
        else begin
            data_flits_next = data_flits_reg;
        end
    end

endmodule
