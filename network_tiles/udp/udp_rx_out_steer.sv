`include "udp_rx_tile_defs.svh"
module udp_rx_out_steer (
     input clk
    ,input rst

    ,input                          src_steer_data_noc0_val
    ,input  [`NOC_DATA_WIDTH-1:0]   src_steer_data_noc0_data
    ,output                         steer_src_data_noc0_rdy

    ,output                         steer_dst_data_noc0_val
    ,output [`NOC_DATA_WIDTH-1:0]   steer_dst_data_noc0_data
    ,input                          dst_steer_data_noc0_rdy

    ,output                         steer_dst_ctrl_noc1_val
    ,output [`CTRL_NOC1_DATA_W-1:0] steer_dst_ctrl_noc1_data
    ,input                          dst_steer_ctrl_noc1_rdy
);

    logic [1:0] dst_sel;
    beehive_noc_hdr_flit splitter_data_line;

    logic                           full_line_ctrl_noc1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   full_line_ctrl_noc1_data;
    logic                           full_line_ctrl_noc1_rdy;

    beehive_noc_splitter #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.num_targets       (2                  )
    ) flit_steer (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_splitter_vr_noc_val   (src_steer_data_noc0_val    )
        ,.src_splitter_vr_noc_data  (src_steer_data_noc0_data   )
        ,.splitter_src_vr_noc_rdy   (steer_src_data_noc0_rdy    )
    
        ,.splitter_dsts_vr_noc_val  ({full_line_ctrl_noc1_val, steer_dst_data_noc0_val})
        ,.splitter_dsts_vr_noc_data ({full_line_ctrl_noc1_data, steer_dst_data_noc0_data})
        ,.dsts_splitter_vr_noc_rdy  ({full_line_ctrl_noc1_rdy, dst_steer_data_noc0_rdy} )
    
        ,.noc_data_line             (splitter_data_line         )
        
        ,.dst_sel_one_hot           (dst_sel                    )
    );

    assign dst_sel = splitter_data_line.core.dst_fbits == PKT_IF_FBITS
                    ? 2'b01
                    : 2'b10;

    noc_data_to_ctrl noc_dtc (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_noc_dtc_val   (full_line_ctrl_noc1_val    )
        ,.src_noc_dtc_data  (full_line_ctrl_noc1_data   )
        ,.noc_dtc_src_rdy   (full_line_ctrl_noc1_rdy    )
    
        ,.noc_dtc_dst_val   (steer_dst_ctrl_noc1_val    )
        ,.noc_dtc_dst_data  (steer_dst_ctrl_noc1_data   )
        ,.dst_noc_dtc_rdy   (dst_steer_ctrl_noc1_rdy    )
    );


endmodule
