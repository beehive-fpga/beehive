`include "tcp_tx_tile_defs.svh"
module tcp_tx_ptr_if_ctrl (
     input clk
    ,input rst 

    ,input  logic                           noc0_ctovr_tcp_tx_ptr_if_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_tcp_tx_ptr_if_data
    ,output logic                           tcp_tx_ptr_if_noc0_ctovr_rdy

    ,output logic                           tcp_tx_ptr_if_noc0_vrtoc_val
    ,input  logic                           noc0_vrtoc_tcp_tx_ptr_if_rdy
    
    ,output logic                           app_tail_ptr_tx_wr_req_val
    ,input                                  tail_ptr_app_tx_wr_req_rdy
    
    ,output logic                           app_tail_ptr_tx_rd_req_val
    ,input  logic                           tail_ptr_app_tx_rd_req_rdy

    ,input                                  tail_ptr_app_tx_rd_resp_val
    ,output logic                           app_tail_ptr_tx_rd_resp_rdy

    ,output logic                           app_head_ptr_tx_rd_req_val
    ,input  logic                           head_ptr_app_tx_rd_req_rdy

    ,input                                  head_ptr_app_tx_rd_resp_val
    ,output logic                           app_head_ptr_tx_rd_resp_rdy

    ,output logic                           ctrl_datap_store_hdr_flit
    ,output logic                           ctrl_datap_store_ptrs
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        WR_TAIL_PTR = 3'd1,
        READ_PTRS = 3'd2,
        READ_PTRS_RESP = 3'd3,
        HDR_FLIT = 3'd4,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    tcp_noc_hdr_flit hdr_flit_cast;

    assign hdr_flit_cast = noc0_ctovr_tcp_tx_ptr_if_data;

    always_comb begin
        tcp_tx_ptr_if_noc0_ctovr_rdy = 1'b0;
        tcp_tx_ptr_if_noc0_vrtoc_val = 1'b0;

        app_tail_ptr_tx_wr_req_val = 1'b0;
        app_head_ptr_tx_rd_req_val = 1'b0;
        app_tail_ptr_tx_rd_req_val = 1'b0;
        app_head_ptr_tx_rd_resp_rdy = 1'b0;
        app_tail_ptr_tx_rd_resp_rdy = 1'b0;

        ctrl_datap_store_hdr_flit = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                tcp_tx_ptr_if_noc0_ctovr_rdy = 1'b1;
                ctrl_datap_store_hdr_flit = 1'b1;

                if (noc0_ctovr_tcp_tx_ptr_if_val) begin
                    if (hdr_flit_cast.core.msg_type == TCP_TX_PTRS_REQ) begin
                        state_next = READ_PTRS;
                    end
                    else begin
                        state_next = WR_TAIL_PTR;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            WR_TAIL_PTR: begin
                app_tail_ptr_tx_wr_req_val = 1'b1;

                if (tail_ptr_app_tx_wr_req_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = WR_TAIL_PTR;
                end
            end
            READ_PTRS: begin
                if (head_ptr_app_tx_rd_req_rdy & tail_ptr_app_tx_rd_req_rdy) begin
                    app_head_ptr_tx_rd_req_val = 1'b1;
                    app_tail_ptr_tx_rd_req_val = 1'b1;

                    state_next = READ_PTRS_RESP;
                end
                else begin
                    state_next = READ_PTRS;
                end
            end
            READ_PTRS_RESP: begin
                ctrl_datap_store_ptrs = 1'b1;
                if (head_ptr_app_tx_rd_resp_val & tail_ptr_app_tx_rd_resp_val) begin
                    app_head_ptr_tx_rd_resp_rdy = 1'b1;
                    app_tail_ptr_tx_rd_resp_rdy = 1'b1;
                    
                    state_next = HDR_FLIT;
                end
                else begin
                    state_next = READ_PTRS_RESP;
                end
            end
            HDR_FLIT: begin
                tcp_tx_ptr_if_noc0_vrtoc_val = 1'b1;
                if (noc0_vrtoc_tcp_tx_ptr_if_rdy) begin
                    state_next = READY;
                end
                else begin
                    state_next = HDR_FLIT;
                end
            end
        endcase
    end


endmodule
