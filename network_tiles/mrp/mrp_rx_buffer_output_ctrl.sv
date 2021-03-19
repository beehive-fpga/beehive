module mrp_rx_buffer_output_ctrl (
     input clk
    ,input rst

    ,input  logic       fifo_output_ctrl_msg_desc_avail
    ,output logic       output_ctrl_fifo_msg_desc_req

    ,output logic       output_ctrl_rx_buf_rd_req_val

    ,output logic       rx_buffer_dst_meta_val
    ,input  logic       dst_rx_buffer_meta_rdy

    ,output logic       rx_buffer_dst_data_val
    ,input  logic       dst_rx_buffer_data_rdy

    ,output logic       output_ctrl_output_datap_init_state
    ,output logic       output_ctrl_output_datap_incr_rd_addr
    ,input  logic       output_datap_output_ctrl_last_rd
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        RD_FIRST_LINE = 2'd1,
        OUTPUT_DATA = 2'd2,
        UND = 'X
    } state_e;

    typedef enum logic {
        WAITING = 1'b0,
        META_OUT = 1'b1,
        UNDEF = 'X
    } meta_state_e;

    state_e state_reg;
    state_e state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    logic meta_output;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            meta_state_reg <= WAITING;
        end
        else begin
            state_reg <= state_next;
            meta_state_reg <= meta_state_next;
        end
    end

    always_comb begin
        output_ctrl_fifo_msg_desc_req = 1'b0;
        output_ctrl_output_datap_init_state = 1'b0;

        output_ctrl_rx_buf_rd_req_val = 1'b0;
        output_ctrl_output_datap_incr_rd_addr = 1'b0;

        rx_buffer_dst_data_val = 1'b0;

        meta_output = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                if (fifo_output_ctrl_msg_desc_avail & (meta_state_reg == WAITING)) begin
                    output_ctrl_fifo_msg_desc_req = 1'b1;
                    output_ctrl_output_datap_init_state = 1'b1;
                    meta_output = 1'b1;

                    state_next = RD_FIRST_LINE;
                end
                else begin
                    state_next = READY;
                end
            end
            RD_FIRST_LINE: begin
                output_ctrl_rx_buf_rd_req_val = 1'b1;

                state_next = OUTPUT_DATA;
            end
            OUTPUT_DATA: begin
                rx_buffer_dst_data_val = 1'b1;
                output_ctrl_rx_buf_rd_req_val = 1'b1;
                if (dst_rx_buffer_data_rdy) begin
                    output_ctrl_output_datap_incr_rd_addr = 1'b1;
                    if (output_datap_output_ctrl_last_rd) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = OUTPUT_DATA;
                    end
                end
                else begin
                    state_next = OUTPUT_DATA;
                end
            end
        endcase
    end

    always_comb begin
        rx_buffer_dst_meta_val = 1'b0;

        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (meta_output) begin
                    meta_state_next = META_OUT;
                end
                else begin
                    meta_state_next = WAITING;
                end
            end
            META_OUT: begin
                rx_buffer_dst_meta_val = 1'b1;
                if (dst_rx_buffer_meta_rdy) begin
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = META_OUT;
                end
            end
        endcase
    end
endmodule
