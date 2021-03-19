`include "packet_defs.vh"
`include "soc_defs.vh"
import packet_struct_pkg::*;
module udp_merger #(
     parameter NUM_SRCS = 3
)(
     input clk
    ,input rst
    
    ,input  logic   [NUM_SRCS-1:0]                          srcs_udp_merger_tx_hdr_val
    ,input  logic   [NUM_SRCS-1:0][`IP_ADDR_W-1:0]          srcs_udp_merger_tx_src_ip
    ,input  logic   [NUM_SRCS-1:0][`IP_ADDR_W-1:0]          srcs_udp_merger_tx_dst_ip
    ,input  logic   [NUM_SRCS-1:0][UDP_HDR_W-1:0]           srcs_udp_merger_tx_udp_hdr
    ,input  logic   [NUM_SRCS-1:0][`PKT_TIMESTAMP_W-1:0]    srcs_udp_merger_tx_timestamp
    ,output logic   [NUM_SRCS-1:0]                          udp_merger_srcs_tx_hdr_rdy

    ,input  logic   [NUM_SRCS-1:0]                          srcs_udp_merger_tx_data_val
    ,input  logic   [NUM_SRCS-1:0][`MAC_INTERFACE_W-1:0]    srcs_udp_merger_tx_data
    ,input  logic   [NUM_SRCS-1:0]                          srcs_udp_merger_tx_last
    ,input  logic   [NUM_SRCS-1:0][`MAC_PADBYTES_W-1:0]     srcs_udp_merger_tx_padbytes
    ,output logic   [NUM_SRCS-1:0]                          udp_merger_srcs_tx_data_rdy
    
    ,output logic                                           udp_merger_dst_tx_hdr_val
    ,output logic   [`IP_ADDR_W-1:0]                        udp_merger_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]                        udp_merger_dst_tx_dst_ip
    ,output udp_pkt_hdr                                     udp_merger_dst_tx_udp_hdr
    ,output         [`PKT_TIMESTAMP_W-1:0]                  udp_merger_dst_tx_timestamp
    ,input                                                  dst_udp_merger_tx_hdr_rdy

    ,output logic                                           udp_merger_dst_tx_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]                  udp_merger_dst_tx_data
    ,output logic                                           udp_merger_dst_tx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]                   udp_merger_dst_tx_padbytes
    ,input  logic                                           dst_udp_merger_tx_data_rdy
);

    logic   [NUM_SRCS-1:0]  grant_reg;
    logic   [NUM_SRCS-1:0]  grant_next;
    logic   [NUM_SRCS-1:0]  grants;
    logic                   store_grant;
    logic                   advance_grant;

    logic                   src_ctrl_hdr_val;
    logic                   ctrl_src_hdr_rdy;
    logic                   src_ctrl_data_val;
    logic                   ctrl_src_data_rdy;

    always_ff @(posedge clk) begin
        if (rst) begin
            grant_reg <= '0;
        end
        else begin
            grant_reg <= grant_next;
        end
    end
    assign grant_next = store_grant
                        ? grants
                        : grant_reg;

    demux_one_hot #(
         .NUM_OUTPUTS   (NUM_SRCS   )
        ,.INPUT_WIDTH   (1)
    ) hdr_rdy_demux (
         .input_sel     (grant_next                 )
        ,.data_input    (ctrl_src_hdr_rdy           )
        ,.data_outputs  (udp_merger_srcs_tx_hdr_rdy )
    );
    
    demux_one_hot #(
         .NUM_OUTPUTS   (NUM_SRCS   )
        ,.INPUT_WIDTH   (1          )
    ) data_rdy_demux (
         .input_sel     (grant_next                 )
        ,.data_input    (ctrl_src_data_rdy          )
        ,.data_outputs  (udp_merger_srcs_tx_data_rdy)
    );
    
    bsg_mux_one_hot #(
         .width_p   (1          )
        ,.els_p     (NUM_SRCS   )
    ) src_hdr_val_mux (
         .data_i        (srcs_udp_merger_tx_hdr_val )
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (src_ctrl_hdr_val           )
    );
    
    bsg_mux_one_hot #(
         .width_p   (1          )
        ,.els_p     (NUM_SRCS   )
    ) src_data_val_mux (
         .data_i        (srcs_udp_merger_tx_data_val)
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (src_ctrl_data_val          )
    );

    bsg_mux_one_hot #(
         .width_p   (`IP_ADDR_W )
        ,.els_p     (NUM_SRCS   )
    ) src_ip_mux (
         .data_i        (srcs_udp_merger_tx_src_ip  )
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (udp_merger_dst_tx_src_ip   )
    );
    
    bsg_mux_one_hot #(
         .width_p   (`IP_ADDR_W )
        ,.els_p     (NUM_SRCS   )
    ) dst_ip_mux (
         .data_i        (srcs_udp_merger_tx_dst_ip  )
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (udp_merger_dst_tx_dst_ip   )
    );
    
    bsg_mux_one_hot #(
         .width_p   (UDP_HDR_W  )
        ,.els_p     (NUM_SRCS   )
    ) udp_hdr_mux (
         .data_i        (srcs_udp_merger_tx_udp_hdr )
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (udp_merger_dst_tx_udp_hdr  )
    );
    
    bsg_mux_one_hot #(
         .width_p   (`PKT_TIMESTAMP_W   )
        ,.els_p     (NUM_SRCS           )
    ) timestamp_mux (
         .data_i        (srcs_udp_merger_tx_timestamp   )
        ,.sel_one_hot_i (grant_next                     )
        ,.data_o        (udp_merger_dst_tx_timestamp    )
    );
    
    bsg_mux_one_hot #(
         .width_p   (`MAC_INTERFACE_W   )
        ,.els_p     (NUM_SRCS           )
    ) data_mux (
         .data_i        (srcs_udp_merger_tx_data    )
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (udp_merger_dst_tx_data     )
    );
    
    bsg_mux_one_hot #(
         .width_p   (`MAC_PADBYTES_W    )
        ,.els_p     (NUM_SRCS           )
    ) padbytes_mux (
         .data_i        (srcs_udp_merger_tx_padbytes)
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (udp_merger_dst_tx_padbytes )
    );

    bsg_mux_one_hot #(
         .width_p   (1          )
        ,.els_p     (NUM_SRCS   )
    ) last_mux (
         .data_i        (srcs_udp_merger_tx_last    )
        ,.sel_one_hot_i (grant_next                 )
        ,.data_o        (udp_merger_dst_tx_last     )
    );

    bsg_arb_round_robin #(
        .width_p    (NUM_SRCS   )
    ) arbiter (
         .clk_i     (clk    )
        ,.reset_i   (rst    )
        
        ,.reqs_i    (srcs_udp_merger_tx_hdr_val )
        ,.grants_o  (grants                     )
        ,.yumi_i    (advance_grant              )
    );

    merger_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_merger_ctrl_hdr_val   (src_ctrl_hdr_val           )
        ,.merger_ctrl_src_hdr_rdy   (ctrl_src_hdr_rdy           )
    
        ,.src_merger_ctrl_data_val  (src_ctrl_data_val          )
        ,.src_merger_ctrl_data_last (udp_merger_dst_tx_last     )
        ,.merger_ctrl_src_data_rdy  (ctrl_src_data_rdy          )
    
        ,.merger_ctrl_dst_hdr_val   (udp_merger_dst_tx_hdr_val  )
        ,.dst_merger_ctrl_hdr_rdy   (dst_udp_merger_tx_hdr_rdy  )
    
        ,.merger_ctrl_dst_data_val  (udp_merger_dst_tx_data_val )
        ,.dst_merger_ctrl_data_rdy  (dst_udp_merger_tx_data_rdy )
        
        ,.store_grant               (store_grant                )
        ,.advance_grant             (advance_grant              )
    );

endmodule
