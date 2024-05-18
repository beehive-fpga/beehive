module tracker_record_ctrl (
     input  logic   clk
    ,input  logic   rst

    ,input  logic                               noc_wr_tracker_in_val
    ,output logic                               wr_tracker_noc_in_rdy
    
    ,output logic                               wr_tracker_noc_out_val
    ,input                                      noc_wr_tracker_out_rdy

    ,input  logic                               datap_ctrl_filter_val
    ,input  logic                               datap_ctrl_filter_record
    ,output logic                               ctrl_datap_filter_rdy
    
    ,output logic                               ctrl_datap_store_hdr
    ,output logic                               ctrl_datap_incr_flits

    ,input  logic                               datap_ctrl_last_flit

    ,output logic                               log_wr_req_val
);

    typedef enum logic[1:0] {
        HDR_FLIT_RECORD = 2'd0,
        FLITS_PASS = 2'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR_FLIT_RECORD;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        ctrl_datap_filter_rdy = 1'b0;
        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_incr_flits = 1'b0;

        log_wr_req_val = 1'b0;

        wr_tracker_noc_out_val = 1'b0;
        wr_tracker_noc_in_rdy = 1'b0;

        state_next = state_reg;
        case (state_reg)
            HDR_FLIT_RECORD: begin
                ctrl_datap_store_hdr = 1'b1;
                wr_tracker_noc_out_val = datap_ctrl_filter_val & noc_wr_tracker_in_val;
                wr_tracker_noc_in_rdy = datap_ctrl_filter_val & noc_wr_tracker_out_rdy;

                if (datap_ctrl_filter_val & noc_wr_tracker_in_val & noc_wr_tracker_out_rdy) begin
                    ctrl_datap_filter_rdy = 1'b1;
                    log_wr_req_val = datap_ctrl_filter_record;

                    state_next = FLITS_PASS;
                end
            end
            FLITS_PASS: begin
                wr_tracker_noc_out_val = noc_wr_tracker_in_val;
                wr_tracker_noc_in_rdy = noc_wr_tracker_out_rdy;

                if (noc_wr_tracker_in_val & noc_wr_tracker_out_rdy) begin
                    ctrl_datap_incr_flits = 1'b1;
                    if (datap_ctrl_last_flit) begin
                        state_next = HDR_FLIT_RECORD;
                    end
                end
            end
            default: begin
                ctrl_datap_filter_rdy = 'X;

                log_wr_req_val = 'X;

                wr_tracker_noc_out_val = 'X;
                wr_tracker_noc_in_rdy = 'X;

                state_next = UND;

            end
        endcase
    end
endmodule
