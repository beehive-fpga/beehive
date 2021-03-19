`include "ip_encap_tx_defs.svh"
module ip_encap_tx_wrap (
     input  clk
    ,input  rst

    ,input  logic                               src_ip_encap_tx_meta_val
    ,input  logic   [`IP_ADDR_W-1:0]            src_ip_encap_tx_src_addr
    ,input  logic   [`IP_ADDR_W-1:0]            src_ip_encap_tx_dst_addr
    ,input  logic   [`TOT_LEN_W-1:0]            src_ip_encap_tx_data_payload_len
    ,input  logic   [`PROTOCOL_W-1:0]           src_ip_encap_tx_protocol
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
    
    logic                           ctrl_datap_store_inputs;
    logic                           ctrl_datap_store_ips;

    logic                           ctrl_ip_dir_cam_read_val;
    logic                           ip_dir_cam_ctrl_read_hit;

    logic                           ctrl_ip_hdr_assemble_val;
    logic   [`IP_ADDR_W-1:0]        datap_ip_hdr_assemble_src_addr;
    logic   [`IP_ADDR_W-1:0]        datap_ip_hdr_assemble_dst_addr;
    logic   [`TOT_LEN_W-1:0]        datap_ip_hdr_assemble_data_payload_len;
    logic   [`PROTOCOL_W-1:0]       datap_ip_hdr_assemble_protocol;
    logic                           ip_hdr_assemble_ctrl_rdy;
    
    logic                           to_stream_ip_encap_tx_data_val;
    logic                           to_stream_ip_encap_tx_data_last;
    logic                           ip_encap_to_stream_tx_data_rdy;
    
    logic                           ip_hdr_assemble_ip_to_stream_hdr_val;
    logic   [`IP_HDR_W-1:0]         ip_hdr_assemble_ip_to_stream_ip_hdr;
    logic                           ip_to_stream_ip_hdr_assemble_hdr_rdy;
    
    logic                           to_stream_ctrl_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  to_stream_datap_data;
    logic                           to_stream_datap_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   to_stream_datap_data_padbytes;
    logic                           ctrl_to_stream_data_rdy;
    
    logic   [`IP_ADDR_W-1:0]        datap_ip_dir_cam_read_src_laddr;
    logic   [`IP_ADDR_W-1:0]        datap_ip_dir_cam_read_dst_laddr;

    logic   [`IP_ADDR_W-1:0]        ip_dir_cam_datap_read_src_paddr;
    logic   [`IP_ADDR_W-1:0]        ip_dir_cam_datap_read_dst_paddr;
    
    logic   [IP_CAM_ELS-1:0]        init_wr_cam_val;
    logic                           init_wr_cam_set;
    logic   [`IP_ADDR_W-1:0]        init_wr_cam_tag;
    logic   [`IP_ADDR_W-1:0]        init_wr_cam_data;
    logic                           wr_cam_init_rdy;

    ip_encap_tx_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_ip_encap_tx_meta_val  (src_ip_encap_tx_meta_val           )
        ,.ip_encap_src_tx_meta_rdy  (ip_encap_src_tx_meta_rdy           )
    
        ,.src_ip_encap_tx_data_val  (to_stream_ctrl_data_val            )
        ,.src_ip_encap_tx_data_last (to_stream_datap_data_last          )
        ,.ip_encap_src_tx_data_rdy  (ctrl_to_stream_data_rdy            )
        
        ,.ip_encap_dst_tx_meta_val  (ip_encap_dst_tx_meta_val           )
        ,.dst_ip_encap_tx_meta_rdy  (dst_ip_encap_tx_meta_rdy           )
                                                                
        ,.ip_encap_dst_tx_data_val  (ip_encap_dst_tx_data_val           )
        ,.dst_ip_encap_tx_data_rdy  (dst_ip_encap_tx_data_rdy           )
    
        ,.ctrl_datap_store_inputs   (ctrl_datap_store_inputs            )
        ,.ctrl_datap_store_ips      (ctrl_datap_store_ips               )
                                                                
        ,.ctrl_ip_dir_cam_read_val  (ctrl_ip_dir_cam_read_val           )
        ,.ip_dir_cam_ctrl_read_hit  (ip_dir_cam_ctrl_read_hit           )
                                                                
        ,.ctrl_ip_hdr_assemble_val  (ctrl_ip_hdr_assemble_val           )
        ,.ip_hdr_assemble_ctrl_rdy  (ip_hdr_assemble_ctrl_rdy           )
    );

    ip_encap_tx_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_ip_encap_tx_src_addr          (src_ip_encap_tx_src_addr           )
        ,.src_ip_encap_tx_dst_addr          (src_ip_encap_tx_dst_addr           )
        ,.src_ip_encap_tx_data_payload_len  (src_ip_encap_tx_data_payload_len   )
        ,.src_ip_encap_tx_protocol          (src_ip_encap_tx_protocol           )
        
        ,.src_ip_encap_tx_data              (to_stream_datap_data               )
        ,.src_ip_encap_tx_data_last         (to_stream_datap_data_last          )
        ,.src_ip_encap_tx_data_padbytes     (to_stream_datap_data_padbytes      )
        
        ,.ip_encap_dst_tx_src_ip            (ip_encap_dst_tx_src_ip             )
        ,.ip_encap_dst_tx_dst_ip            (ip_encap_dst_tx_dst_ip             )
        ,.ip_encap_dst_tx_data_payload_len  (ip_encap_dst_tx_data_payload_len   )
        ,.ip_encap_dst_tx_protocol          (ip_encap_dst_tx_protocol           )
        
        ,.ip_encap_dst_tx_data              (ip_encap_dst_tx_data               )
        ,.ip_encap_dst_tx_data_last         (ip_encap_dst_tx_data_last          )
        ,.ip_encap_dst_tx_data_padbytes     (ip_encap_dst_tx_data_padbytes      )
        
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
        ,.ctrl_datap_store_ips              (ctrl_datap_store_ips               )
        
        ,.datap_ip_dir_cam_read_src_laddr   (datap_ip_dir_cam_read_src_laddr    )
        ,.datap_ip_dir_cam_read_dst_laddr   (datap_ip_dir_cam_read_dst_laddr    )
                                                                                
        ,.ip_dir_cam_datap_read_src_paddr   (ip_dir_cam_datap_read_src_paddr    )
        ,.ip_dir_cam_datap_read_dst_paddr   (ip_dir_cam_datap_read_dst_paddr    )
    
        ,.datap_ip_hdr_assemble_src_addr        (datap_ip_hdr_assemble_src_addr        )
        ,.datap_ip_hdr_assemble_dst_addr        (datap_ip_hdr_assemble_dst_addr        )
        ,.datap_ip_hdr_assemble_data_payload_len(datap_ip_hdr_assemble_data_payload_len)
        ,.datap_ip_hdr_assemble_protocol        (datap_ip_hdr_assemble_protocol        )
    );

    ip_header_assembler inner_hdr (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.ip_hdr_req_val        (ctrl_ip_hdr_assemble_val               )
        ,.source_ip_addr        (datap_ip_hdr_assemble_src_addr         )
        ,.dest_ip_addr          (datap_ip_hdr_assemble_dst_addr         )
        ,.data_payload_len      (datap_ip_hdr_assemble_data_payload_len )
        ,.protocol              (datap_ip_hdr_assemble_protocol         )
        ,.ip_hdr_req_rdy        (ip_hdr_assemble_ctrl_rdy               )
    
        ,.outbound_ip_hdr_val   (ip_hdr_assemble_ip_to_stream_hdr_val   )
        ,.outbound_ip_hdr       (ip_hdr_assemble_ip_to_stream_ip_hdr    )
        ,.outbound_ip_hdr_rdy   (ip_to_stream_ip_hdr_assemble_hdr_rdy   )
    );

    ip_to_stream encap_to_stream (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_ip_to_stream_hdr_val          (ip_hdr_assemble_ip_to_stream_hdr_val   )
        ,.src_ip_to_stream_ip_hdr           (ip_hdr_assemble_ip_to_stream_ip_hdr    )
        ,.ip_to_stream_src_hdr_rdy          (ip_to_stream_ip_hdr_assemble_hdr_rdy   )
    
        ,.src_ip_to_stream_data_val         (src_ip_encap_tx_data_val               )
        ,.src_ip_to_stream_data             (src_ip_encap_tx_data                   )
        ,.src_ip_to_stream_data_last        (src_ip_encap_tx_data_last              )
        ,.src_ip_to_stream_data_padbytes    (src_ip_encap_tx_data_padbytes          )
        ,.ip_to_stream_src_data_rdy         (ip_encap_src_tx_data_rdy               )
        
        ,.ip_to_stream_dst_data_val         (to_stream_ctrl_data_val                )
        ,.ip_to_stream_dst_data             (to_stream_datap_data                   )
        ,.ip_to_stream_dst_data_last        (to_stream_datap_data_last              )
        ,.ip_to_stream_dst_data_padbytes    (to_stream_datap_data_padbytes          )
        ,.dst_ip_to_stream_data_rdy         (ctrl_to_stream_data_rdy                )
    );

    logic   src_ip_dir_cam_ctrl_read_hit;
    logic   dst_ip_dir_cam_ctrl_read_hit;

    bsg_cam_1r1w_unmanaged #(
        .els_p          (IP_CAM_ELS )
       ,.tag_width_p    (`IP_ADDR_W )
       ,.data_width_p   (`IP_ADDR_W )
    ) src_ip_dir_cam (
         .clk_i     (clk    )
        ,.reset_i   (rst    )
        
        ,.w_v_i             (init_wr_cam_val                    )
        ,.w_set_not_clear_i (init_wr_cam_set                    )
        ,.w_tag_i           (init_wr_cam_tag                    )
        ,.w_data_i          (init_wr_cam_data                   )
        ,.w_empty_o         ()
        
        ,.r_v_i             (ctrl_ip_dir_cam_read_val           )
        ,.r_tag_i           (datap_ip_dir_cam_read_src_laddr    )
        ,.r_data_o          (ip_dir_cam_datap_read_src_paddr    )
        ,.r_v_o             (src_ip_dir_cam_ctrl_read_hit       )
    );

    assign wr_cam_init_rdy = 1'b1;
    
    bsg_cam_1r1w_unmanaged #(
        .els_p          (IP_CAM_ELS )
       ,.tag_width_p    (`IP_ADDR_W )
       ,.data_width_p   (`IP_ADDR_W )
    ) dst_ip_dir_cam (
         .clk_i     (clk    )
        ,.reset_i   (rst    )
        
        ,.w_v_i             (init_wr_cam_val                    )
        ,.w_set_not_clear_i (init_wr_cam_set                    )
        ,.w_tag_i           (init_wr_cam_tag                    )
        ,.w_data_i          (init_wr_cam_data                   )
        ,.w_empty_o         ()
        
        ,.r_v_i             (ctrl_ip_dir_cam_read_val           )
        ,.r_tag_i           (datap_ip_dir_cam_read_dst_laddr    )
        ,.r_data_o          (ip_dir_cam_datap_read_dst_paddr    )
        ,.r_v_o             (dst_ip_dir_cam_ctrl_read_hit       )
    );

    assign ip_dir_cam_ctrl_read_hit = dst_ip_dir_cam_ctrl_read_hit 
                                    & src_ip_dir_cam_ctrl_read_hit;

    ip_dir_cam_init #(
         .CAM_ELS       (IP_CAM_ELS         )
        ,.INIT_CAM_ELS  (IP_CAM_INIT_ELS    )
    ) ip_dir_cam_init (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.init_wr_cam_val   (init_wr_cam_val    )
        ,.init_wr_cam_set   (init_wr_cam_set    )
        ,.init_wr_cam_tag   (init_wr_cam_tag    )
        ,.init_wr_cam_data  (init_wr_cam_data   )
        ,.wr_cam_init_rdy   (wr_cam_init_rdy    )
    );
endmodule
