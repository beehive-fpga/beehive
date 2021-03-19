`include "noc_defs.vh"
module open_loop_app_wrap 
import tcp_pkg::*;
import open_loop_pkg::*;
import tx_open_loop_pkg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter RX_DST_BUF_X = -1
    ,parameter RX_DST_BUF_Y = -1
    ,parameter TX_DST_BUF_X = -1
    ,parameter TX_DST_BUF_Y = -1
)(
     input clk
    ,input rst
    
    ,input  logic                           noc_ctovr_app_notif_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_app_notif_data
    ,output logic                           app_notif_noc_ctovr_rdy

    ,output logic                           setup_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   setup_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_setup_rdy

    ,input  logic                           noc_ctovr_setup_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_setup_data
    ,output logic                           setup_noc_ctovr_rdy
    
    ,output logic                           setup_ctrl_noc_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] setup_ctrl_noc_data
    ,input  logic                           ctrl_noc_setup_rdy
    
    ,input  logic                           ctrl_noc_setup_val
    ,input  logic   [`CTRL_NOC1_DATA_W-1:0] ctrl_noc_setup_data
    ,output logic                           setup_ctrl_noc_rdy    

    ,output logic                           rx_engine_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   rx_engine_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_rx_engine_rdy

    ,input  logic                           noc_ctovr_rx_engine_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_rx_engine_data
    ,output logic                           rx_engine_noc_ctovr_rdy
    
    ,output logic                           rx_engine_ctrl_noc_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] rx_engine_ctrl_noc_data
    ,input  logic                           ctrl_noc_rx_engine_rdy

    ,input  logic                           ctrl_noc_rx_engine_val
    ,input  logic   [`CTRL_NOC1_DATA_W-1:0] ctrl_noc_rx_engine_data
    ,output logic                           rx_engine_ctrl_noc_rdy     

    ,output logic                           tx_engine_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tx_engine_noc_vrtoc_data
    ,input  logic                           noc_vrtoc_tx_engine_rdy

    ,input  logic                           noc_ctovr_tx_engine_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_tx_engine_data
    ,output logic                           tx_engine_noc_ctovr_rdy
    
    ,output logic                           tx_engine_ctrl_noc_val
    ,output logic   [`CTRL_NOC1_DATA_W-1:0] tx_engine_ctrl_noc_data
    ,input  logic                           ctrl_noc_tx_engine_rdy

    ,input  logic                           ctrl_noc_tx_engine_val
    ,input  logic   [`CTRL_NOC1_DATA_W-1:0] ctrl_noc_tx_engine_data
    ,output logic                           tx_engine_ctrl_noc_rdy     
);

    logic                   notif_setup_q_wr_req;
    logic   [FLOWID_W-1:0]  notif_setup_q_wr_data;
    
    logic                   notif_setup_q_rd_req;
    logic   [FLOWID_W-1:0]  notif_setup_q_rd_data;
    logic                   notif_setup_q_empty;
    
    logic                   setup_app_mem_wr_req;
    logic   [FLOWID_W-1:0]  setup_app_mem_wr_addr;
    app_cntxt_struct        setup_app_mem_wr_data;

    logic                   setup_send_loop_q_wr_req;
    send_q_struct           setup_send_loop_q_wr_data;
    
    logic                   setup_recv_loop_q_wr_req;
    logic   [FLOWID_W-1:0]  setup_recv_loop_q_wr_flowid;

    logic                   setup_done;
    client_dir_e            bench_dir;
    
    logic                   recv_q_empty;
    logic   [FLOWID_W-1:0]  recv_q_rd_data;
    logic                   recv_q_rd_req;

    logic                   recv_q_wr_req;
    logic   [FLOWID_W-1:0]  recv_q_wr_data;
    
    logic                   rx_engine_q_wr_req;
    logic   [FLOWID_W-1:0]  rx_engine_q_wr_data;
    
    logic                   rx_app_state_rd_req_val;
    logic   [FLOWID_W-1:0]  rx_app_state_rd_flowid;
    logic                   app_state_rx_rd_req_rdy;

    logic                   rx_app_state_wr_req_val;
    app_cntxt_struct        rx_app_state_wr_data;
    logic   [FLOWID_W-1:0]  rx_app_state_wr_flowid;

    logic                   app_state_rx_rd_resp_val;
    app_cntxt_struct        app_state_rx_rd_data;
    logic                   rx_app_state_rd_resp_rdy;

    logic                   app_state_rd_req_val;
    logic   [FLOWID_W-1:0]  app_state_rd_flowid;
    logic                   app_state_rd_req_rdy;

    logic                   app_state_wr_req_val;
    app_cntxt_struct        app_state_wr_data;
    logic   [FLOWID_W-1:0]  app_state_wr_flowid;

    logic                   app_state_rd_resp_val;
    app_cntxt_struct        app_state_rd_data;
    logic                   app_state_rd_resp_rdy;
    
    logic                   send_q_empty;
    send_q_struct           send_q_rd_data;
    logic                   send_q_rd_req;

    logic                   send_q_wr_req;
    send_q_struct           send_q_wr_data;
    logic                   send_q_full;
    
    logic                   tx_engine_q_wr_req;
    send_q_struct           tx_engine_q_wr_data;
    
    logic                   tx_app_state_rd_req_val;
    logic   [FLOWID_W-1:0]  tx_app_state_rd_flowid;
    logic                   app_state_tx_rd_req_rdy;

    logic                   tx_app_state_wr_req_val;
    app_cntxt_struct        tx_app_state_wr_data;
    logic   [FLOWID_W-1:0]  tx_app_state_wr_flowid;

    logic                   app_state_tx_rd_resp_val;
    app_cntxt_struct        app_state_tx_rd_data;
    logic                   tx_app_state_rd_resp_rdy;


    assign app_state_rx_rd_data = app_state_rd_data;
    assign app_state_tx_rd_data = app_state_rd_data;

    always_comb begin
        app_state_tx_rd_req_rdy = 1'b0;
        app_state_rx_rd_req_rdy = 1'b0;

        app_state_rx_rd_resp_val = 1'b0;
        app_state_tx_rd_resp_val = 1'b0;
        
        app_state_rd_resp_rdy = 1'b0;
        app_state_rd_req_val = 1'b0;
        app_state_rd_flowid = 1'b0;

        if (setup_done) begin
            if (bench_dir == SEND) begin
                app_state_wr_req_val = rx_app_state_wr_req_val;
                app_state_wr_flowid = rx_app_state_wr_flowid;
                app_state_wr_data = rx_app_state_wr_data;

                app_state_rd_req_val = rx_app_state_rd_req_val;
                app_state_rd_flowid = rx_app_state_rd_flowid;
                app_state_rx_rd_req_rdy = app_state_rd_req_rdy;

                app_state_rx_rd_resp_val = app_state_rd_resp_val;
                app_state_rd_resp_rdy = rx_app_state_rd_resp_rdy;
            end
            else begin
                app_state_wr_req_val = tx_app_state_wr_req_val;
                app_state_wr_flowid = tx_app_state_wr_flowid;
                app_state_wr_data = tx_app_state_wr_data;

                app_state_rd_req_val = tx_app_state_rd_req_val;
                app_state_rd_flowid = tx_app_state_rd_flowid;
                app_state_tx_rd_req_rdy = app_state_rd_req_rdy;

                app_state_tx_rd_resp_val = app_state_rd_resp_val;
                app_state_rd_resp_rdy = tx_app_state_rd_resp_rdy;
            end
        end
        else begin
            app_state_wr_req_val = setup_app_mem_wr_req;
            app_state_wr_flowid = setup_app_mem_wr_addr;
            app_state_wr_data = setup_app_mem_wr_data;
        end
    end

    ram_1r1w_sync_backpressure #(
         .width_p   (APP_CNTXT_W    )
        ,.els_p     (MAX_FLOW_CNT   )
    ) app_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (app_state_wr_req_val   )
        ,.wr_req_addr   (app_state_wr_flowid    )
        ,.wr_req_data   (app_state_wr_data      )
        ,.wr_req_rdy    ()
    
        ,.rd_req_val    (app_state_rd_req_val   )
        ,.rd_req_addr   (app_state_rd_flowid    )
        ,.rd_req_rdy    (app_state_rd_req_rdy   )
    
        ,.rd_resp_val   (app_state_rd_resp_val  )
        ,.rd_resp_data  (app_state_rd_data      )
        ,.rd_resp_rdy   (app_state_rd_resp_rdy  )
    );

    new_flow_notif notif (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc_ctovr_notif_val   (noc_ctovr_app_notif_val    )
        ,.noc_ctovr_notif_data  (noc_ctovr_app_notif_data   )
        ,.notif_noc_ctovr_rdy   (app_notif_noc_ctovr_rdy    )
    
        ,.notif_setup_q_wr_req  (notif_setup_q_wr_req   )
        ,.notif_setup_q_wr_data (notif_setup_q_wr_data  )
    );

    fifo_1r1w #(
         .width_p       (FLOWID_W   )
        ,.log2_els_p    (FLOWID_W   )
    ) notif_setup_q (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_req    (notif_setup_q_rd_req   )
        ,.rd_data   (notif_setup_q_rd_data  )
        ,.empty     (notif_setup_q_empty    )
    
        ,.wr_req    (notif_setup_q_wr_req   )
        ,.wr_data   (notif_setup_q_wr_data  )
        // this queue should be unable to get full. if it does, something is very wrong
        ,.full      ()
    );

    setup_handler #(
         .SRC_X     (SRC_X          )
        ,.SRC_Y     (SRC_Y          )
        ,.RX_BUF_X  (RX_DST_BUF_X   )
        ,.RX_BUF_Y  (RX_DST_BUF_Y   )
        ,.TX_BUF_X  (TX_DST_BUF_X   )
        ,.TX_BUF_Y  (TX_DST_BUF_Y   )
    ) setup (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.setup_q_handler_empty         (notif_setup_q_empty            )
        ,.setup_q_handler_flowid        (notif_setup_q_rd_data          )
        ,.handler_setup_q_rd_req        (notif_setup_q_rd_req           )
        
        ,.setup_noc_vrtoc_val           (setup_noc_vrtoc_val            )
        ,.setup_noc_vrtoc_data          (setup_noc_vrtoc_data           )
        ,.noc_vrtoc_setup_rdy           (noc_vrtoc_setup_rdy            )
                                                                
        ,.noc_ctovr_setup_val           (noc_ctovr_setup_val            )
        ,.noc_ctovr_setup_data          (noc_ctovr_setup_data           )
        ,.setup_noc_ctovr_rdy           (setup_noc_ctovr_rdy            )
    
        ,.ctrl_noc_setup_val            (ctrl_noc_setup_val             )
        ,.ctrl_noc_setup_data           (ctrl_noc_setup_data            )
        ,.setup_ctrl_noc_rdy            (setup_ctrl_noc_rdy             )
                                                                        
        ,.setup_ctrl_noc_val            (setup_ctrl_noc_val             )
        ,.setup_ctrl_noc_data           (setup_ctrl_noc_data            )
        ,.ctrl_noc_setup_rdy            (ctrl_noc_setup_rdy             )
    
        ,.setup_app_mem_wr_req          (setup_app_mem_wr_req           )
        ,.setup_app_mem_wr_addr         (setup_app_mem_wr_addr          )
        ,.setup_app_mem_wr_data         (setup_app_mem_wr_data          )
                                                                        
        ,.setup_send_loop_q_wr_req      (setup_send_loop_q_wr_req       )
        ,.setup_send_loop_q_wr_data     (setup_send_loop_q_wr_data      )
                                                                        
        ,.setup_recv_loop_q_wr_req      (setup_recv_loop_q_wr_req       )
        ,.setup_recv_loop_q_wr_flowid   (setup_recv_loop_q_wr_flowid    )
                                                                        
        ,.setup_done                    (setup_done                     )
        ,.bench_dir                     (bench_dir                      )
    );

    always_comb begin
        if (setup_done) begin
            recv_q_wr_req = rx_engine_q_wr_req;
            recv_q_wr_data = rx_engine_q_wr_data;
        end
        else begin
            recv_q_wr_req = setup_recv_loop_q_wr_req;
            recv_q_wr_data = setup_recv_loop_q_wr_flowid;
        end
    end
    
    fifo_1r1w #(
         .width_p       (FLOWID_W   )
        ,.log2_els_p    (FLOWID_W   )
    ) recv_q (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_req    (recv_q_rd_req  )
        ,.rd_data   (recv_q_rd_data )
        ,.empty     (recv_q_empty   )
    
        ,.wr_req    (recv_q_wr_req  )
        ,.wr_data   (recv_q_wr_data )
        // this queue should be unable to get full. if it does, something is very wrong
        ,.full      (recv_q_full    )
    );

    open_loop_rx_engine #(
         .SRC_X     (SRC_X          )
        ,.SRC_Y     (SRC_Y          )
        ,.DST_BUF_X (RX_DST_BUF_X  )
        ,.DST_BUF_Y (RX_DST_BUF_Y  )
    ) rx (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.recv_q_empty                  (recv_q_empty                   )
        ,.recv_q_rd_data                (recv_q_rd_data                 )
        ,.recv_q_rd_req                 (recv_q_rd_req                  )
    
        ,.recv_q_full                   (recv_q_full                    )
        ,.recv_q_wr_req                 (rx_engine_q_wr_req             )
        ,.recv_q_wr_data                (rx_engine_q_wr_data            )
    
        ,.rx_engine_noc_vrtoc_val       (rx_engine_noc_vrtoc_val        )
        ,.rx_engine_noc_vrtoc_data      (rx_engine_noc_vrtoc_data       )
        ,.noc_vrtoc_rx_engine_rdy       (noc_vrtoc_rx_engine_rdy        )
                                                                        
        ,.noc_ctovr_rx_engine_val       (noc_ctovr_rx_engine_val        )
        ,.noc_ctovr_rx_engine_data      (noc_ctovr_rx_engine_data       )
        ,.rx_engine_noc_ctovr_rdy       (rx_engine_noc_ctovr_rdy        )
    
        ,.rx_engine_ctrl_noc_val        (rx_engine_ctrl_noc_val         )
        ,.rx_engine_ctrl_noc_data       (rx_engine_ctrl_noc_data        )
        ,.ctrl_noc_rx_engine_rdy        (ctrl_noc_rx_engine_rdy         )
                                                                  
        ,.ctrl_noc_rx_engine_val        (ctrl_noc_rx_engine_val         )
        ,.ctrl_noc_rx_engine_data       (ctrl_noc_rx_engine_data        )
        ,.rx_engine_ctrl_noc_rdy        (rx_engine_ctrl_noc_rdy         )
     
        ,.rx_app_state_rd_req_val       (rx_app_state_rd_req_val        )
        ,.rx_app_state_rd_flowid        (rx_app_state_rd_flowid         )
        ,.app_state_rx_rd_req_rdy       (app_state_rx_rd_req_rdy        )
                                                                        
        ,.rx_app_state_wr_req_val       (rx_app_state_wr_req_val        )
        ,.rx_app_state_wr_data          (rx_app_state_wr_data           )
        ,.rx_app_state_wr_flowid        (rx_app_state_wr_flowid         )
                                                                        
        ,.app_state_rx_rd_resp_val      (app_state_rx_rd_resp_val       )
        ,.app_state_rx_rd_data          (app_state_rx_rd_data           )
        ,.rx_app_state_rd_resp_rdy      (rx_app_state_rd_resp_rdy       )
                                                                        
        ,.setup_done                    (setup_done                     )
    );

    always_comb begin
        if (setup_done) begin
            send_q_wr_req = tx_engine_q_wr_req;
            send_q_wr_data = tx_engine_q_wr_data;
        end
        else begin
            send_q_wr_req = setup_send_loop_q_wr_req;
            send_q_wr_data = setup_send_loop_q_wr_data;
        end
    end
    
    fifo_1r1w #(
         .width_p       (SEND_Q_STRUCT_W    )
        ,.log2_els_p    (FLOWID_W           )
    ) send_q (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_req    (send_q_rd_req  )
        ,.rd_data   (send_q_rd_data )
        ,.empty     (send_q_empty   )
    
        ,.wr_req    (send_q_wr_req  )
        ,.wr_data   (send_q_wr_data )
        // this queue should be unable to get full. if it does, something is very wrong
        ,.full      (send_q_full    )
    );

    open_loop_tx_engine #(
         .SRC_X     (SRC_X          )
        ,.SRC_Y     (SRC_Y          )
        ,.DST_BUF_X (TX_DST_BUF_X   )
        ,.DST_BUF_Y (TX_DST_BUF_Y   )
    ) tx (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.send_q_empty              (send_q_empty               )
        ,.send_q_rd_data            (send_q_rd_data             )
        ,.send_q_rd_req             (send_q_rd_req              )
    
        ,.send_q_wr_req             (tx_engine_q_wr_req         )
        ,.send_q_wr_data            (tx_engine_q_wr_data        )
        ,.send_q_full               (send_q_full                )
    
        ,.tx_engine_noc_vrtoc_val   (tx_engine_noc_vrtoc_val    )
        ,.tx_engine_noc_vrtoc_data  (tx_engine_noc_vrtoc_data   )
        ,.noc_vrtoc_tx_engine_rdy   (noc_vrtoc_tx_engine_rdy    )
                                                                
        ,.noc_ctovr_tx_engine_val   (noc_ctovr_tx_engine_val    )
        ,.noc_ctovr_tx_engine_data  (noc_ctovr_tx_engine_data   )
        ,.tx_engine_noc_ctovr_rdy   (tx_engine_noc_ctovr_rdy    )
    
        ,.ctrl_noc_tx_engine_val    (ctrl_noc_tx_engine_val     )
        ,.ctrl_noc_tx_engine_data   (ctrl_noc_tx_engine_data    )
        ,.tx_engine_ctrl_noc_rdy    (tx_engine_ctrl_noc_rdy     )
                                                                
        ,.tx_engine_ctrl_noc_val    (tx_engine_ctrl_noc_val     )
        ,.tx_engine_ctrl_noc_data   (tx_engine_ctrl_noc_data    )
        ,.ctrl_noc_tx_engine_rdy    (ctrl_noc_tx_engine_rdy     )
     
        ,.tx_app_state_rd_req_val   (tx_app_state_rd_req_val    )
        ,.tx_app_state_rd_flowid    (tx_app_state_rd_flowid     )
        ,.app_state_tx_rd_req_rdy   (app_state_tx_rd_req_rdy    )
                                                                
        ,.tx_app_state_wr_req_val   (tx_app_state_wr_req_val    )
        ,.tx_app_state_wr_data      (tx_app_state_wr_data       )
        ,.tx_app_state_wr_flowid    (tx_app_state_wr_flowid     )
                                                                
        ,.app_state_tx_rd_resp_val  (app_state_tx_rd_resp_val   )
        ,.app_state_tx_rd_data      (app_state_tx_rd_data       )
        ,.tx_app_state_rd_resp_rdy  (tx_app_state_rd_resp_rdy   )
                                                                
        ,.setup_done                (setup_done                 )
    );                                                       
endmodule
