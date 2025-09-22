module tcp_app_notif_ctrl 
import tcp_rx_tile_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic                           app_new_flow_notif_val
    ,output logic                           app_new_flow_notif_rdy

    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_read_cam
    ,output cap_sel_e                       ctrl_datap_sel_cap
    ,output logic                           ctrl_datap_do_tx
    
    ,output logic                           app_notif_monitor_noc_val
    ,input                                  monitor_app_notif_noc_rdy

    ,input                                  monitor_app_notif_noc_val
    ,output logic                           app_notif_monitor_noc_rdy
    
    ,output                                 app_notif_tx_monitor_val
    ,input                                  tx_monitor_app_notif_rdy

    ,input                                  tx_monitor_app_notif_val
    ,output                                 app_notif_tx_monitor_rdy
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        SEND_REQ_HDR = 3'd4,
        SEND_REQ_BODY = 3'd3,
        SEND_NOTIF = 3'd1,
        RECV_RESP = 3'd5,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   do_tx_reg;
    logic   do_tx_next;

    logic internal_rdy;
    logic internal_val;


    bsg_mux #(
         .els_p     (2)
        ,.width_p   (1)
    ) rdys_mux (
         .data_i    ({tx_monitor_app_notif_rdy, monitor_app_notif_noc_rdy})
        ,.sel_i     (do_tx_reg)
        ,.data_o    (internal_rdy)
    );

    demux #(
         .NUM_OUTPUTS    (2)
        ,.INPUT_WIDTH    (1)
    ) vals_demux (
         .input_sel     (do_tx_reg)
        ,.data_input    (internal_val)
        ,.data_outputs  ({app_notif_tx_monitor_val, app_notif_monitor_noc_val})
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            do_tx_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            do_tx_reg <= do_tx_next;
        end
    end

    assign ctrl_datap_do_tx = do_tx_reg;
    assign ctrl_datap_read_cam = 1'b1;

    assign app_notif_tx_monitor_rdy = 1'b0;
    always_comb begin
        app_new_flow_notif_rdy = 1'b0;
        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_sel_cap = HDR;
        internal_val = 1'b0;

        app_notif_monitor_noc_rdy = 1'b0;

        do_tx_next = do_tx_reg;
        state_next = state_reg;
        case (state_reg) 
            READY: begin
                ctrl_datap_store_inputs = 1'b1;
                app_new_flow_notif_rdy = 1'b1;
                do_tx_next = '0;
                if (app_new_flow_notif_val) begin
                    state_next = SEND_REQ_HDR;
                end
            end
            SEND_REQ_HDR: begin
                ctrl_datap_sel_cap = HDR;
                internal_val = 1'b1;
                if (internal_rdy) begin
                    state_next = SEND_REQ_BODY;
                end
            end
            SEND_REQ_BODY: begin
                ctrl_datap_sel_cap = REQ;
                internal_val = 1'b1;
                if (internal_rdy) begin
                    state_next = SEND_NOTIF;
                end
            end
            SEND_NOTIF: begin
                ctrl_datap_sel_cap = NOTIF;
                internal_val = 1'b1;
                if (internal_rdy) begin
                    do_tx_next = 1;
                    if (do_tx_reg) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = SEND_REQ_HDR;
                    end
                end
            end
            default: begin
                app_new_flow_notif_rdy = 'X;
                ctrl_datap_store_inputs = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
