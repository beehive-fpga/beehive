`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager_tx_ctrl (
     input clk
    ,input rst

    ,input                                  noc0_ctovr_ip_rewrite_manager_tx_val
    ,output logic                           ip_rewrite_manager_tx_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_manager_tx_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_ip_rewrite_manager_tx_rdy

    ,input  logic                           in_ctrl_out_ctrl_resp_val
    ,output logic                           out_ctrl_in_ctrl_resp_rdy
    
    ,output logic                           out_ctrl_out_datap_store_inputs
    ,output ip_manager_tx_noc_sel           out_ctrl_out_datap_noc_sel
    ,output logic                           out_ctrl_out_datap_store_notif
    ,output ip_manager_tx_tile_sel          out_ctrl_out_datap_tile_sel

    ,output logic                           out_ctrl_wr_tx_buf_req_val
    ,input  logic                           wr_tx_buf_out_ctrl_req_rdy

    ,output logic                           out_ctrl_wr_tx_buf_req_data_val
    ,output logic                           out_ctrl_wr_tx_buf_req_data_last
    ,input  logic                           wr_tx_buf_out_ctrl_req_data_rdy

    ,input  logic                           wr_tx_buf_out_ctrl_done
    ,output logic                           out_ctrl_wr_tx_buf_done_rdy

);

    typedef enum logic[3:0] {
        WAITING_INPUT = 4'd0,
        TX_SEND_REQ = 4'd1,
        TX_WAIT_REQ_NOTIF = 4'd2,
        SEND_WR_REQ = 4'd3,
        SEND_WR_DATA = 4'd4,
        WAIT_RESP_DATA = 4'd5,
        ADJUST_TX_TAIL = 4'd7,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= WAITING_INPUT;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        ip_rewrite_manager_tx_noc0_ctovr_rdy = 1'b0;
        ip_rewrite_manager_tx_noc0_vrtoc_val = 1'b0;

        out_ctrl_in_ctrl_resp_rdy = 1'b0;

        out_ctrl_out_datap_store_inputs = 1'b0;
        out_ctrl_out_datap_store_notif = 1'b0;
        out_ctrl_out_datap_noc_sel = TCP_TX_REQ;
        out_ctrl_out_datap_tile_sel = TCP_UPDATE_RX_HEAD_PTR;

        out_ctrl_wr_tx_buf_req_val = 1'b0;
        out_ctrl_wr_tx_buf_req_data_val = 1'b0;
        out_ctrl_wr_tx_buf_req_data_last = 1'b0;

        state_next = state_reg;
        case (state_reg)
            WAITING_INPUT: begin
                out_ctrl_in_ctrl_resp_rdy = 1'b1;
                if (in_ctrl_out_ctrl_resp_val) begin
                    out_ctrl_out_datap_store_inputs = 1'b1;
                    state_next = TX_SEND_REQ;
                end
            end
            TX_SEND_REQ: begin
                out_ctrl_out_datap_noc_sel = TCP_TX_REQ;
                ip_rewrite_manager_tx_noc0_vrtoc_val = 1'b1;

                if (noc0_vrtoc_ip_rewrite_manager_tx_rdy) begin
                    state_next = TX_WAIT_REQ_NOTIF;
                end
            end
            TX_WAIT_REQ_NOTIF: begin
                ip_rewrite_manager_tx_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_ip_rewrite_manager_tx_val) begin
                    out_ctrl_out_datap_store_notif = 1'b1;
                    state_next = SEND_WR_REQ;
                end
            end
            SEND_WR_REQ: begin
                out_ctrl_wr_tx_buf_req_val = 1'b1;
                if (wr_tx_buf_out_ctrl_req_rdy) begin
                    state_next = SEND_WR_DATA;
                end
            end
            SEND_WR_DATA: begin
                out_ctrl_wr_tx_buf_req_data_val = 1'b1;
                out_ctrl_wr_tx_buf_req_data_last = 1'b1;
                if (wr_tx_buf_out_ctrl_req_data_rdy) begin
                    state_next = WAIT_RESP_DATA;
                end
            end
            WAIT_RESP_DATA: begin
                out_ctrl_wr_tx_buf_done_rdy = 1'b1;
                if (wr_tx_buf_out_ctrl_done) begin
                    state_next = ADJUST_TX_TAIL;
                end
            end
            ADJUST_TX_TAIL: begin
                ip_rewrite_manager_tx_noc0_vrtoc_val = 1'b1;
                out_ctrl_out_datap_noc_sel = TCP_PTR_UPDATE;
                out_ctrl_out_datap_tile_sel = TCP_UPDATE_TX_TAIL_PTR;
                if (noc0_vrtoc_ip_rewrite_manager_tx_rdy) begin
                    state_next = WAITING_INPUT;
                end
            end
            default: begin
                ip_rewrite_manager_tx_noc0_ctovr_rdy = 'X;
                ip_rewrite_manager_tx_noc0_vrtoc_val = 'X;

                out_ctrl_in_ctrl_resp_rdy = 'X;

                out_ctrl_out_datap_store_inputs = 'X;
                out_ctrl_out_datap_store_notif = 'X;

                out_ctrl_wr_tx_buf_req_val = 'X;
                out_ctrl_wr_tx_buf_req_data_val = 'X;
                out_ctrl_wr_tx_buf_req_data_last = 'X;
                
                out_ctrl_out_datap_noc_sel = TCP_TX_REQ;
                out_ctrl_out_datap_tile_sel = TCP_UPDATE_RX_HEAD_PTR;

                state_next = UND;
            end
        endcase
    end

endmodule
