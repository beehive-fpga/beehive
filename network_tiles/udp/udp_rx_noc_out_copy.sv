`include "udp_rx_tile_defs.svh"
module udp_rx_noc_out_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input                                  udp_formatter_udp_rx_out_rx_hdr_val
    ,input          [`IP_ADDR_W-1:0]        udp_formatter_udp_rx_out_rx_src_ip
    ,input          [`IP_ADDR_W-1:0]        udp_formatter_udp_rx_out_rx_dst_ip
    ,input  udp_pkt_hdr                     udp_formatter_udp_rx_out_rx_udp_hdr
    ,input          [MSG_TIMESTAMP_W-1:0]   udp_formatter_udp_rx_out_rx_timestamp
    ,output logic                           udp_rx_out_udp_formatter_rx_hdr_rdy

    ,input                                  udp_formatter_udp_rx_out_rx_data_val
    ,input          [`MAC_INTERFACE_W-1:0]  udp_formatter_udp_rx_out_rx_data
    ,input                                  udp_formatter_udp_rx_out_rx_last
    ,input          [`MAC_PADBYTES_W-1:0]   udp_formatter_udp_rx_out_rx_padbytes
    ,output logic                           udp_rx_out_udp_formatter_rx_data_rdy
    
    ,output logic                           udp_rx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_rx_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_udp_rx_out_rdy
);
    udp_rx_tile_pkg::noc_out_flit_mux_sel            ctrl_datap_flit_sel;
    logic                           ctrl_datap_store_inputs;
    
    logic                           datap_ctrl_last_output;
    logic                           datap_ctrl_no_data;

    logic                           ctrl_cam_rd_cam;
    logic                           cam_ctrl_rd_hit;
    logic   [`PORT_NUM_W-1:0]       datap_cam_rd_tag;
    udp_rx_cam_entry                cam_datap_rd_data;

    udp_rx_noc_out_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_formatter_udp_rx_out_rx_hdr_val   (udp_formatter_udp_rx_out_rx_hdr_val    )
        ,.udp_rx_out_udp_formatter_rx_hdr_rdy   (udp_rx_out_udp_formatter_rx_hdr_rdy    )
                                                                                        
        ,.udp_formatter_udp_rx_out_rx_data_val  (udp_formatter_udp_rx_out_rx_data_val   )
        ,.udp_formatter_udp_rx_out_rx_last      (udp_formatter_udp_rx_out_rx_last       )
        ,.udp_rx_out_udp_formatter_rx_data_rdy  (udp_rx_out_udp_formatter_rx_data_rdy   )
                                                                                        
        ,.udp_rx_out_noc0_vrtoc_val             (udp_rx_out_noc0_vrtoc_val              )
        ,.noc0_vrtoc_udp_rx_out_rdy             (noc0_vrtoc_udp_rx_out_rdy              )
                                                                                        
        ,.ctrl_datap_flit_sel                   (ctrl_datap_flit_sel                    )
        ,.ctrl_datap_store_inputs               (ctrl_datap_store_inputs                )
                                                                                        
        ,.datap_ctrl_last_output                (datap_ctrl_last_output                 )
        ,.datap_ctrl_no_data                    (datap_ctrl_no_data                     )
    
        ,.ctrl_cam_rd_cam                       (ctrl_cam_rd_cam                        )
        ,.cam_ctrl_rd_hit                       (cam_ctrl_rd_hit                        )
    );

    udp_rx_noc_out_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_formatter_udp_rx_out_rx_src_ip    (udp_formatter_udp_rx_out_rx_src_ip     )
        ,.udp_formatter_udp_rx_out_rx_dst_ip    (udp_formatter_udp_rx_out_rx_dst_ip     )
        ,.udp_formatter_udp_rx_out_rx_udp_hdr   (udp_formatter_udp_rx_out_rx_udp_hdr    )
        ,.udp_formatter_udp_rx_out_rx_timestamp (udp_formatter_udp_rx_out_rx_timestamp  )
                                                                                        
        ,.udp_formatter_udp_rx_out_rx_data      (udp_formatter_udp_rx_out_rx_data       )
        ,.udp_formatter_udp_rx_out_rx_last      (udp_formatter_udp_rx_out_rx_last       )
        ,.udp_formatter_udp_rx_out_rx_padbytes  (udp_formatter_udp_rx_out_rx_padbytes   )
                                                                                        
        ,.udp_rx_out_noc0_vrtoc_data            (udp_rx_out_noc0_vrtoc_data             )
                                                                                        
        ,.ctrl_datap_flit_sel                   (ctrl_datap_flit_sel                    )
        ,.ctrl_datap_store_inputs               (ctrl_datap_store_inputs                )
                                                                                        
        ,.datap_ctrl_last_output                (datap_ctrl_last_output                 )
        ,.datap_ctrl_no_data                    (datap_ctrl_no_data                     )

        ,.datap_cam_rd_tag                      (datap_cam_rd_tag                       )
        ,.cam_datap_rd_data                     (cam_datap_rd_data                      )
    );
    
    udp_rx_out_cam_multi #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) out_table (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.rd_cam_val    (ctrl_cam_rd_cam    )
        ,.rd_cam_tag    (datap_cam_rd_tag   )
        ,.rd_cam_data   (cam_datap_rd_data  )
        ,.rd_cam_hit    (cam_ctrl_rd_hit    )
    );

endmodule
