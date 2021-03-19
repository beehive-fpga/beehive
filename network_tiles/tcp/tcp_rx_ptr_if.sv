`include "tcp_rx_tile_defs.svh"
module tcp_rx_ptr_if #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,input  logic                           noc0_ctovr_tcp_rx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_rx_ptr_if_data
    ,output logic                           tcp_rx_app_if_noc0_ctovr_rdy

    ,output logic                           tcp_rx_ptr_if_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_ptr_if_noc0_vrtoc_data
    ,input  logic                           noc0_vrtoc_tcp_rx_ptr_if_rdy
    
    ,output logic                           app_rx_head_ptr_wr_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_rx_head_ptr_wr_req_addr
    ,output logic   [`RX_PAYLOAD_PTR_W:0]   app_rx_head_ptr_wr_req_data
    ,input  logic                           rx_head_ptr_app_wr_req_rdy

    ,output logic                           app_rx_head_ptr_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_rx_head_ptr_rd_req_addr
    ,input  logic                           rx_head_ptr_app_rd_req_rdy
    
    ,input  logic                           rx_head_ptr_app_rd_resp_val
    ,input  logic   [`RX_PAYLOAD_PTR_W:0]   rx_head_ptr_app_rd_resp_data
    ,output logic                           app_rx_head_ptr_rd_resp_rdy

    ,output logic                           app_rx_commit_ptr_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_rx_commit_ptr_rd_req_addr
    ,input  logic                           rx_commit_ptr_app_rd_req_rdy

    ,input  logic                           rx_commit_ptr_app_rd_resp_val
    ,input  logic   [`RX_PAYLOAD_PTR_W:0]   rx_commit_ptr_app_rd_resp_data
    ,output logic                           app_rx_commit_ptr_rd_resp_rdy
);
    
    logic                           ctrl_datap_store_hdr_flit;
    logic                           ctrl_datap_store_ptrs;

    tcp_rx_ptr_if_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_tcp_rx_ptr_if_data     (noc0_ctovr_tcp_rx_ptr_if_data  )
                                                                            
        ,.tcp_rx_ptr_if_noc0_vrtoc_data     (tcp_rx_ptr_if_noc0_vrtoc_data  )
                                                                            
        ,.app_rx_head_ptr_wr_req_addr       (app_rx_head_ptr_wr_req_addr    )
        ,.app_rx_head_ptr_wr_req_data       (app_rx_head_ptr_wr_req_data    )
                                                                            
        ,.app_rx_head_ptr_rd_req_addr       (app_rx_head_ptr_rd_req_addr    )
                                                                            
        ,.rx_head_ptr_app_rd_resp_data      (rx_head_ptr_app_rd_resp_data   )
                                                                            
        ,.app_rx_commit_ptr_rd_req_addr     (app_rx_commit_ptr_rd_req_addr  )
                                                                            
        ,.rx_commit_ptr_app_rd_resp_data    (rx_commit_ptr_app_rd_resp_data )
                                                                            
        ,.ctrl_datap_store_hdr_flit         (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_ptrs             (ctrl_datap_store_ptrs          )
    );

    tcp_rx_ptr_if_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.noc0_ctovr_tcp_rx_ptr_if_val  (noc0_ctovr_tcp_rx_ptr_if_val   )
        ,.noc0_ctovr_tcp_rx_ptr_if_data (noc0_ctovr_tcp_rx_ptr_if_data  )
        ,.tcp_rx_ptr_if_noc0_ctovr_rdy  (tcp_rx_app_if_noc0_ctovr_rdy   )
                                                                        
        ,.tcp_rx_ptr_if_noc0_vrtoc_val  (tcp_rx_ptr_if_noc0_vrtoc_val   )
        ,.noc0_vrtoc_tcp_rx_ptr_if_rdy  (noc0_vrtoc_tcp_rx_ptr_if_rdy   )
                                                                        
        ,.app_rx_head_ptr_wr_req_val    (app_rx_head_ptr_wr_req_val     )
        ,.rx_head_ptr_app_wr_req_rdy    (rx_head_ptr_app_wr_req_rdy     )
                                                                        
        ,.app_rx_head_ptr_rd_req_val    (app_rx_head_ptr_rd_req_val     )
        ,.rx_head_ptr_app_rd_req_rdy    (rx_head_ptr_app_rd_req_rdy     )
                                                                        
        ,.rx_head_ptr_app_rd_resp_val   (rx_head_ptr_app_rd_resp_val    )
        ,.app_rx_head_ptr_rd_resp_rdy   (app_rx_head_ptr_rd_resp_rdy    )
                                                                        
        ,.app_rx_commit_ptr_rd_req_val  (app_rx_commit_ptr_rd_req_val   )
        ,.rx_commit_ptr_app_rd_req_rdy  (rx_commit_ptr_app_rd_req_rdy   )
                                                                        
        ,.rx_commit_ptr_app_rd_resp_val (rx_commit_ptr_app_rd_resp_val  )
        ,.app_rx_commit_ptr_rd_resp_rdy (app_rx_commit_ptr_rd_resp_rdy  )
                                                                        
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_ptrs         (ctrl_datap_store_ptrs          )
    );


endmodule
