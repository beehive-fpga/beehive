`include "tcp_rx_tile_defs.svh"
module tcp_app_notif_ctrl (
     input clk
    ,input rst
    
    ,output logic                           tcp_rx_notif_if_noc0_vrtoc_val
    ,input  logic                           noc0_vrtoc_tcp_rx_notif_if_rdy
    
    ,input  logic                           app_new_flow_notif_val
    ,output logic                           app_new_flow_notif_rdy

    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_read_cam
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        HDR_FLIT = 2'd1,
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

    always_comb begin
        tcp_rx_notif_if_noc0_vrtoc_val = 1'b0;
        app_new_flow_notif_rdy = 1'b0;
        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_read_cam = 1'b0;

        state_next = state_reg;
        case (state_reg) 
            READY: begin
                ctrl_datap_store_inputs = 1'b1;
                app_new_flow_notif_rdy = 1'b1;
                if (app_new_flow_notif_val) begin
                    state_next = HDR_FLIT;
                end
                else begin
                    state_next = READY;
                end
            end
            HDR_FLIT: begin
                tcp_rx_notif_if_noc0_vrtoc_val = 1'b1;
                ctrl_datap_read_cam = 1'b1;
                if (noc0_vrtoc_tcp_rx_notif_if_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = HDR_FLIT;
                end
            end
            default: begin
                tcp_rx_notif_if_noc0_vrtoc_val = 'X;
                app_new_flow_notif_rdy = 'X;
                ctrl_datap_store_inputs = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
