`include "soc_defs.vh"
module ip_filter 
import tracker_pkg::*;
import packet_struct_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic                           src_ip_filter_rx_hdr_val  
    ,input  ip_pkt_hdr                      src_ip_filter_rx_ip_hdr   
    ,input  tracker_stats_struct            src_ip_filter_rx_timestamp
    ,output logic                           ip_filter_src_rx_hdr_rdy  

    ,input  logic                           src_ip_filter_rx_data_val 
    ,input  logic   [`MAC_INTERFACE_W-1:0]  src_ip_filter_rx_data     
    ,input  logic                           src_ip_filter_rx_last     
    ,input  logic   [`MAC_PADBYTES_W-1:0]   src_ip_filter_rx_padbytes 
    ,output logic                           ip_filter_src_rx_data_rdy 
                                                                      
    ,output logic                           ip_filter_dst_rx_hdr_val  
    ,output ip_pkt_hdr                      ip_filter_dst_rx_ip_hdr   
    ,output tracker_stats_struct            ip_filter_dst_rx_timestamp
    ,input  logic                           dst_ip_filter_rx_hdr_rdy  

    ,output logic                           ip_filter_dst_rx_data_val 
    ,output logic   [`MAC_INTERFACE_W-1:0]  ip_filter_dst_rx_data     
    ,output logic                           ip_filter_dst_rx_last     
    ,output logic   [`MAC_PADBYTES_W-1:0]   ip_filter_dst_rx_padbytes 
    ,input  logic                           dst_ip_filter_rx_data_rdy 
);

    logic   table_read;
    logic   table_hit;

    assign ip_filter_dst_rx_ip_hdr = src_ip_filter_rx_ip_hdr;
    assign ip_filter_dst_rx_timestamp = src_ip_filter_rx_timestamp;

    assign ip_filter_dst_rx_data = src_ip_filter_rx_data;
    assign ip_filter_dst_rx_last = src_ip_filter_rx_last;
    assign ip_filter_dst_rx_padbytes = src_ip_filter_rx_padbytes;

    filter_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_filter_hdr_val    (src_ip_filter_rx_hdr_val   )
        ,.filter_src_hdr_rdy    (ip_filter_src_rx_hdr_rdy   )

        ,.src_filter_data_val   (src_ip_filter_rx_data_val  )
        ,.src_filter_data_last  (src_ip_filter_rx_last      )
        ,.filter_src_data_rdy   (ip_filter_src_rx_data_rdy  )

        ,.filter_dst_hdr_val    (ip_filter_dst_rx_hdr_val   )
        ,.dst_filter_hdr_rdy    (dst_ip_filter_rx_hdr_rdy   )

        ,.filter_dst_data_val   (ip_filter_dst_rx_data_val  )
        ,.dst_filter_data_rdy   (dst_ip_filter_rx_data_rdy  )
                                                        
        ,.table_hit             (table_hit                  )
        ,.table_read            (table_read                 )
        ,.store_table_res       ()
    );

    ip_filter_cam #(
         .IP_NUM_DST(1)
        ,.DST_ID_W  (1)
    ) filter_table (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_cam_val    (table_read                         )
        ,.rd_cam_tag    (src_ip_filter_rx_ip_hdr.protocol_no)
        ,.rd_cam_data   ()
        ,.rd_cam_hit    (table_hit                          )
    );

endmodule
