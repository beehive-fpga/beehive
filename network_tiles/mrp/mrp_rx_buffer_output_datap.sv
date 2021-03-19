`include "mrp_defs.svh"
module mrp_rx_buffer_output_datap (
     input clk
    ,input rst

    ,input  output_ctrl_enq_struct              fifo_output_datap_msg_desc

    ,output         [RX_BUF_ADDR_W-1:0]         output_datap_rx_buf_rd_req_addr
    ,input          [`MAC_INTERFACE_W-1:0]      rx_buf_output_datap_rd_resp

    ,output logic   [CONN_ID_W-1:0]             rx_buffer_dst_conn_id
    ,output logic   [RX_CONN_BUF_ADDR_W-1:0]    rx_buffer_dst_msg_len

    ,output logic   [`MAC_INTERFACE_W-1:0]      rx_buffer_dst_data
    ,output logic                               rx_buffer_dst_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       rx_buffer_dst_data_padbytes
    
    ,input  logic                               output_ctrl_output_datap_init_state
    ,input  logic                               output_ctrl_output_datap_incr_rd_addr
    ,output logic                               output_datap_output_ctrl_last_rd
);
    localparam RX_CONN_BUF_LINE_ADDR_W = RX_CONN_BUF_ADDR_W - `MAC_INTERFACE_BYTES_W;

    output_ctrl_enq_struct msg_desc_reg;
    output_ctrl_enq_struct msg_desc_next;

    logic   [RX_CONN_BUF_ADDR_W-1:0]    rd_addr_reg;
    logic   [RX_CONN_BUF_ADDR_W-1:0]    rd_addr_next;

    logic   [RX_CONN_BUF_LINE_ADDR_W-1:0]   rd_addr_line;
    logic   [RX_CONN_BUF_LINE_ADDR_W-1:0]   head_ptr_line;

    logic   [`MAC_PADBYTES_W:0]             padbytes_calc;

    assign rd_addr_line = rd_addr_reg[RX_CONN_BUF_ADDR_W-1 -: RX_CONN_BUF_LINE_ADDR_W];
    assign head_ptr_line = msg_desc_reg.head_ptr[RX_CONN_BUF_ADDR_W-1 -: RX_CONN_BUF_LINE_ADDR_W];

    assign output_datap_rx_buf_rd_req_addr = {msg_desc_reg.conn_id, rd_addr_next};

    assign rx_buffer_dst_msg_len = msg_desc_reg.head_ptr;


    assign rx_buffer_dst_conn_id = msg_desc_reg.conn_id;
    assign rx_buffer_dst_data = rx_buf_output_datap_rd_resp;
    assign rx_buffer_dst_data_last = output_datap_output_ctrl_last_rd;
    assign padbytes_calc = `MAC_INTERFACE_BYTES - msg_desc_reg.head_ptr[`MAC_INTERFACE_BYTES_W-1:0];
    assign rx_buffer_dst_data_padbytes = rx_buffer_dst_data_last
                                            ? padbytes_calc[`MAC_PADBYTES_W-1:0]
                                            : '0;

    always_comb begin
         // if we had an exact multiple of 32
         if (msg_desc_reg.head_ptr[`MAC_INTERFACE_BYTES_W-1:0] == 0) begin
            output_datap_output_ctrl_last_rd = rd_addr_line == (head_ptr_line-1);
        end
        else begin
            output_datap_output_ctrl_last_rd = rd_addr_line == head_ptr_line;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            msg_desc_reg <= '0;
            rd_addr_reg <= '0;
        end
        else begin
            msg_desc_reg <= msg_desc_next;
            rd_addr_reg <= rd_addr_next;
        end
    end

    assign msg_desc_next = output_ctrl_output_datap_init_state
                            ? fifo_output_datap_msg_desc
                            : msg_desc_reg;

    always_comb begin
        if (output_ctrl_output_datap_init_state) begin
            rd_addr_next = '0;
        end
        else if (output_ctrl_output_datap_incr_rd_addr) begin
            rd_addr_next = rd_addr_reg + `MAC_INTERFACE_BYTES;
        end
        else begin
            rd_addr_next = rd_addr_reg;
        end
    end
endmodule
