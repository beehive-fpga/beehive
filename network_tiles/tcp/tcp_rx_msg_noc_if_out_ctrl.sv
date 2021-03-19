module tcp_rx_msg_noc_if_out_ctrl (
     input clk
    ,input rst
    
    ,output logic                           tcp_rx_ptr_if_noc_val
    ,input  logic                           noc_tcp_rx_ptr_if_rdy
    
    ,input  logic                           poller_msg_noc_if_meta_val
    ,output logic                           noc_if_poller_msg_meta_rdy

    ,output logic                           ctrl_datap_store_inputs
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        HDR_FLIT = 2'd1,
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
        noc_if_poller_msg_meta_rdy = 1'b0;
        ctrl_datap_store_inputs = 1'b0;
        tcp_rx_ptr_if_noc_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                noc_if_poller_msg_meta_rdy = 1'b1;
                ctrl_datap_store_inputs = 1'b1;
                if (poller_msg_noc_if_meta_val) begin
                    state_next = HDR_FLIT;
                end
                else begin
                    state_next = READY;
                end
            end
            HDR_FLIT: begin
                tcp_rx_ptr_if_noc_val = 1'b1;
                if (noc_tcp_rx_ptr_if_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = HDR_FLIT;
                end
            end
            default: begin
                noc_if_poller_msg_meta_rdy = 'X;
                ctrl_datap_store_inputs = 'X;
                tcp_rx_ptr_if_noc_val = 'X;

                state_next = state_reg;
            end
        endcase
    end


endmodule
