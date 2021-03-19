`include "ip_encap_tx_defs.svh"
module ip_encap_tx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_encap_tx_noc0_data_N // data inputs from neighboring tiles
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_encap_tx_noc0_data_E 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_encap_tx_noc0_data_S 
    ,input [`NOC_DATA_WIDTH-1:0]            src_ip_encap_tx_noc0_data_W 
                                                                     
    ,input                                  src_ip_encap_tx_noc0_val_N  // valid signals from neighboring tiles
    ,input                                  src_ip_encap_tx_noc0_val_E  
    ,input                                  src_ip_encap_tx_noc0_val_S  
    ,input                                  src_ip_encap_tx_noc0_val_W  
                                                                     
    ,output                                 ip_encap_tx_src_noc0_yummy_N// yummy signal to neighbors' output buffers
    ,output                                 ip_encap_tx_src_noc0_yummy_E
    ,output                                 ip_encap_tx_src_noc0_yummy_S
    ,output                                 ip_encap_tx_src_noc0_yummy_W
                                                                     
    ,output [`NOC_DATA_WIDTH-1:0]           ip_encap_tx_dst_noc0_data_N // data outputs to neighbors
    ,output [`NOC_DATA_WIDTH-1:0]           ip_encap_tx_dst_noc0_data_E 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_encap_tx_dst_noc0_data_S 
    ,output [`NOC_DATA_WIDTH-1:0]           ip_encap_tx_dst_noc0_data_W 
                                                                     
    ,output                                 ip_encap_tx_dst_noc0_val_N  // valid outputs to neighbors
    ,output                                 ip_encap_tx_dst_noc0_val_E  
    ,output                                 ip_encap_tx_dst_noc0_val_S  
    ,output                                 ip_encap_tx_dst_noc0_val_W  
                                                                     
    ,input                                  dst_ip_encap_tx_noc0_yummy_N// neighbor consumed output data
    ,input                                  dst_ip_encap_tx_noc0_yummy_E
    ,input                                  dst_ip_encap_tx_noc0_yummy_S
    ,input                                  dst_ip_encap_tx_noc0_yummy_W
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
    
    logic                           ip_encap_tx_out_noc0_vrtoc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ip_encap_tx_out_noc0_vrtoc_data;    
    logic                           noc0_vrtoc_ip_encap_tx_out_rdy;
    
    logic                           noc0_ctovr_ip_encap_tx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_encap_tx_in_data;
    logic                           ip_encap_tx_in_noc0_ctovr_rdy;     
    
    logic                               ip_tx_in_ip_encap_tx_meta_val;
    ip_tx_metadata_flit                 ip_tx_in_ip_encap_tx_meta_flit;
    logic   [`IP_ADDR_W-1:0]            ip_tx_in_ip_encap_tx_src_addr;
    logic   [`IP_ADDR_W-1:0]            ip_tx_in_ip_encap_tx_dst_addr;
    logic   [`TOT_LEN_W-1:0]            ip_tx_in_ip_encap_tx_data_payload_len;
    logic   [`PROTOCOL_W-1:0]           ip_tx_in_ip_encap_tx_protocol;
    logic                               ip_encap_ip_tx_in_tx_meta_rdy;
    
    logic                               ip_tx_in_ip_encap_tx_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]       ip_tx_in_ip_encap_tx_data;
    logic                               ip_tx_in_ip_encap_tx_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   ip_tx_in_ip_encap_tx_data_padbytes;
    logic                               ip_encap_ip_tx_in_tx_data_rdy;
    
    logic                               ip_encap_to_ip_tx_meta_val;
    logic   [`IP_ADDR_W-1:0]            ip_encap_to_ip_tx_src_ip;
    logic   [`IP_ADDR_W-1:0]            ip_encap_to_ip_tx_dst_ip;
    logic   [`TOT_LEN_W-1:0]            ip_encap_to_ip_tx_data_payload_len;
    logic   [`PROTOCOL_W-1:0]           ip_encap_to_ip_tx_protocol;
    logic                               to_ip_ip_encap_tx_meta_rdy;
    
    logic                               ip_encap_to_ip_tx_data_val;
    logic   [`NOC_DATA_WIDTH-1:0]       ip_encap_to_ip_tx_data;
    logic                               ip_encap_to_ip_tx_data_last;
    logic   [`NOC_PADBYTES_WIDTH-1:0]   ip_encap_to_ip_tx_data_padbytes;
    logic                               to_ip_ip_encap_tx_data_rdy;
    
    dynamic_node_top_wrap #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.XY_COORD_W        (`XY_WIDTH          )
        ,.CHIP_ID_W         (`CHIP_ID_WIDTH     )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
    ) tile_tx_noc0_router (
         .clk                   (clk)
        ,.reset_in              (rst)
        
        ,.src_router_data_N     (src_ip_encap_tx_noc0_data_N        )
        ,.src_router_data_E     (src_ip_encap_tx_noc0_data_E        )
        ,.src_router_data_S     (src_ip_encap_tx_noc0_data_S        )
        ,.src_router_data_W     (src_ip_encap_tx_noc0_data_W        )
        ,.src_router_data_P     (noc0_vrtoc_tile_tx_router_data     )
                                
        ,.src_router_val_N      (src_ip_encap_tx_noc0_val_N         )
        ,.src_router_val_E      (src_ip_encap_tx_noc0_val_E         )
        ,.src_router_val_S      (src_ip_encap_tx_noc0_val_S         )
        ,.src_router_val_W      (src_ip_encap_tx_noc0_val_W         )
        ,.src_router_val_P      (noc0_vrtoc_tile_tx_router_val      )
                                
        ,.router_src_yummy_N    (ip_encap_tx_src_noc0_yummy_N       )
        ,.router_src_yummy_E    (ip_encap_tx_src_noc0_yummy_E       )
        ,.router_src_yummy_S    (ip_encap_tx_src_noc0_yummy_S       )
        ,.router_src_yummy_W    (ip_encap_tx_src_noc0_yummy_W       )
        ,.router_src_yummy_P    (tile_tx_router_noc0_vrtoc_yummy    )
        
        ,.myLocX                (SRC_X[`XY_WIDTH-1:0]               )
        ,.myLocY                (SRC_Y[`XY_WIDTH-1:0]               )
        ,.myChipID              (`CHIP_ID_WIDTH'd0                  )

        ,.router_dst_data_N     (ip_encap_tx_dst_noc0_data_N        )
        ,.router_dst_data_E     (ip_encap_tx_dst_noc0_data_E        )
        ,.router_dst_data_S     (ip_encap_tx_dst_noc0_data_S        )
        ,.router_dst_data_W     (ip_encap_tx_dst_noc0_data_W        )
        ,.router_dst_data_P     (tile_tx_router_noc0_ctovr_data     )
                            
        ,.router_dst_val_N      (ip_encap_tx_dst_noc0_val_N         )
        ,.router_dst_val_E      (ip_encap_tx_dst_noc0_val_E         )
        ,.router_dst_val_S      (ip_encap_tx_dst_noc0_val_S         )
        ,.router_dst_val_W      (ip_encap_tx_dst_noc0_val_W         )
        ,.router_dst_val_P      (tile_tx_router_noc0_ctovr_val      )
                            
        ,.dst_router_yummy_N    (dst_ip_encap_tx_noc0_yummy_N       )
        ,.dst_router_yummy_E    (dst_ip_encap_tx_noc0_yummy_E       )
        ,.dst_router_yummy_S    (dst_ip_encap_tx_noc0_yummy_S       )
        ,.dst_router_yummy_W    (dst_ip_encap_tx_noc0_yummy_W       )
        ,.dst_router_yummy_P    (noc0_ctovr_tile_tx_router_yummy    )
        
        
        ,.router_src_thanks_P   ()  // thanksIn to processor's space_avail
    );
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_tx_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        //credit based interface 
        ,.src_ctovr_data    (tile_tx_router_noc0_ctovr_data     )
        ,.src_ctovr_val     (tile_tx_router_noc0_ctovr_val      )
        ,.ctovr_src_yummy   (noc0_ctovr_tile_tx_router_yummy    )

        //val/rdy interface
        ,.ctovr_dst_data    (noc0_ctovr_ip_encap_tx_in_data     )
        ,.ctovr_dst_val     (noc0_ctovr_ip_encap_tx_in_val      )
        ,.dst_ctovr_rdy     (ip_encap_tx_in_noc0_ctovr_rdy      )
    );

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) tile_tx_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        //val/rdy interface
        ,.src_vrtoc_data    (ip_encap_tx_out_noc0_vrtoc_data    )
        ,.src_vrtoc_val     (ip_encap_tx_out_noc0_vrtoc_val     )
        ,.vrtoc_src_rdy     (noc0_vrtoc_ip_encap_tx_out_rdy     )

		//credit based interface	
        ,.vrtoc_dst_data    (noc0_vrtoc_tile_tx_router_data     )
        ,.vrtoc_dst_val     (noc0_vrtoc_tile_tx_router_val      )
		,.dst_vrtoc_yummy   (tile_tx_router_noc0_vrtoc_yummy    )
    );
    
    ip_tx_tile_noc_in tx_noc_in (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_ip_tx_in_val       (noc0_ctovr_ip_encap_tx_in_val      )
        ,.noc0_ctovr_ip_tx_in_data      (noc0_ctovr_ip_encap_tx_in_data     )
        ,.ip_tx_in_noc0_ctovr_rdy       (ip_encap_tx_in_noc0_ctovr_rdy      )
   
        ,.ip_tx_in_assemble_meta_val    (ip_tx_in_ip_encap_tx_meta_val      )
        ,.ip_tx_in_assemble_meta_flit   (ip_tx_in_ip_encap_tx_meta_flit     )
        ,.assemble_ip_tx_in_meta_rdy    (ip_encap_ip_tx_in_tx_meta_rdy      )
                                                                    
        ,.ip_tx_in_assemble_data_val    (ip_tx_in_ip_encap_tx_data_val      )
        ,.ip_tx_in_assemble_data        (ip_tx_in_ip_encap_tx_data          )
        ,.ip_tx_in_assemble_last        (ip_tx_in_ip_encap_tx_data_last     )
        ,.ip_tx_in_assemble_padbytes    (ip_tx_in_ip_encap_tx_data_padbytes )
        ,.assemble_ip_tx_in_data_rdy    (ip_encap_ip_tx_in_tx_data_rdy      )
    );

    assign ip_tx_in_ip_encap_tx_src_addr = ip_tx_in_ip_encap_tx_meta_flit.src_ip;
    assign ip_tx_in_ip_encap_tx_dst_addr = ip_tx_in_ip_encap_tx_meta_flit.dst_ip;
    assign ip_tx_in_ip_encap_tx_data_payload_len = ip_tx_in_ip_encap_tx_meta_flit.data_payload_len;
    assign ip_tx_in_ip_encap_tx_protocol = ip_tx_in_ip_encap_tx_meta_flit.protocol;

    ip_encap_tx_wrap ip_encap_tx (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_ip_encap_tx_meta_val          (ip_tx_in_ip_encap_tx_meta_val          )
        ,.src_ip_encap_tx_src_addr          (ip_tx_in_ip_encap_tx_src_addr          )
        ,.src_ip_encap_tx_dst_addr          (ip_tx_in_ip_encap_tx_dst_addr          )
        ,.src_ip_encap_tx_data_payload_len  (ip_tx_in_ip_encap_tx_data_payload_len  )
        ,.src_ip_encap_tx_protocol          (ip_tx_in_ip_encap_tx_protocol          )
        ,.ip_encap_src_tx_meta_rdy          (ip_encap_ip_tx_in_tx_meta_rdy          )
                                                                                
        ,.src_ip_encap_tx_data_val          (ip_tx_in_ip_encap_tx_data_val          )
        ,.src_ip_encap_tx_data              (ip_tx_in_ip_encap_tx_data              )
        ,.src_ip_encap_tx_data_last         (ip_tx_in_ip_encap_tx_data_last         )
        ,.src_ip_encap_tx_data_padbytes     (ip_tx_in_ip_encap_tx_data_padbytes     )
        ,.ip_encap_src_tx_data_rdy          (ip_encap_ip_tx_in_tx_data_rdy          )
        
        ,.ip_encap_dst_tx_meta_val          (ip_encap_to_ip_tx_meta_val             )
        ,.ip_encap_dst_tx_src_ip            (ip_encap_to_ip_tx_src_ip               )
        ,.ip_encap_dst_tx_dst_ip            (ip_encap_to_ip_tx_dst_ip               )
        ,.ip_encap_dst_tx_data_payload_len  (ip_encap_to_ip_tx_data_payload_len     )
        ,.ip_encap_dst_tx_protocol          (ip_encap_to_ip_tx_protocol             )
        ,.dst_ip_encap_tx_meta_rdy          (to_ip_ip_encap_tx_meta_rdy             )
                                                                                      
        ,.ip_encap_dst_tx_data_val          (ip_encap_to_ip_tx_data_val             )
        ,.ip_encap_dst_tx_data              (ip_encap_to_ip_tx_data                 )
        ,.ip_encap_dst_tx_data_last         (ip_encap_to_ip_tx_data_last            )
        ,.ip_encap_dst_tx_data_padbytes     (ip_encap_to_ip_tx_data_padbytes        )
        ,.dst_ip_encap_tx_data_rdy          (to_ip_ip_encap_tx_data_rdy             )
    );

    to_ip_tx_noc_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) ip_encap_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.to_ip_tx_out_noc0_val         (ip_encap_tx_out_noc0_vrtoc_val     )
        ,.to_ip_tx_out_noc0_data        (ip_encap_tx_out_noc0_vrtoc_data    )
        ,.noc0_to_ip_tx_out_rdy         (noc0_vrtoc_ip_encap_tx_out_rdy     )
    
        ,.src_to_ip_tx_out_hdr_val      (ip_encap_to_ip_tx_meta_val         )
        ,.src_to_ip_tx_out_src_ip       (ip_encap_to_ip_tx_src_ip           )
        ,.src_to_ip_tx_out_dst_ip       (ip_encap_to_ip_tx_dst_ip           )
        ,.src_to_ip_tx_out_payload_len  (ip_encap_to_ip_tx_data_payload_len )
        ,.src_to_ip_tx_out_protocol     (ip_encap_to_ip_tx_protocol         )
        ,.src_to_ip_tx_out_dst_x        (IP_TX_X[`XY_WIDTH-1:0]             )
        ,.src_to_ip_tx_out_dst_y        (IP_TX_Y[`XY_WIDTH-1:0]             )
        ,.to_ip_tx_out_src_hdr_rdy      (to_ip_ip_encap_tx_meta_rdy         )
                                                                            
        ,.src_to_ip_tx_out_data_val     (ip_encap_to_ip_tx_data_val         )
        ,.src_to_ip_tx_out_data         (ip_encap_to_ip_tx_data             )
        ,.src_to_ip_tx_out_last         (ip_encap_to_ip_tx_data_last        )
        ,.src_to_ip_tx_out_padbytes     (ip_encap_to_ip_tx_data_padbytes    )
        ,.to_ip_tx_out_src_data_rdy     (to_ip_ip_encap_tx_data_rdy         )
    );
endmodule
