`include "tcp_rx_tile_defs.svh"
module tcp_rx_msg_noc_if_out #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           tcp_rx_ptr_if_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_ptr_if_noc_data
    ,input  logic                           noc_tcp_rx_ptr_if_rdy
    
    ,input  logic                           poller_msg_noc_if_meta_val
    ,input  logic   [FLOWID_W-1:0]          poller_msg_noc_if_flowid
    ,input  logic   [RX_PAYLOAD_PTR_W:0]    poller_msg_noc_if_head_ptr
    ,input  logic   [RX_PAYLOAD_PTR_W-1:0]  poller_msg_noc_if_len
    ,input  logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_x
    ,input  logic   [`XY_WIDTH-1:0]         poller_msg_noc_if_dst_y
    ,input  logic   [`NOC_FBITS_WIDTH-1:0]  poller_msg_noc_if_dst_fbits
    ,output logic                           noc_if_poller_msg_meta_rdy
);
    
    logic                           ctrl_datap_store_inputs;

    tcp_rx_msg_noc_if_out_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tcp_rx_ptr_if_noc_val         (tcp_rx_ptr_if_noc_val          )
        ,.noc_tcp_rx_ptr_if_rdy         (noc_tcp_rx_ptr_if_rdy          )
                                                                        
        ,.poller_msg_noc_if_meta_val    (poller_msg_noc_if_meta_val     )
        ,.noc_if_poller_msg_meta_rdy    (noc_if_poller_msg_meta_rdy     )
                                                                        
        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs        )
    );

    tcp_rx_msg_noc_if_out_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tcp_rx_ptr_if_noc_data        (tcp_rx_ptr_if_noc_data         )
                                                                        
        ,.poller_msg_noc_if_flowid      (poller_msg_noc_if_flowid       )
        ,.poller_msg_noc_if_head_ptr    (poller_msg_noc_if_head_ptr     )
        ,.poller_msg_noc_if_len         (poller_msg_noc_if_len          )
        ,.poller_msg_noc_if_dst_x       (poller_msg_noc_if_dst_x        )
        ,.poller_msg_noc_if_dst_y       (poller_msg_noc_if_dst_y        )
        ,.poller_msg_noc_if_dst_fbits   (poller_msg_noc_if_dst_fbits    )
                                                                        
        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs        )
    );


endmodule
