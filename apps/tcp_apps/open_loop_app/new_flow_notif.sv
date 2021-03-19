`include "noc_defs.vh"
module new_flow_notif 
import tcp_pkg::*;
import beehive_tcp_msg::*;
(
     input clk
    ,input rst
    
    ,input  logic                           noc_ctovr_notif_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_notif_data
    ,output logic                           notif_noc_ctovr_rdy

    ,output logic                           notif_setup_q_wr_req
    ,output logic   [FLOWID_W-1:0]          notif_setup_q_wr_data
);

    typedef enum logic {
        READY = 1'd0,
        WRITE_FIFO = 1'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    tcp_noc_hdr_flit hdr_flit_cast;

    logic [FLOWID_W-1:0]    flowid_reg;
    logic [FLOWID_W-1:0]    flowid_next;

    logic                   store_flowid;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            flowid_reg <= flowid_next;
        end
    end

    assign hdr_flit_cast = noc_ctovr_notif_data;

    assign flowid_next = store_flowid
                        ? hdr_flit_cast.flowid
                        : flowid_reg;

    assign notif_setup_q_wr_data = flowid_reg;

    always_comb begin
        notif_noc_ctovr_rdy = 1'b0;

        notif_setup_q_wr_req = 1'b0;

        store_flowid = 1'b0;

        state_next = state_reg;

        case (state_reg)
            READY: begin
                store_flowid = 1'b1;

                notif_noc_ctovr_rdy = 1'b1;

                if (noc_ctovr_notif_val) begin
                    state_next = WRITE_FIFO;
                end
            end
            WRITE_FIFO: begin
                notif_setup_q_wr_req = 1'b1;
                state_next = READY;
            end
            default: begin
                notif_noc_ctovr_rdy = 'X;

                notif_setup_q_wr_req = 'X;

                store_flowid = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
