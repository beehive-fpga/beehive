`include "ip_tx_tile_defs.svh"
module ip_tx_tile_copy #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter USE_INT_LB = 1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_tx_noc0_data_N // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_tx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_tx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_tx_noc0_data_W 
                                                                     
    ,input                                  src_ip_tx_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_ip_tx_noc0_val_E  
    ,input                                  src_ip_tx_noc0_val_S  
    ,input                                  src_ip_tx_noc0_val_W  
                                                                     
    ,output                                 ip_tx_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 ip_tx_src_noc0_yummy_E
    ,output                                 ip_tx_src_noc0_yummy_S
    ,output                                 ip_tx_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           ip_tx_dst_noc0_data_N // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           ip_tx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_tx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_tx_dst_noc0_data_W 
                                                                     
    ,output                                 ip_tx_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 ip_tx_dst_noc0_val_E  
    ,output                                 ip_tx_dst_noc0_val_S  
    ,output                                 ip_tx_dst_noc0_val_W  
                                                                     
    ,input                                  dst_ip_tx_noc0_yummy_N// neighbor consumed output data
    ,input                                  dst_ip_tx_noc0_yummy_E
    ,input                                  dst_ip_tx_noc0_yummy_S
    ,input                                  dst_ip_tx_noc0_yummy_W
);
    
    typedef struct packed {
        logic   [`NOC_DATA_WIDTH-1:0]       data;
        logic                               last;
        logic   [`NOC_PADBYTES_WIDTH-1:0]   padbytes;
    } data_buf_q_struct;
    localparam DATA_BUF_Q_STRUCT_W = `NOC_DATA_WIDTH + 1 + `NOC_PADBYTES_WIDTH;
    
    logic                           noc0_vrtoc_tile_tx_router_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_vrtoc_tile_tx_router_data;
    logic                           tile_tx_router_noc0_vrtoc_yummy;

    logic                           tile_tx_router_noc0_ctovr_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_tx_router_noc0_ctovr_data;
    logic                           noc0_ctovr_tile_tx_router_yummy;
    
    logic                           ip_tx_out_lb_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ip_tx_out_lb_data;    
    logic                           lb_ip_tx_out_rdy;
    
    logic                           lb_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   lb_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_lb_rdy;
    
    logic                           noc0_ctovr_ip_tx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_tx_in_data;
    logic                           ip_tx_in_noc0_ctovr_rdy;     
    
    logic                               ip_tx_in_assemble_meta_val;
    ip_tx_metadata_flit                 ip_tx_in_assemble_meta_flit;
    logic                               assemble_ip_tx_in_meta_rdy;
    
    logic                               ip_tx_in_assemble_data_val;
    logic   [`MAC_INTERFACE_W-1:0]      ip_tx_in_assemble_data;
    logic                               ip_tx_in_assemble_last;
    logic   [`MAC_PADBYTES_W-1:0]       ip_tx_in_assemble_padbytes;
    logic                               assemble_ip_tx_in_data_rdy;
    
    logic                               assemble_ip_to_ethstream_hdr_val;
    ip_pkt_hdr                          assemble_ip_to_ethstream_ip_hdr;
    logic   [MSG_TIMESTAMP_W-1:0]       assemble_ip_to_ethstream_timestamp;
    logic                               ip_to_ethstream_assemble_hdr_rdy;

    logic                               assemble_ip_to_ethstream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]      assemble_ip_to_ethstream_data;
    logic                               assemble_ip_to_ethstream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]       assemble_ip_to_ethstream_data_padbytes;
    logic                               ip_to_ethstream_assemble_data_rdy;
    
    logic                               src_data_buf_q_wr_req;
    data_buf_q_struct                   src_data_buf_q_wr_data;
    logic                               data_buf_q_src_full;

    logic                               dst_data_buf_q_rd_req;
    data_buf_q_struct                   data_buf_q_dst_rd_data;
    logic                               data_buf_q_dst_empty;
    
    logic                           ip_to_ethstream_ip_tx_out_hdr_val;
    eth_hdr                         ip_to_ethstream_ip_tx_out_eth_hdr;
    logic   [`TOT_LEN_W-1:0]        ip_to_ethstream_ip_tx_out_data_len;
    logic   [MSG_TIMESTAMP_W-1:0]   ip_to_ethstream_ip_tx_out_timestamp;
    logic                           ip_tx_out_ip_to_ethstream_hdr_rdy;

    logic                           ip_to_ethstream_ip_tx_out_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  ip_to_ethstream_ip_tx_out_data;
    logic                           ip_to_ethstream_ip_tx_out_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   ip_to_ethstream_ip_tx_out_data_padbytes;
    logic                           ip_tx_out_ip_to_ethstream_data_rdy;

    
    dynamic_node_top_wrap tile_tx_noc0_router(
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_ip_tx_noc0_data_N              )
        ,.src_router_data_E     (src_ip_tx_noc0_data_E              )
        ,.src_router_data_S     (src_ip_tx_noc0_data_S              )
        ,.src_router_data_W     (src_ip_tx_noc0_data_W              )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data     )
                                
        ,.src_router_val_N      (src_ip_tx_noc0_val_N               )
        ,.src_router_val_E      (src_ip_tx_noc0_val_E               )
        ,.src_router_val_S      (src_ip_tx_noc0_val_S               )
        ,.src_router_val_W      (src_ip_tx_noc0_val_W               )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val      )
                                
        ,.router_src_yummy_N    (ip_tx_src_noc0_yummy_N             )
        ,.router_src_yummy_E    (ip_tx_src_noc0_yummy_E             )
        ,.router_src_yummy_S    (ip_tx_src_noc0_yummy_S             )
        ,.router_src_yummy_W    (ip_tx_src_noc0_yummy_W             )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (ip_tx_dst_noc0_data_N              )
        ,.router_dst_data_E     (ip_tx_dst_noc0_data_E              )
        ,.router_dst_data_S     (ip_tx_dst_noc0_data_S              )
        ,.router_dst_data_W     (ip_tx_dst_noc0_data_W              )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (ip_tx_dst_noc0_val_N               )
        ,.router_dst_val_E      (ip_tx_dst_noc0_val_E               )
        ,.router_dst_val_S      (ip_tx_dst_noc0_val_S               )
        ,.router_dst_val_W      (ip_tx_dst_noc0_val_W               )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_ip_tx_noc0_yummy_N             )
        ,.dst_router_yummy_E    (dst_ip_tx_noc0_yummy_E             )
        ,.dst_router_yummy_S    (dst_ip_tx_noc0_yummy_S             )
        ,.dst_router_yummy_W    (dst_ip_tx_noc0_yummy_W             )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail

    );
    
    beehive_credit_to_valrdy tile_tx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_tx_router_noc0_ctovr_data )
        ,.src_ctovr_val     (tile_tx_router_noc0_ctovr_val  )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_tx_router_yummy)

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_ip_tx_in_data       )
        ,.ctovr_dst_val     (noc0_ctovr_ip_tx_in_val        )
        ,.dst_ctovr_rdy     (ip_tx_in_noc0_ctovr_rdy        )
    );

    beehive_valrdy_to_credit tile_tx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (lb_noc0_vrtoc_data             )
        ,.src_vrtoc_val     (lb_noc0_vrtoc_val              )
        ,.vrtoc_src_rdy     (noc0_vrtoc_lb_rdy              )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_tx_router_data )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_tx_router_val  )
		,.dst_vrtoc_yummy   (tile_tx_router_noc0_vrtoc_yummy)
    );

    ip_tx_tile_noc_in tx_noc_in (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_tx_in_val       (noc0_ctovr_ip_tx_in_val    )
        ,.noc0_ctovr_ip_tx_in_data      (noc0_ctovr_ip_tx_in_data   )
        ,.ip_tx_in_noc0_ctovr_rdy       (ip_tx_in_noc0_ctovr_rdy    )
   
        ,.ip_tx_in_assemble_meta_val    (ip_tx_in_assemble_meta_val )
        ,.ip_tx_in_assemble_meta_flit   (ip_tx_in_assemble_meta_flit)
        ,.assemble_ip_tx_in_meta_rdy    (assemble_ip_tx_in_meta_rdy )
                                                                    
        ,.ip_tx_in_assemble_data_val    (ip_tx_in_assemble_data_val )
        ,.ip_tx_in_assemble_data        (ip_tx_in_assemble_data     )
        ,.ip_tx_in_assemble_last        (ip_tx_in_assemble_last     )
        ,.ip_tx_in_assemble_padbytes    (ip_tx_in_assemble_padbytes )
        ,.assemble_ip_tx_in_data_rdy    (assemble_ip_tx_in_data_rdy )
    );

    ip_header_assembler #(
        .DATA_WIDTH (`MAC_INTERFACE_W   )
    ) tx_hdr_assembler (
         .clk   (clk)
        ,.rst   (rst)

        ,.ip_hdr_req_val        (ip_tx_in_assemble_meta_val                     )
        ,.source_ip_addr        (ip_tx_in_assemble_meta_flit.src_ip             )
        ,.dest_ip_addr          (ip_tx_in_assemble_meta_flit.dst_ip             )
        ,.data_payload_len      (ip_tx_in_assemble_meta_flit.data_payload_len   )
        ,.protocol              (ip_tx_in_assemble_meta_flit.protocol           )
        ,.timestamp             (ip_tx_in_assemble_meta_flit.timestamp          )
        ,.ip_hdr_req_rdy        (assemble_ip_tx_in_meta_rdy                     )

        ,.outbound_ip_hdr_val   (assemble_ip_to_ethstream_hdr_val               )
        ,.outbound_ip_hdr_rdy   (ip_to_ethstream_assemble_hdr_rdy               )
        ,.outbound_timestamp    (assemble_ip_to_ethstream_timestamp             )
        ,.outbound_ip_hdr       (assemble_ip_to_ethstream_ip_hdr                )
    );

    ip_hdr_assembler_pipe #(
         .DATA_W         (`MAC_INTERFACE_W  )
    ) tx_hdr_assembler (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_assembler_req_val             (ip_tx_in_assemble_meta_val )
        ,.src_assembler_src_ip_addr         (ip_tx_in_assemble_meta_flit.src_ip)
        ,.src_assembler_dst_ip_addr         (ip_tx_in_assemble_meta_flit.dst_ip)
        ,.src_assembler_data_payload_len    (ip_tx_in_assemble_meta_flit.data_payload_len)
        ,.src_assembler_protocol            (ip_tx_in_assemble_meta_flit.protocol)
        ,.src_assembler_timestamp           (ip_tx_in_assemble_meta_flit.timestamp)
        ,.assembler_src_req_rdy             (assemble_ip_tx_in_meta_rdy         )
    
        ,.src_assembler_data_val            (ip_tx_in_assemble_data_val )
        ,.src_assembler_data                (ip_tx_in_assemble_data )
        ,.src_assembler_data_last           (ip_tx_in_assemble_last)
        ,.src_assembler_data_padbytes       (ip_tx_in_assemble_padbytes)
        ,.assembler_src_data_rdy            (assemble_ip_tx_in_data_rdy)
    
        ,.assembler_dst_hdr_val             (assemble_ip_to_ethstream_hdr_val   )
        ,.assembler_dst_timestamp           (assemble_ip_to_ethstream_timestamp )
        ,.assembler_dst_ip_hdr              (assemble_ip_to_ethstream_ip_hdr    )
        ,.dst_assembler_hdr_rdy             (ip_to_ethstream_assemble_hdr_rdy   )
    
        ,.assembler_dst_data_val            (assemble_ip_to_ethstream_data_val  )
        ,.assembler_dst_data                (assemble_ip_to_ethstream_data      )
        ,.assembler_dst_data_padbytes       (assemble_ip_to_ethstream_data_padbytes)
        ,.assembler_dst_data_last           (assemble_ip_to_ethstream_data_last )
        ,.dst_assembler_data_rdy            (ip_to_ethstream_assemble_data_rdy  )
    );

    ip_to_ethstream tx_ip_to_ethstream (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.src_ip_to_ethstream_hdr_val       (assemble_ip_to_ethstream_hdr_val       )
        ,.src_ip_to_ethstream_ip_hdr        (assemble_ip_to_ethstream_ip_hdr        )
        ,.src_ip_to_ethstream_timestamp     (assemble_ip_to_ethstream_timestamp     )
        ,.ip_to_ethstream_src_hdr_rdy       (ip_to_ethstream_assemble_hdr_rdy       )
                                                                         
        ,.src_ip_to_ethstream_data_val      (assemble_ip_to_ethstream_data_val      )
        ,.src_ip_to_ethstream_data          (assemble_ip_to_ethstream_data          )
        ,.src_ip_to_ethstream_data_last     (assemble_ip_to_ethstream_data_last     )
        ,.src_ip_to_ethstream_data_padbytes (assemble_ip_to_ethstream_data_padbytes )
        ,.ip_to_ethstream_src_data_rdy      (ip_to_ethstream_assemble_data_rdy      )
    
        ,.ip_to_ethstream_dst_hdr_val       (ip_to_ethstream_ip_tx_out_hdr_val      )
        ,.ip_to_ethstream_dst_eth_hdr       (ip_to_ethstream_ip_tx_out_eth_hdr      )
        ,.ip_to_ethstream_dst_data_len      (ip_to_ethstream_ip_tx_out_data_len     )
        ,.ip_to_ethstream_dst_timestamp     (ip_to_ethstream_ip_tx_out_timestamp    )
        ,.dst_ip_to_ethstream_hdr_rdy       (ip_tx_out_ip_to_ethstream_hdr_rdy      )
        
        ,.ip_to_ethstream_dst_data_val      (ip_to_ethstream_ip_tx_out_data_val     )
        ,.ip_to_ethstream_dst_data          (ip_to_ethstream_ip_tx_out_data         )
        ,.ip_to_ethstream_dst_data_last     (ip_to_ethstream_ip_tx_out_data_last    )
        ,.ip_to_ethstream_dst_data_padbytes (ip_to_ethstream_ip_tx_out_data_padbytes)
        ,.dst_ip_to_ethstream_data_rdy      (ip_tx_out_ip_to_ethstream_data_rdy     )
    );

    ip_tx_noc_out #(
         .SRC_X (SRC_X)
        ,.SRC_Y (SRC_Y)
    ) ip_tx_noc_out (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.ip_tx_out_noc0_vrtoc_val                  (ip_tx_out_lb_val                           )
        ,.ip_tx_out_noc0_vrtoc_data                 (ip_tx_out_lb_data                          )
        ,.noc0_vrtoc_ip_tx_out_rdy                  (lb_ip_tx_out_rdy                           )
                                                                                                
        ,.ip_to_ethstream_ip_tx_out_hdr_val         (ip_to_ethstream_ip_tx_out_hdr_val          )
        ,.ip_to_ethstream_ip_tx_out_eth_hdr         (ip_to_ethstream_ip_tx_out_eth_hdr          )
        ,.ip_to_ethstream_ip_tx_out_data_len        (ip_to_ethstream_ip_tx_out_data_len         )
        ,.ip_to_ethstream_ip_tx_out_timestamp       (ip_to_ethstream_ip_tx_out_timestamp        )
        ,.ip_tx_out_ip_to_ethstream_hdr_rdy         (ip_tx_out_ip_to_ethstream_hdr_rdy          )
                                                                                                
        ,.ip_to_ethstream_ip_tx_out_data_val        (ip_to_ethstream_ip_tx_out_data_val         )
        ,.ip_to_ethstream_ip_tx_out_data            (ip_to_ethstream_ip_tx_out_data             )
        ,.ip_to_ethstream_ip_tx_out_data_last       (ip_to_ethstream_ip_tx_out_data_last        )
        ,.ip_to_ethstream_ip_tx_out_data_padbytes   (ip_to_ethstream_ip_tx_out_data_padbytes    )
        ,.ip_tx_out_ip_to_ethstream_data_rdy        (ip_tx_out_ip_to_ethstream_data_rdy         )
    );

generate
    if (USE_INT_LB == 1) begin
        ip_tx_lb_out ip_tx_lb (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_ip_tx_lb_val  (ip_tx_out_lb_val   )
            ,.src_ip_tx_lb_data (ip_tx_out_lb_data  )
            ,.ip_tx_lb_src_rdy  (lb_ip_tx_out_rdy   )
        
            ,.ip_tx_lb_dst_val  (lb_noc0_vrtoc_val  )
            ,.ip_tx_lb_dst_data (lb_noc0_vrtoc_data )
            ,.dst_ip_tx_lb_rdy  (noc0_vrtoc_lb_rdy  )
        );
    end
    else begin
        assign lb_noc0_vrtoc_val = ip_tx_out_lb_val;
        assign lb_noc0_vrtoc_data = ip_tx_out_lb_data;
        assign lb_ip_tx_out_rdy = noc0_vrtoc_lb_rdy;
    end
endgenerate
    
endmodule
