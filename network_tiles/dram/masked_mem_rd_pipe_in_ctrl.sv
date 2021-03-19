module masked_mem_rd_pipe_in_ctrl (
     input clk
    ,input rst
    
    ,input                                      start_read
    
    ,output logic                               controller_mem_read_en
    ,input  logic                               mem_controller_rdy
    
    ,output logic                               rd_ctrl_datap_update_state

    ,input  logic                               datap_rd_ctrl_last_read
    ,input  logic                               datap_rd_ctrl_read_aligned
);

    typedef enum logic[1:0] {
        READY=2'd0,
        READING=2'd1,
        UND='X
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
        rd_ctrl_datap_update_state = 1'b0;
        controller_mem_read_en = 1'b0;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                if (start_read) begin
                    state_next = READING;
                end
            end
            READING: begin
                controller_mem_read_en = 1'b1;
                if (mem_controller_rdy) begin
                    rd_ctrl_datap_update_state = 1'b1;

                    if (datap_rd_ctrl_last_read) begin
                        state_next = READY;
                    end
                end
            end
            default: begin
                rd_ctrl_datap_update_state = 'X;
                state_next = UND;
            end
        endcase
    end

endmodule
