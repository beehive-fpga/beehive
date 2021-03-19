`include "mrp_defs.svh"
module mrp_rx_ctrl (
     input clk
    ,input rst
    
    ,input                                          src_mrp_rx_meta_val
    ,output logic                                   mrp_src_rx_meta_rdy

    ,input                                          src_mrp_rx_data_val
    ,input                                          src_mrp_rx_data_last
    ,input          [`MAC_PADBYTES_W-1:0]           src_mrp_rx_data_padbytes
    ,output logic                                   mrp_src_rx_data_rdy
    
    ,output logic                                   mrp_dst_rx_outstream_meta_val
    ,output logic                                   mrp_dst_rx_outstream_start
    ,output logic                                   mrp_dst_rx_outstream_msg_done
    ,input                                          dst_mrp_rx_outstream_meta_rdy

    ,output logic                                   mrp_dst_rx_outstream_val
    ,output logic                                   mrp_dst_rx_outstream_last
    ,input                                          dst_mrp_rx_outstream_rdy

    ,output logic                                   ctrl_cam_wr_cam
    ,output logic                                   ctrl_cam_clear_entry
    ,output         addr_mux_sel_e                  ctrl_addr_mux_sel

    // the controller has to do timer deallocation so we don't simulatenously invalidate
    // a connection while processing a packet for that connection
    ,input                                          timeout_ctrl_val
    ,output logic                                   ctrl_timeout_rdy

    ,input                                          datap_ctrl_new_flow_val

    ,output logic                                   ctrl_datap_store_meta
    ,output logic                                   ctrl_datap_store_fifo_conn_id
    ,output logic                                   ctrl_datap_store_hdr
    ,output logic                                   ctrl_datap_store_cam_result 

    ,output logic                                   ctrl_datap_store_hold
    
    ,input                                          datap_ctrl_pkt_expected

    ,output logic                                   ctrl_state_rd_req_val
    ,input  logic                                   state_ctrl_rd_resp_val
    
    ,output logic                                   ctrl_state_wr_req

    ,output logic                                   ctrl_cam_rd_cam_val

    ,input                                          datap_ctrl_cam_hit
    
    ,output logic                                   ctrl_set_timer_flag
    ,output logic                                   ctrl_clear_timer_flag

    ,output logic                                   ctrl_datap_store_padbytes
    
    ,input          mrp_flags                       datap_ctrl_mrp_flags
    
    ,input                                          conn_id_fifo_ctrl_id_avail
    ,output logic                                   ctrl_conn_id_fifo_id_req

    ,output logic                                   ctrl_conn_id_fifo_wr_req
    
    ,output logic                                   mrp_rx_conn_id_table_wr_val

    ,input                                          datap_ctrl_last_data

    ,output logic   [31:0]                          pkts_recved_cnt
    ,output logic   [31:0]                          dropped_pkts_cnt
    ,output logic                                   ctrl_write_log
);


    typedef enum logic[3:0] {
        READY = 4'd0,
        ID_LOOKUP = 4'd1,
        RD_REQ = 4'd2,
        RD_RESP = 4'd3,
        WR_STATE = 4'd4,
        DEALLOC = 4'd5,
        DUMP_DATA = 4'd6,
        PASS_DATA = 4'd7,
        PASS_DATA_LAST = 4'd8,
        DEALLOC_TIMEOUT = 4'd9,
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

    logic   sent_start_reg;
    logic   sent_start_next;
    logic   got_last_reg;
    logic   got_last_next;

    logic   [31:0]  recved_cnt_reg;
    logic   [31:0]  recved_cnt_next;

    logic   [31:0]  dropped_pkts_cnt_reg;
    logic   [31:0]  dropped_pkts_cnt_next;

    assign pkts_recved_cnt = recved_cnt_next;
    assign dropped_pkts_cnt = dropped_pkts_cnt_next;

    logic   meta_output;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            meta_state_reg <= WAITING;
            recved_cnt_reg <= '0;
            dropped_pkts_cnt_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            sent_start_reg <= sent_start_next;
            meta_state_reg <= meta_state_next;
            got_last_reg <= got_last_next;
            recved_cnt_reg <= recved_cnt_next;
            dropped_pkts_cnt_reg <= dropped_pkts_cnt_next;
        end
    end

    assign mrp_dst_rx_outstream_msg_done = datap_ctrl_mrp_flags.last_pkt;

    always_comb begin
        mrp_src_rx_meta_rdy = 1'b0;
        mrp_src_rx_data_rdy = 1'b0;
        mrp_dst_rx_outstream_val = 1'b0;
        mrp_dst_rx_outstream_start = 1'b0;
        mrp_dst_rx_outstream_last = 1'b0;

        ctrl_datap_store_meta = 1'b0;
        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_store_hold = 1'b0;

        ctrl_cam_rd_cam_val = 1'b0;
        ctrl_datap_store_cam_result = 1'b0;
        ctrl_datap_store_fifo_conn_id = 1'b0;

        ctrl_state_rd_req_val = 1'b0;

        ctrl_state_wr_req = 1'b0;
        ctrl_set_timer_flag = 1'b0;
        ctrl_cam_wr_cam = 1'b0;
        ctrl_addr_mux_sel = DATAP;

        ctrl_cam_clear_entry = 1'b0;
        ctrl_clear_timer_flag = 1'b0;
        ctrl_timeout_rdy = 1'b0;

        ctrl_datap_store_padbytes = 1'b0;

        sent_start_next = sent_start_reg;

        ctrl_conn_id_fifo_id_req = 1'b0;
        ctrl_conn_id_fifo_wr_req = 1'b0;

        mrp_rx_conn_id_table_wr_val = 1'b0;

        dropped_pkts_cnt_next = dropped_pkts_cnt_reg;
        recved_cnt_next = recved_cnt_reg;
        ctrl_write_log = 1'b0;
        meta_output = 1'b0;

        ctrl_timeout_rdy = 1'b0;

        got_last_next = got_last_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                sent_start_next = 1'b0;
                got_last_next = src_mrp_rx_data_last;
                if (src_mrp_rx_meta_val & src_mrp_rx_data_val & (meta_state_reg == WAITING)) begin
                    mrp_src_rx_meta_rdy = 1'b1;
                    mrp_src_rx_data_rdy = 1'b1;
                    ctrl_datap_store_meta = 1'b1;
                    ctrl_datap_store_hdr = 1'b1;
                    ctrl_datap_store_hold = 1'b1;
                    ctrl_write_log = 1'b1;
                    ctrl_datap_store_padbytes = src_mrp_rx_data_last;

                    state_next = ID_LOOKUP;
                end
                else if (timeout_ctrl_val) begin
                    state_next = DEALLOC_TIMEOUT;
                end
                else begin
                    state_next = READY;
                end
            end
            ID_LOOKUP: begin
                ctrl_cam_rd_cam_val = 1'b1;
                ctrl_datap_store_cam_result = 1'b1;
                state_next = RD_REQ;
            end
            RD_REQ: begin
                ctrl_state_rd_req_val = datap_ctrl_cam_hit;

                state_next = RD_RESP;
            end
            RD_RESP: begin
                if (datap_ctrl_pkt_expected) begin
                    // if we have a valid new flow, but there's no space, just drop it
                    // also check if we have timed out flows
                    if (~datap_ctrl_cam_hit & ~conn_id_fifo_ctrl_id_avail) begin
                        if (timeout_ctrl_val) begin
                            state_next = DEALLOC_TIMEOUT;
                        end
                        else begin
                            state_next = DUMP_DATA;
                        end
                    end
                    else begin
                        state_next = WR_STATE;
                    end
                end
                else begin
                    if (datap_ctrl_cam_hit) begin
                        state_next = DEALLOC;
                    end
                    else begin
                        if (got_last_reg) begin
                            state_next = READY;
                        end
                        else begin
                            state_next = DUMP_DATA;
                        end
                    end
                end
            end
            WR_STATE: begin
                meta_output = 1'b1;
                ctrl_conn_id_fifo_id_req = datap_ctrl_new_flow_val;
                ctrl_datap_store_fifo_conn_id = datap_ctrl_new_flow_val;
                mrp_rx_conn_id_table_wr_val = datap_ctrl_new_flow_val;
                ctrl_state_wr_req = 1'b1;

                recved_cnt_next = recved_cnt_reg + 1'b1;
                ctrl_write_log = 1'b1;

                if (datap_ctrl_mrp_flags.last_pkt) begin
                    ctrl_clear_timer_flag = 1'b1;
                end
                else begin
                    ctrl_set_timer_flag = 1'b1;
                end
                ctrl_cam_wr_cam = datap_ctrl_new_flow_val;
                ctrl_addr_mux_sel = DATAP;
                if (got_last_reg) begin
                    state_next = PASS_DATA_LAST;
                end
                else begin
                    state_next = PASS_DATA;
                end
            end
            DEALLOC: begin
                ctrl_cam_wr_cam = 1'b1;
                ctrl_conn_id_fifo_wr_req = 1'b1;
                ctrl_cam_clear_entry = 1'b1;
                ctrl_addr_mux_sel = DATAP;
                ctrl_clear_timer_flag = 1'b1;
                
                if (got_last_reg) begin
                    state_next = READY;
                end
                else begin
                    state_next = DUMP_DATA;
                end
            end
            DEALLOC_TIMEOUT: begin
                ctrl_cam_wr_cam = 1'b1;
                ctrl_conn_id_fifo_wr_req = 1'b1;
                ctrl_cam_clear_entry = 1'b1;
                ctrl_addr_mux_sel = TIMEOUT;
                ctrl_timeout_rdy = 1'b1;
                ctrl_clear_timer_flag = 1'b1;
                ctrl_timeout_rdy = 1'b1;
                
                state_next = READY;
            end
            PASS_DATA: begin
                mrp_src_rx_data_rdy = dst_mrp_rx_outstream_rdy;
                mrp_dst_rx_outstream_val = src_mrp_rx_data_val;

                mrp_dst_rx_outstream_start = ~sent_start_reg & datap_ctrl_new_flow_val;
                if (dst_mrp_rx_outstream_rdy & src_mrp_rx_data_val) begin
                    ctrl_datap_store_hold = 1'b1;
                    sent_start_next = 1'b1;
                    if (src_mrp_rx_data_last) begin
                        ctrl_datap_store_padbytes = 1'b1;
                        if (datap_ctrl_last_data) begin
                            mrp_dst_rx_outstream_last = 1'b1;
                            state_next = READY;
                        end
                        else begin
                            state_next = PASS_DATA_LAST;
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
                mrp_dst_rx_outstream_val = 1'b1;
                mrp_dst_rx_outstream_start = ~sent_start_reg & datap_ctrl_new_flow_val;
                mrp_dst_rx_outstream_last = 1'b1;
                
                if (dst_mrp_rx_outstream_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = PASS_DATA_LAST;
                end
            end
            DUMP_DATA: begin
                mrp_src_rx_data_rdy = 1'b1;

                if (src_mrp_rx_data_val & src_mrp_rx_data_last) begin
                    dropped_pkts_cnt_next = dropped_pkts_cnt_reg + 1'b1;
                    ctrl_write_log = 1'b1;
                    state_next = READY;
                end
                else begin
                    state_next = DUMP_DATA;
                end
            end
        endcase
    end

    always_comb begin
        mrp_dst_rx_outstream_meta_val = 1'b0;

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
                mrp_dst_rx_outstream_meta_val = 1'b1;

                if (dst_mrp_rx_outstream_meta_rdy) begin
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = META_OUT;
                end
            end
        endcase
    end

endmodule
