`include "tcp_tx_tile_defs.svh"
module tcp_tx_ptr_if #(
     parameter SRC_X = "inv"
    ,parameter SRC_Y = "inv"
)(
     input clk
    ,input rst
    
    ,input  logic                           noc0_ctovr_tcp_tx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_tx_ptr_if_data
    ,output logic                           tcp_tx_ptr_if_noc0_ctovr_rdy

    ,output logic                           tcp_tx_ptr_if_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_tx_ptr_if_noc0_vrtoc_data
    ,input  logic                           noc0_vrtoc_tcp_tx_ptr_if_rdy
    
    ,output logic                           app_tail_ptr_tx_wr_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_tail_ptr_tx_wr_req_flowid
    ,output logic   [`PAYLOAD_PTR_W:0]      app_tail_ptr_tx_wr_req_data
    ,input                                  tail_ptr_app_tx_wr_req_rdy
    
    ,output logic                           app_tail_ptr_tx_rd_req_val
    ,output logic   [`FLOW_ID_W-1:0]        app_tail_ptr_tx_rd_req_flowid
    ,input  logic                           tail_ptr_app_tx_rd_req_rdy

    ,input                                  tail_ptr_app_tx_rd_resp_val
    ,input  logic   [`FLOW_ID_W-1:0]        tail_ptr_app_tx_rd_resp_flowid
    ,input  logic   [`PAYLOAD_PTR_W:0]      tail_ptr_app_tx_rd_resp_data
    ,output logic                           app_tail_ptr_tx_rd_resp_rdy

    ,output                                 app_head_ptr_tx_rd_req_val
    ,output         [`FLOW_ID_W-1:0]        app_head_ptr_tx_rd_req_flowid
    ,input  logic                           head_ptr_app_tx_rd_req_rdy

    ,input                                  head_ptr_app_tx_rd_resp_val
    ,input  logic   [`FLOW_ID_W-1:0]        head_ptr_app_tx_rd_resp_flowid
    ,input  logic   [`PAYLOAD_PTR_W:0]      head_ptr_app_tx_rd_resp_data
    ,output logic                           app_head_ptr_tx_rd_resp_rdy
);
    
    logic                           ctrl_datap_store_hdr_flit;
    logic                           ctrl_datap_store_ptrs;

    tcp_tx_ptr_if_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_tcp_tx_ptr_if_data     (noc0_ctovr_tcp_tx_ptr_if_data  )
                                                                            
        ,.tcp_tx_ptr_if_noc0_vrtoc_data     (tcp_tx_ptr_if_noc0_vrtoc_data  )
                                                                            
        ,.app_tail_ptr_tx_wr_req_flowid     (app_tail_ptr_tx_wr_req_flowid  )
        ,.app_tail_ptr_tx_wr_req_data       (app_tail_ptr_tx_wr_req_data    )
                                                                            
        ,.app_tail_ptr_tx_rd_req_flowid     (app_tail_ptr_tx_rd_req_flowid  )
                                                                            
        ,.tail_ptr_app_tx_rd_resp_flowid    (tail_ptr_app_tx_rd_resp_flowid )
        ,.tail_ptr_app_tx_rd_resp_data      (tail_ptr_app_tx_rd_resp_data   )
                                                                            
        ,.app_head_ptr_tx_rd_req_flowid     (app_head_ptr_tx_rd_req_flowid  )
                                                                            
        ,.head_ptr_app_tx_rd_resp_flowid    (head_ptr_app_tx_rd_resp_flowid )
        ,.head_ptr_app_tx_rd_resp_data      (head_ptr_app_tx_rd_resp_data   )
                                                                            
        ,.ctrl_datap_store_hdr_flit         (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_ptrs             (ctrl_datap_store_ptrs          )
    );

    tcp_tx_ptr_if_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_ctovr_tcp_tx_ptr_if_val  (noc0_ctovr_tcp_tx_ptr_if_val   )
        ,.noc0_ctovr_tcp_tx_ptr_if_data (noc0_ctovr_tcp_tx_ptr_if_data  )
        ,.tcp_tx_ptr_if_noc0_ctovr_rdy  (tcp_tx_ptr_if_noc0_ctovr_rdy   )
                                                                        
        ,.tcp_tx_ptr_if_noc0_vrtoc_val  (tcp_tx_ptr_if_noc0_vrtoc_val   )
        ,.noc0_vrtoc_tcp_tx_ptr_if_rdy  (noc0_vrtoc_tcp_tx_ptr_if_rdy   )
                                                                        
        ,.app_tail_ptr_tx_wr_req_val    (app_tail_ptr_tx_wr_req_val     )
        ,.tail_ptr_app_tx_wr_req_rdy    (tail_ptr_app_tx_wr_req_rdy     )
                                                                        
        ,.app_tail_ptr_tx_rd_req_val    (app_tail_ptr_tx_rd_req_val     )
        ,.tail_ptr_app_tx_rd_req_rdy    (tail_ptr_app_tx_rd_req_rdy     )
                                                                        
        ,.tail_ptr_app_tx_rd_resp_val   (tail_ptr_app_tx_rd_resp_val    )
        ,.app_tail_ptr_tx_rd_resp_rdy   (app_tail_ptr_tx_rd_resp_rdy    )
                                                                        
        ,.app_head_ptr_tx_rd_req_val    (app_head_ptr_tx_rd_req_val     )
        ,.head_ptr_app_tx_rd_req_rdy    (head_ptr_app_tx_rd_req_rdy     )
                                                                        
        ,.head_ptr_app_tx_rd_resp_val   (head_ptr_app_tx_rd_resp_val    )
        ,.app_head_ptr_tx_rd_resp_rdy   (app_head_ptr_tx_rd_resp_rdy    )
                                                                        
        ,.ctrl_datap_store_hdr_flit     (ctrl_datap_store_hdr_flit      )
        ,.ctrl_datap_store_ptrs         (ctrl_datap_store_ptrs          )
    );
endmodule
