`include "ip_rx_tile_defs.svh"
module ip_rx_noc_out_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input  logic                           ip_format_ip_rx_out_rx_hdr_val
    ,input  ip_pkt_hdr                      ip_format_ip_rx_out_rx_ip_hdr
    ,input          [MSG_TIMESTAMP_W-1:0]   ip_format_ip_rx_out_rx_timestamp
    ,output                                 ip_rx_out_ip_format_rx_hdr_rdy

    ,input  logic                           ip_format_ip_rx_out_rx_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  ip_format_ip_rx_out_rx_data
    ,input  logic                           ip_format_ip_rx_out_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   ip_format_ip_rx_out_rx_padbytes
    ,output                                 ip_rx_out_ip_format_rx_data_rdy
    
    ,output logic                           ip_rx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_rx_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_ip_rx_out_rdy
);
    ip_rx_tile_pkg::noc_out_flit_mux_sel    ctrl_datap_flit_sel;
    logic                                   ctrl_datap_store_inputs;
    
    logic                           datap_ctrl_last_output;

    logic   [`PROTOCOL_W-1:0]       datap_cam_rd_tag;
    logic   [(2 * `XY_WIDTH)-1:0]   cam_datap_rd_data;
    logic                           ctrl_cam_rd_cam;
    logic                           cam_ctrl_rd_hit;

    ip_rx_noc_out_datap #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.ip_format_ip_rx_out_rx_ip_hdr     (ip_format_ip_rx_out_rx_ip_hdr      )
        ,.ip_format_ip_rx_out_rx_timestamp  (ip_format_ip_rx_out_rx_timestamp   )
                                                                                
        ,.ip_format_ip_rx_out_rx_data       (ip_format_ip_rx_out_rx_data        )
        ,.ip_format_ip_rx_out_rx_last       (ip_format_ip_rx_out_rx_last        )
        ,.ip_format_ip_rx_out_rx_padbytes   (ip_format_ip_rx_out_rx_padbytes    )
                                                                                
        ,.ip_rx_out_noc0_vrtoc_data         (ip_rx_out_noc0_vrtoc_data          )
                                                                                
        ,.ctrl_datap_flit_sel               (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
                                                                                
        ,.datap_ctrl_last_output            (datap_ctrl_last_output             )
    
        ,.datap_cam_rd_tag                  (datap_cam_rd_tag                   )
        ,.cam_datap_rd_data                 (cam_datap_rd_data                  )
    );

    ip_rx_noc_out_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.ip_format_ip_rx_out_rx_hdr_val    (ip_format_ip_rx_out_rx_hdr_val     )
        ,.ip_rx_out_ip_format_rx_hdr_rdy    (ip_rx_out_ip_format_rx_hdr_rdy     )
                                                                                
        ,.ip_format_ip_rx_out_rx_data_val   (ip_format_ip_rx_out_rx_data_val    )
        ,.ip_format_ip_rx_out_rx_last       (ip_format_ip_rx_out_rx_last        )
        ,.ip_rx_out_ip_format_rx_data_rdy   (ip_rx_out_ip_format_rx_data_rdy    )
                                                                                
        ,.ip_rx_out_noc0_vrtoc_val          (ip_rx_out_noc0_vrtoc_val           )
        ,.noc0_vrtoc_ip_rx_out_rdy          (noc0_vrtoc_ip_rx_out_rdy           )
                                                                                
        ,.ctrl_datap_flit_sel               (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
                                                                                
        ,.datap_ctrl_last_output            (datap_ctrl_last_output             )
    
        ,.ctrl_cam_rd_cam                   (ctrl_cam_rd_cam                    )
        ,.cam_ctrl_rd_hit                   (cam_ctrl_rd_hit                    )
    );

    ip_rx_out_cam_multi #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) out_table (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.rd_cam_val    (ctrl_cam_rd_cam    )
        ,.rd_cam_tag    (datap_cam_rd_tag   )
        ,.rd_cam_data   (cam_datap_rd_data  )
        ,.rd_cam_hit    (cam_ctrl_rd_hit    )
    );


endmodule
