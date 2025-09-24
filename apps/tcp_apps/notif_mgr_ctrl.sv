module notif_mgr_ctrl (
     input clk
    ,input rst

    ,input  logic                           src_notif_mgr_rx_val
    ,output logic                           notif_mgr_src_rx_rdy

    ,output logic                           ctrl_rx_index_wr_req_val
    ,input  logic                           rx_index_ctrl_wr_req_rdy

    ,output logic                           ctrl_tx_index_wr_req_val
    ,input  logic                           tx_index_ctrl_wr_req_rdy

    ,output logic                           ctrl_datap_store_hdr
    ,output logic                           ctrl_datap_store_index_line
    ,output logic                           ctrl_datap_store_flow_info

    ,input  buf_dir_e                       datap_ctrl_info_dir
    ,input  logic                           datap_ctrl_bufs_valid

    ,output logic                           ctrl_active_q_wr_req
    ,input  logic                           active_q_ctrl_wr_rdy 
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        STORE_INDEX_LINE = 3'd1,
        STORE_FLOW_INFO_LINE = 3'd2,
        WR_CONTEXT = 3'd5,
        CHECK_VALID_VECTORS = 3'd3,
        ENQ_FLOW = 3'd4,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posdege clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_store_index_line = 1'b0;
        ctrl_datap_store_flow_info = 1'b0;

        notif_mgr_src_rx_rdy = 1'b1;
        ctrl_rx_index_wr_req_val = 1'b0;
        ctrl_tx_index_wr_req_val = 1'b0;
        ctrl_active_q_wr_req = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                notif_mgr_src_rx_rdy = 1'b1;
                ctrl_datap_store_hdr = 1'b1;
                if (src_notif_mgr_rx_val) begin
                    state_next = STORE_INDEX_LINE;
                end
            end
            STORE_INDEX_LINE: begin
                notif_mgr_src_rx_rdy = 1'b1;
                ctrl_datap_store_index_line = 1'b1;
                if (src_notif_mgr_rx_val) begin
                    state_next = STORE_FLOW_INFO_LINE;
                end
            end
            STORE_FLOW_INFO_LINE: begin
                notif_mgr_src_rx_rdy = 1'b1;
                ctrl_datap_store_flow_info = 1'b1;
                if (src_notif_mgr_rx_val) begin
                    state_next = WR_CONTEXT;
                end
            end
            WR_CONTEXT: begin
                if (datap_ctrl_info_dir == RX) begin
                    ctrl_rx_index_wr_req_val = 1'b1;
                    if (rx_index_ctrl_wr_req_rdy) begin
                        state_next = CHECK_VALID_VECTORS;
                    end  
                end
                else begin
                    ctrl_tx_index_wr_req_val = 1'b1;
                    if (tx_index_ctrl_wr_req_rdy) begin
                        state_next = CHECK_VALID_VECTORS;
                    end
                end
            end
            ENQ_FLOW: begin
                if (active_q_ctrl_wr_rdy) begin
                    ctrl_active_q_wr_req = datap_ctrl_bufs_valid;
                    state_next = READY;
                end
            end
        endcase
    end
endmodule