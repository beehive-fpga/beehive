// This literally just exists to check parameters and throw errors
// if they are the wrong size. Hopefully any hardware tools will just
// optimize this away
`include "noc_defs.vh"
import beehive_tcp_msg::*;
import beehive_ip_msg::*;
import beehive_udp_msg::*;
import beehive_eth_msg::*;
module parameter_checker (input clk);
    generate
        if ($bits(eth_rx_metadata_flit) != `NOC_DATA_WIDTH) begin
            $error("ETH RX header flit wrong width");
        end
        if ($bits(eth_tx_metadata_flit) != `NOC_DATA_WIDTH) begin
            $error("ETH TX header flit wrong width");
        end
    endgenerate

    generate
        if ($bits(udp_rx_metadata_flit) != `NOC_DATA_WIDTH) begin
            $error("UDP RX header flit wrong width");
        end
        if ($bits(udp_tx_metadata_flit) != `NOC_DATA_WIDTH) begin
            $error("UDP TX header flit wrong width");
        end
    endgenerate

    generate
        if ($bits(ip_rx_metadata_flit) != `NOC_DATA_WIDTH) begin
            $error("IP RX header flit wrong width");
        end
        if ($bits(ip_tx_metadata_flit) != `NOC_DATA_WIDTH) begin
            $error("IP TX header flit wrong width");
        end
    endgenerate

    generate
        if ($bits(tcp_noc_hdr_flit) != `NOC_DATA_WIDTH) begin
            $error("TCP header flit wrong width");
        end
    endgenerate
endmodule
