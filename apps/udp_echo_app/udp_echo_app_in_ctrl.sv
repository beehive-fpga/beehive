`include "udp_echo_app_defs.svh"
module udp_echo_app_in_ctrl (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_app_in_val
    ,output logic                           udp_app_in_noc0_ctovr_rdy

    ,output logic                           in_data_val
    ,input                                  out_data_rdy

    ,output logic                           in_store_hdr_flit
    ,output logic                           in_store_meta_flit
    ,output logic                           reset_flit_vals

    ,output logic                           app_stats_do_log
    ,output logic                           app_stats_incr_bytes_sent
    ,output logic   [`NOC_DATA_BYTES_W:0]   app_stats_num_bytes_sent

    ,input  logic   [`MSG_LENGTH_WIDTH-1:0] total_flits 
    ,input  logic   [`UDP_LENGTH_W-1:0]     data_length
);
    
    typedef enum logic[2:0] {
        READY = 3'd0,
        META_FLIT = 3'd1,
        DATA_PASSTHRU = 3'd2,
        UND = 'X
    } in_state_e;

    in_state_e state_reg;
    in_state_e state_next;

    logic   do_log_reg;
    logic   do_log_next;

    logic   [`MSG_LENGTH_WIDTH-1:0] curr_flit_num_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] curr_flit_num_next;
    logic                           reset_curr_flits_num;
    logic                           incr_curr_flits_num;

    assign app_stats_do_log = do_log_reg;

    always_comb begin
        app_stats_num_bytes_sent = `NOC_DATA_BYTES;
        if (curr_flit_num_reg == total_flits) begin
            if (data_length[`NOC_DATA_BYTES_W-1:0] == '0) begin
                app_stats_num_bytes_sent = `NOC_DATA_BYTES;
            end
            else begin
                app_stats_num_bytes_sent = {1'b0, data_length[`NOC_DATA_BYTES_W-1:0]};
            end
        end
        else begin
            app_stats_num_bytes_sent = `NOC_DATA_BYTES;
        end
    end

    
    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            curr_flit_num_reg <= '0;
            do_log_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            curr_flit_num_reg <= curr_flit_num_next;
            do_log_reg <= do_log_next;
        end
    end

    always_comb begin
        curr_flit_num_next = curr_flit_num_reg;
        if (reset_curr_flits_num) begin
            if (incr_curr_flits_num) begin
                curr_flit_num_next = 1;
            end
            else begin
                curr_flit_num_next = '0;
            end
        end
        else if (incr_curr_flits_num) begin
            curr_flit_num_next = curr_flit_num_reg + 1'b1;
        end
        else begin
            curr_flit_num_next = curr_flit_num_reg;
        end
    end



    always_comb begin
        udp_app_in_noc0_ctovr_rdy = 1'b0;

        in_store_hdr_flit = 1'b0;
        in_store_meta_flit = 1'b0;

        reset_flit_vals = 1'b0;

        reset_curr_flits_num = 1'b0;
        incr_curr_flits_num = 1'b0;

        in_data_val = 1'b0;

        app_stats_incr_bytes_sent = 1'b0;

        do_log_next = do_log_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                udp_app_in_noc0_ctovr_rdy = 1'b1;
                reset_flit_vals = ~noc0_ctovr_udp_app_in_val;
                reset_curr_flits_num = 1'b1;

                if (noc0_ctovr_udp_app_in_val) begin
                    do_log_next = 1'b1;
                    in_store_hdr_flit = 1'b1;
                    incr_curr_flits_num = 1'b1;
                    state_next = META_FLIT;
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT: begin
                udp_app_in_noc0_ctovr_rdy = 1'b1;

                if (noc0_ctovr_udp_app_in_val) begin
                    in_store_meta_flit = 1'b1;
                    incr_curr_flits_num = 1'b1;
                    if (curr_flit_num_reg == total_flits) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_PASSTHRU;
                    end
                end
                else begin
                    state_next = META_FLIT;
                end
            end
            DATA_PASSTHRU: begin
                udp_app_in_noc0_ctovr_rdy = out_data_rdy;
                in_data_val = noc0_ctovr_udp_app_in_val;

                if (noc0_ctovr_udp_app_in_val & out_data_rdy) begin
                    app_stats_incr_bytes_sent = 1'b1;
                    incr_curr_flits_num = 1'b1;
                    if (curr_flit_num_reg == total_flits) begin
                        reset_flit_vals = 1'b1;
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_PASSTHRU;
                    end
                end
                else begin
                    state_next = DATA_PASSTHRU;
                end
            end
            default: begin
                udp_app_in_noc0_ctovr_rdy = 'X;

                in_store_hdr_flit = 'X;
                in_store_meta_flit = 'X;

                reset_flit_vals = 'X;

                reset_curr_flits_num = 'X;
                incr_curr_flits_num = 'X;

                app_stats_incr_bytes_sent = 'X;

                state_next = UND;
            end
        endcase
    end
endmodule
