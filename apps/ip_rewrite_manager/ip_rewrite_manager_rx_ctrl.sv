`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager_rx_ctrl (
     input clk
    ,input rst 
    
    ,input                                  noc0_ctovr_ip_rewrite_manager_rx_val
    ,output logic                           ip_rewrite_manager_rx_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_manager_rx_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_ip_rewrite_manager_rx_rdy

    ,output logic                           in_ctrl_out_ctrl_resp_val
    ,input  logic                           out_ctrl_in_ctrl_resp_rdy

    ,output logic                           in_ctrl_in_datap_store_flow_notif
    ,output ip_manager_noc_sel              in_ctrl_in_datap_noc_sel
    ,output ip_manager_tile_sel             in_ctrl_in_datap_tile_sel
    ,output ip_manager_if_sel               in_ctrl_in_datap_if_sel
    ,output logic                           in_ctrl_in_datap_store_req_notif
    ,output logic                           in_ctrl_in_datap_store_rewrite_req

    ,output logic                           in_ctrl_rd_rx_buf_val
    ,input  logic                           rd_rx_buf_in_ctrl_rdy
    
    ,input  logic                           rd_rx_buf_in_ctrl_data_val
    ,output logic                           in_ctrl_rd_rx_buf_data_rdy
    
    ,input  logic                           noc_rewrite_ctrl_in_val
    ,output logic                           rewrite_ctrl_noc_in_rdy

    ,output logic                           rewrite_ctrl_noc_out_val
    ,input  logic                           noc_rewrite_ctrl_out_rdy
);

    typedef enum logic[3:0] {
        WAIT_FLOW_NOTIF = 4'd0,
        SEND_REQ = 4'd1,
        WAIT_REQ_NOTIF = 4'd2,
        GET_REQ_DATA = 4'd3,
        WAIT_REQ_DATA = 4'd4,
        REWRITE_UPDATE_SEND_HDR = 4'd5,
        REWRITE_UPDATE_SEND_BODY = 4'd6,
        REWRITE_UPDATE_WAIT = 4'd7,
        NOTIF_OUTPUT = 4'd8,
        ADJUST_RX_HEAD = 4'd9,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    ip_manager_tile_sel tile_sel_reg;
    ip_manager_tile_sel tile_sel_next;
    
    assign in_ctrl_in_datap_tile_sel = tile_sel_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= WAIT_FLOW_NOTIF;
            tile_sel_reg <= RX_REWRITE;
        end
        else begin
            state_reg <= state_next;
            tile_sel_reg <= tile_sel_next;
        end
    end

    always_comb begin
        ip_rewrite_manager_rx_noc0_ctovr_rdy = 1'b0;
        ip_rewrite_manager_rx_noc0_vrtoc_val = 1'b0;

        rewrite_ctrl_noc_in_rdy = 1'b0;
        rewrite_ctrl_noc_out_val = 1'b0;

        in_ctrl_in_datap_store_flow_notif = 1'b0;
        in_ctrl_in_datap_store_req_notif = 1'b0;
        in_ctrl_in_datap_store_rewrite_req = 1'b0;

        in_ctrl_in_datap_noc_sel = TCP_REQ;
        in_ctrl_in_datap_if_sel = TCP_BUF_REQ;

        in_ctrl_rd_rx_buf_val = 1'b0;
        in_ctrl_rd_rx_buf_data_rdy = 1'b0;

        in_ctrl_out_ctrl_resp_val = 1'b0;

        tile_sel_next = tile_sel_reg;
        state_next = state_reg;
        case (state_reg)
            WAIT_FLOW_NOTIF: begin
                ip_rewrite_manager_rx_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_ip_rewrite_manager_rx_val) begin
                    in_ctrl_in_datap_store_flow_notif = 1'b1;
                    state_next = SEND_REQ;
                end
            end
            SEND_REQ: begin
                tile_sel_next = RX_REWRITE;
                in_ctrl_in_datap_noc_sel = TCP_REQ;
                in_ctrl_in_datap_if_sel = TCP_BUF_REQ;
                ip_rewrite_manager_rx_noc0_vrtoc_val = 1'b1;

                if (noc0_vrtoc_ip_rewrite_manager_rx_rdy) begin
                    state_next = WAIT_REQ_NOTIF;
                end
            end
            WAIT_REQ_NOTIF: begin
                ip_rewrite_manager_rx_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_ip_rewrite_manager_rx_val) begin
                    in_ctrl_in_datap_store_req_notif = 1'b1;
                    state_next = GET_REQ_DATA;
                end
            end
            GET_REQ_DATA: begin
                in_ctrl_rd_rx_buf_val = 1'b1;
                if (rd_rx_buf_in_ctrl_rdy) begin
                    state_next = WAIT_REQ_DATA;
                end
            end
            WAIT_REQ_DATA: begin
                in_ctrl_rd_rx_buf_data_rdy = 1'b1;
                if (rd_rx_buf_in_ctrl_data_val) begin
                    in_ctrl_in_datap_store_rewrite_req = 1'b1;
                    state_next = REWRITE_UPDATE_SEND_HDR;
                end
            end
            REWRITE_UPDATE_SEND_HDR: begin
                rewrite_ctrl_noc_out_val = 1'b1;
                in_ctrl_in_datap_noc_sel = REWRITE_NOTIF_HDR;
                if (noc_rewrite_ctrl_out_rdy) begin
                    state_next = REWRITE_UPDATE_SEND_BODY;
                end
            end
            REWRITE_UPDATE_SEND_BODY: begin
                rewrite_ctrl_noc_out_val = 1'b1;
                in_ctrl_in_datap_noc_sel = REWRITE_NOTIF_BODY;
                if (noc_rewrite_ctrl_out_rdy) begin
                    state_next = REWRITE_UPDATE_WAIT;
                end
            end
            REWRITE_UPDATE_WAIT: begin
                rewrite_ctrl_noc_in_rdy = 1'b1;
                if (noc_rewrite_ctrl_in_val) begin
                    if (tile_sel_reg == RX_REWRITE) begin
                        tile_sel_next = TX_REWRITE;
                        state_next = REWRITE_UPDATE_SEND_HDR;
                    end
                    else begin
                        state_next = NOTIF_OUTPUT;
                    end
                end
            end
            NOTIF_OUTPUT: begin
                in_ctrl_out_ctrl_resp_val = 1'b1;
                if (out_ctrl_in_ctrl_resp_rdy) begin
                    state_next = ADJUST_RX_HEAD;
                end
            end
            ADJUST_RX_HEAD: begin
                in_ctrl_in_datap_noc_sel = TCP_REQ;
                in_ctrl_in_datap_if_sel = TCP_RX_PTR_UPDATE;

                ip_rewrite_manager_rx_noc0_vrtoc_val = 1'b1;

                if (noc0_vrtoc_ip_rewrite_manager_rx_rdy) begin
                    state_next = SEND_REQ;
                end
            end
            default: begin
                ip_rewrite_manager_rx_noc0_ctovr_rdy = 'X;
                ip_rewrite_manager_rx_noc0_vrtoc_val = 'X;
        
                rewrite_ctrl_noc_in_rdy = 'X;
                rewrite_ctrl_noc_out_val = 'X;

                in_ctrl_in_datap_store_flow_notif = 'X;
                in_ctrl_in_datap_store_req_notif = 'X;
                in_ctrl_in_datap_store_rewrite_req = 'X;

                in_ctrl_in_datap_noc_sel = REWRITE_NOTIF_HDR;
                in_ctrl_in_datap_if_sel = TCP_BUF_REQ;

                in_ctrl_rd_rx_buf_val = 'X;
                in_ctrl_rd_rx_buf_data_rdy = 'X;

                in_ctrl_out_ctrl_resp_val = 'X;

                tile_sel_next = RX_REWRITE;
                state_next = UND;
            end
        endcase
    end
endmodule
