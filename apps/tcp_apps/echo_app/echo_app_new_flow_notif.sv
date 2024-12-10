`include "echo_app_defs.svh"
module echo_app_new_flow_notif (
     input clk
    ,input rst
    
    ,input  logic                           noc0_ctovr_rx_notif_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rx_notif_data
    ,output logic                           rx_notif_noc0_ctovr_rdy

    ,output logic                           rx_notif_active_q_wr_req
    ,output logic   [FLOWID_W-1:0]          rx_notif_active_q_wr_data
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        WRITE_FIFO = 2'd1,
        UND = 'X
    } state_e;

    tcp_noc_hdr_flit hdr_flit_cast;

    state_e state_reg;
    state_e state_next;

    logic   [FLOWID_W-1:0]    flowid_reg;
    logic   [FLOWID_W-1:0]    flowid_next;

    logic   store_flowid;


    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY; 
            flowid_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            flowid_reg <= flowid_next;
        end
    end

    assign hdr_flit_cast = noc0_ctovr_rx_notif_data;

    assign flowid_next = store_flowid
                        ? hdr_flit_cast.inner.flowid
                        : flowid_reg;

    assign rx_notif_active_q_wr_data = flowid_reg;

    always_comb begin
        rx_notif_noc0_ctovr_rdy = 1'b0;

        rx_notif_active_q_wr_req = 1'b0;

        store_flowid = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                store_flowid = 1'b1;
                rx_notif_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_rx_notif_val) begin
                    state_next = WRITE_FIFO;
                end
                else begin
                    state_next = READY;
                end
            end
            WRITE_FIFO: begin
                rx_notif_active_q_wr_req = 1'b1;
                state_next = READY;
            end
            default: begin
                rx_notif_noc0_ctovr_rdy = 'X;

                rx_notif_active_q_wr_req = 'X;

                store_flowid = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
