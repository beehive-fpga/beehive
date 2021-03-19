// Always prefers input 0
module mem_mux #(
     parameter ADDR_W = -1
    ,parameter DATA_W = -1
)(
     input clk
    ,input rst

    ,input                          src0_rd_req_val
    ,input  logic   [ADDR_W-1:0]    src0_rd_req_addr
    ,output logic                   src0_rd_req_rdy
    
    ,output logic                   src0_rd_resp_val
    ,output logic   [DATA_W-1:0]    src0_rd_resp_data
    ,input  logic                   src0_rd_resp_rdy
    
    ,input                          src1_rd_req_val
    ,input  logic   [ADDR_W-1:0]    src1_rd_req_addr
    ,output logic                   src1_rd_req_rdy
    
    ,output logic                   src1_rd_resp_val
    ,output logic   [DATA_W-1:0]    src1_rd_resp_data
    ,input  logic                   src1_rd_resp_rdy

    ,output logic                   dst_rd_req_val
    ,output logic   [ADDR_W-1:0]    dst_rd_req_addr
    ,input  logic                   dst_rd_req_rdy
    
    ,input  logic                   dst_rd_resp_val
    ,input  logic   [DATA_W-1:0]    dst_rd_resp_data
    ,output logic                   dst_rd_resp_rdy
);

    typedef enum logic {
        SRC_0,
        SRC_1
    } src_sel_e;

    typedef enum logic[1:0] {
        READY = 2'd0,
        RD_RESP = 2'd1,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    src_sel_e src_sel_reg;
    src_sel_e src_sel_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            src_sel_reg <= src_sel_next;
        end
    end

    assign dst_rd_req_addr = src_sel_next == SRC_1
                            ? src1_rd_req_addr
                            : src0_rd_req_addr;

    assign src0_rd_resp_data = dst_rd_resp_data;
    assign src1_rd_resp_data = dst_rd_resp_data;

    always_comb begin
        dst_rd_req_val = 1'b0;
        dst_rd_resp_rdy = 1'b0;

        src0_rd_resp_val = 1'b0;
        src1_rd_resp_val = 1'b0;

        src0_rd_req_rdy = 1'b0;
        src1_rd_req_rdy = 1'b0;
        src_sel_next = src_sel_reg;
        state_next = state_reg;
        case (state_reg)
            READY: begin
                dst_rd_req_val = src0_rd_req_val | src1_rd_req_val;
                src_sel_next = SRC_0;

                if (src0_rd_req_val) begin
                    src_sel_next = SRC_0;
                    src0_rd_req_rdy = dst_rd_req_rdy;
                    src1_rd_req_rdy = 1'b0;
                    if (dst_rd_req_rdy) begin
                        state_next = RD_RESP;
                    end
                end
                else if (src1_rd_req_val) begin
                    src_sel_next = SRC_1;
                    src1_rd_req_rdy = dst_rd_req_rdy;
                    src0_rd_req_rdy = 1'b0;
                    if (dst_rd_req_rdy) begin
                        state_next = RD_RESP;
                    end
                end
            end
            RD_RESP: begin
                if (src_sel_reg == SRC_0) begin
                    src0_rd_resp_val = dst_rd_resp_val;
                    dst_rd_resp_rdy = src0_rd_resp_rdy;

                    if (dst_rd_resp_val & src0_rd_resp_rdy) begin
                        state_next = READY;
                    end
                end
                else if (src_sel_reg == SRC_1) begin
                    src1_rd_resp_val = dst_rd_resp_val;
                    dst_rd_resp_rdy = src1_rd_resp_rdy;

                    if( dst_rd_resp_val & src1_rd_resp_rdy) begin
                        state_next = READY;
                    end
                end
            end
        endcase
    end

/**************************
 * Partial pipeline implementation, save for later
 **************************/
//    // Re(q)uest stage
//    logic                   rd_req_val_q;
//    logic   [ADDR_W-1:0]    rd_req_addr_q;
//    logic                   rd_req_rdy_q;
//    src_sel_e               src_sel_q;
//
//    assign src_sel_q = src0_rd_req_val 
//                        ? SRC_0
//                        : src1_rd_req_val
//                            ? SRC_1
//                            : SRC_0
//                        : SRC_0;
//
//    always_comb begin
//        if (src_sel_q == SRC_1) begin
//            rd_req_val_q = src1_rd_req_val;
//            rd_req_addr_q = src1_rd_req_addr;
//
//            src0_rd_req_rdy = 1'b0;
//            src1_rd_req_rdy = dst_rd_req_rdy;
//        end
//        else begin
//            rd_req_val_q = src0_rd_req_val;
//            rd_req_addr_q = src0_rd_req_addr;
//
//            src0_rd_req_rdy = dst_rd_req_rdy;
//            src1_rd_req_rdy = 1'b0;
//        end
//    end
//
//    
//    // Res(p) stage
//    logic                   rd_req_val_reg_p;
//    logic   [ADDR_W-1:0]    rd_req_addr_reg_p;
//    logic                   stall_p;
//
//    always_ff @(posedge clk) begin
//        if (rst) begin
//            rd_req_reg_p <= '0;
//        end
//        else begin
//            if (~stall_p) begin
//                rd_req_reg_p <= rd_req_val_q;
//                rd_req_addr_reg_p <= rd_req_addr_q;
//            end
//        end
//    end
//                            
//
//    assign stall_p = rd_req_val_reg_p & ((~dst_rd_resp_val) | (dst_rd_resp_val & ~dst_rd_resp_rdy));
//    
//    assign dst_rd_resp_rdy = src_sel_reg_p == SRC_0
//                            ? src0_rd_resp_rdy
//                            : src1_rd_resp_rdy;
//    
//
endmodule
