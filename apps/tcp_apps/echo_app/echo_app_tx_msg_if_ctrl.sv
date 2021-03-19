`include "echo_app_defs.svh"
module echo_app_tx_msg_if_ctrl (
     input clk
    ,input rst
    
    ,output logic                           tx_app_noc_vrtoc_val
    ,input  logic                           noc_vrtoc_tx_app_rdy

    ,input  logic                           noc_ctovr_tx_app_val
    ,output logic                           tx_app_noc_ctovr_rdy     
    
    ,input  logic                           rx_if_tx_if_msg_val
    ,output logic                           tx_if_rx_if_msg_rdy
    
    ,output logic                           ctrl_wr_buf_req_val
    ,input  logic                           wr_buf_ctrl_req_rdy

    ,output logic                           ctrl_wr_buf_req_data_val
    ,input  logic                           wr_buf_ctrl_req_data_rdy

    ,input  logic                           wr_buf_ctrl_req_done
    ,output logic                           ctrl_wr_buf_done_rdy

    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_decr_bytes_left
    ,output         buf_mux_sel_e           ctrl_datap_buf_mux_sel
    ,output logic                           ctrl_datap_store_notif

    ,input  logic                           datap_ctrl_last_wr
    
    ,output logic                           echo_app_incr_req_done
);

    typedef enum logic[2:0] {
        READY = 3'd0,

        TX_MSG_REQ = 3'd1,
        TX_MSG_NOTIF = 3'd2,
        
        TX_WR_MEM_REQ = 3'd3,
        PAYLOAD_COPY = 3'd4,
        WAIT_WR_RESP = 3'd5,
        
        ADJUST_TX_TAIL = 3'd6,

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
        tx_if_rx_if_msg_rdy = 1'b0;

        tx_app_noc_vrtoc_val = 1'b0;
        tx_app_noc_ctovr_rdy = 1'b0;

        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_decr_bytes_left = 1'b0;
        ctrl_datap_buf_mux_sel = BODY_VALUES;
        ctrl_datap_store_notif = 1'b0;

        ctrl_wr_buf_req_val = 1'b0;
        ctrl_wr_buf_req_data_val = 1'b0;
        ctrl_wr_buf_done_rdy = 1'b0;

        echo_app_incr_req_done = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_store_inputs = 1'b1;
                tx_if_rx_if_msg_rdy = 1'b1;
                if (rx_if_tx_if_msg_val) begin
                    state_next = TX_MSG_REQ;
                end
                else begin
                    state_next = READY;
                end
            end
            TX_MSG_REQ: begin
                ctrl_datap_buf_mux_sel = BODY_VALUES;
                tx_app_noc_vrtoc_val = 1'b1;

                if (noc_vrtoc_tx_app_rdy) begin
                    state_next = TX_MSG_NOTIF;
                end
                else begin
                    state_next = TX_MSG_REQ;
                end
            end
            TX_MSG_NOTIF: begin
                ctrl_datap_store_notif = 1'b1;
                tx_app_noc_ctovr_rdy = 1'b1;
                if (noc_ctovr_tx_app_val) begin
                    state_next = TX_WR_MEM_REQ;
                end
                else begin
                    state_next = TX_MSG_NOTIF;
                end
            end
            TX_WR_MEM_REQ: begin
                ctrl_wr_buf_req_val = 1'b1;
                if (wr_buf_ctrl_req_rdy) begin
                    state_next = PAYLOAD_COPY;
                end
                else begin
                    state_next = TX_WR_MEM_REQ;
                end
            end
            PAYLOAD_COPY: begin
                ctrl_wr_buf_req_data_val = 1'b1;
                if (wr_buf_ctrl_req_data_rdy) begin
                    ctrl_datap_decr_bytes_left = 1'b1;
                    if (datap_ctrl_last_wr) begin
                        state_next = WAIT_WR_RESP;
                    end
                    else begin
                        state_next = PAYLOAD_COPY;
                    end
                end
                else begin
                    state_next = PAYLOAD_COPY;
                end
            end
            WAIT_WR_RESP: begin
                ctrl_wr_buf_done_rdy = 1'b1;
                if (wr_buf_ctrl_req_done) begin
                    state_next = ADJUST_TX_TAIL;
                end
                else begin
                    state_next = WAIT_WR_RESP;
                end
            end
            ADJUST_TX_TAIL: begin
                tx_app_noc_vrtoc_val = 1'b1;
                ctrl_datap_buf_mux_sel = PTR_UPDATE;
                if (noc_vrtoc_tx_app_rdy) begin
                    echo_app_incr_req_done = 1'b1;
                    state_next = READY;
                end
                else begin
                    state_next = ADJUST_TX_TAIL;
                end
            end
            default: begin
                tx_if_rx_if_msg_rdy = 'X;

                tx_app_noc_vrtoc_val = 'X;

                ctrl_datap_store_inputs = 'X;
                ctrl_datap_decr_bytes_left = 'X;

                ctrl_wr_buf_req_val = 'X;
                ctrl_wr_buf_req_data_val = 'X;
                ctrl_wr_buf_done_rdy = 'X;
        
                ctrl_datap_buf_mux_sel = BODY_VALUES;
                ctrl_datap_store_notif = 'X;

                echo_app_incr_req_done = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
