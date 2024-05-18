`include "tcp_tx_tile_defs.svh"
module tcp_tx_msg_noc_if_in_ctrl (
     input clk
    ,input rst
    
    ,input  logic                           noc_tcp_tx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_tcp_tx_ptr_if_data
    ,output logic                           tcp_tx_ptr_if_noc_rdy
    
    ,output logic                           noc_if_poller_msg_req_val
    ,input  logic                           poller_noc_if_msg_req_rdy
    
    ,output logic                           app_tail_ptr_tx_wr_req_val
    ,input                                  tail_ptr_app_tx_wr_req_rdy
    
    ,output logic                           app_sched_update_val
    ,input  logic                           sched_app_update_rdy

    ,output logic                           ctrl_datap_store_hdr_flit
);

    typedef enum logic [2:0] {
        READY = 3'd0,
        TX_REQ_MSG = 3'd1,
        TX_ADJUST_PTR = 3'd2,
        TX_KICK_SCHED = 3'd3,
        UND = 'X
    } state_e;

    beehive_noc_hdr_flit    hdr_flit_cast;

    state_e state_reg;
    state_e state_next;

    assign hdr_flit_cast = noc_tcp_tx_ptr_if_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        tcp_tx_ptr_if_noc_rdy = 1'b0;

        noc_if_poller_msg_req_val = 1'b0;

        app_tail_ptr_tx_wr_req_val = 1'b0;

        app_sched_update_val = 1'b0;

        ctrl_datap_store_hdr_flit = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                tcp_tx_ptr_if_noc_rdy = 1'b1;
                ctrl_datap_store_hdr_flit = 1'b1;
                if (noc_tcp_tx_ptr_if_val) begin
                    if (hdr_flit_cast.core.core.msg_type == TCP_TX_MSG_REQ) begin
                        state_next = TX_REQ_MSG;
                    end
                    else begin
                        state_next = TX_ADJUST_PTR;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            TX_REQ_MSG: begin
                noc_if_poller_msg_req_val = 1'b1;
                if (poller_noc_if_msg_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = TX_REQ_MSG;
                end
            end
            TX_ADJUST_PTR: begin
                app_tail_ptr_tx_wr_req_val = 1'b1;

                if (tail_ptr_app_tx_wr_req_rdy) begin
                    state_next = TX_KICK_SCHED;
                end
                else begin
                    state_next = TX_ADJUST_PTR;
                end
            end
            TX_KICK_SCHED: begin
                app_sched_update_val = 1'b1;
                if (sched_app_update_rdy) begin
                    state_next = READY;
                end
            end
            default: begin
                tcp_tx_ptr_if_noc_rdy = 'X;

                noc_if_poller_msg_req_val = 'X;

                app_tail_ptr_tx_wr_req_val = 'X;

                ctrl_datap_store_hdr_flit = 'X;

                state_next = UND;
            end
        endcase
    end

    


    
endmodule
