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
    ,output logic                               controller_mem_rd_data_rdy
    
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
    ,input  logic                               datap_rd_ctrl_read_aligned
);

    typedef enum logic[3:0] {
        READY = 4'd0,
        // technically we can issue the first read from ready...but then we'd 
        // need to take the address before it's been flopped
        RD_OP_FIRST_RD = 4'd1,
        RD_OP_FIRST_RESP = 4'd2,
        RD_OP_UNALIGNED_RD = 4'd3,
        RD_OP_UNALIGNED_RD_RESP = 4'd4,
        RD_PAYLOAD_OUT = 4'd5,
        RD_PAYLOAD_REM_OUT = 4'd6,
        HDR_FLIT_OUT = 4'd7,
        MEM_WAIT = 4'd8,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic hdr_out_reg;
    logic hdr_out_next;
    
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
        controller_mem_rd_data_rdy = 1'b0;

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
            RD_OP_FIRST_RESP: begin
                controller_mem_rd_data_rdy = 1'b1;
                if (mem_controller_rd_data_val) begin
                    if (datap_rd_ctrl_read_aligned | datap_rd_ctrl_last_read) begin
                        rd_ctrl_datap_store_rem_reg = 1'b1;
                        state_next = HDR_FLIT_OUT;
                    end
                    else begin
                        rd_ctrl_datap_shift_regs = 1'b1;
                        state_next = RD_OP_UNALIGNED_RD;
                    end
                end
            end
            RD_OP_UNALIGNED_RD: begin
                controller_mem_read_en = 1'b1;
                if (mem_controller_rdy) begin
                    rd_ctrl_datap_update_state = 1'b1;
                    state_next = RD_OP_UNALIGNED_RD_RESP;
                end
            end
            RD_OP_UNALIGNED_RD_RESP: begin
                controller_mem_rd_data_rdy = 1'b1;
                if (mem_controller_rd_data_val) begin
                    rd_ctrl_datap_shift_regs = 1'b1;
                    state_next = HDR_FLIT_OUT;
                end
            end
            RD_PAYLOAD_OUT: begin
                controller_mem_rd_data_rdy = noc0_vrtoc_controller_rdy;
                controller_noc0_vrtoc_val = mem_controller_rd_data_val;

                if (mem_controller_rd_data_val & noc0_vrtoc_controller_rdy) begin
                    rd_ctrl_datap_incr_sent_flits = 1'b1;
                    rd_ctrl_datap_shift_regs = ~datap_rd_ctrl_read_aligned;
                    rd_ctrl_datap_store_rem_reg = datap_rd_ctrl_read_aligned;

                    if (datap_rd_ctrl_last_read) begin
                        state_next = RD_PAYLOAD_REM_OUT;
                    end
                    else begin
                        controller_mem_read_en = 1'b1;
                        if (mem_controller_rdy) begin
                            rd_ctrl_datap_update_state = 1'b1;
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
                // we don't need to read another line from memory
                if (datap_rd_ctrl_last_read) begin
                    controller_noc0_vrtoc_val = 1'b1;
                    hdr_out_next = 1'b1;

                    if (noc0_vrtoc_controller_rdy) begin
                        state_next = RD_PAYLOAD_REM_OUT;
                    end
                end
                else begin
                    if (mem_controller_rdy & noc0_vrtoc_controller_rdy) begin
                        controller_noc0_vrtoc_val = 1'b1;
                        controller_mem_read_en = 1'b1;
                        hdr_out_next = 1'b1;
                        rd_ctrl_datap_update_state = 1'b1;
                        state_next = RD_PAYLOAD_OUT;
                    end
                end
            end
            MEM_WAIT: begin
                controller_mem_read_en = 1'b1;
                if (mem_controller_rdy) begin
                    rd_ctrl_datap_update_state = 1'b1;

                    state_next = RD_PAYLOAD_OUT;
                end
            end
            default: begin
                controller_noc0_ctovr_rdy = 'X;
                controller_noc0_vrtoc_val = 'X;

                controller_mem_read_en = 'X;
                controller_mem_rd_data_rdy = 'X;

                rd_ctrl_datap_store_state = 'X;
                rd_ctrl_datap_update_state = 'X;
                rd_ctrl_datap_shift_regs = 'X;
                rd_ctrl_datap_store_rem_reg = 'X;
                rd_ctrl_datap_hdr_flit_out = 'X;
                rd_ctrl_datap_incr_sent_flits = 'X;

                hdr_out_next = 'X;
                state_next = UND;
            end
        endcase
    end
endmodule
