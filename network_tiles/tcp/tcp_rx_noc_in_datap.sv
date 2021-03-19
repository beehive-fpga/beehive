`include "tcp_rx_tile_defs.svh"
module tcp_rx_noc_in_datap (
     input clk
    ,input rst
    
    ,input  [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_rx_in_data
    
    // I/O from the MAC side
    ,output logic   [`IP_ADDR_W-1:0]        tcp_rx_in_tcp_format_src_ip
    ,output logic   [`IP_ADDR_W-1:0]        tcp_rx_in_tcp_format_dst_ip
    ,output logic   [`TOT_LEN_W-1:0]        tcp_rx_in_tcp_format_tcp_len

    ,output logic   [`MAC_INTERFACE_W-1:0]  tcp_rx_in_tcp_format_data
    ,output logic                           tcp_rx_in_tcp_format_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   tcp_rx_in_tcp_format_padbytes
    
    ,input  logic                   ctrl_datap_store_hdr_flit
    ,input  logic                   ctrl_datap_store_meta_flit
    ,input  logic                   ctrl_datap_init_num_flits
    ,input  logic                   ctrl_datap_decr_num_flits

    ,output logic                   datap_ctrl_last_flit
);
    
    beehive_noc_hdr_flit                hdr_flit_reg;
    beehive_noc_hdr_flit                hdr_flit_next;

    ip_rx_metadata_flit                 meta_flit_reg;
    ip_rx_metadata_flit                 meta_flit_next;
    
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_remaining_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0]     flits_remaining_next;
    logic   [`MAC_PADBYTES_W:0]         padbytes_calc;

    assign tcp_rx_in_tcp_format_data = noc0_ctovr_tcp_rx_in_data;
    assign tcp_rx_in_tcp_format_last = datap_ctrl_last_flit;
    assign padbytes_calc = meta_flit_reg.data_payload_len[`NOC_DATA_BYTES_W-1:0] == 0
                         ? '0
                         : `NOC_DATA_BYTES - meta_flit_reg.data_payload_len[`NOC_DATA_BYTES_W-1:0];
    assign tcp_rx_in_tcp_format_padbytes = datap_ctrl_last_flit
                                            ? padbytes_calc[`MAC_PADBYTES_W-1:0]
                                            : '0;

    assign datap_ctrl_last_flit = flits_remaining_reg == 1;

    assign tcp_rx_in_tcp_format_src_ip = meta_flit_next.src_ip;
    assign tcp_rx_in_tcp_format_dst_ip = meta_flit_next.dst_ip;
    assign tcp_rx_in_tcp_format_tcp_len = meta_flit_next.data_payload_len;

    assign hdr_flit_next = ctrl_datap_store_hdr_flit
                            ? noc0_ctovr_tcp_rx_in_data
                            : hdr_flit_reg;
    assign meta_flit_next = ctrl_datap_store_meta_flit
                            ? noc0_ctovr_tcp_rx_in_data
                            : meta_flit_reg;

    always_comb begin
        if (ctrl_datap_init_num_flits) begin
            flits_remaining_next = hdr_flit_next.core.msg_len;
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
