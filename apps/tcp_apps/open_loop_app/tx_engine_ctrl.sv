module tx_engine_ctrl 
import open_loop_pkg::*;
import tx_open_loop_pkg::*;
(
     input clk
    ,input rst

    ,input                                  send_q_empty
    ,input  send_q_struct                   send_q_rd_data
    ,output logic                           send_q_rd_req

    ,output logic                           send_q_wr_req
    ,output send_q_struct                   send_q_wr_data
    ,input  logic                           send_q_full
    
    ,output logic                           tx_app_noc_vrtoc_val
    ,input  logic                           noc_vrtoc_tx_app_rdy

    ,input  logic                           noc_ctovr_tx_app_val
    ,output logic                           tx_app_noc_ctovr_rdy     
    
    ,output logic                           tx_ptr_if_ctrl_noc_val
    ,input  logic                           ctrl_noc_tx_ptr_if_rdy

    ,input  logic                           ctrl_noc_tx_ptr_if_val
    ,output logic                           tx_ptr_if_ctrl_noc_rdy
    
    ,output logic                           ctrl_wr_buf_req_val
    ,input  logic                           wr_buf_ctrl_req_rdy

    ,output logic                           ctrl_wr_buf_req_data_val
    ,input  logic                           wr_buf_ctrl_req_data_rdy

    ,input  logic                           wr_buf_ctrl_req_done
    ,output logic                           ctrl_wr_buf_done_rdy

    ,output logic                           tx_app_state_rd_req_val
    ,input  logic                           app_state_tx_rd_req_rdy
    ,output logic                           tx_app_state_wr_req_val

    ,input  logic                           app_state_tx_rd_resp_val
    ,output logic                           tx_app_state_rd_resp_rdy

    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_store_app_state
    ,output logic                           ctrl_datap_decr_bytes_left
    ,output logic                           ctrl_datap_store_notif
    ,output tx_out_mux_sel_e                ctrl_datap_out_mux_sel
    
    ,input  logic                           datap_ctrl_last_wr
    ,input  logic                           datap_ctrl_last_pkt
    ,input  flag_e                          datap_ctrl_should_copy
    
    ,output tx_noc_sel_e                    noc_unit_sel
    ,input                                  setup_done
);

    typedef enum logic [3:0] {
        READY = 4'd0,

        RD_APP_STATE = 4'd8,
        WAIT_APP_STATE = 4'd9,

        TX_MSG_REQ = 4'd1,
        TX_MSG_NOTIF = 4'd2,

        TX_WR_MEM_REQ = 4'd3,
        PAYLOAD_COPY = 4'd4, 
        WAIT_WR_RESP = 4'd5,

        BUMP_TAIL = 4'd6,

        UPDATE_FLOW = 4'd7,

        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    send_q_struct send_q_data_reg;
    send_q_struct send_q_data_next;

    always_comb begin
        send_q_wr_data = '0;
        send_q_wr_data.cmd = BENCH;
        send_q_wr_data.flowid = send_q_data_reg.flowid;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            send_q_data_reg <= send_q_data_next;
        end
    end

    always_comb begin
        send_q_rd_req = 1'b0;
        send_q_wr_req = 1'b0;

        noc_unit_sel = TCP_WRITE; 

        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_store_app_state = 1'b0;
        ctrl_datap_out_mux_sel = MSG_REQ;
        ctrl_datap_store_notif = 1'b0;
        ctrl_datap_decr_bytes_left = 1'b0;

        ctrl_wr_buf_req_val = 1'b0;
        ctrl_wr_buf_req_data_val = 1'b0;
        ctrl_wr_buf_done_rdy = 1'b0;

        tx_app_noc_vrtoc_val = 1'b0;
        tx_app_noc_ctovr_rdy = 1'b0;

        tx_ptr_if_ctrl_noc_val = 1'b0;
        tx_ptr_if_ctrl_noc_rdy = 1'b0;
    
        tx_app_state_rd_req_val = 1'b0;
        tx_app_state_wr_req_val = 1'b0;

        tx_app_state_rd_resp_rdy = 1'b0;

        send_q_data_next = send_q_data_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                send_q_data_next = send_q_rd_data;
                if (~send_q_empty) begin
                    ctrl_datap_store_inputs = 1'b1;
                    if (send_q_rd_data.cmd == BENCH) begin
                        if (setup_done) begin
                            send_q_rd_req = 1'b1;
                            state_next = RD_APP_STATE;
                        end
                    end
                    else begin
                        send_q_rd_req = 1'b1;
                        state_next = TX_MSG_REQ;
                    end
                end
            end
            RD_APP_STATE: begin
                tx_app_state_rd_req_val = 1'b1;
                state_next = WAIT_APP_STATE;
            end
            WAIT_APP_STATE: begin
                tx_app_state_rd_resp_rdy = 1'b1;
                ctrl_datap_store_app_state = 1'b1;

                if (app_state_tx_rd_resp_val) begin
                    state_next = TX_MSG_REQ;
                end
            end
            TX_MSG_REQ: begin
                ctrl_datap_out_mux_sel = MSG_REQ;

                tx_ptr_if_ctrl_noc_val = 1'b1;

                if (ctrl_noc_tx_ptr_if_rdy) begin
                    state_next = TX_MSG_NOTIF;
                end
            end
            TX_MSG_NOTIF: begin
                ctrl_datap_store_notif = 1'b1;
                tx_ptr_if_ctrl_noc_rdy = 1'b1;

                if (ctrl_noc_tx_ptr_if_val) begin
                    tx_app_state_rd_resp_rdy = 1'b1;
                    if ((send_q_data_reg.cmd == BENCH)  & (datap_ctrl_should_copy == FALSE)) begin
                        state_next = BUMP_TAIL;
                    end
                    else begin
                        state_next = TX_WR_MEM_REQ;
                    end
                end
            end
            TX_WR_MEM_REQ: begin
                noc_unit_sel = BUF_WRITE;
                ctrl_wr_buf_req_val = 1'b1;
                if (wr_buf_ctrl_req_rdy) begin
                    state_next = PAYLOAD_COPY;
                end
            end
            PAYLOAD_COPY: begin
                noc_unit_sel = BUF_WRITE;
                ctrl_wr_buf_req_data_val = 1'b1;
                if (wr_buf_ctrl_req_data_rdy) begin
                    ctrl_datap_decr_bytes_left = 1'b1;
                    if (datap_ctrl_last_wr) begin
                        state_next = WAIT_WR_RESP;
                    end
                end
            end
            WAIT_WR_RESP: begin
                noc_unit_sel = BUF_WRITE;
                ctrl_wr_buf_done_rdy = 1'b1;
                if (wr_buf_ctrl_req_done) begin
                    state_next = BUMP_TAIL;
                end
            end
            BUMP_TAIL: begin
                tx_ptr_if_ctrl_noc_val = 1'b1;
                ctrl_datap_out_mux_sel = PTR_UPDATE;

                if (ctrl_noc_tx_ptr_if_rdy) begin
                    state_next = UPDATE_FLOW;
                end
            end
            UPDATE_FLOW: begin
                if (send_q_data_reg.cmd == BENCH) begin
                    tx_app_state_wr_req_val = 1'b1;
                    if (~datap_ctrl_last_pkt) begin
                        send_q_wr_req = 1'b1;
                    end
                end
                state_next = READY;
            end
            default: begin
                send_q_rd_req = 'X;
                send_q_wr_req = 'X;

                ctrl_datap_store_inputs = 'X;
                ctrl_datap_store_notif = 'X;
                ctrl_datap_decr_bytes_left = 'X;

                ctrl_wr_buf_req_val = 'X;
                ctrl_wr_buf_req_data_val = 'X;
                ctrl_wr_buf_done_rdy = 'X;

                tx_app_noc_vrtoc_val = 'X;
                tx_app_noc_ctovr_rdy = 'X;
        
                tx_ptr_if_ctrl_noc_val = 'X;
                tx_ptr_if_ctrl_noc_rdy = 'X;
        
                tx_app_state_rd_req_val = 'X;
                tx_app_state_wr_req_val = 'X;

                tx_app_state_rd_resp_rdy = 'X;
                
                noc_unit_sel = TCP_WRITE; 
                ctrl_datap_out_mux_sel = MSG_REQ;

                send_q_data_next = 'X;
                state_next = UND;
            end
        endcase
    end
endmodule
