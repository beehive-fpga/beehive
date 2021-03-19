`include "tcp_rx_tile_defs.svh"
module tcp_app_notif #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic                           tcp_rx_notif_if_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_notif_if_noc0_vrtoc_data
    ,input  logic                           noc0_vrtoc_tcp_rx_notif_if_rdy
    
    ,input  logic                           app_new_flow_notif_val
    ,input  logic   [FLOWID_W-1:0]          app_new_flow_flowid
    ,input  four_tuple_struct               app_new_flow_entry
    ,output logic                           app_new_flow_notif_rdy
);

    logic   ctrl_datap_store_inputs;
    logic   ctrl_datap_read_cam;


    tcp_app_notif_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.tcp_rx_notif_if_noc0_vrtoc_val    (tcp_rx_notif_if_noc0_vrtoc_val )
        ,.noc0_vrtoc_tcp_rx_notif_if_rdy    (noc0_vrtoc_tcp_rx_notif_if_rdy )
                                                                            
        ,.app_new_flow_notif_val            (app_new_flow_notif_val         )
        ,.app_new_flow_notif_rdy            (app_new_flow_notif_rdy         )
                                                                            
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs        )
        ,.ctrl_datap_read_cam               (ctrl_datap_read_cam            )
    );

    tcp_app_notif_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.tcp_rx_notif_if_noc0_vrtoc_data   (tcp_rx_notif_if_noc0_vrtoc_data    )
                                                                                
        ,.app_new_flow_flowid               (app_new_flow_flowid                )
        ,.app_new_flow_entry                (app_new_flow_entry                 )
                                                                                
        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs            )
        ,.ctrl_datap_read_cam               (ctrl_datap_read_cam                )
    );

endmodule
