module from_udp 
import beehive_udp_msg::*;
#(
     parameter NOC_DATA_W = -1
    ,parameter NOC_PADBYTES = NOC_DATA_W/8
    ,parameter NOC_PADBYTES_W = $clog2(NOC_PADBYTES)
)(
     input clk
    ,input rst

    ,input  logic                           noc_ctovr_fr_udp_val
    ,input  logic   [NOC_DATA_W-1:0]        noc_ctovr_fr_udp_data
    ,output logic                           fr_udp_noc_ctovr_rdy

    ,output logic                           fr_udp_dst_meta_val
    ,output udp_info                        fr_udp_dst_meta_info
    ,input                                  dst_fr_udp_meta_rdy

    ,output logic                           fr_udp_dst_data_val
    ,output logic   [NOC_DATA_W-1:0]        fr_udp_dst_data
    ,output logic                           fr_udp_dst_data_last
    ,output logic   [NOC_PADBYTES_W-1:0]    fr_udp_dst_data_padbytes
    ,input  logic                           dst_fr_udp_data_rdy
);
    
    logic                       ctrl_datap_store_hdr_data;
    logic                       ctrl_datap_store_meta_data;
    logic                       ctrl_datap_cnt_flit;

    logic                       datap_ctrl_last_data;

    from_udp_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.noc_ctovr_fr_udp_val          (noc_ctovr_fr_udp_val       )
        ,.fr_udp_noc_ctovr_rdy          (fr_udp_noc_ctovr_rdy       )
                                                                    
        ,.fr_udp_dst_meta_val           (fr_udp_dst_meta_val        )
        ,.dst_fr_udp_meta_rdy           (dst_fr_udp_meta_rdy        )
                                                                    
        ,.fr_udp_dst_data_val           (fr_udp_dst_data_val        )
        ,.fr_udp_dst_data_last          (fr_udp_dst_data_last       )
        ,.dst_fr_udp_data_rdy           (dst_fr_udp_data_rdy        )

        ,.ctrl_datap_store_hdr_data     (ctrl_datap_store_hdr_data  )
        ,.ctrl_datap_store_meta_data    (ctrl_datap_store_meta_data )
        ,.ctrl_datap_cnt_flit           (ctrl_datap_cnt_flit        )
                                                                    
        ,.datap_ctrl_last_data          (datap_ctrl_last_data       )
    );

    from_udp_datap #(
        .NOC_DATA_W  (NOC_DATA_W )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_ctovr_fr_udp_data         (noc_ctovr_fr_udp_data      )
                                                                    
        ,.fr_udp_dst_meta_info          (fr_udp_dst_meta_info       )
                                                                    
        ,.fr_udp_dst_data               (fr_udp_dst_data            )
        ,.fr_udp_dst_data_padbytes      (fr_udp_dst_data_padbytes   )
                                                                    
        ,.ctrl_datap_store_hdr_data     (ctrl_datap_store_hdr_data  )
        ,.ctrl_datap_store_meta_data    (ctrl_datap_store_meta_data )
        ,.ctrl_datap_cnt_flit           (ctrl_datap_cnt_flit        )
                                                                    
        ,.datap_ctrl_last_data          (datap_ctrl_last_data       )
    );
endmodule
