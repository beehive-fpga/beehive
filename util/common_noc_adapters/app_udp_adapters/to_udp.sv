`include "noc_defs.vh"
module to_udp 
import beehive_noc_msg::*;
import beehive_udp_msg::*;
import app_udp_adapter_pkg::*;
#(
     parameter NOC_DATA_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter SRC_FBITS = -1
)(
     input clk
    ,input rst

    ,input  logic                           src_to_udp_meta_val
    ,input  udp_info                        src_to_udp_meta_info
    ,output logic                           to_udp_src_meta_rdy

    ,input  logic                           src_to_udp_data_val
    ,input  logic   [NOC_DATA_W-1:0]        src_to_udp_data
    ,output logic                           to_udp_src_data_rdy

    ,output logic                           to_udp_noc_vrtoc_val
    ,output logic   [NOC_DATA_W-1:0]        to_udp_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_to_udp_rdy
    
    ,input  logic   [`XY_WIDTH-1:0]         src_to_udp_dst_x
    ,input  logic   [`XY_WIDTH-1:0]         src_to_udp_dst_y
    ,input  logic   [`NOC_FBITS_WIDTH-1:0]  src_to_udp_dst_fbits
);
    to_udp_mux_out_e                ctrl_datap_data_mux_sel;
    logic                           ctrl_datap_init_state;
    logic                           ctrl_datap_cnt_flit;

    logic                           datap_ctrl_last_flit;

    to_udp_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_to_udp_meta_val       (src_to_udp_meta_val        )
        ,.to_udp_src_meta_rdy       (to_udp_src_meta_rdy        )
                                                                
        ,.src_to_udp_data_val       (src_to_udp_data_val        )
        ,.to_udp_src_data_rdy       (to_udp_src_data_rdy        )
                                                                
        ,.to_udp_noc_vrtoc_val      (to_udp_noc_vrtoc_val       )
        ,.noc_vrtoc_to_udp_rdy      (noc_vrtoc_to_udp_rdy       )
                                                                
        ,.ctrl_datap_data_mux_sel   (ctrl_datap_data_mux_sel    )
        ,.ctrl_datap_init_state     (ctrl_datap_init_state      )
        ,.ctrl_datap_cnt_flit       (ctrl_datap_cnt_flit        )
                                                                
        ,.datap_ctrl_last_flit      (datap_ctrl_last_flit       )
    );

    to_udp_datap #(
         .NOC_DATA_W    (NOC_DATA_W )
        ,.SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.SRC_FBITS     (SRC_FBITS  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_to_udp_meta_info      (src_to_udp_meta_info       )
                                                                
        ,.src_to_udp_data           (src_to_udp_data            )
                                                                
        ,.to_udp_noc_vrtoc_data     (to_udp_noc_vrtoc_data      )
                                                                
        ,.src_to_udp_dst_x          (src_to_udp_dst_x           )
        ,.src_to_udp_dst_y          (src_to_udp_dst_y           )
        ,.src_to_udp_dst_fbits      (src_to_udp_dst_fbits       )
                                                                
        ,.ctrl_datap_data_mux_sel   (ctrl_datap_data_mux_sel    )
        ,.ctrl_datap_init_state     (ctrl_datap_init_state      )
        ,.ctrl_datap_cnt_flit       (ctrl_datap_cnt_flit        )
                                                                
        ,.datap_ctrl_last_flit      (datap_ctrl_last_flit       )
    );


endmodule
