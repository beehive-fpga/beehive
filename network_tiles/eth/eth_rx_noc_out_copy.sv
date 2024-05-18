`include "eth_rx_tile_defs.svh"
module eth_rx_noc_out_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                               eth_rx_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       eth_rx_out_noc0_vrtoc_data
    ,input                                      noc0_vrtoc_eth_rx_out_rdy
    
    ,input  logic   [ETH_HDR_W-1:0]             eth_format_eth_rx_out_eth_hdr
    ,input  logic                               eth_format_eth_rx_out_hdr_val
    ,input  logic   [`MTU_SIZE_W-1:0]           eth_format_eth_rx_out_data_size
    ,output                                     eth_rx_out_eth_format_hdr_rdy

    ,input  logic                               eth_format_eth_rx_out_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]      eth_format_eth_rx_out_data
    ,output                                     eth_rx_out_eth_format_data_rdy
    ,input  logic                               eth_format_eth_rx_out_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]       eth_format_eth_rx_out_data_padbytes
);
    
    eth_rx_tile_pkg::noc_out_flit_mux_sel   ctrl_datap_flit_sel;
    logic                                   ctrl_datap_store_inputs;
    logic                                   ctrl_datap_incr_packet_num;
    
    logic   [`ETH_TYPE_W-1:0]               datap_cam_rd_tag;
    logic   [(2 * `XY_WIDTH)-1:0]           cam_datap_rd_data;
    logic                                   ctrl_cam_rd_cam;
    logic                                   cam_ctrl_rd_hit;

    eth_rx_noc_out_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)

        ,.eth_rx_out_noc0_vrtoc_val         (eth_rx_out_noc0_vrtoc_val          )
        ,.noc0_vrtoc_eth_rx_out_rdy         (noc0_vrtoc_eth_rx_out_rdy          )
                                                                                
        ,.eth_format_eth_rx_out_hdr_val     (eth_format_eth_rx_out_hdr_val      )
        ,.eth_rx_out_eth_format_hdr_rdy     (eth_rx_out_eth_format_hdr_rdy      )
                                                                                
        ,.eth_format_eth_rx_out_data_val    (eth_format_eth_rx_out_data_val     )
        ,.eth_format_eth_rx_out_data_last   (eth_format_eth_rx_out_data_last    )
        ,.eth_rx_out_eth_format_data_rdy    (eth_rx_out_eth_format_data_rdy     )
                                                                                
        ,.ctrl_datap_flit_sel               (ctrl_datap_flit_sel                )
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
        ,.ctrl_datap_incr_packet_num        (ctrl_datap_incr_packet_num         )

        ,.ctrl_cam_rd_cam                   (ctrl_cam_rd_cam                    )
        ,.cam_ctrl_rd_hit                   (cam_ctrl_rd_hit                    )
    );

    eth_rx_noc_out_datap #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) datap (
         .clk   (clk)
        ,.rst   (rst)
                                                                                        
        ,.eth_rx_out_noc0_vrtoc_data            (eth_rx_out_noc0_vrtoc_data             )
                                                                                        
        ,.eth_format_eth_rx_out_eth_hdr         (eth_format_eth_rx_out_eth_hdr          )
        ,.eth_format_eth_rx_out_data_size       (eth_format_eth_rx_out_data_size        )
                                                                                        
        ,.eth_format_eth_rx_out_data            (eth_format_eth_rx_out_data             )
        ,.eth_format_eth_rx_out_data_last       (eth_format_eth_rx_out_data_last        )
        ,.eth_format_eth_rx_out_data_padbytes   (eth_format_eth_rx_out_data_padbytes    )
                                                                                        
        ,.ctrl_datap_flit_sel                   (ctrl_datap_flit_sel                    )
        ,.ctrl_datap_store_inputs               (ctrl_datap_store_inputs                )
        ,.ctrl_datap_incr_packet_num            (ctrl_datap_incr_packet_num             )
    
        ,.datap_cam_rd_tag                      (datap_cam_rd_tag                       )
        ,.cam_datap_rd_data                     (cam_datap_rd_data                      )
    );
    
    eth_rx_out_cam_multi #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) out_table (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.rd_cam_val    (ctrl_cam_rd_cam        )
        ,.rd_cam_tag    (datap_cam_rd_tag       )
        ,.rd_cam_data   (cam_datap_rd_data      )
        ,.rd_cam_hit    (cam_ctrl_rd_hit        )
    );
    
endmodule
