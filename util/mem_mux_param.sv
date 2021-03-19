module mem_mux_param #(
     parameter ADDR_W = -1
    ,parameter DATA_W = -1
    ,parameter NUM_SRCS = -1
)(
     input clk
    ,input rst

    ,input  logic   [NUM_SRCS-1:0]              srcs_rd_req_vals
    ,input  logic   [NUM_SRCS-1:0][ADDR_W-1:0]  srcs_rd_req_addrs
    ,output logic   [NUM_SRCS-1:0]              srcs_rd_req_rdys

    ,output logic   [NUM_SRCS-1:0]              srcs_rd_resp_vals
    ,output logic   [DATA_W-1:0]                srcs_rd_resp_data
    ,input  logic   [NUM_SRCS-1:0]              srcs_rd_resp_rdys

    ,output logic                               dst_rd_req_val
    ,output logic   [ADDR_W-1:0]                dst_rd_req_addr
    ,input  logic                               dst_rd_req_rdy
    
    ,input  logic                               dst_rd_resp_val
    ,input  logic   [DATA_W-1:0]                dst_rd_resp_data
    ,output logic                               dst_rd_resp_rdy
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        RD_RESP = 2'd1,
        UND = 'X
    } state_e;
    
    state_e state_reg;
    state_e state_next;

    logic   [NUM_SRCS-1:0]  src_sel_reg;
    logic   [NUM_SRCS-1:0]  src_sel_next;
    logic   [NUM_SRCS-1:0]  src_sel_grant;
    logic                   advance_arbiter;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            src_sel_reg <= src_sel_next;
        end
    end

    assign srcs_rd_resp_data = dst_rd_resp_data;

    bsg_arb_round_robin #(
        .width_p    (NUM_SRCS)
    ) arbiter (
         .clk_i     (clk )
        ,.reset_i   (rst  )

        ,.reqs_i    (srcs_rd_req_vals   )
        ,.grants_o  (src_sel_grant      )
        ,.yumi_i    (advance_arbiter    )
    );

    always_comb begin
        dst_rd_req_val = 1'b0;

        advance_arbiter = 1'b0;

        src_sel_next = src_sel_reg;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                dst_rd_req_val = | src_sel_grant;
                src_sel_next = src_sel_grant;

                if (dst_rd_req_val & dst_rd_req_rdy) begin
                    advance_arbiter = 1'b1;
                    state_next = RD_RESP;
                end
            end
            RD_RESP: begin
                if (dst_rd_resp_val & dst_rd_resp_rdy) begin
                    state_next = READY;
                end
            end
        endcase
    end

    demux_one_hot #(
         .NUM_OUTPUTS   (NUM_SRCS   )
        ,.INPUT_WIDTH   (1          )
    ) req_rdy_demux (
         .input_sel     (src_sel_next       )
        ,.data_input    (dst_rd_req_rdy     )
        ,.data_outputs  (srcs_rd_req_rdys   )
    );
    
    bsg_mux_one_hot #(
         .width_p   (ADDR_W     )
        ,.els_p     (NUM_SRCS   )
    ) req_addr_mux (
         .data_i        (srcs_rd_req_addrs  )
        ,.sel_one_hot_i (src_sel_next       )
        ,.data_o        (dst_rd_req_addr    )
    );
    
    demux_one_hot #(
         .NUM_OUTPUTS   (NUM_SRCS   )
        ,.INPUT_WIDTH   (1          )
    ) resp_val_demux (
         .input_sel     (src_sel_next       )
        ,.data_input    (dst_rd_resp_val    )
        ,.data_outputs  (srcs_rd_resp_vals  )
    );
    
    bsg_mux_one_hot #(
         .width_p   (1  )
        ,.els_p     (NUM_SRCS   )
    ) resp_rdy_mux (
         .data_i        (srcs_rd_resp_rdys  )
        ,.sel_one_hot_i (src_sel_next       )
        ,.data_o        (dst_rd_resp_rdy    )
    );

endmodule
