`include "noc_defs.vh"
module tcp_app_notif 
import tcp_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter MONITOR_DATA_W = -1
    ,parameter FBITS = -1
)(
     input clk
    ,input rst
    
    ,input  logic                           app_new_flow_notif_val
    ,input  app_new_flow_info               app_new_flow_notif_info
    ,output logic                           app_new_flow_notif_rdy
    
    ,output                                 app_notif_monitor_noc_val
    ,output [MONITOR_DATA_W-1:0]            app_notif_monitor_noc_data
    ,input                                  monitor_app_notif_noc_rdy

    ,input                                  monitor_app_notif_noc_val
    ,input  [MONITOR_DATA_W-1:0]            monitor_app_notif_noc_data
    ,output                                 app_notif_monitor_noc_rdy
    
    ,output                                 app_notif_tx_monitor_val
    ,output [MONITOR_DATA_W-1:0]            app_notif_tx_monitor_data
    ,input                                  tx_monitor_app_notif_rdy

    ,input                                  tx_monitor_app_notif_val
    ,input  [MONITOR_DATA_W-1:0]            tx_monitor_app_notif_data
    ,output                                 app_notif_tx_monitor_rdy
);

    logic   ctrl_datap_store_inputs;
    logic   ctrl_datap_read_cam;
    logic                           ctrl_datap_store_op_resp;
    tcp_notif_mux_sel_e             ctrl_datap_op_mux_sel;
    cap_sel_e                       ctrl_datap_sel_cap;
    logic                           ctrl_datap_do_tx;
    
    tcp_app_notif_ctrl ctrl (
         .clk   (clk)
        ,.rst   (rst)

        ,.app_new_flow_notif_val            (app_new_flow_notif_val         )
        ,.app_new_flow_notif_rdy            (app_new_flow_notif_rdy         )

        ,.ctrl_datap_store_inputs           (ctrl_datap_store_inputs        )
        ,.ctrl_datap_read_cam               (ctrl_datap_read_cam            )
    
        ,.ctrl_datap_sel_cap                (ctrl_datap_sel_cap             )
        ,.ctrl_datap_do_tx                  (ctrl_datap_do_tx               )
                                             
        ,.app_notif_monitor_noc_val         (app_notif_monitor_noc_val      )
        ,.monitor_app_notif_noc_rdy         (monitor_app_notif_noc_rdy      )
                                             
        ,.monitor_app_notif_noc_val         (monitor_app_notif_noc_val      )
        ,.app_notif_monitor_noc_rdy         (app_notif_monitor_noc_rdy      )
    
        ,.app_notif_tx_monitor_val          (app_notif_tx_monitor_val       )
        ,.tx_monitor_app_notif_rdy          (tx_monitor_app_notif_rdy       )
                                             
        ,.tx_monitor_app_notif_val          (tx_monitor_app_notif_val       )
        ,.app_notif_tx_monitor_rdy          (app_notif_tx_monitor_rdy       )
    );

    tcp_app_notif_datap #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
        ,.MONITOR_DATA_W    (MONITOR_DATA_W )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.app_new_flow_notif_info       (app_new_flow_notif_info    )

        ,.ctrl_datap_store_inputs       (ctrl_datap_store_inputs    )
        ,.ctrl_datap_read_cam           (ctrl_datap_read_cam        )
        ,.ctrl_datap_sel_cap            (ctrl_datap_sel_cap         )
        ,.ctrl_datap_do_tx                  (ctrl_datap_do_tx               )

        ,.app_notif_monitor_noc_data    (app_notif_monitor_noc_data )

        ,.monitor_app_notif_noc_data    (monitor_app_notif_noc_data )
    
        ,.app_notif_tx_monitor_data     (app_notif_tx_monitor_data)

        ,.tx_monitor_app_notif_data     (tx_monitor_app_notif_data)
    );

endmodule
