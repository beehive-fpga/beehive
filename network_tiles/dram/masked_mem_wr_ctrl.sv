module masked_mem_wr_ctrl (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_controller_val
    ,output logic                           controller_noc0_ctovr_rdy

    ,output logic                           controller_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_controller_rdy
    
    ,output logic                           wr_resp_noc_vrtoc_val
    ,input                                  noc_wr_resp_vrtoc_rdy

    ,output logic                           controller_mem_write_en
    ,input                                  mem_controller_rdy

    ,output logic                           wr_ctrl_wr_in_progress
    
    ,output logic                           wr_ctrl_datap_store_state
    ,output logic                           wr_ctrl_datap_update_state
    ,output logic                           wr_ctrl_datap_hdr_flit_out
    ,output logic                           wr_ctrl_datap_store_rem_reg
    ,output logic                           wr_ctrl_datap_shift_regs
    ,output logic                           wr_ctrl_datap_incr_recv_flits
    ,output logic                           wr_ctrl_datap_first_wr

    ,input  logic                           datap_wr_ctrl_last_flit
    ,input  logic                           datap_wr_ctrl_last_write
    ,input  logic                           datap_wr_ctrl_wr_aligned
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        WR_DATA_STORE = 3'd1,
        WR_DATA = 3'd2,
        WR_DATA_REM = 3'd3,
        WR_RESP = 3'd4,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   first_write_reg;
    logic   first_write_next;

    assign wr_ctrl_wr_in_progress = (state_reg != READY);

    assign wr_ctrl_datap_first_wr = first_write_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            first_write_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            first_write_reg <= first_write_next;
        end
    end

    always_comb begin
        controller_noc0_ctovr_rdy = 1'b0;
        controller_noc0_vrtoc_val = 1'b0;

        wr_resp_noc_vrtoc_val = 1'b0;
        
        controller_mem_write_en = 1'b0;

        wr_ctrl_datap_store_state = 1'b0;
        wr_ctrl_datap_update_state = 1'b0;
        wr_ctrl_datap_store_rem_reg = 1'b0;
        wr_ctrl_datap_incr_recv_flits = 1'b0;
        wr_ctrl_datap_hdr_flit_out = 1'b0;
        wr_ctrl_datap_shift_regs = 1'b0;

        first_write_next = first_write_reg;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                first_write_next = 1'b1;
                controller_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_controller_val) begin
                    wr_ctrl_datap_store_state = 1'b1;
                    state_next = WR_DATA_STORE;
                end
            end
            WR_DATA_STORE: begin
                controller_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_controller_val) begin
                    wr_ctrl_datap_shift_regs = 1'b1;
                    wr_ctrl_datap_incr_recv_flits = 1'b1;

                    if (datap_wr_ctrl_last_flit) begin
                        state_next = WR_DATA_REM;
                    end
                    else begin
                        state_next = WR_DATA;
                    end
                end
            end
            WR_DATA: begin
                controller_noc0_ctovr_rdy = mem_controller_rdy;
                controller_mem_write_en = noc0_ctovr_controller_val;
                first_write_next = 1'b0;

                if (mem_controller_rdy & noc0_ctovr_controller_val) begin
                    wr_ctrl_datap_update_state = 1'b1;
                    wr_ctrl_datap_incr_recv_flits = 1'b1;
                    if (datap_wr_ctrl_wr_aligned) begin
                        wr_ctrl_datap_shift_regs = 1'b1;;
                    end
                    else begin
                        wr_ctrl_datap_shift_regs = 1'b1;
                    end
                    // if this is the last data we'll receive
                    if (datap_wr_ctrl_last_flit) begin
                        // we may be able to write everything out
                        if (datap_wr_ctrl_last_write) begin
                            state_next = WR_RESP;
                        end
                        else begin
                            state_next = WR_DATA_REM;
                        end
                    end
                end
            end
            WR_DATA_REM: begin
                controller_mem_write_en = 1'b1;
                if (mem_controller_rdy) begin
                    first_write_next = 1'b0;
                    if (datap_wr_ctrl_last_write) begin
                        state_next = WR_RESP;
                    end
                    else begin
                        wr_ctrl_datap_update_state = 1'b1;
                        wr_ctrl_datap_shift_regs = 1'b1;
                        state_next = WR_DATA_REM;
                    end
                end
            end
            WR_RESP: begin
                wr_ctrl_datap_hdr_flit_out = 1'b1;
                wr_resp_noc_vrtoc_val = 1'b1;

                if (noc_wr_resp_vrtoc_rdy) begin
                    state_next = READY;
                end
            end
            default: begin
                controller_noc0_ctovr_rdy = 'X;
                
                controller_mem_write_en = 'X;

                wr_ctrl_datap_store_state = 'X;
                wr_ctrl_datap_update_state = 'X;
                wr_ctrl_datap_store_rem_reg = 'X;
                wr_ctrl_datap_incr_recv_flits = 'X;
                wr_ctrl_datap_hdr_flit_out = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
