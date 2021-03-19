module masked_mem_rd_pipe_ctrl #(
     parameter PIPE_STAGES=2
    ,parameter PIPE_STAGES_W=$clog2(PIPE_STAGES)
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_controller_val
    ,output logic                           controller_noc0_ctovr_rdy

    ,output logic                           controller_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_controller_rdy
    
    ,output logic                           controller_mem_read_en
    ,input  logic                           mem_controller_rdy

    ,input                                  mem_controller_rd_data_val
    ,output logic                           controller_mem_rd_data_rdy
    
    ,output logic                           rd_ctrl_rd_in_progress
    
    ,output logic                           rd_ctrl_fifo_wr_req
    ,input  logic                           fifo_rd_ctrl_full
    
    ,output logic                           rd_ctrl_fifo_rd_req
    ,input  logic   [PIPE_STAGES_W:0]       fifo_rd_ctrl_num_els
    
    ,output logic                           rd_ctrl_datap_store_state
    ,output logic                           rd_ctrl_datap_update_state

    ,output logic                           rd_ctrl_datap_hdr_flit_out
    ,output logic                           rd_ctrl_datap_incr_sent_flits

    ,input  logic                           datap_rd_ctrl_last_read
    ,input  logic                           datap_rd_ctrl_last_read_out
    ,input  logic                           datap_rd_ctrl_last_flit
    ,input  logic                           datap_rd_ctrl_first_read
    ,input  logic                           datap_rd_ctrl_read_aligned
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        HDR_FLIT_OUT = 3'd1,
        DATA_OUT = 3'd2,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   dst_out_ctrl_data_rdy;
    logic   out_ctrl_dst_data_out_val;
    logic   start_read;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    assign rd_ctrl_rd_in_progress = state_reg != READY;

    assign rd_ctrl_fifo_wr_req = mem_controller_rd_data_val & ~fifo_rd_ctrl_full;
    assign controller_mem_rd_data_rdy = ~fifo_rd_ctrl_full;
    
    always_comb begin
        controller_noc0_ctovr_rdy = 1'b0;
        controller_noc0_vrtoc_val = 1'b0;

        rd_ctrl_datap_store_state = 1'b0;
        rd_ctrl_datap_hdr_flit_out = 1'b0;

        dst_out_ctrl_data_rdy = 1'b0;
        start_read = 1'b0;
        
        state_next = state_reg;
        case (state_reg)
            READY: begin
                controller_noc0_ctovr_rdy = 1'b1;

                if (noc0_ctovr_controller_val) begin
                    rd_ctrl_datap_store_state = 1'b1;
                    start_read = 1'b1;
                    state_next = HDR_FLIT_OUT;
                end
            end
            HDR_FLIT_OUT: begin
                controller_noc0_vrtoc_val = out_ctrl_dst_data_out_val;
                rd_ctrl_datap_hdr_flit_out = 1'b1;

                if (out_ctrl_dst_data_out_val & noc0_vrtoc_controller_rdy) begin
                    state_next = DATA_OUT;
                end
            end
            DATA_OUT: begin
                controller_noc0_vrtoc_val = out_ctrl_dst_data_out_val;
                dst_out_ctrl_data_rdy = noc0_vrtoc_controller_rdy;

                if (out_ctrl_dst_data_out_val & noc0_vrtoc_controller_rdy & datap_rd_ctrl_last_flit) begin
                    state_next = READY;
                end
            end
            default: begin
                controller_noc0_ctovr_rdy = 'X;
                controller_noc0_vrtoc_val = 'X;

                rd_ctrl_datap_store_state = 'X;

                dst_out_ctrl_data_rdy = 'X;
                
                state_next = UND;
            end
        endcase
    end

    masked_mem_rd_pipe_in_ctrl in_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.start_read                    (start_read                 )
        
        ,.controller_mem_read_en        (controller_mem_read_en     )
        ,.mem_controller_rdy            (mem_controller_rdy         )
        
        ,.rd_ctrl_datap_update_state    (rd_ctrl_datap_update_state )
    
        ,.datap_rd_ctrl_last_read       (datap_rd_ctrl_last_read    )
        ,.datap_rd_ctrl_read_aligned    (datap_rd_ctrl_read_aligned )
    );

    masked_mem_rd_pipe_out_ctrl #(
         .PIPE_STAGES   (PIPE_STAGES    )
    ) out_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.rd_ctrl_datap_incr_sent_flits (rd_ctrl_datap_incr_sent_flits  )
                                                                        
        ,.datap_rd_ctrl_read_aligned    (datap_rd_ctrl_read_aligned     )
        ,.datap_rd_ctrl_last_read_out   (datap_rd_ctrl_last_read_out    )
    
        ,.dst_out_ctrl_data_rdy         (dst_out_ctrl_data_rdy          )
        ,.out_ctrl_dst_data_out_val     (out_ctrl_dst_data_out_val      )
    
        ,.ctrl_out_fifo_rd_req          (rd_ctrl_fifo_rd_req            )
        ,.fifo_ctrl_out_num_els         (fifo_rd_ctrl_num_els           )
    );

endmodule
