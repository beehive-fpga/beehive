`include "mrp_defs.svh"
module mrp_rx_buffer_input_datap (
     input clk
    ,input rst

    ,input          [CONN_ID_W-1:0]         mrp_rx_buffer_outstream_conn_id

    ,input          [`MAC_INTERFACE_W-1:0]  mrp_rx_buffer_outstream_data
    ,input                                  mrp_rx_buffer_outstream_data_last
    ,input          [`MAC_PADBYTES_W-1:0]   mrp_rx_buffer_outstream_data_padbytes
    
    ,output logic   [RX_BUF_ADDR_W-1:0]     input_datap_rx_buf_wr_addr
    ,output logic   [`MAC_INTERFACE_W-1:0]  input_datap_rx_buf_wr_data
    
    ,output logic   [CONN_ID_W-1:0]         input_datap_rx_ptr_rd_addr

    ,input          rx_ptrs_struct          rx_ptr_input_datap_rd_data

    ,output logic   [CONN_ID_W-1:0]         input_datap_rx_ptr_wr_addr
    ,output         rx_ptrs_struct          input_datap_rx_ptr_wr_data

    ,input  logic                           input_ctrl_input_datap_store_meta
    ,input  logic                           input_ctrl_input_datap_store_rx_ptrs
    ,input          rx_ptr_mux_sel_e        input_ctrl_input_datap_rx_ptrs_sel
    ,input  logic                           input_ctrl_input_datap_incr_head_ptr

    ,output logic                           input_datap_input_ctrl_ptrs_stored

    ,output         output_ctrl_enq_struct  input_datap_fifo_enq_msg_desc
);

    logic   [CONN_ID_W-1:0] conn_id_reg;
    logic   [CONN_ID_W-1:0] conn_id_next;

    rx_ptrs_struct          rx_ptrs_reg;
    rx_ptrs_struct          rx_ptrs_mux_next;
    rx_ptrs_struct          rx_ptrs_store_next;
    logic                   ptrs_stored_reg;
    logic                   ptrs_stored_next;

    assign input_datap_rx_buf_wr_addr = {conn_id_reg, rx_ptrs_mux_next.head_ptr};
    assign input_datap_rx_buf_wr_data = mrp_rx_buffer_outstream_data;

    assign input_datap_rx_ptr_rd_addr = conn_id_next;
    assign input_datap_rx_ptr_wr_addr = conn_id_reg;
    assign input_datap_rx_ptr_wr_data = rx_ptrs_store_next;

    assign input_datap_fifo_enq_msg_desc.conn_id = conn_id_reg;
    assign input_datap_fifo_enq_msg_desc.head_ptr = rx_ptrs_reg.head_ptr;

    assign input_datap_input_ctrl_ptrs_stored = ptrs_stored_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            conn_id_reg <= '0;
            rx_ptrs_reg <= '0;
            ptrs_stored_reg <= '0;
        end
        else begin
            conn_id_reg <= conn_id_next;
            rx_ptrs_reg <= rx_ptrs_store_next;
            ptrs_stored_reg <= ptrs_stored_next;
        end
    end

    assign conn_id_next = input_ctrl_input_datap_store_meta 
                            ? mrp_rx_buffer_outstream_conn_id
                            : conn_id_reg;

    always_comb begin
        if (input_ctrl_input_datap_store_meta) begin
            ptrs_stored_next = 1'b0;
        end
        else if (input_ctrl_input_datap_store_rx_ptrs) begin
            ptrs_stored_next = 1'b1;
        end
        else begin
            ptrs_stored_next = ptrs_stored_reg;
        end
    end

    always_comb begin
        rx_ptrs_mux_next = rx_ptrs_reg;
        if (input_ctrl_input_datap_store_rx_ptrs) begin
            if (input_ctrl_input_datap_rx_ptrs_sel == INPUT) begin
                rx_ptrs_mux_next = rx_ptr_input_datap_rd_data;
            end
            else begin
                rx_ptrs_mux_next = '0;
            end
        end
        else begin
            rx_ptrs_mux_next = rx_ptrs_reg;
        end
    end

    always_comb begin
        rx_ptrs_store_next = rx_ptrs_mux_next;
        if (input_ctrl_input_datap_incr_head_ptr) begin
            if (mrp_rx_buffer_outstream_data_last) begin
                rx_ptrs_store_next.head_ptr = rx_ptrs_mux_next.head_ptr + 
                                     (`MAC_INTERFACE_BYTES - mrp_rx_buffer_outstream_data_padbytes);
            end
            else begin
                rx_ptrs_store_next.head_ptr = rx_ptrs_mux_next.head_ptr + `MAC_INTERFACE_BYTES;
            end
        end
        else begin
            rx_ptrs_store_next = rx_ptrs_mux_next;
        end
    end




endmodule
