module ip_rewrite_noc_tx #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter NOC1_DATA_W = -1
    ,parameter NOC2_DATA_W = -1
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_ip_rewrite_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_rewrite_in_data
    ,output logic                           ip_rewrite_in_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_out_noc0_vrtoc_data    
    ,input  logic                           noc0_vrtoc_ip_rewrite_out_rdy
    
    ,input                                  noc_lookup_ctrl_in_val
    ,input          [NOC1_DATA_W-1:0]       noc_lookup_ctrl_in_data
    ,output logic                           lookup_ctrl_in_noc_rdy
    
    ,output logic                           lookup_ctrl_out_noc_val
    ,output logic   [NOC2_DATA_W-1:0]       lookup_ctrl_out_noc_data    
    ,input  logic                           noc_lookup_ctrl_out_rdy
);
    
    localparam TABLE_ENTRIES = 8;
    logic                           ctrl_cam_lookup_val;
    logic   [`PROTOCOL_W-1:0]       datap_cam_lookup_protocol;
    logic   [`NOC_X_WIDTH-1:0]      cam_datap_dst_x;
    logic   [`NOC_Y_WIDTH-1:0]      cam_datap_dst_y;
    
    logic                           lookup_rd_table_val;
    flow_lookup_tuple               lookup_rd_table_read_tuple;
    logic                           lookup_rd_table_rdy;

    logic                           lookup_rd_table_rewrite_hit;
    logic   [`IP_ADDR_W-1:0]        lookup_rd_table_rewrite_addr;

    logic   [TABLE_ENTRIES-1:0]     lookup_wr_table_val;
    flow_lookup_tuple               lookup_wr_table_tuple;
    logic   [`IP_ADDR_W-1:0]        lookup_wr_table_addr;
    logic                           lookup_wr_table_set;
    
    logic                           noc_ctd_lookup_ctrl_val;
    logic   [`NOC_DATA_WIDTH-1:0]   noc_ctd_lookup_ctrl_data;
    logic                           lookup_ctrl_noc_ctd_rdy;
    
    logic                           lookup_ctrl_noc_dtc_val;
    logic   [`NOC_DATA_WIDTH-1:0]   lookup_ctrl_noc_dtc_data;
    logic                           noc_dtc_lookup_ctrl_rdy;

    assign lookup_rd_table_rdy = ~lookup_wr_table_val;

generate
    if (NOC1_DATA_W != `NOC_DATA_WIDTH) begin
        noc_ctrl_to_data ctd (
             .clk   (clk    )
            ,.rst   (rst    )
            
            ,.src_noc_ctd_val   (noc_lookup_ctrl_in_val     )
            ,.src_noc_ctd_data  (noc_lookup_ctrl_in_data    )
            ,.noc_ctd_src_rdy   (lookup_ctrl_in_noc_rdy     )
        
            ,.noc_ctd_dst_val   (noc_ctd_lookup_ctrl_val    )
            ,.noc_ctd_dst_data  (noc_ctd_lookup_ctrl_data   )
            ,.dst_noc_ctd_rdy   (lookup_ctrl_noc_ctd_rdy    )
        );
    end
    else begin
        assign noc_ctd_lookup_ctrl_val = noc_lookup_ctrl_in_val;
        assign noc_ctd_lookup_ctrl_data = noc_lookup_ctrl_in_data;
        assign lookup_ctrl_in_noc_rdy = lookup_ctrl_noc_ctd_rdy;
    end
endgenerate

    lookup_table_ctrl #(
         .SRC_X         (SRC_X          )
        ,.SRC_Y         (SRC_Y          )
        ,.TABLE_ENTRIES (TABLE_ENTRIES  )
    ) lookup_table_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc_lookup_ctrl_in_val    (noc_ctd_lookup_ctrl_val    )
        ,.noc_lookup_ctrl_in_data   (noc_ctd_lookup_ctrl_data   )
        ,.lookup_ctrl_in_noc_rdy    (lookup_ctrl_noc_ctd_rdy    )
                                             
        ,.lookup_ctrl_out_noc_val   (lookup_ctrl_noc_dtc_val    )
        ,.lookup_ctrl_out_noc_data  (lookup_ctrl_noc_dtc_data   )
        ,.noc_lookup_ctrl_out_rdy   (noc_dtc_lookup_ctrl_rdy    )
                                                                                
        ,.lookup_wr_table_val       (lookup_wr_table_val        )
        ,.lookup_wr_table_tuple     (lookup_wr_table_tuple      )
        ,.lookup_wr_table_addr      (lookup_wr_table_addr       )
        ,.lookup_wr_table_set       (lookup_wr_table_set        )
    );

