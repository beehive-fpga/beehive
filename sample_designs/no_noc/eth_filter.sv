`include "soc_defs.vh"
module eth_filter 
import tracker_pkg::*;
import packet_struct_pkg::*;
(
     input clk
    ,input rst
    
    ,input  eth_hdr                         src_eth_filter_eth_hdr  
    ,input  logic   [`MTU_SIZE_W-1:0]       src_eth_filter_data_size
    ,input  logic                           src_eth_filter_hdr_val  
    ,input  tracker_stats_struct            src_eth_filter_timestamp
    ,output logic                           eth_filter_src_hdr_rdy  

    ,input  logic                           src_eth_filter_data_val     
    ,input  logic   [`MAC_INTERFACE_W-1:0]  src_eth_filter_data         
    ,input  logic                           src_eth_filter_data_last    
    ,input  logic   [`MAC_PADBYTES_W-1:0]   src_eth_filter_data_padbytes
    ,output                                 eth_filter_src_data_rdy     

    ,output eth_hdr                         eth_filter_dst_eth_hdr      
    ,output logic   [`MTU_SIZE_W-1:0]       eth_filter_dst_data_size    
    ,output logic                           eth_filter_dst_hdr_val      
    ,output tracker_stats_struct            eth_filter_dst_timestamp    
    ,input                                  dst_eth_filter_hdr_rdy      

    ,output logic                           eth_filter_dst_data_val     
    ,output logic   [`MAC_INTERFACE_W-1:0]  eth_filter_dst_data         
    ,output logic                           eth_filter_dst_data_last    
    ,output logic   [`MAC_PADBYTES_W-1:0]   eth_filter_dst_data_padbytes
    ,input                                  dst_eth_filter_data_rdy     
);


    logic   table_hit;
    logic   table_read;
    logic   store_table_res;
    tracker_stats_struct  pkt_timestamp_reg;
    tracker_stats_struct  pkt_timestamp_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            pkt_timestamp_reg <= '0;
        end
        else begin
            pkt_timestamp_reg <= pkt_timestamp_next;
        end
    end

    assign pkt_timestamp_next = store_table_res
                            ? src_eth_filter_timestamp
                            : pkt_timestamp_reg;

    assign eth_filter_dst_data_size = src_eth_filter_data_size;
    assign eth_filter_dst_eth_hdr = src_eth_filter_eth_hdr;
    assign eth_filter_dst_timestamp = pkt_timestamp_next;

    assign eth_filter_dst_data = src_eth_filter_data;
    assign eth_filter_dst_data_last = src_eth_filter_data_last;
    assign eth_filter_dst_data_padbytes = src_eth_filter_data_padbytes;

    filter_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_filter_hdr_val    (src_eth_filter_hdr_val     )
        ,.filter_src_hdr_rdy    (eth_filter_src_hdr_rdy     )
                                                      
        ,.src_filter_data_val   (src_eth_filter_data_val    )
        ,.src_filter_data_last  (src_eth_filter_data_last   )
        ,.filter_src_data_rdy   (eth_filter_src_data_rdy    )
                                                      
        ,.filter_dst_hdr_val    (eth_filter_dst_hdr_val     )
        ,.dst_filter_hdr_rdy    (dst_eth_filter_hdr_rdy     )
                                                      
        ,.filter_dst_data_val   (eth_filter_dst_data_val    )
        ,.dst_filter_data_rdy   (dst_eth_filter_data_rdy    )
                                                      
        ,.table_hit             (table_hit                  )
        ,.table_read            (table_read                 )
        ,.store_table_res       (store_table_res            )
    );


    eth_filter_cam #(
         .ETH_NUM_DST   (1)
        ,.DST_ID_W      (1)
    ) filter_cam (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_cam_val    (table_read                         )
        ,.rd_cam_tag    (src_eth_filter_eth_hdr.eth_type    )
        ,.rd_cam_data   ()
        ,.rd_cam_hit    (table_hit                          )
    );

endmodule
