`include "ip_rewrite_noc_pipe_defs.svh"
module ip_rewrite_noc #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter RX_REWRITE = 1
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_ip_rewrite_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_rewrite_in_data
    ,output logic                           ip_rewrite_in_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_out_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_out_noc0_vrtoc_data    
    ,input  logic                           noc0_vrtoc_ip_rewrite_out_rdy

    ,output logic                           lookup_rd_table_val
    ,output flow_lookup_tuple               lookup_rd_table_read_tuple
    ,input  logic                           lookup_rd_table_rdy

    ,input  logic                           lookup_rd_table_rewrite_hit
    ,input          [`IP_ADDR_W-1:0]        lookup_rd_table_rewrite_addr
   
    ,output logic                           ctrl_cam_lookup_val
    ,output logic   [`PROTOCOL_W-1:0]       datap_cam_lookup_protocol
    ,input  logic   [`NOC_X_WIDTH-1:0]      cam_datap_dst_x
    ,input  logic   [`NOC_Y_WIDTH-1:0]      cam_datap_dst_y
);
    logic                           ctrl_datap_store_hdr;
    logic                           ctrl_datap_store_meta;
    logic                           ctrl_datap_store_lookup;
    logic                           ctrl_datap_store_dst;
    ip_rewrite_out_sel_e            ctrl_datap_noc_out_sel;
    logic                           ctrl_datap_init_flit_cnt;
    logic                           ctrl_datap_incr_flit_cnt;
    logic                           ctrl_datap_use_rewrite_chksum;
    
    logic                           datap_ctrl_last_flit;

    ip_rewrite_noc_pipe_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_in_val  (noc0_ctovr_ip_rewrite_in_val   )
        ,.ip_rewrite_in_noc0_ctovr_rdy  (ip_rewrite_in_noc0_ctovr_rdy   )
                                                                        
        ,.ip_rewrite_out_noc0_vrtoc_val (ip_rewrite_out_noc0_vrtoc_val  )
        ,.noc0_vrtoc_ip_rewrite_out_rdy (noc0_vrtoc_ip_rewrite_out_rdy  )
    
        ,.lookup_rd_table_val           (lookup_rd_table_val            )
        ,.lookup_rd_table_rdy           (lookup_rd_table_rdy            )
        
        ,.ctrl_cam_lookup_val           (ctrl_cam_lookup_val            )
                                                                        
        ,.ctrl_datap_store_hdr          (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_lookup       (ctrl_datap_store_lookup        )
        ,.ctrl_datap_store_dst          (ctrl_datap_store_dst           )
        ,.ctrl_datap_noc_out_sel        (ctrl_datap_noc_out_sel         )
        ,.ctrl_datap_init_flit_cnt      (ctrl_datap_init_flit_cnt       )
        ,.ctrl_datap_incr_flit_cnt      (ctrl_datap_incr_flit_cnt       )
        ,.ctrl_datap_use_rewrite_chksum (ctrl_datap_use_rewrite_chksum  )
                                                                        
        ,.datap_ctrl_last_flit          (datap_ctrl_last_flit           )
    );

    ip_rewrite_noc_pipe_datap #(
         .SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.RX_REWRITE    (RX_REWRITE )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_ctovr_ip_rewrite_in_data     (noc0_ctovr_ip_rewrite_in_data  )
                                                                            
        ,.ip_rewrite_out_noc0_vrtoc_data    (ip_rewrite_out_noc0_vrtoc_data )
                                                                            
        ,.lookup_rd_table_read_tuple        (lookup_rd_table_read_tuple     )
                                                                            
        ,.lookup_rd_table_rewrite_hit       (lookup_rd_table_rewrite_hit    )
        ,.lookup_rd_table_rewrite_addr      (lookup_rd_table_rewrite_addr   )
                                                                            
        ,.datap_cam_lookup_protocol         (datap_cam_lookup_protocol      )
        ,.cam_datap_dst_x                   (cam_datap_dst_x                )
        ,.cam_datap_dst_y                   (cam_datap_dst_y                )
                                                                            
        ,.ctrl_datap_store_hdr              (ctrl_datap_store_hdr           )
        ,.ctrl_datap_store_meta             (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_lookup           (ctrl_datap_store_lookup        )
        ,.ctrl_datap_store_dst              (ctrl_datap_store_dst           )
        ,.ctrl_datap_noc_out_sel            (ctrl_datap_noc_out_sel         )
        ,.ctrl_datap_init_flit_cnt          (ctrl_datap_init_flit_cnt       )
        ,.ctrl_datap_incr_flit_cnt          (ctrl_datap_incr_flit_cnt       )
        ,.ctrl_datap_use_rewrite_chksum     (ctrl_datap_use_rewrite_chksum  )
                                                                            
        ,.datap_ctrl_last_flit              (datap_ctrl_last_flit           )
    );


endmodule
