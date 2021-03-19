module masked_mem_rd_ctrl (
     input clk
    ,input rst
    
    ,input                                      noc0_ctovr_controller_val
    ,output logic                               controller_noc0_ctovr_rdy

    ,output logic                               controller_noc0_vrtoc_val
    ,input                                      noc0_vrtoc_controller_rdy

    ,output logic                               controller_mem_read_en
    ,input  logic                               mem_controller_rdy
    ,input                                      mem_controller_rd_data_val
    
    ,output logic                               rd_ctrl_rd_in_progress

    ,output logic                               rd_ctrl_datap_store_state
    ,output logic                               rd_ctrl_datap_update_state
    ,output logic                               rd_ctrl_datap_store_rem_reg
    ,output logic                               rd_ctrl_datap_shift_regs
    ,output logic                               rd_ctrl_datap_hdr_flit_out
    ,output logic                               rd_ctrl_datap_incr_sent_flits

    ,input  logic                               datap_rd_ctrl_last_read
    ,input  logic                               datap_rd_ctrl_last_flit
    ,input  logic                               datap_rd_ctrl_first_read
    ,input  logic                               datap_rd_ctrl_first_read_wait

);

    typedef enum logic[2:0] {
        READY = 3'd0,
        // technically we can issue the first read from ready...but then we'd 
        // need to take the address before it's been flopped
        RD_OP_FIRST_RD = 3'd1,
        RD_OP_FIRST_RESP = 3'd2,
        RD_OP_RESP = 3'd3,
        RD_PAYLOAD_OUT = 3'd4,
        RD_PAYLOAD_REM_OUT = 3'd5,
        MEM_WAIT = 3'd6,
        HDR_FLIT_OUT = 3'd7,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   hdr_out_reg;
    logic   hdr_out_next;

    assign rd_ctrl_rd_in_progress = state_reg != READY;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            hdr_out_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            hdr_out_reg <= hdr_out_next;
        end
    end

    always_comb begin
        controller_noc0_ctovr_rdy = 1'b0;
        controller_noc0_vrtoc_val = 1'b0;

        controller_mem_read_en = 1'b0;

        rd_ctrl_datap_store_state = 1'b0;
        rd_ctrl_datap_update_state = 1'b0;
        rd_ctrl_datap_shift_regs = 1'b0;
        rd_ctrl_datap_store_rem_reg = 1'b0;
        rd_ctrl_datap_hdr_flit_out = 1'b0;
        rd_ctrl_datap_incr_sent_flits = 1'b0;

        hdr_out_next = hdr_out_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                controller_noc0_ctovr_rdy = 1'b1;
                hdr_out_next = 1'b0;
                if (noc0_ctovr_controller_val) begin
                    rd_ctrl_datap_store_state = 1'b1;
                    state_next = RD_OP_FIRST_RD;
                end
            end
            RD_OP_FIRST_RD: begin
                controller_mem_read_en = 1'b1;
                if (mem_controller_rdy) begin
                    rd_ctrl_datap_update_state = 1'b1;
                    state_next = RD_OP_FIRST_RESP;
                end
            end
            MEM_WAIT: begin
                controller_mem_read_en = 1'b1;
                if (mem_controller_rdy) begin
                    rd_ctrl_datap_update_state = 1'b1;
                    if (datap_rd_ctrl_first_read) begin
                        state_next = RD_OP_FIRST_RESP;
                    end
                    else begin
                        state_next = RD_OP_RESP;
                    end
                end
            end
            RD_OP_FIRST_RESP: begin
                if (mem_controller_rd_data_val) begin
                    // the first read can be a partial line, in which case we
                    // need to save and wait for the next line
                    if (datap_rd_ctrl_first_read_wait) begin
                        rd_ctrl_datap_shift_regs = 1'b1;
                        if (mem_controller_rdy) begin
                            rd_ctrl_datap_update_state = 1'b1;
                            controller_mem_read_en = 1'b1;

                            state_next = RD_OP_RESP;
                        end
                        else begin
                            state_next = MEM_WAIT;
                        end
                    end
                    else begin
                        rd_ctrl_datap_store_rem_reg = 1'b1;
                        state_next = HDR_FLIT_OUT;
                    end
                end
            end
            RD_OP_RESP: begin
                if (mem_controller_rd_data_val) begin
                    // this only works, because in the case we're unaligned and
                    // we don't wait, we never pass through this state
                    if (datap_rd_ctrl_first_read_wait) begin
                        rd_ctrl_datap_shift_regs = 1'b1;
                    end
                    else begin
                        rd_ctrl_datap_store_rem_reg = 1'b1;
                    end
                    if (hdr_out_reg == '0) begin
                        state_next = HDR_FLIT_OUT;
                    end
                    else begin
                        state_next = RD_PAYLOAD_OUT;
                    end
                end
            end
            RD_PAYLOAD_OUT: begin
                controller_noc0_vrtoc_val = 1'b1;
                if (noc0_vrtoc_controller_rdy) begin
                    rd_ctrl_datap_incr_sent_flits = 1'b1;
                    // we've read all the data
                    if (datap_rd_ctrl_last_read) begin
                        // have we also sent all the data?
                        if (datap_rd_ctrl_last_flit) begin
                            state_next = READY;
                        end
                        // sometimes we have a little extra
                        // to send at the end
                        else begin
                            rd_ctrl_datap_shift_regs = 1'b1;
                            state_next = RD_PAYLOAD_REM_OUT;
                        end
                    end
                    else begin
                        rd_ctrl_datap_update_state = 1'b1;
                        controller_mem_read_en = 1'b1;
                        if (mem_controller_rdy) begin
                            state_next = RD_OP_RESP;
                        end
                        else begin
                            state_next = MEM_WAIT;
                        end
                    end
                end
            end
            RD_PAYLOAD_REM_OUT: begin
                controller_noc0_vrtoc_val = 1'b1;
                if (noc0_vrtoc_controller_rdy) begin
                    if (datap_rd_ctrl_last_flit) begin
                        state_next = READY;
                    end
                    else begin
                        rd_ctrl_datap_incr_sent_flits = 1'b1;
                        rd_ctrl_datap_shift_regs = 1'b1;
                        state_next = RD_PAYLOAD_REM_OUT;
                    end
                end
            end
            HDR_FLIT_OUT: begin
                rd_ctrl_datap_hdr_flit_out = 1'b1;
                controller_noc0_vrtoc_val = 1'b1;
                hdr_out_next = 1'b1;
                if (noc0_vrtoc_controller_rdy) begin
                    if (datap_rd_ctrl_last_read) begin
                        state_next = RD_PAYLOAD_REM_OUT;
                    end
                    else begin
                        state_next = RD_PAYLOAD_OUT;
                    end
                end
            end
            default: begin
                controller_noc0_ctovr_rdy = 'X;
                controller_noc0_vrtoc_val = 'X;

                controller_mem_read_en = 'X;

                hdr_out_next = 'X;

                rd_ctrl_datap_store_state = 'X;
                rd_ctrl_datap_update_state = 'X;
                rd_ctrl_datap_shift_regs = 'X;
                rd_ctrl_datap_store_rem_reg = 'X;
                rd_ctrl_datap_hdr_flit_out = 'X;
                rd_ctrl_datap_incr_sent_flits = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
