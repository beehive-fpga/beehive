module simple_log_no_noc_reader_ctrl (
     input clk
    ,input rst
    
    ,input  logic                               udp_log_rx_hdr_val
    ,output logic                               log_udp_rx_hdr_rdy

    ,input  logic                               udp_log_rx_data_val
    ,output logic                               log_udp_rx_data_rdy
    
    ,output logic                               log_udp_tx_hdr_val
    ,input                                      udp_log_tx_hdr_rdy

    ,output logic                               log_udp_tx_data_val
    ,output logic                               log_udp_tx_last
    ,input  logic                               udp_log_tx_data_rdy

    ,output logic                               log_rd_req_val

    ,input  logic                               log_rd_resp_val

    ,output logic                               ctrl_datap_store_hdr
    ,output logic                               ctrl_datap_store_req
    ,output logic                               ctrl_datap_store_log_resp

    ,input  logic                               datap_ctrl_rd_meta
);

    typedef enum logic [2:0] {
        READY = 3'b0,
        STORE_REQ = 3'd1,
        RD_LOG = 3'd2,
        SAVE_LOG_RD = 3'd3,
        HDR_OUT = 3'd4,
        RESP_OUT = 3'd5,
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
        log_udp_rx_hdr_rdy = 1'b0;
        log_udp_rx_data_rdy = 1'b0;
        log_udp_tx_hdr_val = 1'b0;
        log_udp_tx_data_val = 1'b0;
        log_udp_tx_last = 1'b0;

        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_store_req = 1'b0;
        ctrl_datap_store_log_resp = 1'b0;

        log_rd_req_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                log_udp_rx_hdr_rdy = 1'b1;
                ctrl_datap_store_hdr = 1'b1;
                if (udp_log_rx_hdr_val) begin
                    state_next = STORE_REQ;
                end
                else begin
                    state_next = READY;
                end
            end
            STORE_REQ: begin
                log_udp_rx_data_rdy = 1'b1;
                ctrl_datap_store_req = 1'b1;
                if (udp_log_rx_data_val) begin
                    state_next = RD_LOG;
                end
                else begin
                    state_next = STORE_REQ;
                end
            end
            RD_LOG: begin
                log_rd_req_val = ~datap_ctrl_rd_meta;
                state_next = SAVE_LOG_RD;
            end
            SAVE_LOG_RD: begin
                ctrl_datap_store_log_resp = 1'b1;
                if (~datap_ctrl_rd_meta) begin
                    if (log_rd_resp_val) begin
                        state_next = HDR_OUT;
                    end
                    else begin
                        state_next = SAVE_LOG_RD;
                    end
                end
                else begin
                    state_next = HDR_OUT;
                end
            end
            HDR_OUT: begin
                log_udp_tx_hdr_val = 1'b1;
                if (udp_log_tx_hdr_rdy) begin
                    state_next = RESP_OUT;
                end
                else begin
                    state_next = HDR_OUT;
                end
            end
            RESP_OUT: begin
                log_udp_tx_data_val = 1'b1;
                log_udp_tx_last = 1'b1;
                if (udp_log_tx_data_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = RESP_OUT;
                end
            end
            default: begin
                log_udp_rx_hdr_rdy = 'X;
                log_udp_rx_data_rdy = 'X;
                log_udp_tx_hdr_val = 'X;
                log_udp_tx_data_val = 'X;
                log_udp_tx_last = 'X;

                ctrl_datap_store_hdr = 'X;
                ctrl_datap_store_req = 'X;
                ctrl_datap_store_log_resp = 'X;

                log_rd_req_val = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