generate
    if (NOC2_DATA_W != `NOC_DATA_WIDTH) begin
        noc_data_to_ctrl dtc (
              .clk   (clk    )
             ,.rst   (rst    )
         
             ,.src_noc_dtc_val   (lookup_ctrl_noc_dtc_val    )
             ,.src_noc_dtc_data  (lookup_ctrl_noc_dtc_data   )
             ,.noc_dtc_src_rdy   (noc_dtc_lookup_ctrl_rdy    )
         
             ,.noc_dtc_dst_val   (lookup_ctrl_out_noc_val    )
             ,.noc_dtc_dst_data  (lookup_ctrl_out_noc_data   )
             ,.dst_noc_dtc_rdy   (noc_lookup_ctrl_out_rdy    )
        );
    end
    else begin
        assign lookup_ctrl_out_noc_val = lookup_ctrl_noc_dtc_val;
        assign lookup_ctrl_out_noc_data = lookup_ctrl_noc_dtc_data;
        assign noc_dtc_lookup_ctrl_rdy = noc_lookup_ctrl_out_rdy;
    end
endgenerate
    
    ip_rewrite_noc #(
         .SRC_X         (SRC_X  )
        ,.SRC_Y         (SRC_Y  )
        ,.RX_REWRITE    (0      )
    ) ip_rewriter (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_in_val      (noc0_ctovr_ip_rewrite_in_val   )
        ,.noc0_ctovr_ip_rewrite_in_data     (noc0_ctovr_ip_rewrite_in_data  )
        ,.ip_rewrite_in_noc0_ctovr_rdy      (ip_rewrite_in_noc0_ctovr_rdy   )
                                                                            
        ,.ip_rewrite_out_noc0_vrtoc_val     (ip_rewrite_out_noc0_vrtoc_val  )
        ,.ip_rewrite_out_noc0_vrtoc_data    (ip_rewrite_out_noc0_vrtoc_data )
        ,.noc0_vrtoc_ip_rewrite_out_rdy     (noc0_vrtoc_ip_rewrite_out_rdy  )
    
        ,.lookup_rd_table_val               (lookup_rd_table_val            )
        ,.lookup_rd_table_read_tuple        (lookup_rd_table_read_tuple     )
        ,.lookup_rd_table_rdy               (lookup_rd_table_rdy            )
                                                                            
        ,.lookup_rd_table_rewrite_hit       (lookup_rd_table_rewrite_hit    )
        ,.lookup_rd_table_rewrite_addr      (lookup_rd_table_rewrite_addr   )
       
        ,.ctrl_cam_lookup_val               (ctrl_cam_lookup_val            )
        ,.datap_cam_lookup_protocol         (datap_cam_lookup_protocol      )
        ,.cam_datap_dst_x                   (IP_TX_TILE_X                   )
        ,.cam_datap_dst_y                   (IP_TX_TILE_Y                   )
    );

    bsg_cam_1r1w_unmanaged #(
        .els_p           (TABLE_ENTRIES         )
       ,.tag_width_p     (FLOW_LOOKUP_TUPLE_W   )
       ,.data_width_p    (`IP_ADDR_W            )
    ) lookup_cam (
         .clk_i      (clk    )
        ,.reset_i    (rst    )
        
        ,.w_v_i              (lookup_wr_table_val           )
        ,.w_set_not_clear_i  (lookup_wr_table_set           )
        ,.w_tag_i            (lookup_wr_table_tuple         )
        ,.w_data_i           (lookup_wr_table_addr          )
        ,.w_empty_o          ()
        
        ,.r_v_i              (lookup_rd_table_val           )
        ,.r_tag_i            (lookup_rd_table_read_tuple    )
        ,.r_data_o           (lookup_rd_table_rewrite_addr  )
        ,.r_v_o              (lookup_rd_table_rewrite_hit   )
    );
endmodule
