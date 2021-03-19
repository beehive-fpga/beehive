module beehive_noc_splitter #(
     parameter                      NOC_DATA_W = 512
    ,parameter                      MSG_PAYLOAD_LEN = 22
    ,parameter                      MSG_LEN_HI = 477
    ,parameter                      MSG_LEN_LO = MSG_LEN_HI - MSG_PAYLOAD_LEN - 1
    ,parameter  [2:0]               num_targets = 3'd1
)(
     input clk
    ,input rst
    
    ,input                                              src_splitter_vr_noc_val
    ,input          [NOC_DATA_W-1:0]                    src_splitter_vr_noc_data
    ,output logic                                       splitter_src_vr_noc_rdy

    ,output logic   [num_targets-1:0]                   splitter_dsts_vr_noc_val
    ,output logic   [num_targets-1:0][NOC_DATA_W-1:0]   splitter_dsts_vr_noc_data
    ,input  logic   [num_targets-1:0]                   dsts_splitter_vr_noc_rdy

    // interface for arbitrary logic
    ,output logic   [NOC_DATA_W-1:0]    noc_data_line
    
    ,input logic    [num_targets-1:0]   dst_sel_one_hot
);

    generate
        genvar i;
        for (i = 0; i < num_targets; i += 1) begin
            assign splitter_dsts_vr_noc_data[i] = src_splitter_vr_noc_data;
        end
    endgenerate

    typedef enum logic [1:0]{
        READY = 2'd0,
        PASS_DATA = 2'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   store_count;
    logic   decr_count;
    logic   [MSG_PAYLOAD_LEN-1:0]   count_reg;
    logic   [MSG_PAYLOAD_LEN-1:0]   count_next;

    logic                           store_dst_sel;
    logic   [num_targets-1:0]       dst_sel_reg;
    logic   [num_targets-1:0]       dst_sel_next;

    assign noc_data_line = src_splitter_vr_noc_data;

    assign count_next = store_count
                        ? noc_data_line[MSG_LEN_HI:MSG_LEN_LO]
                        : decr_count
                          ? count_reg - 1'b1
                          : count_reg;

    assign dst_sel_next = store_dst_sel
                        ? dst_sel_one_hot
                        : dst_sel_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            count_reg <= count_next;
            dst_sel_reg <= dst_sel_next;
        end
    end

    demux_one_hot #(
         .NUM_OUTPUTS   (num_targets    )
        ,.INPUT_WIDTH   (1              )
    ) val_demux (
         .input_sel     (dst_sel_next               )
        ,.data_input    (src_splitter_vr_noc_val    )
        ,.data_outputs  (splitter_dsts_vr_noc_val   )
    );

    bsg_mux_one_hot #(
         .width_p   (1  )
        ,.els_p     (num_targets    )
    ) num_mux (
         .data_i        (dsts_splitter_vr_noc_rdy   )
        ,.sel_one_hot_i (dst_sel_one_hot            )
        ,.data_o        (splitter_src_vr_noc_rdy    )
    );

    always_comb begin
        store_dst_sel = 1'b0;
        store_count = 1'b0;
        decr_count = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                store_dst_sel = 1'b1;
                store_count = 1'b1;
                if (src_splitter_vr_noc_val & splitter_src_vr_noc_rdy) begin
                    if (count_next != '0) begin
                        state_next = PASS_DATA;
                    end
                end
            end
            PASS_DATA: begin
                if (src_splitter_vr_noc_val & splitter_src_vr_noc_rdy) begin
                    decr_count = 1'b1;
                    if (count_reg == 1) begin
                        state_next = READY;
                    end
                end
            end
        endcase
    end
endmodule
