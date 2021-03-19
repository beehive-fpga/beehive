// Copyright (c) 2020 Princeton University
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Filename: beehive_noc_prio_merger.v
// Author: Fei Gao  
// Description: Merge the noc traffic. Each source has a priority, and src0 has the highest. 

`include "bsg_defines.v"
module beehive_noc_prio_merger #(
     parameter NOC_DATA_W = 512
    ,parameter MSG_PAYLOAD_LEN = 22
    ,parameter MSG_LEN_HI = 477
    ,parameter MSG_LEN_LO = MSG_LEN_HI - MSG_PAYLOAD_LEN
    ,parameter   [2:0]  num_sources = 3'd1      // Maximum source number is fixed to 5
) (   
    input                           clk,
    input                           rst_n,

    input                           src0_merger_vr_noc_val,   // Highest priority
    input       [NOC_DATA_W-1:0]    src0_merger_vr_noc_dat,
    output reg                      merger_src0_vr_noc_rdy,

    input                           src1_merger_vr_noc_val,
    input       [NOC_DATA_W-1:0]    src1_merger_vr_noc_dat,
    output reg                      merger_src1_vr_noc_rdy,

    input                           src2_merger_vr_noc_val,
    input       [NOC_DATA_W-1:0]    src2_merger_vr_noc_dat,
    output reg                      merger_src2_vr_noc_rdy,

    input                           src3_merger_vr_noc_val,
    input       [NOC_DATA_W-1:0]    src3_merger_vr_noc_dat,
    output reg                      merger_src3_vr_noc_rdy,

    input                           src4_merger_vr_noc_val,  // Lowest priority
    input       [NOC_DATA_W-1:0]    src4_merger_vr_noc_dat,
    output reg                      merger_src4_vr_noc_rdy,

    output reg                      merger_dst_vr_noc_val,   
    output reg  [NOC_DATA_W-1:0]    merger_dst_vr_noc_dat,
    input                           dst_merger_vr_noc_rdy
);

    localparam num_sources_w  = `BSG_SAFE_CLOG2(num_sources);

    localparam IDLE = 3'd0;
    localparam COUNT_PRIO0 = 3'd1;
    localparam COUNT_PRIO1 = 3'd2;
    localparam COUNT_PRIO2 = 3'd3;
    localparam COUNT_PRIO3 = 3'd4;
    localparam COUNT_PRIO4 = 3'd5;
    localparam NONE = 3'd7; 
    
    reg [2:0] state_reg;
    reg [2:0] state_next;
    
    reg [MSG_PAYLOAD_LEN-1:0] count_reg;
    reg [MSG_PAYLOAD_LEN-1:0] count_next;

    wire [63:0] debug_index;

    assign debug_index = MSG_LEN_HI;

    wire [2:0] sel_src_id;
    wire [NOC_DATA_W-1:0] merger_dst_vr_noc_dat_header;
    
    always @(posedge clk) begin
        if (~rst_n) begin
            state_reg <= IDLE;
            count_reg <= {MSG_PAYLOAD_LEN{1'b0}};
        end
        else begin
            state_reg <= state_next;
            if ((state_next != IDLE)) begin
                count_reg <= count_next;
            end
        end
    end

    wire [num_sources-1:0] vals;
    wire [num_sources-1:0] grants;
    wire [num_sources_w-1:0] grant_id;

    wire [4:0]  src_merger_vr_noc_val_vec;
    wire advance_prio;
    wire grant_val;

    assign advance_prio = |vals;
 
    assign src_merger_vr_noc_val_vec[0] = src0_merger_vr_noc_val;
    assign src_merger_vr_noc_val_vec[1] = src1_merger_vr_noc_val;
    assign src_merger_vr_noc_val_vec[2] = src2_merger_vr_noc_val;
    assign src_merger_vr_noc_val_vec[3] = src3_merger_vr_noc_val;
    assign src_merger_vr_noc_val_vec[4] = src4_merger_vr_noc_val;

    genvar i;
    generate
        for (i = 0; i < num_sources; i = i + 1) begin : gen_val_vec
            assign vals[i] = num_sources > i & src_merger_vr_noc_val_vec[i];
        end
    endgenerate

    assign grant_val = |(vals[num_sources-1:0]);

    bsg_arb_round_robin #(
        .width_p(num_sources)
    ) arbiter (
         .clk_i     (clk    )
        ,.reset_i   (~rst_n )

        ,.reqs_i    (vals           )
        ,.grants_o  (grants         )
        ,.yumi_i    (advance_prio   )
    );

    bsg_encode_one_hot #(
        .width_p    (num_sources)
    ) grants_encoder (
         .i         (grants     )
        ,.addr_o    (grant_id   )
        ,.v_o       ()
    );
   
 
    //assign sel_src_id = src0_merger_vr_noc_val ? 3'd0 :
    //                    ( num_sources > 1 & src1_merger_vr_noc_val ) ? 3'd1 :
    //                    ( num_sources > 2 & src2_merger_vr_noc_val ) ? 3'd2 :
    //                    ( num_sources > 3 & src3_merger_vr_noc_val ) ? 3'd3 :
    //                    ( num_sources > 4 & src4_merger_vr_noc_val ) ? 3'd4 : NONE;

    assign sel_src_id = grant_id;
    
    assign merger_dst_vr_noc_dat_header = (sel_src_id == 3'd0) ? src0_merger_vr_noc_dat :
                                       (sel_src_id == 3'd1) ? src1_merger_vr_noc_dat :
                                       (sel_src_id == 3'd2) ? src2_merger_vr_noc_dat :
                                       (sel_src_id == 3'd3) ? src3_merger_vr_noc_dat :
                                       (sel_src_id == 3'd4) ? src4_merger_vr_noc_dat : {NOC_DATA_W{1'b0}};
    
    always @* begin
        merger_src0_vr_noc_rdy = 0; 
        merger_src1_vr_noc_rdy = 0; 
        merger_src2_vr_noc_rdy = 0; 
        merger_src3_vr_noc_rdy = 0; 
        merger_src4_vr_noc_rdy = 0; 

        case (state_reg)
        IDLE: begin
    
            count_next =    merger_dst_vr_noc_dat_header[MSG_LEN_HI:MSG_LEN_LO];
    
            merger_dst_vr_noc_val = grant_val;
            merger_dst_vr_noc_dat = merger_dst_vr_noc_dat_header;
    
            merger_src0_vr_noc_rdy = (sel_src_id == 3'd0) & dst_merger_vr_noc_rdy;
            merger_src1_vr_noc_rdy = (sel_src_id == 3'd1) & dst_merger_vr_noc_rdy;
            merger_src2_vr_noc_rdy = (sel_src_id == 3'd2) & dst_merger_vr_noc_rdy;
            merger_src3_vr_noc_rdy = (sel_src_id == 3'd3) & dst_merger_vr_noc_rdy;
            merger_src4_vr_noc_rdy = (sel_src_id == 3'd4) & dst_merger_vr_noc_rdy;

            if (grant_val) begin
                state_next = (merger_dst_vr_noc_dat_header[MSG_LEN_HI:MSG_LEN_LO] == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE :
                             merger_src0_vr_noc_rdy ? COUNT_PRIO0 :
                             merger_src1_vr_noc_rdy ? COUNT_PRIO1 :
                             merger_src2_vr_noc_rdy ? COUNT_PRIO2 :
                             merger_src3_vr_noc_rdy ? COUNT_PRIO3 :
                             merger_src4_vr_noc_rdy ? COUNT_PRIO4 : IDLE;
            end
            else begin
                state_next = IDLE;
            end
    
        end
        COUNT_PRIO0: begin
            merger_src0_vr_noc_rdy = dst_merger_vr_noc_rdy;
            merger_dst_vr_noc_val = src0_merger_vr_noc_val;
            merger_dst_vr_noc_dat = src0_merger_vr_noc_dat;
            
            count_next = (src0_merger_vr_noc_val & merger_src0_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_PRIO0;
        end
        COUNT_PRIO1: begin
            merger_src1_vr_noc_rdy = dst_merger_vr_noc_rdy;
            merger_dst_vr_noc_val = src1_merger_vr_noc_val;
            merger_dst_vr_noc_dat = src1_merger_vr_noc_dat;
            
            count_next = (src1_merger_vr_noc_val & merger_src1_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_PRIO1;
        end
        COUNT_PRIO2: begin
            merger_src2_vr_noc_rdy = dst_merger_vr_noc_rdy;
            merger_dst_vr_noc_val = src2_merger_vr_noc_val;
            merger_dst_vr_noc_dat = src2_merger_vr_noc_dat;
            
            count_next = (src2_merger_vr_noc_val & merger_src2_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_PRIO2;
        end
        COUNT_PRIO3: begin
            merger_src3_vr_noc_rdy = dst_merger_vr_noc_rdy;
            merger_dst_vr_noc_val = src3_merger_vr_noc_val;
            merger_dst_vr_noc_dat = src3_merger_vr_noc_dat;
            
            count_next = (src3_merger_vr_noc_val & merger_src3_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_PRIO3;
        end
        COUNT_PRIO4: begin
            merger_src4_vr_noc_rdy = dst_merger_vr_noc_rdy;
            merger_dst_vr_noc_val = src4_merger_vr_noc_val;
            merger_dst_vr_noc_dat = src4_merger_vr_noc_dat;
            
            count_next = (src4_merger_vr_noc_val & merger_src4_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_PRIO4;
        end
        default: begin
            count_next = {MSG_PAYLOAD_LEN{1'b0}};
    
            merger_dst_vr_noc_val = 1'b0;
            merger_dst_vr_noc_dat = {NOC_DATA_W{1'b0}};
    
            state_next = IDLE;
        end
        endcase
    end

endmodule
