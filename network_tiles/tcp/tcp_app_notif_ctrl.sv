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
    
    ,output logic                           app_notif_monitor_noc_val
    ,input                                  monitor_app_notif_noc_rdy

    ,input                                  monitor_app_notif_noc_val
    ,output logic                           app_notif_monitor_noc_rdy
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

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    assign ctrl_datap_read_cam = 1'b1;
    always_comb begin
        app_new_flow_notif_rdy = 1'b0;
        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_sel_cap = HDR;

        app_notif_monitor_noc_val = 1'b0;
        app_notif_monitor_noc_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg) 
            READY: begin
                ctrl_datap_store_inputs = 1'b1;
                app_new_flow_notif_rdy = 1'b1;
                if (app_new_flow_notif_val) begin
                    state_next = SEND_REQ_HDR;
                end
            end
            SEND_REQ_HDR: begin
                app_notif_monitor_noc_val = 1'b1;
                ctrl_datap_sel_cap = HDR;
                if (monitor_app_notif_noc_rdy) begin
                    state_next = SEND_REQ_BODY;
                end
            end
            SEND_REQ_BODY: begin
                ctrl_datap_sel_cap = REQ;
                app_notif_monitor_noc_val = 1'b1;
                if (monitor_app_notif_noc_rdy) begin
                    state_next = SEND_NOTIF;
                end
            end
            SEND_NOTIF: begin
                ctrl_datap_sel_cap = NOTIF;
                app_notif_monitor_noc_val = 1'b1;
                if (monitor_app_notif_noc_rdy) begin
                    state_next = RECV_RESP;
                end
            end
            RECV_RESP: begin
                app_notif_monitor_noc_rdy =!'b1;
                if (monitor_app_notif_noc_val) begin
                    state_next = READY;
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
