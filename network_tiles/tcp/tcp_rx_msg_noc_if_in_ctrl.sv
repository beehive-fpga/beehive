`include "tcp_rx_tile_defs.svh"
module tcp_rx_msg_noc_if_in_ctrl (
     input clk
    ,input rst
    
    ,input  logic                           noc_tcp_rx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_tcp_rx_ptr_if_data
    ,output logic                           tcp_rx_ptr_if_noc_rdy
    
    ,output logic                           noc_if_poller_msg_req_val
    ,input  logic                           poller_noc_if_msg_req_rdy

    ,output logic                           app_rx_head_idx_wr_req_val
    ,input  logic                           rx_head_idx_app_wr_req_rdy

    ,output logic                           app_rx_free_req_val
    ,input  logic                           rx_free_app_req_rdy

    ,output logic                           ctrl_datap_store_hdr_flit
);

    typedef enum logic [2:0] {
        READY = 3'd0,
        RX_REQ_MSG = 3'd1,
        RX_ADJUST_PTR = 3'd2,
        FREE_BUF = 3'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;
    
    beehive_noc_hdr_flit hdr_flit_cast;

    assign hdr_flit_cast = noc_tcp_rx_ptr_if_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        tcp_rx_ptr_if_noc_rdy = 1'b0;
        
        noc_if_poller_msg_req_val = 1'b0;

        app_rx_head_idx_wr_req_val = 1'b0;

        app_rx_free_req_val = 1'b0;

        ctrl_datap_store_hdr_flit = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                tcp_rx_ptr_if_noc_rdy  = 1'b1;
                ctrl_datap_store_hdr_flit = 1'b1;
                if (noc_tcp_rx_ptr_if_val) begin
                    if (hdr_flit_cast.core.core.msg_type == TCP_RX_MSG_REQ) begin
                        state_next = RX_REQ_MSG;
                    end
                    else begin
                        state_next = RX_ADJUST_PTR;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            RX_REQ_MSG: begin
                noc_if_poller_msg_req_val = 1'b1;
                if (poller_noc_if_msg_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = RX_REQ_MSG;
                end
            end
            RX_ADJUST_PTR: begin
                app_rx_head_idx_wr_req_val = 1'b1;

                if (rx_head_idx_app_wr_req_rdy) begin
                    state_next = FREE_BUF;
                end
                else begin
                    state_next = RX_ADJUST_PTR;
                end
            end
            FREE_BUF: begin
                app_rx_free_req_val = 1'b1;

                if (rx_free_app_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = FREE_BUF;
                end
            end
            default: begin
                tcp_rx_ptr_if_noc_rdy = 'X;
                
                noc_if_poller_msg_req_val = 'X;

                app_rx_head_idx_wr_req_val = 'X;

                app_rx_free_req_val = 'X;

                state_next = state_reg;
            end
        endcase
    end
endmodule
