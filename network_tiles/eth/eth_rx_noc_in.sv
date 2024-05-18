`include "eth_rx_tile_defs.svh"
module eth_rx_noc_in (
     input clk
    ,input rst

    ,input  logic                           noc_eth_rx_in_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_eth_rx_in_data
    ,output logic                           eth_rx_in_noc_rdy

    ,output logic                           eth_rx_in_dst_val
    ,output logic   [`MAC_INTERFACE_W-1:0]  eth_rx_in_dst_data
    ,output logic   [`MTU_SIZE_W-1:0]       eth_rx_in_dst_frame_size
    ,output logic                           eth_rx_in_dst_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]   eth_rx_in_dst_data_padbytes
    ,input  logic                           dst_eth_rx_in_rdy
);

    typedef enum logic {
        HDR = 1'b0,
        DATA = 1'b1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    eth_rx_hdr_flit hdr_flit_cast;

    logic   [`MTU_SIZE_W-1:0]       frame_size_reg;
    logic   [`MTU_SIZE_W-1:0]       frame_size_next;
    logic                           store_hdr_flit_data;

    logic   [`MSG_LENGTH_WIDTH-1:0] msg_len_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] msg_len_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_next;
    logic                           reset_flit_cnt;
    logic                           incr_flit_cnt;

    assign hdr_flit_cast = noc_eth_rx_in_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR;
            frame_size_reg <= '0;
            msg_len_reg <= '0;
            flit_cnt_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            frame_size_reg <= frame_size_next;
            msg_len_reg <= msg_len_next;
            flit_cnt_reg <= flit_cnt_next;
        end
    end

    assign frame_size_next = store_hdr_flit_data
                            ? hdr_flit_cast.frame_size
                            : frame_size_reg;

    assign msg_len_next = store_hdr_flit_data
                        ? hdr_flit_cast.core.core.msg_len
                        : msg_len_reg;

    assign flit_cnt_next = reset_flit_cnt
                        ? '0
                        : incr_flit_cnt
                            ? flit_cnt_reg + 1'b1
                            : flit_cnt_reg;

    assign eth_rx_in_dst_data = noc_eth_rx_in_data;
    assign eth_rx_in_dst_data_last = flit_cnt_reg == (msg_len_reg - 1'b1);
    assign eth_rx_in_dst_data_padbytes = frame_size_reg[`NOC_DATA_BYTES_W-1:0] == '0
                                        ? '0
                                        : `NOC_DATA_BYTES - frame_size_reg[`NOC_DATA_BYTES_W-1:0];
    assign eth_rx_in_dst_frame_size = frame_size_reg;

    always_comb begin
        eth_rx_in_noc_rdy = 1'b0;
        eth_rx_in_dst_val = 1'b0;
        store_hdr_flit_data = 1'b0;
        reset_flit_cnt = 1'b0;
        incr_flit_cnt = 1'b0;

        state_next = state_reg;
        case (state_reg)
            HDR: begin
                eth_rx_in_noc_rdy = 1'b1;
                store_hdr_flit_data = 1'b1;
                reset_flit_cnt = 1'b1;
                if (noc_eth_rx_in_val) begin
                    state_next = DATA; 
                end
            end
            DATA: begin
                eth_rx_in_dst_val = noc_eth_rx_in_val;
                eth_rx_in_noc_rdy = dst_eth_rx_in_rdy;
                if (noc_eth_rx_in_val & dst_eth_rx_in_rdy) begin
                    incr_flit_cnt = 1'b1;
                    if (eth_rx_in_dst_data_last) begin
                        state_next = HDR;
                    end
                end
            end
            default: begin
                eth_rx_in_noc_rdy = 1'b0;
                eth_rx_in_dst_val = 1'b0;
                store_hdr_flit_data = 1'b0;
                reset_flit_cnt = 1'b0;
                incr_flit_cnt = 1'b0;

                state_next = UND;
            end
        endcase
    end
endmodule
