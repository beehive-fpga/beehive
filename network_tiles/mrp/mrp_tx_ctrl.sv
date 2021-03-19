`include "mrp_defs.svh"
module mrp_tx_ctrl (
     input  clk
    ,input  rst
    
    ,output logic                                   mrp_tx_conn_id_table_rd_req_val
    ,input                                          conn_id_table_mrp_tx_rd_resp_val
    
    ,input  logic                                   src_mrp_tx_meta_val
    ,output logic                                   mrp_src_tx_meta_rdy

    ,input  logic                                   src_mrp_tx_instream_val
    ,input  logic                                   src_mrp_tx_instream_last
    ,output logic                                   mrp_src_tx_instream_rdy
    
    ,output logic                                   mrp_dst_tx_meta_val
    ,input                                          dst_mrp_tx_meta_rdy

    ,output logic                                   mrp_dst_tx_data_val
    ,output logic                                   mrp_dst_tx_data_last
    ,input  logic                                   dst_mrp_tx_data_rdy

    ,output logic                                   ctrl_datap_store_meta
    ,output logic                                   ctrl_datap_store_conn_data
    ,output logic                                   ctrl_datap_update_pkt_data
    ,output logic                                   ctrl_datap_calc_pkt_len
    ,output logic                                   ctrl_datap_decr_bytes_rem

    ,output logic                                   ctrl_datap_store_hold
    ,output         tx_hold_mux_sel_e               ctrl_datap_hold_mux_sel

    ,input                                          datap_ctrl_drain_hold
    ,input  logic                                   datap_ctrl_msg_end
    ,input  logic                                   datap_ctrl_last_pkt_bytes
    ,input  logic                                   datap_ctrl_last_pkt
    ,output logic                                   ctrl_datap_store_padbytes
    ,output         tx_padbytes_mux_sel_e           ctrl_datap_padbytes_mux_sel

    ,output logic                                   ctrl_tx_state_rd_req_val

    ,input                                          tx_state_ctrl_rd_resp_val

    ,output logic                                   ctrl_tx_state_wr_req_val
    ,input                                          tx_state_ctrl_wr_req_rdy
    
    ,output logic                                   mrp_tx_dealloc_msg_finalize_val
    ,input  logic                                   dealloc_mrp_tx_msg_finalize_rdy

    ,output logic   [63:0]                          pkts_sent_cnt
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        MRP_HDR_ASSEMBLE = 3'd1,
        PASS_DATA = 3'd2,
        PASS_DATA_LAST = 3'd3,
        WR_STATE = 3'd4,
        FINALIZE_MSG = 3'd5,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        HDR_OUT = 2'd1,
        UNDEF = 'X 
    } meta_state_e;

    state_e state_reg;
    state_e state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    logic   cont_send_reg;
    logic   cont_send_next;

    logic   meta_data_output;

    logic   [63:0]  pkts_sent_cnt_reg;
    logic   [63:0]  pkts_sent_cnt_next;

    assign pkts_sent_cnt = pkts_sent_cnt_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            cont_send_reg <= '0;
            meta_state_reg <= WAITING;
            pkts_sent_cnt_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            cont_send_reg <= cont_send_next;
            meta_state_reg <= meta_state_next;
            pkts_sent_cnt_reg <= pkts_sent_cnt_next;
        end
    end

    always_comb begin
        mrp_src_tx_meta_rdy = 1'b0;
        mrp_src_tx_instream_rdy = 1'b0;
        mrp_dst_tx_data_val = 1'b0;
        mrp_dst_tx_data_last = 1'b0;

        ctrl_datap_store_hold = 1'b0;
        ctrl_datap_store_meta = 1'b0;
        ctrl_datap_hold_mux_sel = mrp_pkg::DATA;

        ctrl_datap_store_conn_data = 1'b0;
        ctrl_datap_store_padbytes = 1'b0;
        ctrl_datap_padbytes_mux_sel = INPUT;

        ctrl_datap_update_pkt_data = 1'b0;
        ctrl_datap_calc_pkt_len = 1'b0;
        ctrl_datap_decr_bytes_rem = 1'b0;

        ctrl_tx_state_rd_req_val = 1'b0;
        mrp_tx_conn_id_table_rd_req_val = 1'b0;
        ctrl_tx_state_wr_req_val = 1'b0;

        meta_data_output = 1'b0;

        mrp_tx_dealloc_msg_finalize_val = 1'b0;

        cont_send_next = cont_send_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                cont_send_next = 1'b0;
                mrp_src_tx_meta_rdy = meta_state_reg == WAITING;
                if (src_mrp_tx_meta_val & (meta_state_reg == WAITING)) begin
                    ctrl_datap_store_meta = 1'b1;
                    ctrl_tx_state_rd_req_val = 1'b1;
                    mrp_tx_conn_id_table_rd_req_val = 1'b1;

                    state_next = MRP_HDR_ASSEMBLE;
                end
                else begin
                    state_next = READY;
                end
            end
            MRP_HDR_ASSEMBLE: begin
                ctrl_datap_store_hold = 1'b1;
                ctrl_datap_hold_mux_sel = HDR;
                ctrl_datap_store_conn_data = ~cont_send_reg;

                if (meta_state_reg == WAITING) begin
                    meta_data_output = 1'b1;
                    ctrl_datap_calc_pkt_len = 1'b1;
                    state_next = PASS_DATA;
                end
                else begin
                    state_next = MRP_HDR_ASSEMBLE;
                end
            end
            PASS_DATA: begin
                mrp_dst_tx_data_val = src_mrp_tx_instream_val;
                mrp_src_tx_instream_rdy = dst_mrp_tx_data_rdy;

                if (src_mrp_tx_instream_val & dst_mrp_tx_data_rdy) begin
                    ctrl_datap_decr_bytes_rem = 1'b1;
                    ctrl_datap_store_hold = 1'b1;

                    if (datap_ctrl_last_pkt_bytes) begin
                        ctrl_datap_store_padbytes = 1'b1;
                        ctrl_datap_padbytes_mux_sel = src_mrp_tx_instream_last
                                                    ? INPUT
                                                    : ZERO;

                        if (datap_ctrl_drain_hold) begin
                            state_next = PASS_DATA_LAST;
                        end
                        else begin
                            mrp_dst_tx_data_last = 1'b1;
                            if (src_mrp_tx_instream_last) begin
                                state_next = WR_STATE;
                            end
                            else begin
                                ctrl_datap_update_pkt_data = 1'b1;
                                cont_send_next = 1'b1;
                                state_next = MRP_HDR_ASSEMBLE;
                            end
                        end
                    end
                    else begin
                        state_next = PASS_DATA;
                    end
                end
                else begin
                    state_next = PASS_DATA;
                end
            end
            PASS_DATA_LAST: begin
                mrp_dst_tx_data_val = 1'b1;
                mrp_dst_tx_data_last = 1'b1;

                if (dst_mrp_tx_data_rdy) begin
                    ctrl_datap_decr_bytes_rem = 1'b1;
                    if (datap_ctrl_last_pkt) begin
                        state_next = WR_STATE;
                    end
                    else begin
                        cont_send_next = 1'b1;
                        ctrl_datap_update_pkt_data = 1'b1;
                        state_next = MRP_HDR_ASSEMBLE;
                    end
                end
                else begin
                    state_next = PASS_DATA_LAST;
                end
            end
            WR_STATE: begin
                ctrl_tx_state_wr_req_val = 1'b1;
                if (tx_state_ctrl_wr_req_rdy) begin
                    if (datap_ctrl_msg_end) begin
                        state_next = FINALIZE_MSG;
                    end
                    else begin
                        state_next = READY;
                    end
                end
                else begin
                    state_next = WR_STATE;
                end
            end
            FINALIZE_MSG: begin
                mrp_tx_dealloc_msg_finalize_val = 1'b1;
                if (dealloc_mrp_tx_msg_finalize_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = FINALIZE_MSG;
                end
            end
            default: begin
                mrp_src_tx_meta_rdy = 'X;
                mrp_src_tx_instream_rdy = 'X;
                mrp_dst_tx_data_val = 'X;

                ctrl_datap_store_hold = 'X;
                ctrl_datap_store_meta = 'X;

                ctrl_datap_store_conn_data = 'X;
                ctrl_datap_store_padbytes = 'X;

                ctrl_tx_state_rd_req_val = 'X;
                mrp_tx_conn_id_table_rd_req_val = 'X;
                ctrl_tx_state_wr_req_val = 'X;

                meta_data_output = 'X;
                
                ctrl_datap_hold_mux_sel = mrp_pkg::DATA;
                ctrl_datap_padbytes_mux_sel = INPUT;

                cont_send_next = 'X;
                state_next = UND;
            end
        endcase
    end

    always_comb begin
        mrp_dst_tx_meta_val = 1'b0;
        pkts_sent_cnt_next = pkts_sent_cnt_reg;

        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (meta_data_output) begin
                    meta_state_next = HDR_OUT;
                end
                else begin
                    meta_state_next = WAITING;
                end
            end
            HDR_OUT: begin
                mrp_dst_tx_meta_val = 1'b1;
                if (dst_mrp_tx_meta_rdy) begin
                    pkts_sent_cnt_next = pkts_sent_cnt_reg + 1'b1;
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = HDR_OUT;
                end
            end
        endcase
    end



endmodule
