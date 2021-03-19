module stream_mux #(
     parameter NUM_SRCS = -1
    ,parameter DATA_W = -1
)(
     input clk
    ,input rst

    ,output logic                               mux_dst_val
    ,output logic                               mux_dst_last
    ,output logic   [DATA_W-1:0]                mux_dst_data
    ,input                                      dst_mux_rdy
     
    ,input  logic   [NUM_SRCS-1:0]              src_mux_vals
    ,input  logic   [NUM_SRCS-1:0]              src_mux_lasts
    ,input  logic   [NUM_SRCS-1:0][DATA_W-1:0]  src_mux_datas
    ,output         [NUM_SRCS-1:0]              mux_src_rdys
);
    typedef enum logic {
        READY = 1'b0,
        DATA = 1'b1,
        UND = 'X
    } state_e;
    
    logic   [NUM_SRCS-1:0]  grants_reg;
    logic   [NUM_SRCS-1:0]  grants_next;
    logic   [NUM_SRCS-1:0]  grants;
    logic                   grants_advance;
    logic                   store_grants;
    logic                   any_grant;

    state_e state_reg;
    state_e state_next;

    assign any_grant = |grants;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            grants_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            grants_reg <= grants_next;
        end
    end

    assign grants_next = store_grants
                        ? grants
                        : grants_reg;

    always_comb begin
        store_grants = 1'b0;
        grants_advance = 1'b0;

        state_next = state_reg;
        unique case (state_reg)
            READY: begin
                store_grants = 1'b1;

                if (mux_dst_val) begin
                    grants_advance = 1'b1;
                    if (dst_mux_rdy & mux_dst_last) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA;
                    end
                end
            end
            DATA: begin
                if (mux_dst_val & dst_mux_rdy & mux_dst_last) begin
                    state_next = READY;
                end
            end
            default: begin
                store_grants = 'X;
                grants_advance = 'X;

                state_next = UND;
            end
        endcase
    end



    bsg_arb_round_robin #(
        .width_p    (NUM_SRCS   )
    ) arbiter (
         .clk_i     (clk    )
        ,.reset_i   (rst    )

        ,.reqs_i    (src_mux_vals   )
        ,.grants_o  (grants         )
        ,.yumi_i    (grants_advance )
    );
    
    demux_one_hot #(
         .NUM_OUTPUTS   (NUM_SRCS   )
        ,.INPUT_WIDTH   (1          )
    ) rdy_demux (
         .input_sel     (grants_next    )
        ,.data_input    (dst_mux_rdy    )
        ,.data_outputs  (mux_src_rdys   )
    );

    bsg_mux_one_hot #(
         .width_p   (1  )
        ,.els_p     (NUM_SRCS   )
    ) val_mux (
         .data_i        (src_mux_vals   )
        ,.sel_one_hot_i (grants_next    )
        ,.data_o        (mux_dst_val    )
    );
    
    bsg_mux_one_hot #(
         .width_p   (DATA_W     )
        ,.els_p     (NUM_SRCS   )
    ) data_mux (
         .data_i        (src_mux_datas  )
        ,.sel_one_hot_i (grants_next    )
        ,.data_o        (mux_dst_data   )
    );
    
    bsg_mux_one_hot #(
         .width_p   (1          )
        ,.els_p     (NUM_SRCS   )
    ) last_mux (
         .data_i        (src_mux_lasts  )
        ,.sel_one_hot_i (grants_next    )
        ,.data_o        (mux_dst_last   )
    );
endmodule
