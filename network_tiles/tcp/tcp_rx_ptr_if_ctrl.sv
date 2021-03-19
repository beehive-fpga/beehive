`include "tcp_rx_tile_defs.svh"
module tcp_rx_ptr_if_ctrl (
     input clk
    ,input rst
    
    ,input  logic                           noc0_ctovr_tcp_rx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_rx_ptr_if_data
    ,output logic                           tcp_rx_ptr_if_noc0_ctovr_rdy

    ,output logic                           tcp_rx_ptr_if_noc0_vrtoc_val
    ,input  logic                           noc0_vrtoc_tcp_rx_ptr_if_rdy
    
    ,output logic                           app_rx_head_ptr_wr_req_val
    ,input  logic                           rx_head_ptr_app_wr_req_rdy

    ,output logic                           app_rx_head_ptr_rd_req_val
    ,input  logic                           rx_head_ptr_app_rd_req_rdy
    
    ,input  logic                           rx_head_ptr_app_rd_resp_val
    ,output logic                           app_rx_head_ptr_rd_resp_rdy

    ,output logic                           app_rx_commit_ptr_rd_req_val
    ,input  logic                           rx_commit_ptr_app_rd_req_rdy

    ,input  logic                           rx_commit_ptr_app_rd_resp_val
    ,output logic                           app_rx_commit_ptr_rd_resp_rdy

    ,output logic                           ctrl_datap_store_hdr_flit
    ,output logic                           ctrl_datap_store_ptrs
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        WR_HD_PTR = 3'd1,
        READ_PTRS = 3'd2,
        READ_PTRS_RESP = 3'd3,
        HDR_FLIT = 3'd4,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    beehive_noc_hdr_flit hdr_flit_cast;

    assign hdr_flit_cast = noc0_ctovr_tcp_rx_ptr_if_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        tcp_rx_ptr_if_noc0_ctovr_rdy = 1'b0;
        tcp_rx_ptr_if_noc0_vrtoc_val = 1'b0;

        app_rx_head_ptr_wr_req_val = 1'b0;
        app_rx_head_ptr_rd_req_val = 1'b0;
        app_rx_commit_ptr_rd_req_val = 1'b0;
        app_rx_head_ptr_rd_resp_rdy = 1'b0;
        app_rx_commit_ptr_rd_resp_rdy = 1'b0;

        ctrl_datap_store_hdr_flit = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                tcp_rx_ptr_if_noc0_ctovr_rdy = 1'b1;
                ctrl_datap_store_hdr_flit = 1'b1;

                if (noc0_ctovr_tcp_rx_ptr_if_val) begin
                    if (hdr_flit_cast.core.msg_type == TCP_RX_PTRS_REQ) begin
                        state_next = READ_PTRS;
                    end
                    else begin
                        state_next = WR_HD_PTR;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            WR_HD_PTR: begin
                app_rx_head_ptr_wr_req_val = 1'b1;

                if (rx_head_ptr_app_wr_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = WR_HD_PTR;
                end
            end
            READ_PTRS: begin
                if (rx_head_ptr_app_rd_req_rdy & rx_commit_ptr_app_rd_req_rdy) begin
                    app_rx_commit_ptr_rd_req_val = 1'b1;
                    app_rx_head_ptr_rd_req_val = 1'b1;

                    state_next = READ_PTRS_RESP;
                end
                else begin
                    state_next = READ_PTRS;
                end
            end
            READ_PTRS_RESP: begin
                ctrl_datap_store_ptrs = 1'b1;
                if (rx_head_ptr_app_rd_resp_val & rx_commit_ptr_app_rd_resp_val) begin
                    app_rx_head_ptr_rd_resp_rdy = 1'b1;
                    app_rx_commit_ptr_rd_resp_rdy = 1'b1;
                    state_next = HDR_FLIT;
                end
                else begin
                    state_next = READ_PTRS_RESP;
                end
            end
            HDR_FLIT: begin
                tcp_rx_ptr_if_noc0_vrtoc_val = 1'b1;
                if (noc0_vrtoc_tcp_rx_ptr_if_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = HDR_FLIT;
                end
            end
            default: begin
                tcp_rx_ptr_if_noc0_ctovr_rdy = 'X;
                tcp_rx_ptr_if_noc0_vrtoc_val = 'X;

                app_rx_head_ptr_wr_req_val = 'X;
                app_rx_head_ptr_rd_req_val = 'X;
                app_rx_commit_ptr_rd_req_val = 'X;
                app_rx_head_ptr_rd_resp_rdy = 'X;
                app_rx_commit_ptr_rd_resp_rdy = 'X;

                ctrl_datap_store_hdr_flit = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
