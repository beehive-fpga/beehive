`include "bsg_defines.v"
module if_w_startframe_convert #(
     parameter DATA_W = 0
    ,parameter PADBYTES_W = `BSG_SAFE_CLOG2(DATA_W/8)
)(
     input clk
    ,input rst
    
    ,input  logic                       src_startframe_convert_data_val
    ,input  logic   [DATA_W-1:0]        src_startframe_convert_data
    ,input  logic                       src_startframe_convert_data_last
    ,input  logic   [PADBYTES_W-1:0]    src_startframe_convert_data_padbytes
    ,output logic                       startframe_convert_src_data_rdy

    ,output logic                       startframe_convert_dst_val
    ,output logic                       startframe_convert_dst_startframe
    ,output logic                       startframe_convert_dst_endframe
    ,output logic   [DATA_W-1:0]        startframe_convert_dst_data
    ,output logic   [PADBYTES_W-1:0]    startframe_convert_dst_padbytes
    ,input  logic                       dst_startframe_convert_rdy
);

    typedef enum logic {
        READY = 1'b0,
        WAIT_FOR_END = 1'b1,
        UND = 1'bX
    } state_e;

    state_e state_reg;
    state_e state_next;

    assign startframe_convert_src_data_rdy = dst_startframe_convert_rdy;
    assign startframe_convert_dst_val = src_startframe_convert_data_val;
    assign startframe_convert_dst_data = src_startframe_convert_data;
    assign startframe_convert_dst_padbytes = src_startframe_convert_data_padbytes;
    assign startframe_convert_dst_endframe =  src_startframe_convert_data_last;
    
    always_ff @(posedge clk) begin
        if (rst) begin
           state_reg <= READY;
        end
        else begin
           state_reg <= state_next; 
        end
    end

    always_comb begin
        startframe_convert_dst_startframe = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                startframe_convert_dst_startframe = src_startframe_convert_data_val;
                if (src_startframe_convert_data_val & dst_startframe_convert_rdy) begin
                    if (src_startframe_convert_data_last) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = WAIT_FOR_END;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            WAIT_FOR_END: begin
                if (src_startframe_convert_data_val & dst_startframe_convert_rdy) begin
                    if (src_startframe_convert_data_last) begin
                        state_next = READY;     
                    end
                    else begin
                        state_next = WAIT_FOR_END;
                    end
                end
                else begin
                   state_next = WAIT_FOR_END; 
                end
            end
            default: begin
                startframe_convert_dst_startframe = 'X;
                state_next = UND;
            end
        endcase
    end
endmodule
