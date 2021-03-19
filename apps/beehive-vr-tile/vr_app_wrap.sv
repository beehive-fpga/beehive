`include "noc_defs.vh"
module vr_app_wrap 
import beehive_topology::*;
import beehive_udp_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter SRC_FBITS = -1
    ,parameter UDP_APP_DST_X = -1
    ,parameter UDP_APP_DST_Y = -1
)(
     input clk
    ,input rst

    ,input  logic                           noc_ctovr_app_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_app_data
    ,output logic                           app_noc_ctovr_rdy

    ,output logic                           app_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   app_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_app_rdy
);
    
    logic                           fr_udp_beehive_vr_meta_val;
    udp_info                        fr_udp_beehive_vr_meta_info;
    logic                           beehive_vr_fr_udp_meta_rdy;

    logic                           fr_udp_beehive_vr_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]   fr_udp_beehive_vr_data;
    logic                           fr_udp_beehive_vr_data_last;
    logic   [`NOC_DATA_BYTES_W-1:0] fr_udp_beehive_vr_data_padbytes;
    logic                           beehive_vr_fr_udp_data_rdy;
    
    logic                           beehive_vr_to_udp_meta_val;
    udp_info                        beehive_vr_to_udp_meta_info;
    logic                           to_udp_beehive_vr_meta_rdy;

    logic                           beehive_vr_to_udp_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]   beehive_vr_to_udp_data;
    logic                           to_udp_beehive_vr_data_rdy;

    from_udp #(
         .NOC_DATA_W (`NOC_DATA_WIDTH   )
    ) fr_udp (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc_ctovr_fr_udp_val      (noc_ctovr_app_val                  )
        ,.noc_ctovr_fr_udp_data     (noc_ctovr_app_data                 )
        ,.fr_udp_noc_ctovr_rdy      (app_noc_ctovr_rdy                  )
    
        ,.fr_udp_dst_meta_val       (fr_udp_beehive_vr_meta_val         )
        ,.fr_udp_dst_meta_info      (fr_udp_beehive_vr_meta_info        )
        ,.dst_fr_udp_meta_rdy       (beehive_vr_fr_udp_meta_rdy         )
    
        ,.fr_udp_dst_data_val       (fr_udp_beehive_vr_data_val         )
        ,.fr_udp_dst_data           (fr_udp_beehive_vr_data             )
        ,.fr_udp_dst_data_last      (fr_udp_beehive_vr_data_last        )
        ,.fr_udp_dst_data_padbytes  (fr_udp_beehive_vr_data_padbytes    )
        ,.dst_fr_udp_data_rdy       (beehive_vr_fr_udp_data_rdy         )
    );

    beehive_vr_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
    ) vr_wrap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.fr_udp_beehive_vr_meta_val        (fr_udp_beehive_vr_meta_val         )
        ,.fr_udp_beehive_vr_meta_info       (fr_udp_beehive_vr_meta_info        )
        ,.beehive_vr_fr_udp_meta_rdy        (beehive_vr_fr_udp_meta_rdy         )
                                                                                
        ,.fr_udp_beehive_vr_data_val        (fr_udp_beehive_vr_data_val         )
        ,.fr_udp_beehive_vr_data            (fr_udp_beehive_vr_data             )
        ,.fr_udp_beehive_vr_data_last       (fr_udp_beehive_vr_data_last        )
        ,.fr_udp_beehive_vr_data_padbytes   (fr_udp_beehive_vr_data_padbytes    )
        ,.beehive_vr_fr_udp_data_rdy        (beehive_vr_fr_udp_data_rdy         )
                                                                                
        ,.beehive_vr_to_udp_meta_val        (beehive_vr_to_udp_meta_val         )
        ,.beehive_vr_to_udp_meta_info       (beehive_vr_to_udp_meta_info        )
        ,.to_udp_beehive_vr_meta_rdy        (to_udp_beehive_vr_meta_rdy         )
                                                                                
        ,.beehive_vr_to_udp_data_val        (beehive_vr_to_udp_data_val         )
        ,.beehive_vr_to_udp_data            (beehive_vr_to_udp_data             )
        ,.to_udp_beehive_vr_data_rdy        (to_udp_beehive_vr_data_rdy         )
    );

    to_udp #(
         .NOC_DATA_W    (`NOC_DATA_WIDTH    )
        ,.SRC_X         (SRC_X              )
        ,.SRC_Y         (SRC_Y              )
        ,.SRC_FBITS     (SRC_FBITS          )
    ) to_udp (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_to_udp_meta_val   (beehive_vr_to_udp_meta_val         )
        ,.src_to_udp_meta_info  (beehive_vr_to_udp_meta_info        )
        ,.to_udp_src_meta_rdy   (to_udp_beehive_vr_meta_rdy         )

        ,.src_to_udp_data_val   (beehive_vr_to_udp_data_val         )
        ,.src_to_udp_data       (beehive_vr_to_udp_data             )
        ,.to_udp_src_data_rdy   (to_udp_beehive_vr_data_rdy         )

        ,.to_udp_noc_vrtoc_val  (app_noc_vrtoc_val                  )
        ,.to_udp_noc_vrtoc_data (app_noc_vrtoc_data                 )
        ,.noc_vrtoc_to_udp_rdy  (noc_vrtoc_app_rdy                  )

        ,.src_to_udp_dst_x      (UDP_APP_DST_X[`XY_WIDTH-1:0]       )
        ,.src_to_udp_dst_y      (UDP_APP_DST_Y[`XY_WIDTH-1:0]       )
        ,.src_to_udp_dst_fbits  (PKT_IF_FBITS[`NOC_FBITS_WIDTH-1:0] )
    );

endmodule

