`include "soc_defs.vh"
module eth_loopback_sim_top (
     input clk
    ,input rst
    
    ,input  logic                           mac_engine_rx_val
    ,input  logic   [`MAC_INTERFACE_W-1:0]  mac_engine_rx_data
    ,input  logic                           mac_engine_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   mac_engine_rx_padbytes
    ,output logic                           engine_mac_rx_rdy
    
    ,output logic                           engine_mac_tx_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  engine_mac_tx_data
    ,output logic                           engine_mac_tx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   engine_mac_tx_padbytes
    ,input  logic                           mac_engine_tx_rdy
);

    logic   [2:0]   count_reg;
    logic   [2:0]   count_next;
    logic           incr_count;

    assign engine_mac_tx_data = mac_engine_rx_data;
    assign engine_mac_tx_last = mac_engine_rx_last;
    assign engine_mac_tx_padbytes = mac_engine_rx_padbytes;

    typedef enum logic[1:0] {
        READY = 2'd0,
        WAIT = 2'd1,
        SEND = 2'd2,
        END = 2'd3
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            count_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            count_reg <= count_next;
        end
    end

    assign count_next = incr_count
                      ? count_reg + 1
                      : count_reg;

    always_comb begin
        incr_count = 0;

        engine_mac_rx_rdy = 1'b0;
        engine_mac_tx_val = 1'b0;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                if (mac_engine_rx_val) begin
                    incr_count = 1;
                    state_next = WAIT;
                end
                else begin
                    state_next = READY;
                end
            end
            WAIT: begin
                incr_count = 1;
                if (count_reg == '1) begin
                    engine_mac_rx_rdy = 1'b1;
                    state_next = SEND;
                end
                else begin
                    state_next = WAIT;
                end
            end
            SEND: begin
                engine_mac_tx_val = 1'b1;

                if (mac_engine_tx_rdy) begin
                    state_next = END;
                end
                else begin
                    state_next = SEND;
                end
            end
            END: begin
                state_next = END;
            end
        endcase
    end

    dummy_module dummy (
         .clk   (clk)
        ,.rst   (rst)
    );
    

endmodule
