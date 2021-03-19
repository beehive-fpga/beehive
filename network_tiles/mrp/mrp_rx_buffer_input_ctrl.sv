`include "mrp_defs.svh"
module mrp_rx_buffer_input_ctrl (
     input clk
    ,input rst
    
    ,input                              mrp_rx_buffer_outstream_meta_val
    ,input                              mrp_rx_buffer_outstream_start
    ,input                              mrp_rx_buffer_outstream_msg_done
    ,output logic                       rx_buffer_mrp_outstream_meta_rdy
   
    ,input                              mrp_rx_buffer_outstream_data_val
    ,input                              mrp_rx_buffer_outstream_last
    ,output logic                       rx_buffer_mrp_outstream_data_rdy

    ,output logic                       input_ctrl_rx_buf_wr_req
    ,output logic                       input_ctrl_rx_ptr_rd_req
    ,output logic                       input_ctrl_rx_ptr_wr_req

    ,output logic                       input_ctrl_input_datap_store_meta
    ,output logic                       input_ctrl_input_datap_store_rx_ptrs
    ,output         rx_ptr_mux_sel_e    input_ctrl_input_datap_rx_ptrs_sel
    ,output logic                       input_ctrl_input_datap_incr_head_ptr

    ,input  logic                       input_datap_input_ctrl_ptrs_stored

    ,output logic                       input_ctrl_fifo_enq_msg_desc_req
    ,input                              fifo_input_ctrl_enq_msg_desc_rdy

);

    typedef enum logic[1:0] {
        READY = 2'd0, 
        WR_PAYLOAD = 2'd1,
        ENQ_OUTPUT = 2'd2,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   msg_done_reg;
    logic   msg_start_reg;
    logic   msg_done_next;
    logic   msg_start_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            msg_done_reg <= '0;
            msg_start_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            msg_done_reg <= msg_done_next;
            msg_start_reg <= msg_start_next;
        end
    end

    assign msg_done_next = input_ctrl_input_datap_store_meta
                           ? mrp_rx_buffer_outstream_msg_done
                           : msg_done_reg;
    assign msg_start_next = input_ctrl_input_datap_store_meta
                            ? mrp_rx_buffer_outstream_start
                            : msg_start_reg;

    always_comb begin
        rx_buffer_mrp_outstream_meta_rdy = 1'b0;
        rx_buffer_mrp_outstream_data_rdy = 1'b0;

        input_ctrl_input_datap_store_meta = 1'b0;
        input_ctrl_input_datap_store_rx_ptrs = 1'b0;
        input_ctrl_input_datap_rx_ptrs_sel = MEM;
        input_ctrl_input_datap_incr_head_ptr = 1'b0;

        input_ctrl_fifo_enq_msg_desc_req = 1'b0;

        input_ctrl_rx_buf_wr_req = 1'b0;
        input_ctrl_rx_ptr_rd_req = 1'b0;
        input_ctrl_rx_ptr_wr_req = 1'b0;

        state_next = state_reg;
        case (state_reg) 
            READY: begin
                rx_buffer_mrp_outstream_meta_rdy = 1'b1;
                if (mrp_rx_buffer_outstream_meta_val) begin
                    input_ctrl_input_datap_store_meta = 1'b1;
                    input_ctrl_rx_ptr_rd_req = ~mrp_rx_buffer_outstream_start;

                    state_next = WR_PAYLOAD;
                end
                else begin
                    state_next = READY;
                end
            end
            WR_PAYLOAD: begin
                rx_buffer_mrp_outstream_data_rdy = 1'b1;
                input_ctrl_input_datap_store_rx_ptrs = ~input_datap_input_ctrl_ptrs_stored;

                if (msg_start_reg) begin
                    input_ctrl_input_datap_rx_ptrs_sel = RESET;
                end
                else begin
                    input_ctrl_input_datap_rx_ptrs_sel = MEM;
                end

                if (mrp_rx_buffer_outstream_data_val) begin
                    input_ctrl_input_datap_incr_head_ptr = 1'b1;
                    input_ctrl_rx_buf_wr_req = 1'b1;

                    if (mrp_rx_buffer_outstream_last) begin
                        input_ctrl_rx_ptr_wr_req = 1'b1;

                        if (msg_done_reg) begin
                            state_next = ENQ_OUTPUT;
                        end
                        else begin
                            state_next = READY;
                        end
                    end
                    else begin
                        state_next = WR_PAYLOAD;
                    end
                end
                else begin
                    state_next = WR_PAYLOAD;
                end
            end
            ENQ_OUTPUT: begin
                input_ctrl_fifo_enq_msg_desc_req = 1'b1;
                if (fifo_input_ctrl_enq_msg_desc_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = ENQ_OUTPUT;
                end
            end
        endcase
    end

endmodule
