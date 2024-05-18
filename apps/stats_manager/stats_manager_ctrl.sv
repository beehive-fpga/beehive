module stats_manager_ctrl 
    import tracker_pkg::*;
(
     input clk
    ,input rst

    ,input  logic               in_manager_noc0_val
    ,output logic               manager_in_noc0_rdy

    ,input  logic               in_manager_notif_noc1_val
    ,output logic               manager_in_notif_noc1_rdy

    ,output logic               manager_out_notif_noc1_val
    ,input  logic               out_manager_notif_noc1_rdy

    ,output logic               ctrl_datap_store_new_flow
    ,output logic               ctrl_datap_store_notif
    ,output logic               ctrl_datap_store_req
    ,output logic               ctrl_datap_store_meta
    ,output logic               ctrl_datap_rx_notif_req
    ,output logic               ctrl_datap_make_req
    ,output tracker_req_type    ctrl_datap_req_type
    ,output logic               ctrl_datap_output_len
    
    ,output logic               ctrl_requester_hdr_val
    ,input                      requester_ctrl_hdr_rdy
    
    ,input  logic               requester_ctrl_resp_val
    ,input  logic               requester_ctrl_resp_last
    ,output logic               ctrl_requester_resp_rdy

    ,output logic               ctrl_rd_buf_req_val
    ,input  logic               rd_buf_ctrl_req_rdy

    ,input  logic               rd_buf_ctrl_resp_data_val
    ,input  logic               rd_buf_ctrl_resp_data_last
    ,output logic               ctrl_rd_buf_resp_data_rdy
    
    ,output logic               ctrl_wr_buf_req_val
    ,input  logic               wr_buf_ctrl_req_rdy

    ,output logic               ctrl_wr_buf_req_data_val
    ,output logic               ctrl_wr_buf_req_data_last
    ,input  logic               wr_buf_ctrl_req_data_rdy
    
    ,input  logic               wr_buf_ctrl_req_done
    ,output logic               ctrl_wr_buf_done_rdy
);

    typedef enum logic[3:0] {
        WAIT_NOTIF = 4'd0,
        SEND_READ_REQ = 4'd1,
        WAIT_RESP = 4'd2,
        READ_MEM = 4'd3,
        WAIT_MEM = 4'd4,
        REQ_META_TILE = 4'd5,
        WAIT_META_TILE = 4'd6, 
        REQ_DATA_TILE = 4'd7,
        REQ_TX_BUF = 4'd13,
        WAIT_TX_BUF = 4'd14,
        WR_REQ = 4'd9,
        WR_LEN = 4'd15,
        WR_DATA = 4'd8,
        WAIT_WR = 4'd10,
        BUMP_HEAD = 4'd11,
        BUMP_TAIL = 4'd12,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= WAIT_NOTIF;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        manager_in_noc0_rdy = 1'b0;
        manager_out_notif_noc1_val = 1'b0;
        manager_in_notif_noc1_rdy = 1'b0;

        ctrl_datap_output_len = 1'b0;
        ctrl_datap_store_new_flow = 1'b0;
        ctrl_datap_store_notif = 1'b0;
        ctrl_datap_store_req = 1'b0;
        ctrl_datap_store_meta = 1'b0;

        ctrl_rd_buf_req_val = 1'b0;
        ctrl_rd_buf_resp_data_rdy = 1'b0;
        ctrl_wr_buf_req_val = 1'b0;
        ctrl_wr_buf_req_data_val = 1'b0;

        ctrl_requester_hdr_val = 1'b0;
        ctrl_requester_resp_rdy = 1'b0;

        ctrl_datap_rx_notif_req = 1'b0;
        ctrl_datap_make_req = 1'b0;
        ctrl_datap_req_type = READ_REQ;

        state_next = state_reg;
        case (state_reg)
            WAIT_NOTIF: begin
                ctrl_datap_store_new_flow = 1'b1;
                manager_in_noc0_rdy = 1'b1;
                if (in_manager_noc0_val) begin
                    state_next = SEND_READ_REQ;
                end
            end
            SEND_READ_REQ: begin
                ctrl_datap_rx_notif_req = 1'b1;
                ctrl_datap_make_req = 1'b1;
                manager_out_notif_noc1_val = 1'b1;
                if (out_manager_notif_noc1_rdy) begin
                    state_next = WAIT_RESP;
                end
            end
            WAIT_RESP: begin
                manager_in_notif_noc1_rdy = 1'b1;
                ctrl_datap_store_notif = 1'b1;
                if (in_manager_notif_noc1_val) begin
                    state_next = READ_MEM;
                end
            end
            READ_MEM: begin
                ctrl_rd_buf_req_val = 1'b1;
                if (rd_buf_ctrl_req_rdy) begin
                    state_next = WAIT_MEM;
                end
            end
            WAIT_MEM: begin
                ctrl_rd_buf_resp_data_rdy = 1'b1;
                ctrl_datap_store_req = 1'b1;
                if (rd_buf_ctrl_resp_data_val) begin
                    state_next = BUMP_HEAD;
                end
            end
            BUMP_HEAD: begin
                ctrl_datap_rx_notif_req = 1'b1;
                manager_out_notif_noc1_val = 1'b1;
                if (out_manager_notif_noc1_rdy) begin
                    state_next = REQ_META_TILE;
                end
            end
            REQ_META_TILE: begin
                ctrl_requester_hdr_val = 1'b1;
                ctrl_datap_req_type = META_REQ;
                
                if (requester_ctrl_hdr_rdy) begin
                    state_next = WAIT_META_TILE;
                end
            end
            WAIT_META_TILE: begin
                ctrl_requester_resp_rdy = 1'b1;
                ctrl_datap_store_meta = 1'b1;
                if (requester_ctrl_resp_val) begin
                    state_next = REQ_TX_BUF;
                end
            end
            REQ_TX_BUF: begin
                ctrl_datap_make_req = 1'b1;
                manager_out_notif_noc1_val = 1'b1;
                if (out_manager_notif_noc1_rdy) begin
                    state_next = WAIT_TX_BUF;
                end
            end
            WAIT_TX_BUF: begin
                manager_in_notif_noc1_rdy = 1'b1;
                ctrl_datap_store_notif = 1'b1;
                if (in_manager_notif_noc1_val) begin
                    state_next = REQ_DATA_TILE;
                end
            end
            REQ_DATA_TILE: begin
                ctrl_datap_req_type = READ_REQ;
                ctrl_requester_hdr_val = 1'b1;
                if (requester_ctrl_hdr_rdy) begin
                    state_next = WR_REQ;
                end
            end
            WR_REQ: begin
                ctrl_wr_buf_req_val = 1'b1;
                if (wr_buf_ctrl_req_rdy) begin
                    state_next = WR_LEN;
                end
            end
            WR_LEN: begin
                ctrl_datap_output_len = 1'b1;

                ctrl_wr_buf_req_data_val = 1'b1;
                ctrl_wr_buf_req_data_last = 1'b0;

                if (wr_buf_ctrl_req_data_rdy) begin
                    state_next = WR_DATA;
                end
            end
            WR_DATA: begin
                ctrl_wr_buf_req_data_val = requester_ctrl_resp_val;
                ctrl_requester_resp_rdy = wr_buf_ctrl_req_data_rdy; 
                ctrl_wr_buf_req_data_last = requester_ctrl_resp_last;
                if (requester_ctrl_resp_val & wr_buf_ctrl_req_data_rdy) begin
                    if (requester_ctrl_resp_last) begin
                        state_next = WAIT_WR;
                    end
                end
            end
            WAIT_WR: begin
                ctrl_wr_buf_done_rdy = 1'b1;
                if (wr_buf_ctrl_req_done) begin
                    state_next = BUMP_TAIL;
                end
            end
            BUMP_TAIL: begin
                manager_out_notif_noc1_val = 1'b1;
                if (out_manager_notif_noc1_rdy) begin
                    state_next = SEND_READ_REQ;
                end
            end
            default: begin
                manager_in_noc0_rdy = 'X;
                manager_out_notif_noc1_val = 'X;
                manager_in_notif_noc1_rdy = 'X;

                ctrl_datap_store_new_flow = 'X;
                ctrl_datap_store_notif = 'X;
                ctrl_datap_store_req = 'X;
                ctrl_datap_store_meta = 'X;

                ctrl_rd_buf_req_val = 'X;
                ctrl_rd_buf_resp_data_rdy = 'X;
                ctrl_wr_buf_req_val = 'X;
                ctrl_wr_buf_req_data_val = 'X;

                ctrl_requester_hdr_val = 'X;
                ctrl_requester_resp_rdy = 'X;

                ctrl_datap_rx_notif_req = 'X;
                ctrl_datap_make_req = 'X;
                ctrl_datap_req_type = READ_REQ;

                state_next = UND;
            end
        endcase
    end
endmodule
