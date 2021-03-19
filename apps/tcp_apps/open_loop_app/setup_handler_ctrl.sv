module setup_handler_ctrl 
import open_loop_pkg::*;
import setup_open_loop_pkg::*;
import tcp_pkg::*;
(
     input clk
    ,input rst

    ,input  logic                               setup_q_handler_empty
    ,output logic                               handler_setup_q_rd_req
    
    ,output logic                               setup_noc_vrtoc_val
    ,input  logic                               noc_vrtoc_setup_rdy
    
    ,input  logic                               noc_ctovr_setup_val
    ,output logic                               setup_noc_ctovr_rdy    
    
    ,output logic                               setup_ptr_if_ctrl_noc_val
    ,input  logic                               ctrl_noc_setup_ptr_if_rdy
    
    ,input  logic                               ctrl_noc_setup_ptr_if_val
    ,output logic                               setup_ptr_if_ctrl_noc_rdy

    ,output logic                               setup_rd_buf_req_val
    ,input  logic                               rd_buf_setup_req_rdy

    ,input  logic                               rd_buf_setup_resp_val
    ,output logic                               setup_rd_buf_resp_rdy
    
    ,output logic                               setup_wr_buf_req_val
    ,input  logic                               wr_buf_setup_req_rdy

    ,output logic                               setup_wr_buf_req_data_val
    ,input  logic                               wr_buf_setup_req_data_rdy

    ,input  logic                               wr_buf_setup_req_done
    ,output logic                               setup_wr_buf_done_rdy

    ,output logic                               setup_app_mem_wr_req

    ,output logic                               setup_send_loop_q_wr_req
    
    ,output logic                               setup_recv_loop_q_wr_req

    ,output logic                               ctrl_datap_store_flowid
    ,output logic                               ctrl_datap_store_notif
    ,output logic                               ctrl_datap_store_hdr
    ,output buf_mux_sel_e                       ctrl_datap_buf_mux_sel
    ,output logic                               ctrl_datap_send_setup_confirm

    ,output logic                               ctrl_datap_save_conn
    ,output logic                               ctrl_datap_incr_bytes_written
    ,output logic                               ctrl_datap_reset_bytes_written

    ,input  client_dir_e                        datap_ctrl_dir
    ,input                                      datap_ctrl_last_conn_recv
    ,input  flag_e                              datap_ctrl_should_copy
    ,input                                      datap_ctrl_last_line

    ,output setup_noc_sel_e                     noc_mux_sel
    ,output logic                               setup_done
);

    localparam BUFFER_BYTES = 1 << TX_PAYLOAD_PTR_W;


    typedef enum logic[3:0] {
        READY = 4'd0,
        REQ_HDR = 4'd1,
        GET_NOTIF = 4'd2,
        READ_HDR = 4'd3,
        GET_HDR = 4'd4,
        UPDATE_PTRS = 4'd8,
        SEND_SETUP_CONFIRM = 4'd9,

        WAIT_NOTIF = 4'd6,
        PROCESS_SETUP = 4'd5,

        PUSH_TO_UNIT = 4'd7,

        PRELOAD_BUFFER = 4'd11,
        PRELOAD_BUFFER_COPY = 4'd12,
        PRELOAD_BUFFER_WAIT = 4'd13,

        DONE = 4'd10,

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
        handler_setup_q_rd_req = 1'b0;

        ctrl_datap_store_flowid = 1'b0;
        ctrl_datap_store_notif = 1'b0;
        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_save_conn = 1'b0;
        ctrl_datap_send_setup_confirm = 1'b0;

        setup_app_mem_wr_req = 1'b0;

        setup_noc_vrtoc_val = 1'b0;
        setup_noc_ctovr_rdy = 1'b0;

        setup_ptr_if_ctrl_noc_val = 1'b0;
        setup_ptr_if_ctrl_noc_rdy = 1'b0;

        setup_rd_buf_req_val = 1'b0;
        setup_rd_buf_resp_rdy = 1'b0;

        setup_wr_buf_req_val = 1'b0;
        setup_wr_buf_req_data_val = 1'b0;
        setup_wr_buf_done_rdy = 1'b0;

        setup_send_loop_q_wr_req = 1'b0;
        setup_recv_loop_q_wr_req = 1'b0;

        ctrl_datap_buf_mux_sel = HDR_REQ;

        noc_mux_sel = TCP_WRITE;

        setup_done = 1'b0;

        ctrl_datap_incr_bytes_written = 1'b0;
        ctrl_datap_reset_bytes_written = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_store_flowid = 1'b1;
                if (~setup_q_handler_empty) begin
                    handler_setup_q_rd_req = 1'b1;
                    state_next = REQ_HDR;
                end
            end
            REQ_HDR: begin
                setup_ptr_if_ctrl_noc_val = 1'b1;
                ctrl_datap_buf_mux_sel = HDR_REQ;

                if (ctrl_noc_setup_ptr_if_rdy) begin
                    state_next = GET_NOTIF;
                end
            end
            GET_NOTIF: begin
                setup_ptr_if_ctrl_noc_rdy = 1'b1;
                ctrl_datap_store_notif = 1'b1;

                if (ctrl_noc_setup_ptr_if_val) begin
                    state_next = READ_HDR;
                end
            end
            READ_HDR: begin
                setup_rd_buf_req_val = 1'b1;
                noc_mux_sel = BUF_READ;

                if (rd_buf_setup_req_rdy) begin
                    state_next = GET_HDR;
                end
            end
            GET_HDR: begin
                ctrl_datap_store_hdr = 1'b1;
                setup_rd_buf_resp_rdy = 1'b1;
                noc_mux_sel = BUF_READ;

                if (rd_buf_setup_resp_val) begin
                    state_next = UPDATE_PTRS;
                end
            end
            UPDATE_PTRS: begin
                setup_ptr_if_ctrl_noc_val = 1'b1;
                ctrl_datap_buf_mux_sel = PTR_UPDATE;

                if (ctrl_noc_setup_ptr_if_rdy) begin
                    state_next = SEND_SETUP_CONFIRM;
                end
            end
            SEND_SETUP_CONFIRM: begin
                setup_send_loop_q_wr_req = 1'b1;
                ctrl_datap_send_setup_confirm = 1'b1;
                state_next = WAIT_NOTIF;
            end
            WAIT_NOTIF: begin
                if (~setup_q_handler_empty) begin
                    handler_setup_q_rd_req = 1'b1;
                    ctrl_datap_save_conn = 1'b1;
                    state_next = PROCESS_SETUP;
                end
            end
            PROCESS_SETUP: begin
                setup_app_mem_wr_req = 1'b1;
                state_next = PUSH_TO_UNIT;
            end
            PUSH_TO_UNIT: begin
                state_next = WAIT_NOTIF;
                if (datap_ctrl_dir == SEND) begin
                    setup_recv_loop_q_wr_req = 1'b1;
                end
                else begin
                    setup_send_loop_q_wr_req = 1'b1;
                end
                    
                if ((datap_ctrl_should_copy == FALSE) && (datap_ctrl_dir == RECV)) begin
                    state_next = PRELOAD_BUFFER;
                end
                else if (datap_ctrl_last_conn_recv) begin
                    state_next = DONE;
                end
                else begin
                    state_next = WAIT_NOTIF;
                end
            end
            PRELOAD_BUFFER: begin
                noc_mux_sel = BUF_WRITE;
                setup_wr_buf_req_val = 1'b1;
                ctrl_datap_reset_bytes_written = 1'b1;
                if (wr_buf_setup_req_rdy) begin
                    state_next = PRELOAD_BUFFER_COPY;
                end
            end
            PRELOAD_BUFFER_COPY: begin
                noc_mux_sel = BUF_WRITE;
                setup_wr_buf_req_data_val = 1'b1;
                if (wr_buf_setup_req_data_rdy) begin
                    ctrl_datap_incr_bytes_written = 1'b1;
                    if (datap_ctrl_last_line) begin
                        state_next = PRELOAD_BUFFER_WAIT;
                    end
                end
            end
            PRELOAD_BUFFER_WAIT: begin
                noc_mux_sel = BUF_WRITE;
                setup_wr_buf_done_rdy = 1'b1;
                if (wr_buf_setup_req_done) begin
                    if (datap_ctrl_last_conn_recv) begin
                        state_next = DONE;
                    end
                    else begin
                        state_next = WAIT_NOTIF;
                    end
                end
            end
            DONE: begin
                setup_done = 1'b1;
            end
            default: begin
                handler_setup_q_rd_req = 'X;

                ctrl_datap_store_flowid = 'X;
                ctrl_datap_store_notif = 'X;
                ctrl_datap_store_hdr = 'X;
                ctrl_datap_save_conn = 'X;

                ctrl_datap_incr_bytes_written = 'X;
                ctrl_datap_reset_bytes_written = 'X;

                setup_app_mem_wr_req = 'X;

                setup_noc_vrtoc_val = 'X;
                setup_noc_ctovr_rdy = 'X;
        
                setup_ptr_if_ctrl_noc_val = 'X;
                setup_ptr_if_ctrl_noc_rdy = 'X;

                setup_rd_buf_req_val = 'X;
                setup_rd_buf_resp_rdy = 'X;

                setup_send_loop_q_wr_req = 'X;

                ctrl_datap_buf_mux_sel = HDR_REQ;

                noc_mux_sel = TCP_WRITE;

                state_next = UND;
            end
        endcase
    end
endmodule
