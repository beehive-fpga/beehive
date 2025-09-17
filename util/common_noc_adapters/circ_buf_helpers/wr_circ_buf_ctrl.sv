module wr_circ_buf_ctrl (
     input clk
    ,input rst

    ,input                                      src_wr_buf_req_val
    ,output logic                               wr_buf_src_req_rdy

    ,input                                      src_wr_buf_req_data_val
    ,output logic                               wr_buf_src_req_data_rdy

    ,output logic                               wr_buf_src_wr_req_done
    ,input                                      src_wr_buf_wr_req_done_rdy

    ,output logic                               wr_buf_wr_mem_req_val
    ,input                                      wr_mem_wr_buf_req_rdy

    ,output logic                               wr_buf_wr_mem_req_data_val
    ,input  logic                               wr_mem_wr_buf_req_data_rdy

    ,output logic                               wr_buf_wr_mem_wr_req_done_rdy
    ,input                                      wr_mem_wr_buf_wr_req_done

    ,input  logic                               split_req
    ,input  logic                               save_reg_has_unused
    ,input  logic                               datap_ctrl_need_input

    ,output logic                               store_req_metadata
    ,output logic                               update_wr_req_metadata

    ,output logic                               init_curr_req_rem_bytes
    ,output logic                               update_curr_req_rem_bytes
    
    ,output logic                               store_save_reg
    ,output logic                               store_save_reg_shift
    ,output logic                               clear_save_reg_shift

    ,input  logic                               datap_ctrl_last_wr
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        MAKE_REQ = 3'd1,
        BUF_DATA = 3'd3,
        SEND_DATA = 3'd4,
        WAIT_REQ = 3'd5,
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
        store_req_metadata = 1'b0;
        update_wr_req_metadata = 1'b0;
        init_curr_req_rem_bytes = 1'b0;
        update_curr_req_rem_bytes = 1'b0;

        wr_buf_wr_mem_req_val = 1'b0;
        wr_buf_wr_mem_req_data_val = 1'b0;
        wr_buf_wr_mem_wr_req_done_rdy = 1'b0;
        wr_buf_src_req_rdy = 1'b0;
        wr_buf_src_req_data_rdy = 1'b0;

        wr_buf_src_wr_req_done = 1'b0;

        store_save_reg = 1'b0;
        store_save_reg_shift = 1'b0;
        clear_save_reg_shift = 1'b0;
        
        state_next = state_reg;
        case (state_reg) 
            READY: begin
                wr_buf_src_req_rdy = 1'b1;
                if (src_wr_buf_req_val) begin
                    store_req_metadata = 1'b1;
                    init_curr_req_rem_bytes = 1'b1; 
                    clear_save_reg_shift = 1'b1;

                    state_next = MAKE_REQ;
                end
                else begin
                    state_next = READY;
                end
            end
            MAKE_REQ: begin
                wr_buf_wr_mem_req_val = 1'b1;

                if (wr_mem_wr_buf_req_rdy) begin
                    init_curr_req_rem_bytes = 1'b1;
                    // there's still valid data in the buffer register, so we don't need
                    // to wait to initialize it
                    if (save_reg_has_unused) begin
                        state_next = SEND_DATA;
                    end
                    else begin
                        state_next = BUF_DATA;
                    end
                end
                else begin
                    state_next = MAKE_REQ;
                end
            end
            BUF_DATA: begin
                store_save_reg = src_wr_buf_req_data_val;
                wr_buf_src_req_data_rdy = 1'b1;

                // otherwise, we just need to wait to initialize the save register
                if (src_wr_buf_req_data_val) begin
                    state_next = SEND_DATA;        
                end
                else begin
                    state_next = BUF_DATA;
                end
            end
            SEND_DATA: begin
                // if we're writing out the last data, we already have it buffered
                // just output it and wait
                if (datap_ctrl_last_wr) begin
                    if (datap_ctrl_need_input) begin
                        wr_buf_wr_mem_req_data_val = src_wr_buf_req_data_val;
                        wr_buf_src_req_data_rdy = wr_mem_wr_buf_req_data_rdy;

                        if (src_wr_buf_req_data_val & wr_mem_wr_buf_req_data_rdy) begin
                            state_next = WAIT_REQ;
                        end
                        else begin
                            state_next = SEND_DATA; 
                        end
                    end
                    else begin
                        wr_buf_wr_mem_req_data_val = 1'b1;
                        if (wr_mem_wr_buf_req_data_rdy) begin
                            state_next = WAIT_REQ;
                        end
                        else begin
                            state_next = SEND_DATA;
                        end
                    end
                end
                else begin
                    wr_buf_wr_mem_req_data_val = src_wr_buf_req_data_val;
                    wr_buf_src_req_data_rdy = wr_mem_wr_buf_req_data_rdy;

                    state_next = SEND_DATA;
                    if (src_wr_buf_req_data_val & wr_mem_wr_buf_req_data_rdy) begin
                        store_save_reg = 1'b1;
                        update_curr_req_rem_bytes = 1'b1;
                    end
                end
            end
            WAIT_REQ: begin
                if (split_req) begin
                    wr_buf_wr_mem_wr_req_done_rdy = 1'b1;
                    if (wr_mem_wr_buf_wr_req_done) begin
                        store_save_reg_shift = 1'b1;
                        update_wr_req_metadata = 1'b1;
                        state_next = MAKE_REQ;
                    end
                    else begin
                        state_next = WAIT_REQ;
                    end
                end
                else begin
                    wr_buf_src_wr_req_done = wr_mem_wr_buf_wr_req_done;
                    wr_buf_wr_mem_wr_req_done_rdy = src_wr_buf_wr_req_done_rdy;

                    if (wr_mem_wr_buf_wr_req_done & src_wr_buf_wr_req_done_rdy) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = WAIT_REQ;
                    end
                end
            end
        endcase
    end


endmodule
