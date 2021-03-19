module ip_encap_tx (
     input clk
    ,input rst

    ,input  logic                               src_ip_encap_tx_meta_val
    ,input  logic   [`IP_ADDR_W-1:0]            src_ip_encap_tx_src_addr
    ,input  logic   [`IP_ADDR_W-1:0]            src_ip_encap_tx_dst_addr
    ,input  logic   [`TOT_LEN_W-1:0]            src_ip_encap_tx_data_payload_len
    ,input  logic   [`PROTOCOL_W-1:0]           src_ip_encap_tx_payload
    ,output logic                               ip_encap_src_tx_meta_rdy

    ,input  logic                               src_ip_encap_tx_data_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       src_ip_encap_tx_data
    ,input  logic                               src_ip_encap_tx_data_last
    ,input  logic   [`NOC_PADBYTES_WIDTH-1:0]   src_ip_encap_tx_data_padbytes
    ,output logic                               ip_encap_src_tx_data_rdy
    
    ,output logic                               ip_encap_dst_tx_meta_val
    ,output logic   [`IP_ADDR_W-1:0]            ip_encap_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            ip_encap_dst_tx_dst_ip
    ,output logic   [`TOT_LEN_W-1:0]            ip_encap_dst_tx_data_payload_len
    ,output logic   [`PROTOCOL_W-1:0]           ip_encap_dst_tx_protocol
    ,input  logic                               dst_ip_encap_tx_meta_rdy
    
    ,output logic                               ip_encap_dst_tx_data_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       ip_encap_dst_tx_data
    ,output logic                               ip_encap_dst_tx_data_last
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   ip_encap_dst_tx_data_padbytes
    ,input  logic                               dst_ip_encap_tx_data_rdy
);


endmodule
