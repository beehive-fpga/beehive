module rd_circ_buf_ctrl_new 
(
     input clk
    ,input rst

    ,input                                          src_rd_buf_req_val
    ,output logic                                   rd_buf_src_req_rdy

    ,output logic                                   ctrl_rd_noc_req_val
    ,input  logic                                   rd_noc_ctrl_req_rdy

    ,input  logic                                   rd_noc_ctrl_resp_data_val
    ,input  logic                                   rd_noc_ctrl_resp_data_last
    ,output logic                                   ctrl_rd_noc_resp_data_rdy

    ,output logic                                   rd_buf_src_resp_data_val
    ,output logic                                   rd_buf_src_resp_data_last
    ,input  logic                                   src_rd_buf_resp_data_rdy

    ,output logic                                   ctrl_datap_store_req_state
    ,output logic                                   ctrl_datap_update_req_state
    ,output logic                                   ctrl_datap_save_req
    ,output logic                                   ctrl_datap_decr_bytes_out_reg
    ,output logic                                   ctrl_datap_store_shift
    ,output logic                                   ctrl_datap_use_shift
    ,output logic                                   ctrl_datap_write_upper
    ,output logic                                   ctrl_datap_shift_regs
    ,output logic                                   ctrl_datap_write_lower
    ,output logic                                   ctrl_datap_lower_zeros

    ,input  logic                                   datap_ctrl_split_req
    ,input  logic                                   datap_ctrl_last_data_out
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        WRAP_REQ = 3'd4,
        WAIT_WRAP_RESP = 3'd5,
        WAIT_RESP = 3'd1,
        DATA_BUFFER = 3'd2,
        DATA_OUTPUT = 3'd3,
        DATA_DRAIN = 3'd7,
        // we need to do this, since we expect the wrapped data
        // to be stored into the lower reg
        DATA_OUT_FOR_WRAP = 3'd6,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   need_wrap_reg;
    logic   need_wrap_next;

    logic   use_shift_reg;
    logic   use_shift_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            need_wrap_reg <= '0;
            use_shift_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            need_wrap_reg <= need_wrap_next;
            use_shift_reg <= use_shift_next;
        end
    end

    assign ctrl_datap_use_shift = use_shift_reg;

    always_comb begin
        rd_buf_src_req_rdy = 1'b0;
        ctrl_rd_noc_req_val = 1'b0;
        rd_buf_src_resp_data_val = 1'b0;
        rd_buf_src_resp_data_last = 1'b0;
        ctrl_rd_noc_resp_data_rdy = 1'b0;

        ctrl_datap_store_req_state = 1'b0;
        ctrl_datap_update_req_state = 1'b0;
        ctrl_datap_write_upper = 1'b0;
        ctrl_datap_write_lower = 1'b0;
        ctrl_datap_store_shift = 1'b0;
        ctrl_datap_shift_regs = 1'b0;
        ctrl_datap_save_req = 1'b0;
        ctrl_datap_decr_bytes_out_reg = 1'b0;
        ctrl_datap_lower_zeros = 1'b0;

        use_shift_next = use_shift_reg;
        need_wrap_next = need_wrap_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                rd_buf_src_req_rdy = rd_noc_ctrl_req_rdy;
                ctrl_rd_noc_req_val = src_rd_buf_req_val;
                ctrl_datap_store_req_state = 1'b1;
                need_wrap_next = datap_ctrl_split_req;
                ctrl_datap_save_req = 1'b1;
                use_shift_next = 1'b0;

                if (src_rd_buf_req_val & rd_noc_ctrl_req_rdy) begin
                    state_next = WAIT_RESP;
                end
            end
            WAIT_RESP: begin
                ctrl_rd_noc_resp_data_rdy = 1'b1;
                if (rd_noc_ctrl_resp_data_val) begin
                    ctrl_datap_update_req_state = 1'b1;
                    // if there was only one line in the read response
                    if (rd_noc_ctrl_resp_data_last) begin
                        ctrl_datap_write_upper = 1'b1;
                        ctrl_datap_store_shift = 1'b1;
                        use_shift_next = use_shift_reg;
                        // if we need to issue another request
                        if (need_wrap_reg) begin
                            state_next = WRAP_REQ;
                        end
                        else begin
                            state_next = DATA_DRAIN;
                        end
                    end
                    else begin
                        ctrl_datap_shift_regs = 1'b1;
                        state_next = DATA_BUFFER;
                    end
                end
            end
            DATA_BUFFER: begin
                ctrl_rd_noc_resp_data_rdy = 1'b1;
                if (rd_noc_ctrl_resp_data_val) begin
                    ctrl_datap_shift_regs = 1'b1;
                    if (rd_noc_ctrl_resp_data_last) begin
                        if (need_wrap_reg) begin
                            ctrl_datap_store_shift = 1'b1;
                            state_next = DATA_OUT_FOR_WRAP;
                        end
                        else begin
                            state_next = DATA_DRAIN;
                        end
                    end
                    else begin
                        state_next = DATA_OUTPUT;
                    end
                end
            end
            DATA_OUTPUT: begin
                rd_buf_src_resp_data_val = rd_noc_ctrl_resp_data_val;
                ctrl_rd_noc_resp_data_rdy = src_rd_buf_resp_data_rdy;

                if (rd_noc_ctrl_resp_data_val & src_rd_buf_resp_data_rdy) begin
                    ctrl_datap_shift_regs = 1'b1;
                    ctrl_datap_decr_bytes_out_reg = 1'b1;

                    if (rd_noc_ctrl_resp_data_last) begin
                        if (need_wrap_reg) begin
                            ctrl_datap_store_shift = 1'b1;
                            state_next = DATA_OUT_FOR_WRAP;
                        end
                        else if (datap_ctrl_last_data_out) begin
                            rd_buf_src_resp_data_last = 1'b1;
                            state_next = READY;
                        end
                        else begin
                            state_next = DATA_DRAIN;
                        end
                    end
                end
            end
            DATA_DRAIN: begin
                rd_buf_src_resp_data_val = 1'b1;
                rd_buf_src_resp_data_last = datap_ctrl_last_data_out;

                if (src_rd_buf_resp_data_rdy) begin
                    if (~datap_ctrl_last_data_out) begin
                        ctrl_datap_decr_bytes_out_reg = 1'b1;
                        ctrl_datap_shift_regs = 1'b1;
                        ctrl_datap_lower_zeros = 1'b1;

                        state_next = DATA_DRAIN;
                    end
                    else begin
                        state_next = READY;
                    end
                end
            end
            DATA_OUT_FOR_WRAP: begin
                rd_buf_src_resp_data_val = 1'b1;
                if (src_rd_buf_resp_data_rdy) begin
                    ctrl_datap_decr_bytes_out_reg = 1'b1;
                    ctrl_datap_shift_regs = 1'b1;
                    state_next = WRAP_REQ;
                end
            end
            WRAP_REQ: begin
                ctrl_rd_noc_req_val = 1'b1;
                need_wrap_next = 1'b0;
                use_shift_next = 1'b1;
                if (rd_noc_ctrl_req_rdy) begin
                    state_next = WAIT_WRAP_RESP;
                end
            end
            WAIT_WRAP_RESP: begin
                ctrl_rd_noc_resp_data_rdy = 1'b1;
                if (rd_noc_ctrl_resp_data_val) begin
                    ctrl_datap_update_req_state = 1'b1;
                    ctrl_datap_write_lower = 1'b1;

                    if (rd_noc_ctrl_resp_data_last) begin
                        state_next = DATA_DRAIN;
                    end
                    else begin
                        state_next = DATA_OUTPUT;
                    end
                end
            end
            default: begin
                rd_buf_src_req_rdy = 'X;
                ctrl_rd_noc_req_val = 'X;
                ctrl_rd_noc_resp_data_rdy = 'X;

                ctrl_datap_store_req_state = 'X;
                ctrl_datap_update_req_state = 'X;
                ctrl_datap_write_upper = 'X;
                ctrl_datap_write_lower = 'X;
                ctrl_datap_store_shift = 'X;
                ctrl_datap_shift_regs = 'X;
                ctrl_datap_save_req = 'X;
                ctrl_datap_decr_bytes_out_reg = 'X;
                ctrl_datap_lower_zeros = 'X;

                use_shift_next = 'X;
                need_wrap_next = 'X;
                state_next = UND;
            end
        endcase
    end
endmodule
