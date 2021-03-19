import tcp_rx_tile_pkg::*;
`include "tcp_rx_tile_defs.svh"
module tcp_rx_noc_in (
     input clk
    ,input rst

    ,input                                  noc0_ctovr_tcp_rx_in_val
    ,input  [`NOC_DATA_WIDTH-1:0]           noc0_ctovr_tcp_rx_in_data
    ,output logic                           tcp_rx_in_noc0_ctovr_rdy     
    
    // I/O from the MAC side
    ,output logic                           tcp_rx_in_tcp_format_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]        tcp_rx_in_tcp_format_src_ip
    ,output logic   [`IP_ADDR_W-1:0]        tcp_rx_in_tcp_format_dst_ip
    ,output logic   [`TOT_LEN_W-1:0]        tcp_rx_in_tcp_format_tcp_len
    ,input                                  tcp_format_tcp_rx_in_hdr_rdy

    ,output logic                           tcp_rx_in_tcp_format_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  tcp_rx_in_tcp_format_data
    ,output logic                           tcp_rx_in_tcp_format_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   tcp_rx_in_tcp_format_padbytes
    ,input                                  tcp_format_tcp_rx_in_data_rdy
);
    logic                   ctrl_datap_store_hdr_flit;
    logic                   ctrl_datap_store_meta_flit;
    logic                   ctrl_datap_init_num_flits;
    logic                   ctrl_datap_decr_num_flits;

    logic                   datap_ctrl_last_flit;

    tcp_rx_noc_in_datap datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_tcp_rx_in_data     (noc0_ctovr_tcp_rx_in_data      )
                                                                        
        ,.tcp_rx_in_tcp_format_src_ip   (tcp_rx_in_tcp_format_src_ip    )
        ,.tcp_rx_in_tcp_format_dst_ip   (tcp_rx_in_tcp_format_dst_ip    )
        ,.tcp_rx_in_tcp_format_tcp_len  (tcp_rx_in_tcp_format_tcp_len   )
                                                                        
        ,.tcp_rx_in_tcp_format_data     (tcp_rx_in_tcp_format_data      )
        ,.tcp_rx_in_tcp_format_last     (tcp_rx_in_tcp_format_last      )
        ,.tcp_rx_in_tcp_format_padbytes (tcp_rx_in_tcp_format_padbytes  )
                                                                        
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit     )
        ,.ctrl_datap_init_num_flits     (ctrl_datap_init_num_flits      )
        ,.ctrl_datap_decr_num_flits     (ctrl_datap_decr_num_flits      )
                                                                        
        ,.datap_ctrl_last_flit          (datap_ctrl_last_flit           )
    );

    tcp_rx_noc_in_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_tcp_rx_in_val      (noc0_ctovr_tcp_rx_in_val       )
        ,.tcp_rx_in_noc0_ctovr_rdy      (tcp_rx_in_noc0_ctovr_rdy       )
                                                                        
        ,.tcp_rx_in_tcp_format_hdr_val  (tcp_rx_in_tcp_format_hdr_val   )
        ,.tcp_format_tcp_rx_in_hdr_rdy  (tcp_format_tcp_rx_in_hdr_rdy   )
                                                                        
        ,.tcp_rx_in_tcp_format_data_val (tcp_rx_in_tcp_format_data_val  )
        ,.tcp_format_tcp_rx_in_data_rdy (tcp_format_tcp_rx_in_data_rdy  )
                                                                        
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_meta_flit    (ctrl_datap_store_meta_flit     )
        ,.ctrl_datap_init_num_flits     (ctrl_datap_init_num_flits      )
        ,.ctrl_datap_decr_num_flits     (ctrl_datap_decr_num_flits      )
                                                                        
        ,.datap_ctrl_last_flit          (datap_ctrl_last_flit           )
    );

endmodule
