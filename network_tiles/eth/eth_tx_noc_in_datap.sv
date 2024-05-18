`include "eth_tx_tile_defs.svh"
module eth_tx_noc_in_datap 
import tracker_pkg::*;    
(
     input clk
    ,input rst
    
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_eth_tx_in_data
    
    ,output eth_hdr                             eth_tx_in_eth_tostream_eth_hdr
    ,output logic   [`MTU_SIZE_W-1:0]           eth_tx_in_eth_tostream_payload_len
    ,output tracker_stats_struct                eth_tx_in_eth_tostream_timestamp

    ,output logic   [`MAC_INTERFACE_W-1:0]      eth_tx_in_eth_tostream_data
    ,output logic                               eth_tx_in_eth_tostream_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       eth_tx_in_eth_tostream_data_padbytes
    
    ,input  logic                               ctrl_datap_store_hdr_flit
    ,input  logic                               ctrl_datap_store_meta_flit
    ,input  logic                               ctrl_datap_init_num_flits
    ,input  logic                               ctrl_datap_decr_num_flits

    ,output                                     datap_ctrl_last_flit
);

    eth_hdr eth_hdr_cast;

    beehive_noc_hdr_flit    hdr_flit_reg;
    beehive_noc_hdr_flit    hdr_flit_next;

    eth_tx_metadata_flit    meta_flit_reg;
    eth_tx_metadata_flit    meta_flit_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] flits_remaining_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flits_remaining_next;
    logic   [`MAC_PADBYTES_W:0]     padbytes_calc;

    assign eth_tx_in_eth_tostream_eth_hdr = eth_hdr_cast;
    assign eth_tx_in_eth_tostream_data = noc0_ctovr_eth_tx_in_data;
    assign eth_tx_in_eth_tostream_data_last = datap_ctrl_last_flit;
    assign eth_tx_in_eth_tostream_data_padbytes = eth_tx_in_eth_tostream_data_last
                                                ? padbytes_calc
                                                : '0;

    assign datap_ctrl_last_flit = flits_remaining_reg == 1;
    assign padbytes_calc = meta_flit_reg.payload_size[`MAC_INTERFACE_BYTES_W-1:0] == 0
                         ? '0
                         : `MAC_INTERFACE_BYTES - meta_flit_reg.payload_size[`MAC_INTERFACE_BYTES_W-1:0];
    
    assign eth_hdr_cast.dst = meta_flit_next.eth_dst;
    assign eth_hdr_cast.src = meta_flit_next.eth_src;
    assign eth_hdr_cast.eth_type = meta_flit_next.eth_type;
    assign eth_tx_in_eth_tostream_payload_len = meta_flit_next.payload_size;
    assign eth_tx_in_eth_tostream_timestamp = hdr_flit_reg.core.timestamp;


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

    assign hdr_flit_next = ctrl_datap_store_hdr_flit
                         ? noc0_ctovr_eth_tx_in_data
                         : hdr_flit_reg;

    assign meta_flit_next = ctrl_datap_store_meta_flit
                          ? noc0_ctovr_eth_tx_in_data
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



endmodule
