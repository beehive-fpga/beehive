`include "simple_log_udp_noc_read_defs.svh"
module simple_log_udp_noc_read_64_ctrl (
     input clk
    ,input rst
    
    ,input                                      ctovr_reader_in_val
    ,output logic                               reader_in_ctovr_rdy
    
    ,output logic                               reader_out_vrtoc_val
    ,input                                      vrtoc_reader_out_rdy
   
    ,output logic                               ctrl_datap_store_msg_len
    ,output logic                               ctrl_datap_store_meta_len
    ,output logic                               ctrl_datap_store_meta
    ,output logic                               ctrl_datap_store_req
    ,output logic                               ctrl_datap_store_log_resp
    ,output         simple_log_resp_sel_e       ctrl_datap_output_flit_sel
    ,output logic                               ctrl_datap_init_flit_count
    ,output logic                               ctrl_datap_incr_flit_count

    ,input  logic                               datap_ctrl_rd_meta
    ,input  logic                               datap_ctrl_last_data_flit

    ,output logic                               log_rd_req_val
    
    ,input  logic                               log_rd_resp_val
);

    typedef enum logic[3:0] {
        READY = 4'd0,
        HDR_2 = 4'd1,
        META_FLITS = 4'd2,
        REQ_DATA_FLITS = 4'd3,
        RD_LOG = 4'd4,
        SAVE_LOG_RD = 4'd5,
        HDR_1_RESP = 4'd6,
        HDR_2_RESP = 4'd7,
        META_FLITS_RESP  = 4'd8,
        DATA_FLITS_RESP = 4'd9,
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
    
    always_comb begin
        reader_in_ctovr_rdy = 1'b0;
        reader_out_vrtoc_val = 1'b0;

        ctrl_datap_store_meta = 1'b0;
        ctrl_datap_store_req = 1'b0;
        ctrl_datap_store_log_resp = 1'b0;
        ctrl_datap_output_flit_sel = simple_log_udp_noc_read_pkg::HDR;
        ctrl_datap_init_flit_count = 1'b0;
        ctrl_datap_incr_flit_count = 1'b0;

        log_rd_req_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
            end
        endcase
    end

endmodule
