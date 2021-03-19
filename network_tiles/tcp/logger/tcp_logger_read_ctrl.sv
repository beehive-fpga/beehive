`include "tcp_logger_read_defs.svh"
module tcp_logger_read_ctrl (
     input clk
    ,input rst

    ,input  logic                           noc_logger_read_val
    ,output logic                           logger_read_noc_rdy

    ,output logic                           logger_read_noc_val
    ,input  logic                           noc_logger_read_rdy
    
    ,output logic                           rd_req_logger_mem_val
    ,input  logic                           rd_req_logger_mem_rdy

    ,input  logic                           rd_resp_logger_mem_val
    ,output logic                           rd_resp_logger_mem_rdy

    ,output logic                           ctrl_datap_store_meta_flit
    ,output logic                           ctrl_datap_store_log_req
    ,output logic                           ctrl_datap_store_log_resp
    ,output logger_mux_out_sel              ctrl_datap_mux_out_sel
    ,output logger_data_mux_sel             ctrl_datap_data_mux_sel

    ,input  logic                           datap_ctrl_read_metadata
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        META_FLIT = 3'd1,
        REQ_BODY = 3'd2,
        RD_LOG = 3'd3,
        LOG_RESP = 3'd4,
        SEND_HDR = 3'd5, 
        SEND_META = 3'd6,
        SEND_RESP = 3'd7,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    assign ctrl_datap_data_mux_sel = datap_ctrl_read_metadata
                                    ? METADATA
                                    : MEM;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    assign rd_resp_logger_mem_rdy = 1'b1;

    always_comb begin
        logger_read_noc_rdy = 1'b0;
        logger_read_noc_val = 1'b0;

        rd_req_logger_mem_val = 1'b0;

        ctrl_datap_store_meta_flit = 1'b0;
        ctrl_datap_store_log_req = 1'b0;
        ctrl_datap_store_log_resp = 1'b0;
        ctrl_datap_mux_out_sel = tcp_logger_pkg::HDR;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                logger_read_noc_rdy = 1'b1;

                if (noc_logger_read_val) begin
                    state_next = META_FLIT;
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT: begin
                logger_read_noc_rdy = 1'b1;

                if (noc_logger_read_val) begin
                    ctrl_datap_store_meta_flit = 1'b1;
                    state_next = REQ_BODY;
                end
                else begin
                    state_next = META_FLIT;
                end
            end
            REQ_BODY: begin
                logger_read_noc_rdy = 1'b1;

                if (noc_logger_read_val) begin
                    ctrl_datap_store_log_req = 1'b1;
                    if (datap_ctrl_read_metadata) begin
                        state_next = SEND_HDR;
                    end
                    else begin
                        state_next = RD_LOG;
                    end
                end
                else begin
                    state_next = REQ_BODY;
                end
            end
            RD_LOG: begin
                rd_req_logger_mem_val = 1'b1;

                if (rd_req_logger_mem_rdy) begin
                    state_next = LOG_RESP;
                end
                else begin
                    state_next = RD_LOG;
                end
            end
            LOG_RESP: begin
                if (rd_resp_logger_mem_val) begin
                    ctrl_datap_store_log_resp = 1'b1;
                    state_next = SEND_HDR;
                end
                else begin
                    state_next = LOG_RESP;
                end
            end
            SEND_HDR: begin
                logger_read_noc_val = 1'b1;
                ctrl_datap_mux_out_sel = tcp_logger_pkg::HDR;
                if (noc_logger_read_rdy) begin
                    state_next = SEND_META;
                end
                else begin
                    state_next = SEND_HDR;
                end
            end
            SEND_META: begin
                logger_read_noc_val = 1'b1;
                ctrl_datap_mux_out_sel = tcp_logger_pkg::META;
                if (noc_logger_read_rdy) begin
                    state_next = SEND_RESP;
                end
                else begin
                    state_next = SEND_META;
                end
            end
            SEND_RESP: begin
                logger_read_noc_val = 1'b1;
                ctrl_datap_mux_out_sel = tcp_logger_pkg::DATA;
                if (noc_logger_read_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = SEND_RESP;
                end
            end
            default: begin
                logger_read_noc_rdy = 'X;
                logger_read_noc_val = 'X;

                rd_req_logger_mem_val = 'X;

                ctrl_datap_store_meta_flit = 'X;
                ctrl_datap_store_log_req = 'X;
                ctrl_datap_store_log_resp = 'X;
                ctrl_datap_mux_out_sel = tcp_logger_pkg::HDR;

                state_next = UND;
            end
        endcase
    end

endmodule
