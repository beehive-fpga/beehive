`include "soc_defs.vh"
import packet_struct_pkg::*;
module udp_splitter #(
     parameter UDP_DSTS = 3
    ,parameter UDP_DST_ID_W = $clog2(UDP_DSTS)
    ,parameter UDP_APP_ID = 0
    ,parameter UDP_LOG_ID = 1
    ,parameter ETH_LAT_LOG_ID = 2
    ,parameter UDP_APP_PORT = 65432
    ,parameter UDP_LOG_PORT = 60000
    ,parameter ETH_LAT_LOG_PORT = 60001
)(
     input clk
    ,input rst

    ,input  logic                                           src_udp_splitter_rx_hdr_val
    ,input  logic   [`IP_ADDR_W-1:0]                        src_udp_splitter_rx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]                        src_udp_splitter_rx_dst_ip
    ,input  udp_pkt_hdr                                     src_udp_splitter_rx_udp_hdr
    ,input          [`PKT_TIMESTAMP_W-1:0]                  src_udp_splitter_rx_timestamp
    ,output logic                                           udp_splitter_src_rx_hdr_rdy

    ,input  logic                                           src_udp_splitter_rx_data_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]                  src_udp_splitter_rx_data
    ,input  logic                                           src_udp_splitter_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]                   src_udp_splitter_rx_padbytes
    ,output logic                                           udp_splitter_src_rx_data_rdy
    
    ,output logic   [UDP_DSTS-1:0]                          udp_splitter_dst_rx_hdr_val
    ,output logic                 [`IP_ADDR_W-1:0]          udp_splitter_dst_rx_src_ip
    ,output logic                 [`IP_ADDR_W-1:0]          udp_splitter_dst_rx_dst_ip
    ,output logic                 [UDP_HDR_W-1:0]           udp_splitter_dst_rx_udp_hdr
    ,output logic                 [`PKT_TIMESTAMP_W-1:0]    udp_splitter_dst_rx_timestamp
    ,input  logic   [UDP_DSTS-1:0]                          dst_udp_splitter_rx_hdr_rdy

    ,output logic   [UDP_DSTS-1:0]                          udp_splitter_dst_rx_data_val
    ,output logic                 [`MAC_INTERFACE_W-1:0]    udp_splitter_dst_rx_data
    ,output logic                                           udp_splitter_dst_rx_last
    ,output logic                 [`MAC_PADBYTES_W-1:0]     udp_splitter_dst_rx_padbytes
    ,input          [UDP_DSTS-1:0]                          dst_udp_splitter_rx_data_rdy
);

    logic   table_read;
    logic   table_hit;
    logic   [UDP_DST_ID_W-1:0]  dst_id;
    logic   store_table_res;
    logic   [UDP_DST_ID_W-1:0]  dst_id_reg;
    logic   [UDP_DST_ID_W-1:0]  dst_id_next;

    logic   ctrl_dst_hdr_val;
    logic   dst_ctrl_hdr_rdy;
    logic   ctrl_dst_data_val;
    logic   dst_ctrl_data_rdy;

    assign udp_splitter_dst_rx_src_ip = src_udp_splitter_rx_src_ip;
    assign udp_splitter_dst_rx_dst_ip = src_udp_splitter_rx_dst_ip;
    assign udp_splitter_dst_rx_udp_hdr = src_udp_splitter_rx_udp_hdr;
    assign udp_splitter_dst_rx_timestamp = src_udp_splitter_rx_timestamp;

    assign udp_splitter_dst_rx_data = src_udp_splitter_rx_data;
    assign udp_splitter_dst_rx_last = src_udp_splitter_rx_last;
    assign udp_splitter_dst_rx_padbytes = src_udp_splitter_rx_padbytes;

    assign dst_id_next = store_table_res
                        ? dst_id
                        : dst_id_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            dst_id_reg <= '0;
        end
        else begin
            dst_id_reg <= dst_id_next;
        end
    end

    logic   [UDP_DSTS-1:0]  hdr_val_vec;
    assign hdr_val_vec = {{(UDP_DSTS-1){1'b0}}, ctrl_dst_hdr_val};
    logic   [UDP_DSTS-1:0]  data_val_vec;
    assign data_val_vec = {{(UDP_DSTS-1){1'b0}}, ctrl_dst_data_val};

    always_comb begin
        udp_splitter_dst_rx_hdr_val = hdr_val_vec << dst_id_next;
        dst_ctrl_hdr_rdy = dst_udp_splitter_rx_hdr_rdy[dst_id_next];
        udp_splitter_dst_rx_data_val = data_val_vec << dst_id_next;
        dst_ctrl_data_rdy = dst_udp_splitter_rx_data_rdy[dst_id_next];
    end

    filter_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_filter_hdr_val    (src_udp_splitter_rx_hdr_val    )
        ,.filter_src_hdr_rdy    (udp_splitter_src_rx_hdr_rdy    )

        ,.src_filter_data_val   (src_udp_splitter_rx_data_val   )
        ,.src_filter_data_last  (src_udp_splitter_rx_last       )
        ,.filter_src_data_rdy   (udp_splitter_src_rx_data_rdy   )
                                                            
        ,.filter_dst_hdr_val    (ctrl_dst_hdr_val               )
        ,.dst_filter_hdr_rdy    (dst_ctrl_hdr_rdy               )
                                 
        ,.filter_dst_data_val   (ctrl_dst_data_val              )
        ,.dst_filter_data_rdy   (dst_ctrl_data_rdy              )
                                                        
        ,.table_hit             (table_hit                      )
        ,.table_read            (table_read                     )
        ,.store_table_res       (store_table_res                )
    );

    udp_splitter_cam #(
         .UDP_NUM_DST       (UDP_DSTS           )
        ,.UDP_APP_ID        (UDP_APP_ID         )
        ,.UDP_LOG_ID        (UDP_LOG_ID         )
        ,.ETH_LAT_LOG_ID    (ETH_LAT_LOG_ID     )
        ,.UDP_APP_PORT      (UDP_APP_PORT       )
        ,.UDP_LOG_PORT      (UDP_LOG_PORT       )
        ,.ETH_LAT_LOG_PORT  (ETH_LAT_LOG_PORT   )
    ) splitter_cam (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_cam_val    (table_read                             )
        ,.rd_cam_tag    (src_udp_splitter_rx_udp_hdr.dst_port   )
        ,.rd_cam_data   (dst_id                                 )
        ,.rd_cam_hit    (table_hit                              )
    );
endmodule
