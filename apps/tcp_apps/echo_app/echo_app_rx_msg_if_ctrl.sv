`include "echo_app_defs.svh"
module echo_app_rx_msg_if_ctrl (
     input clk
    ,input rst
    
    ,output logic                           rx_app_noc_vrtoc_val
    ,input  logic                           noc_vrtoc_rx_app_rdy

    ,input  logic                           noc_ctovr_rx_app_val
    ,output logic                           rx_app_noc_ctovr_rdy    

    ,input  logic                           active_q_msg_if_empty
    ,output logic                           msg_if_active_q_rd_req

    ,output logic                           msg_if_active_q_wr_req
    ,input  logic                           active_q_msg_if_wr_rdy

    ,output logic                           ctrl_rd_buf_req_val
    ,input  logic                           rd_buf_ctrl_req_rdy

    ,input  logic                           rd_buf_ctrl_resp_data_val
    ,output logic                           ctrl_rd_buf_resp_data_rdy

    ,output logic                           rx_if_tx_if_msg_val
    ,input  logic                           tx_if_rx_if_msg_rdy

    ,output logic                           ctrl_datap_store_flowid
    ,output logic                           ctrl_datap_store_hdr
    ,output logic                           ctrl_datap_store_notif
    ,output         buf_mux_sel_e           ctrl_datap_buf_mux_sel

    ,input  logic                           datap_ctrl_last_req
);

    logic   notif_tx;

    typedef enum logic[3:0] {
        READY = 4'd0,
        REQ_HDR = 4'd1,
        HDR_NOTIF = 4'd2,
        RD_HDR = 4'd3,
        HDR_RESP = 4'd4,

        REQ_BODY = 4'd5,
        BODY_NOTIF = 4'd6,

        ADJUST_RX_HEAD = 4'd7,

        REQUEUE_FLOW = 4'd8,

        RX_WAIT = 4'd9,
        RECOVER_WAIT = 4'd10,

        UND = 'X
    } state_e;

    logic   [31:0]  count_reg;
    logic   [31:0]  count_next;

    localparam COUNT_CYCLES = 0;
    logic incr_count;
    logic reset_count;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        TX_NOTIF = 2'd1,
        META_TX_WAIT = 2'd2,
        UNDEF = 'X
    } meta_state_e;

(* mark_debug = "true" *)    state_e state_reg;
    state_e state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            meta_state_reg <= WAITING;
            count_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            meta_state_reg <= meta_state_next;
            count_reg <= count_next;
        end
    end

    always_comb begin
        if (reset_count) begin
            count_next = '0;
        end
        else if (incr_count) begin
            count_next = count_reg + 1'b1;
        end
        else begin
            count_next = count_reg;
        end
    end



    always_comb begin
        rx_app_noc_vrtoc_val = 1'b0;
        rx_app_noc_ctovr_rdy = 1'b0;
        
        msg_if_active_q_rd_req = 1'b0;
        msg_if_active_q_wr_req = 1'b0;

        ctrl_datap_store_flowid = 1'b0;
        ctrl_datap_store_notif = 1'b0;
        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_buf_mux_sel = HDR_VALUES;

        ctrl_rd_buf_req_val = 1'b0;
        ctrl_rd_buf_resp_data_rdy = 1'b0;

        notif_tx = 1'b0;

        reset_count = 1'b0;
        incr_count = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                reset_count = 1'b1;
                ctrl_datap_store_flowid = 1'b1;
                if (~active_q_msg_if_empty) begin
                    msg_if_active_q_rd_req = 1'b1;
                    state_next = REQ_HDR;
                end
                else begin
                    state_next = READY;
                end
            end
            REQ_HDR: begin
                rx_app_noc_vrtoc_val = 1'b1;
                ctrl_datap_buf_mux_sel = HDR_VALUES;

                if (noc_vrtoc_rx_app_rdy) begin
                    state_next = HDR_NOTIF;
                end
                else begin
                    state_next = REQ_HDR;
                end
            end
            HDR_NOTIF: begin
                ctrl_datap_store_notif = 1'b1;
                rx_app_noc_ctovr_rdy = 1'b1;

                if (noc_ctovr_rx_app_val) begin
                    state_next = RD_HDR;
                end
                else begin
                    state_next = HDR_NOTIF;
                end
            end
            RD_HDR: begin
                ctrl_rd_buf_req_val = 1'b1;
                ctrl_datap_buf_mux_sel = HDR_VALUES;
                if (rd_buf_ctrl_req_rdy) begin
                    state_next = HDR_RESP;
                end
                else begin
                    state_next = RD_HDR;
                end
            end
            HDR_RESP: begin
                ctrl_datap_store_hdr = 1'b1;
                ctrl_rd_buf_resp_data_rdy = 1'b1;
                if (rd_buf_ctrl_resp_data_val) begin
                    state_next = REQ_BODY;
                end
                else begin
                    state_next = HDR_RESP;
                end
            end
            REQ_BODY: begin
                rx_app_noc_vrtoc_val = 1'b1;
                ctrl_datap_buf_mux_sel = BODY_VALUES;

                if (noc_vrtoc_rx_app_rdy) begin
                    state_next = BODY_NOTIF;
                end
                else begin
                    state_next = REQ_BODY;
                end
            end
            BODY_NOTIF: begin
                ctrl_datap_store_notif = 1'b1;
                rx_app_noc_ctovr_rdy = 1'b1;

                if (noc_ctovr_rx_app_val) begin
                    notif_tx = 1'b1;
                    state_next = ADJUST_RX_HEAD;
                end
                else begin
                    state_next = BODY_NOTIF;
                end
            end
            ADJUST_RX_HEAD: begin
                rx_app_noc_vrtoc_val = 1'b1;
                ctrl_datap_buf_mux_sel = PTR_UPDATE;

                if (noc_vrtoc_rx_app_rdy) begin
                    state_next = REQUEUE_FLOW;
                end
                else begin
                    state_next = ADJUST_RX_HEAD;
                end
            end
            REQUEUE_FLOW: begin
                msg_if_active_q_wr_req = ~datap_ctrl_last_req;

                if (active_q_msg_if_wr_rdy) begin
                    state_next = RX_WAIT;
                end
                else begin
                    state_next = REQUEUE_FLOW;
                end
            end
            RX_WAIT: begin
                if ((meta_state_reg == META_TX_WAIT)) begin
                    state_next = RECOVER_WAIT;
                end
                else begin
                    state_next = RX_WAIT;
                end
            end
            RECOVER_WAIT: begin
                incr_count = 1'b1;
                if (count_reg == COUNT_CYCLES) begin
                    state_next = READY;
                end
                else begin
                    state_next = RECOVER_WAIT;
                end
            end
            default: begin
                rx_app_noc_vrtoc_val = 'X;
                rx_app_noc_ctovr_rdy = 'X;

                msg_if_active_q_rd_req = 'X;
                msg_if_active_q_wr_req = 'X;

                ctrl_datap_store_flowid = 'X;
                ctrl_datap_store_notif = 'X;
                ctrl_datap_store_hdr = 'X;
                ctrl_datap_buf_mux_sel = HDR_VALUES;

                ctrl_rd_buf_req_val = 'X;
                ctrl_rd_buf_resp_data_rdy = 'X;

                state_next = UND;
            end
        endcase
    end

    always_comb begin
        rx_if_tx_if_msg_val = 1'b0;

        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (notif_tx) begin
                    meta_state_next = TX_NOTIF;
                end
                else begin
                    meta_state_next = WAITING;
                end
            end
            TX_NOTIF: begin
                rx_if_tx_if_msg_val = 1'b1;
                if (tx_if_rx_if_msg_rdy) begin
                    meta_state_next = META_TX_WAIT;
                end
                else begin
                    meta_state_next = TX_NOTIF;
                end
            end
            META_TX_WAIT: begin
                if (state_reg == RX_WAIT) begin
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = META_TX_WAIT;
                end
            end
            default: begin
                rx_if_tx_if_msg_val = 'X;

                meta_state_next = UNDEF;
            end
        endcase
    end

endmodule
