module tracker_read_ctrl 
    import tracker_pkg::*;
(
     input clk
    ,input rst
    
    ,input                                      noc_reader_in_val
    ,output logic                               reader_in_noc_rdy
    
    ,output logic                               reader_out_noc_val
    ,input                                      noc_reader_out_rdy

    ,output logic                               log_rd_req_val
    
    ,input  logic                               log_rd_resp_val

    ,output logic                               ctrl_datap_incr_rd_addr
    ,output logic                               ctrl_datap_store_req
    ,output logic                               ctrl_datap_store_flit_2
    ,output flit_sel_e                          ctrl_datap_output_flit_sel

    ,input  tracker_req_type                    datap_ctrl_req_type
    ,input  logic                               datap_ctrl_last_entry

    ,input  logic                               width_fix_out_ctrl_val
    ,input  logic                               width_fix_out_ctrl_last
    ,input  logic                               width_fix_in_ctrl_rdy
    ,output logic                               width_fix_in_ctrl_last
);

    typedef enum logic [3:0] {
        HDR_1_IN = 4'd0,
        HDR_2_IN = 4'd1,
        REQ_IN = 4'd2,
        HDR_1_OUT = 4'd3,
        HDR_2_OUT = 4'd4,
        RESP_OUT = 4'd5,
        DATA_RESP = 4'd8,
        DATA_READ = 4'd6,
        DRAIN = 4'd7,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR_1_IN;
        end
        else begin
            state_reg <= state_next;
        end
    end

  
    always_comb begin
        width_fix_in_ctrl_last = 1'b0;
        ctrl_datap_store_req = 1'b0;
        ctrl_datap_store_flit_2 = 1'b0;

        ctrl_datap_incr_rd_addr = 1'b0;
        ctrl_datap_output_flit_sel = DATA;

        log_rd_req_val = 1'b0;

        reader_in_noc_rdy = 1'b0;
        reader_out_noc_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            HDR_1_IN: begin
                reader_in_noc_rdy = 1'b1;
                if (noc_reader_in_val) begin
                    state_next = HDR_2_IN;
                end
            end
            HDR_2_IN: begin
                reader_in_noc_rdy = 1'b1;
                ctrl_datap_store_flit_2 = 1'b1;
                if (noc_reader_in_val) begin
                    state_next = REQ_IN;
                end
            end
            REQ_IN: begin
                reader_in_noc_rdy = 1'b1;
                ctrl_datap_store_req = 1'b1;
                if (noc_reader_in_val) begin
                    state_next = HDR_1_OUT;
                end
            end
            HDR_1_OUT: begin
                reader_out_noc_val = 1'b1;
                ctrl_datap_output_flit_sel = HDR_1;
                if (noc_reader_out_rdy) begin
                    state_next = HDR_2_OUT;
                end
            end
            HDR_2_OUT: begin
                reader_out_noc_val = 1'b1;
                ctrl_datap_output_flit_sel = HDR_2;
                if (noc_reader_out_rdy) begin
                    state_next = RESP_OUT;
                end
            end
            RESP_OUT: begin
                reader_out_noc_val = 1'b1;
                ctrl_datap_output_flit_sel = TRACKER;
                if (noc_reader_out_rdy) begin
                    if (datap_ctrl_req_type == READ_REQ) begin
                        state_next = DATA_READ;
                    end
                    else begin
                        state_next = HDR_1_IN;
                    end
                end
            end
            DATA_READ: begin
                reader_out_noc_val = width_fix_out_ctrl_val;
                log_rd_req_val = 1'b1;

                state_next = DATA_RESP;
            end
            DATA_RESP: begin
                reader_out_noc_val = width_fix_out_ctrl_val;
                if (log_rd_resp_val) begin
                    if (width_fix_in_ctrl_rdy) begin
                        ctrl_datap_incr_rd_addr = 1'b1;
                        if (datap_ctrl_last_entry) begin
                            width_fix_in_ctrl_last = 1'b1;
                            state_next = DRAIN;
                        end
                        else begin
                            state_next = DATA_READ;
                        end
                    end
                    else begin
                        state_next = DATA_READ;
                    end
                end
            end
            DRAIN: begin
                reader_out_noc_val = width_fix_out_ctrl_val;
                if (width_fix_out_ctrl_val & noc_reader_out_rdy & width_fix_out_ctrl_last) begin
                    state_next = HDR_1_IN;
                end
            end
            default: begin
                ctrl_datap_store_req = 'X;
                ctrl_datap_store_flit_2 = 'X;

                ctrl_datap_incr_rd_addr = 'X;
                ctrl_datap_output_flit_sel = DATA;

                log_rd_req_val = 'X;

                reader_in_noc_rdy = 'X;
                reader_out_noc_val = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
