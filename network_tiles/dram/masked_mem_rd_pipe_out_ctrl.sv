module masked_mem_rd_pipe_out_ctrl #(
     parameter PIPE_STAGES=2
    ,parameter PIPE_STAGES_W = $clog2(PIPE_STAGES)
)(
     input clk
    ,input rst
    
    ,output logic                               rd_ctrl_datap_incr_sent_flits

    ,input  logic                               datap_rd_ctrl_last_read_out
    ,input  logic                               datap_rd_ctrl_read_aligned

    ,input  logic                               dst_out_ctrl_data_rdy
    ,output logic                               out_ctrl_dst_data_out_val

    ,output logic                               ctrl_out_fifo_rd_req
    ,input  logic   [PIPE_STAGES_W:0]           fifo_ctrl_out_num_els
);

    // read logic control
    assign out_ctrl_dst_data_out_val = (datap_rd_ctrl_read_aligned | datap_rd_ctrl_last_read_out) 
                        ? fifo_ctrl_out_num_els >= 1
                        : fifo_ctrl_out_num_els >= 2;
    
    always_comb begin
        ctrl_out_fifo_rd_req = 1'b0;
        rd_ctrl_datap_incr_sent_flits = 1'b0;
        if (out_ctrl_dst_data_out_val & dst_out_ctrl_data_rdy) begin
            ctrl_out_fifo_rd_req = 1'b1;
            rd_ctrl_datap_incr_sent_flits = 1'b1;
        end
    end

endmodule

//    genvar rdy_i;
//    generate
//        always_comb begin
//            pipe_rdys = '0;
//            for (rdy_i = 0; rdy_i < PIPE_STAGES; rdy_i = rdy_i + 1) begin
//                // for the last reg in the pipeline, we just depend on whether the output is ready
//                // FIXME: is this correct? we might have to also depend on whether the previous reg is valid for unaligned stuff
//                if (rdy_1 == PIPE_STAGES-1) begin
//                    pipe_rdys[rdy_i] = shift_end_regs;
//                end
//                // otherwise, whether this reg is ready to take another shift depends on whether the current stage is valid
//                // or if the next stage is ready
//                else begin
//                    pipe_rdys[rdy_i] = ~pipe_val_regs[rdy_i] | pipe_rdys[rdy_i + 1];
//                end
//            end
//        end
//    endgenerate
//
//    genvar i;
//    generate
//        always_comb begin
//            pipe_val_nexts = pipe_val_regs;
//            for (i = 0; i < PIPE_STAGES; i = i+1) begin
//                if (i == 0) begin
//                    if (pipe_rdys[0]) begin
//                        pipe_val_nexts = mem_controller_rd_data_val;
//                    end
//                end
//                else begin
//                    if (pipe_rdys[i]) begin
//                        pipe_val_nexts[i] = pipe_val_regs[i-1]; 
//                    end
//                end
//            end
//        end
//    endgenerate;
