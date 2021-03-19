`include "ip_encap_tx_defs.svh"
module ip_encap_tx_datap (
     input  clk
    ,input  rst

    ,input  logic   [`IP_ADDR_W-1:0]            src_ip_encap_tx_src_addr
    ,input  logic   [`IP_ADDR_W-1:0]            src_ip_encap_tx_dst_addr
    ,input  logic   [`TOT_LEN_W-1:0]            src_ip_encap_tx_data_payload_len
    ,input  logic   [`PROTOCOL_W-1:0]           src_ip_encap_tx_protocol
    
    ,input  logic   [`NOC_DATA_WIDTH-1:0]       src_ip_encap_tx_data
    ,input  logic                               src_ip_encap_tx_data_last
    ,input  logic   [`NOC_PADBYTES_WIDTH-1:0]   src_ip_encap_tx_data_padbytes
    
    ,output logic   [`IP_ADDR_W-1:0]            ip_encap_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            ip_encap_dst_tx_dst_ip
    ,output logic   [`TOT_LEN_W-1:0]            ip_encap_dst_tx_data_payload_len
    ,output logic   [`PROTOCOL_W-1:0]           ip_encap_dst_tx_protocol
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]       ip_encap_dst_tx_data
    ,output logic                               ip_encap_dst_tx_data_last
    ,output logic   [`NOC_PADBYTES_WIDTH-1:0]   ip_encap_dst_tx_data_padbytes
    
    ,input  logic                               ctrl_datap_store_inputs
    ,input  logic                               ctrl_datap_store_ips
    
    ,output logic   [`IP_ADDR_W-1:0]            datap_ip_dir_cam_read_src_laddr
    ,output logic   [`IP_ADDR_W-1:0]            datap_ip_dir_cam_read_dst_laddr

    ,input  logic   [`IP_ADDR_W-1:0]            ip_dir_cam_datap_read_src_paddr
    ,input  logic   [`IP_ADDR_W-1:0]            ip_dir_cam_datap_read_dst_paddr
    
    ,output logic   [`IP_ADDR_W-1:0]            datap_ip_hdr_assemble_src_addr
    ,output logic   [`IP_ADDR_W-1:0]            datap_ip_hdr_assemble_dst_addr
    ,output logic   [`TOT_LEN_W-1:0]            datap_ip_hdr_assemble_data_payload_len
    ,output logic   [`PROTOCOL_W-1:0]           datap_ip_hdr_assemble_protocol
);

    logic   [`IP_ADDR_W-1:0]    src_laddr_reg;
    logic   [`IP_ADDR_W-1:0]    dst_laddr_reg;
    logic   [`IP_ADDR_W-1:0]    src_paddr_reg;
    logic   [`IP_ADDR_W-1:0]    dst_paddr_reg;
    logic   [`TOT_LEN_W-1:0]    payload_len_reg;
    logic   [`PROTOCOL_W-1:0]   protocol_reg;


    logic   [`IP_ADDR_W-1:0]    src_laddr_next;
    logic   [`IP_ADDR_W-1:0]    dst_laddr_next;
    logic   [`IP_ADDR_W-1:0]    src_paddr_next;
    logic   [`IP_ADDR_W-1:0]    dst_paddr_next;
    logic   [`TOT_LEN_W-1:0]    payload_len_next;
    logic   [`PROTOCOL_W-1:0]   protocol_next;

    assign datap_ip_dir_cam_read_src_laddr = src_laddr_reg;
    assign datap_ip_dir_cam_read_dst_laddr = dst_laddr_reg;

    assign  ip_encap_dst_tx_src_ip = src_paddr_reg;
    assign  ip_encap_dst_tx_dst_ip = dst_paddr_reg;
    assign  ip_encap_dst_tx_data_payload_len = payload_len_reg + `IP_HDR_BYTES;
    assign  ip_encap_dst_tx_protocol = `IPPROTO_IP_IN_IP;

    assign ip_encap_dst_tx_data = src_ip_encap_tx_data;
    assign ip_encap_dst_tx_data_last = src_ip_encap_tx_data_last;
    assign ip_encap_dst_tx_data_padbytes = src_ip_encap_tx_data_padbytes;

    assign datap_ip_hdr_assemble_src_addr = src_laddr_reg;
    assign datap_ip_hdr_assemble_dst_addr = dst_laddr_reg;
    assign datap_ip_hdr_assemble_data_payload_len = payload_len_reg;
    assign datap_ip_hdr_assemble_protocol = protocol_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            src_laddr_reg <= '0;
            dst_laddr_reg <= '0;
            src_paddr_reg <= '0;
            dst_paddr_reg <= '0;
            payload_len_reg <= '0;
            protocol_reg <= '0;
        end
        else begin
            src_laddr_reg <= src_laddr_next;
            dst_laddr_reg <= dst_laddr_next;
            src_paddr_reg <= src_paddr_next;
            dst_paddr_reg <= dst_paddr_next;
            payload_len_reg <= payload_len_next;
            protocol_reg <= protocol_next;
        end
    end

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            src_laddr_next = src_ip_encap_tx_src_addr;
            dst_laddr_next = src_ip_encap_tx_dst_addr;
            payload_len_next = src_ip_encap_tx_data_payload_len;
            protocol_next = src_ip_encap_tx_protocol;
        end
        else begin
            src_laddr_next = src_laddr_reg;
            dst_laddr_next = dst_laddr_reg;
            payload_len_next = payload_len_reg;
            protocol_next = protocol_reg;
        end
    end

    assign src_paddr_next = ctrl_datap_store_ips
                        ? ip_dir_cam_datap_read_src_paddr
                        : src_paddr_reg;

    assign dst_paddr_next = ctrl_datap_store_ips
                        ? ip_dir_cam_datap_read_dst_paddr
                        : dst_paddr_reg;



endmodule
