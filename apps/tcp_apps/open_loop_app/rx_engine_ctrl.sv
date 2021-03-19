module rx_engine_ctrl 
import open_loop_pkg::*;
import rx_open_loop_pkg::*;
(
     input clk
    ,input rst
    
    ,input                                  recv_q_empty
    ,output logic                           recv_q_rd_req

    ,input  logic                           recv_q_full
    ,output logic                           recv_q_wr_req
    
    ,output logic                           rx_app_noc_vrtoc_val
    ,input  logic                           noc_vrtoc_rx_app_rdy

    ,input  logic                           noc_ctovr_rx_app_val
    ,output logic                           rx_app_noc_ctovr_rdy

    ,output logic                           rx_engine_ctrl_noc_val
    ,input  logic                           ctrl_noc_rx_engine_rdy

    ,input  logic                           ctrl_noc_rx_engine_val
    ,output logic                           rx_engine_ctrl_noc_rdy     
 
    ,output logic                           rx_app_state_rd_req_val
    ,input  logic                           app_state_rx_rd_req_rdy

    ,output logic                           rx_app_state_wr_req_val

    ,input  logic                           app_state_rx_rd_resp_val
    ,output logic                           rx_app_state_rd_resp_rdy

    ,output logic                           ctrl_rd_buf_req_val
    ,input  logic                           rd_buf_ctrl_req_rdy

    ,input  logic                           rd_buf_ctrl_resp_data_val
    ,output logic                           ctrl_rd_buf_resp_data_rdy

    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_store_app_state
    ,output logic                           ctrl_datap_store_notif
    ,output rx_out_mux_sel_e                ctrl_datap_out_mux_sel

    ,input  logic                           datap_ctrl_last_pkt
    ,input  logic                           datap_ctrl_last_data
    ,input  flag_e                          datap_ctrl_should_copy

    ,output rx_noc_sel_e                    noc_unit_sel
    ,input                                  setup_done
);

    typedef enum logic[3:0] {
        READY = 4'd0,

        RD_APP_STATE = 4'd1,
        WAIT_APP_STATE = 4'd2,

        RX_MSG_REQ = 4'd3,
        RX_MSG_NOTIF = 4'd4,

        RX_RD_MEM_REQ = 4'd5,
        PAYLOAD_RECV = 4'd6,

        BUMP_HEAD = 4'd7,

        UPDATE_FLOW = 4'd8,

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
        recv_q_rd_req = 1'b0;
        recv_q_wr_req = 1'b0;

        rx_app_state_wr_req_val = 1'b0;
        rx_app_state_rd_req_val = 1'b0;
        rx_app_state_rd_resp_rdy = 1'b0;

        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_store_app_state = 1'b0;
        ctrl_datap_store_notif = 1'b0;
        ctrl_datap_out_mux_sel = MSG_REQ;
        noc_unit_sel = TCP_WRITE;

        ctrl_rd_buf_req_val = 1'b0;
        ctrl_rd_buf_resp_data_rdy = 1'b0;

        rx_app_noc_vrtoc_val = 1'b0;
        rx_app_noc_ctovr_rdy = 1'b0;

        rx_engine_ctrl_noc_val = 1'b0;
        rx_engine_ctrl_noc_rdy = 1'b0;


        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_store_inputs = 1'b1;
                if (~recv_q_empty & setup_done) begin
                    recv_q_rd_req = 1'b1;
                    state_next = RD_APP_STATE;
                end
            end
            RD_APP_STATE: begin
                rx_app_state_rd_req_val = 1'b1;
                if (app_state_rx_rd_req_rdy) begin
                    state_next = WAIT_APP_STATE;
                end
            end
            WAIT_APP_STATE: begin
                rx_app_state_rd_resp_rdy = 1'b1;
                ctrl_datap_store_app_state = 1'b1;
                if (app_state_rx_rd_resp_val) begin
                    state_next = RX_MSG_REQ;
                end
            end
            RX_MSG_REQ: begin
                rx_engine_ctrl_noc_val = 1'b1;
                if (ctrl_noc_rx_engine_rdy) begin
                    state_next = RX_MSG_NOTIF;
                end
            end
            RX_MSG_NOTIF: begin
                rx_engine_ctrl_noc_rdy = 1'b1;
                ctrl_datap_store_notif = 1'b1;
                if (ctrl_noc_rx_engine_val) begin
                    if (datap_ctrl_should_copy == TRUE) begin
                        state_next = RX_RD_MEM_REQ;
                    end
                    else begin
                        state_next = BUMP_HEAD;
                    end
                end
            end
            RX_RD_MEM_REQ: begin
                noc_unit_sel = BUF_WRITE;
                ctrl_rd_buf_req_val = 1'b1;

                if (rd_buf_ctrl_req_rdy) begin
                    state_next = PAYLOAD_RECV;
                end
            end
            PAYLOAD_RECV: begin
                noc_unit_sel = BUF_WRITE;
                ctrl_rd_buf_resp_data_rdy = 1'b1;
                if (rd_buf_ctrl_resp_data_val) begin
                    if (datap_ctrl_last_data) begin
                        state_next = BUMP_HEAD;
                    end
                end
            end
            BUMP_HEAD: begin
                ctrl_datap_out_mux_sel = PTR_UPDATE;

                rx_engine_ctrl_noc_val = 1'b1;
                if (ctrl_noc_rx_engine_rdy) begin
                    state_next = UPDATE_FLOW;
                end
            end
            UPDATE_FLOW: begin
                rx_app_state_wr_req_val = 1'b1;
                if (~datap_ctrl_last_pkt) begin
                    recv_q_wr_req = 1'b1;
                end
                state_next = READY;
            end
            default: begin
                recv_q_rd_req = 'X;
                recv_q_wr_req = 'X;

                rx_app_state_rd_req_val = 'X;
                rx_app_state_rd_resp_rdy = 'X;

                ctrl_datap_store_inputs = 'X;
                ctrl_datap_store_app_state = 'X;
                ctrl_datap_store_notif = 'X;

                ctrl_rd_buf_req_val = 'X;
                ctrl_rd_buf_resp_data_rdy = 'X;

                rx_app_noc_vrtoc_val = 'X;
                rx_app_noc_ctovr_rdy = 'X;
        
                rx_engine_ctrl_noc_val = 'X;
                rx_engine_ctrl_noc_rdy = 'X;
                
                ctrl_datap_out_mux_sel = MSG_REQ;
                noc_unit_sel = TCP_WRITE;

                state_next = UND;
            end
        endcase
    end
endmodule
