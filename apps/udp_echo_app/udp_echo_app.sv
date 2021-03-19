`include "udp_echo_app_defs.svh"
`include "udp_echo_app_stats_defs.svh"
module udp_echo_app #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NOC1_DATA_W = -1
    ,parameter NOC2_DATA_W = -1
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_app_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_udp_app_in_data
    ,output logic                           udp_app_in_noc0_ctovr_rdy
    
    ,output logic                           udp_app_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   udp_app_out_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_udp_app_out_rdy
    
    ,input                                  ctovr_udp_stats_in_val
    ,input          [NOC1_DATA_W-1:0]       ctovr_udp_stats_in_data
    ,output logic                           udp_stats_in_ctovr_rdy
    
    ,output logic                           udp_stats_out_vrtoc_val
    ,output logic   [NOC2_DATA_W-1:0]       udp_stats_out_vrtoc_data
    ,input                                  vrtoc_udp_stats_out_rdy
);
    
    logic   in_store_hdr_flit;
    logic   in_store_meta_flit;

    udp_app_out_mux_sel_e   out_data_mux_sel;

    logic   [`MSG_LENGTH_WIDTH-1:0] total_flits;
    
    logic                           app_stats_incr_bytes_sent;
    logic   [`NOC_DATA_BYTES_W:0]   app_stats_num_bytes_sent;
    logic   [`UDP_LENGTH_W-1:0]     data_length;
        
    logic                           noc_ctd_udp_stats_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc_ctd_udp_stats_data;
    logic                           udp_stats_noc_ctd_rdy;
    
    logic                           udp_stats_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_stats_noc_dtc_data;
    logic                           noc_dtc_udp_stats_rdy;

generate
    if (NOC1_DATA_W != `NOC_DATA_WIDTH) begin
        // noc narrow to wide
        noc_ctrl_to_data ctd (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_noc_ctd_val   (ctovr_udp_stats_in_val     )
            ,.src_noc_ctd_data  (ctovr_udp_stats_in_data    )
            ,.noc_ctd_src_rdy   (udp_stats_in_ctovr_rdy     )
        
            ,.noc_ctd_dst_val   (noc_ctd_udp_stats_val      )
            ,.noc_ctd_dst_data  (noc_ctd_udp_stats_data     )
            ,.dst_noc_ctd_rdy   (udp_stats_noc_ctd_rdy      )
        );
    end
    else begin
        assign noc_ctd_udp_stats_val = ctovr_udp_stats_in_val;
        assign noc_ctd_udp_stats_data = ctovr_udp_stats_in_data;
        assign udp_stats_in_ctovr_rdy = udp_stats_noc_ctd_rdy;
    end
endgenerate

    udp_echo_app_stats #(
         .SRC_X         (SRC_X  )
        ,.SRC_Y         (SRC_Y  )
        ,.NOC1_DATA_W   (`NOC_DATA_WIDTH    )
        ,.NOC2_DATA_W   (`NOC_DATA_WIDTH    )
    ) stats (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.app_stats_incr_bytes_sent (app_stats_incr_bytes_sent      )
        ,.app_stats_num_bytes_sent  (app_stats_num_bytes_sent       )
                                                                        
        ,.ctovr_udp_stats_in_val    (noc_ctd_udp_stats_val          )
        ,.ctovr_udp_stats_in_data   (noc_ctd_udp_stats_data         )
        ,.udp_stats_in_ctovr_rdy    (udp_stats_noc_ctd_rdy          )

        ,.udp_stats_out_vrtoc_val   (udp_stats_noc_dtc_val          )
        ,.udp_stats_out_vrtoc_data  (udp_stats_noc_dtc_data         )
        ,.vrtoc_udp_stats_out_rdy   (noc_dtc_udp_stats_rdy          )
    );

generate
    if (NOC2_DATA_W != `NOC_DATA_WIDTH) begin
        // noc wide to narrow
        noc_data_to_ctrl dtc (
             .clk   (clk    )
            ,.rst   (rst    )
        
            ,.src_noc_dtc_val   (udp_stats_noc_dtc_val      )
            ,.src_noc_dtc_data  (udp_stats_noc_dtc_data     )
            ,.noc_dtc_src_rdy   (noc_dtc_udp_stats_rdy      )
        
            ,.noc_dtc_dst_val   (udp_stats_out_vrtoc_val    )
            ,.noc_dtc_dst_data  (udp_stats_out_vrtoc_data   )
            ,.dst_noc_dtc_rdy   (vrtoc_udp_stats_out_rdy    )
        );
    end
    else begin
        assign udp_stats_out_vrtoc_val = udp_stats_noc_dtc_val;
        assign udp_stats_out_vrtoc_data = udp_stats_noc_dtc_data;
        assign noc_dtc_udp_stats_rdy = vrtoc_udp_stats_out_rdy;
    end
endgenerate

    udp_echo_app_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_app_in_data    (noc0_ctovr_udp_app_in_data     )
                                                                        
        ,.udp_app_out_noc0_vrtoc_data   (udp_app_out_noc0_vrtoc_data    )

        ,.src_udp_app_out_dst_x         (UDP_TX_TILE_X                  )
        ,.src_udp_app_out_dst_y         (UDP_TX_TILE_Y                  )
                                                                        
        ,.in_store_hdr_flit             (in_store_hdr_flit              )
        ,.in_store_meta_flit            (in_store_meta_flit             )
                                                                        
        ,.out_data_mux_sel              (out_data_mux_sel               )

        ,.total_flits                   (total_flits                    )
        ,.data_length                   (data_length                    )
    );

    udp_echo_app_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_app_in_val     (noc0_ctovr_udp_app_in_val  )
        ,.udp_app_in_noc0_ctovr_rdy     (udp_app_in_noc0_ctovr_rdy  )
                                                                    
        ,.udp_app_out_noc0_vrtoc_val    (udp_app_out_noc0_vrtoc_val )
        ,.noc0_vrtoc_udp_app_out_rdy    (noc0_vrtoc_udp_app_out_rdy )
                                                                    
        ,.in_store_hdr_flit             (in_store_hdr_flit          )
        ,.in_store_meta_flit            (in_store_meta_flit         )
                                                                    
        ,.out_data_mux_sel              (out_data_mux_sel           )
                                                                    
        ,.app_stats_incr_bytes_sent     (app_stats_incr_bytes_sent  )
        ,.app_stats_num_bytes_sent      (app_stats_num_bytes_sent   )
        ,.data_length                   (data_length                )
        ,.total_flits                   (total_flits                )
    );


endmodule
