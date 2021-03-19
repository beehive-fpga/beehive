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

// Filename: beehive_noc_fbits_splitter.v
// Author: Fei Gao
// Description: Split the noc message to different destination based on the fbits

// NoC msg with unspecified fbits will not be received: 
// the ready signal keeps low, and it will block the router
module beehive_noc_fbits_splitter #(
     parameter                      NOC_FBITS_W = 4
    ,parameter                      NOC_DATA_W = 512
    ,parameter                      MSG_PAYLOAD_LEN = 22
    ,parameter                      MSG_LEN_HI = 477
    ,parameter                      MSG_LEN_LO = MSG_LEN_HI - MSG_PAYLOAD_LEN - 1
    ,parameter                      FBITS_HI = 481  
    ,parameter                      FBITS_LO = FBITS_HI - NOC_FBITS_W - 1
    ,parameter  [2:0]               num_targets = 3'd1
    ,parameter  [NOC_FBITS_W-1:0]   fbits_type0 = 0    // Processor
    ,parameter  [NOC_FBITS_W-1:0]   fbits_type1 = 0
    ,parameter  [NOC_FBITS_W-1:0]   fbits_type2 = 0
    ,parameter  [NOC_FBITS_W-1:0]   fbits_type3 = 0
    ,parameter  [NOC_FBITS_W-1:0]   fbits_type4 = 0     // Maximum target number is fixed to 5
) (
    input                          clk,
    input                          rst_n,

    input                           src_splitter_vr_noc_val,
    input       [NOC_DATA_W-1:0]    src_splitter_vr_noc_dat,
    output reg                      splitter_src_vr_noc_rdy,

    output reg                      splitter_dst0_vr_noc_val,
    output      [NOC_DATA_W-1:0]    splitter_dst0_vr_noc_dat,
    input                           dst0_splitter_vr_noc_rdy,

    output reg                      splitter_dst1_vr_noc_val,
    output      [NOC_DATA_W-1:0]    splitter_dst1_vr_noc_dat,
    input                           dst1_splitter_vr_noc_rdy,

    output reg                      splitter_dst2_vr_noc_val,
    output      [NOC_DATA_W-1:0]    splitter_dst2_vr_noc_dat,
    input                           dst2_splitter_vr_noc_rdy,

    output reg                      splitter_dst3_vr_noc_val,
    output      [NOC_DATA_W-1:0]    splitter_dst3_vr_noc_dat,
    input                           dst3_splitter_vr_noc_rdy,

    output reg                      splitter_dst4_vr_noc_val,
    output      [NOC_DATA_W-1:0]    splitter_dst4_vr_noc_dat,
    input                           dst4_splitter_vr_noc_rdy

);

    localparam IDLE = 3'd0;
    localparam COUNT_TYPE0 = 3'd1;
    localparam COUNT_TYPE1 = 3'd2;
    localparam COUNT_TYPE2 = 3'd3;
    localparam COUNT_TYPE3 = 3'd4;
    localparam COUNT_TYPE4 = 3'd5;
    
    reg [2:0] state_reg;
    reg [2:0] state_next;
    
    reg [MSG_PAYLOAD_LEN-1:0] count_reg;
    reg [MSG_PAYLOAD_LEN-1:0] count_next;
    
    always @(posedge clk) begin
        if (~rst_n) begin
            state_reg <= IDLE;
            count_reg <= {MSG_PAYLOAD_LEN{1'b0}};
        end
        else begin
            state_reg <= state_next;
            if ((state_next >= COUNT_TYPE0) && (state_next <= COUNT_TYPE4)) begin
                count_reg <= count_next;
            end
        end
    end
    
    assign splitter_dst0_vr_noc_dat = src_splitter_vr_noc_dat;
    assign splitter_dst1_vr_noc_dat = src_splitter_vr_noc_dat;
    assign splitter_dst2_vr_noc_dat = src_splitter_vr_noc_dat;
    assign splitter_dst3_vr_noc_dat = src_splitter_vr_noc_dat;
    assign splitter_dst4_vr_noc_dat = src_splitter_vr_noc_dat;
    
    always @* begin
        splitter_dst0_vr_noc_val = 0;    
        splitter_dst1_vr_noc_val = 0;
        splitter_dst2_vr_noc_val = 0;
        splitter_dst3_vr_noc_val = 0;
        splitter_dst4_vr_noc_val = 0;
    
        case (state_reg)
        IDLE: begin
    
            count_next = src_splitter_vr_noc_val & |src_splitter_vr_noc_dat[MSG_LEN_HI:MSG_LEN_LO] ?
                            src_splitter_vr_noc_dat[MSG_LEN_HI:MSG_LEN_LO] :
                            {MSG_PAYLOAD_LEN{1'b0}};
            
            splitter_dst0_vr_noc_val = src_splitter_vr_noc_val & (src_splitter_vr_noc_dat[FBITS_HI:FBITS_LO] == fbits_type0);
            splitter_dst1_vr_noc_val = src_splitter_vr_noc_val & (src_splitter_vr_noc_dat[FBITS_HI:FBITS_LO] == fbits_type1) & (num_targets > 1) 
                                        & ~splitter_dst0_vr_noc_val;
            splitter_dst2_vr_noc_val = src_splitter_vr_noc_val & (src_splitter_vr_noc_dat[FBITS_HI:FBITS_LO] == fbits_type2) & (num_targets > 2)
                                        & ~splitter_dst0_vr_noc_val
                                        & ~splitter_dst1_vr_noc_val;
            splitter_dst3_vr_noc_val = src_splitter_vr_noc_val & (src_splitter_vr_noc_dat[FBITS_HI:FBITS_LO] == fbits_type3) & (num_targets > 3)
                                        & ~splitter_dst0_vr_noc_val
                                        & ~splitter_dst1_vr_noc_val
                                        & ~splitter_dst2_vr_noc_val;
            splitter_dst4_vr_noc_val = src_splitter_vr_noc_val & (src_splitter_vr_noc_dat[FBITS_HI:FBITS_LO] == fbits_type4) & (num_targets > 4)
                                        & ~splitter_dst0_vr_noc_val
                                        & ~splitter_dst1_vr_noc_val
                                        & ~splitter_dst2_vr_noc_val
                                        & ~splitter_dst3_vr_noc_val;                      // Conservative design, in case different fbits_types are set to a same value
    
            splitter_src_vr_noc_rdy =  (splitter_dst0_vr_noc_val & dst0_splitter_vr_noc_rdy) | 
                                    (splitter_dst1_vr_noc_val & dst1_splitter_vr_noc_rdy) |
                                    (splitter_dst2_vr_noc_val & dst2_splitter_vr_noc_rdy) |
                                    (splitter_dst3_vr_noc_val & dst3_splitter_vr_noc_rdy) |
                                    (splitter_dst4_vr_noc_val & dst4_splitter_vr_noc_rdy) ;
    
            state_next =    (|src_splitter_vr_noc_dat[MSG_LEN_HI:MSG_LEN_LO] == 0) 
                            ? (IDLE) 
                            : (splitter_dst0_vr_noc_val & dst0_splitter_vr_noc_rdy)
                            ? (COUNT_TYPE0) 
                            : (splitter_dst1_vr_noc_val & dst1_splitter_vr_noc_rdy)
                            ? (COUNT_TYPE1)
                            : (splitter_dst2_vr_noc_val & dst2_splitter_vr_noc_rdy)
                            ? (COUNT_TYPE2)
                            : (splitter_dst3_vr_noc_val & dst3_splitter_vr_noc_rdy)
                            ? (COUNT_TYPE3)
                            : (splitter_dst4_vr_noc_val & dst4_splitter_vr_noc_rdy)
                            ? (COUNT_TYPE4) 
                            : (IDLE);
        end
        COUNT_TYPE0: begin
            splitter_dst0_vr_noc_val = src_splitter_vr_noc_val;
            splitter_src_vr_noc_rdy = dst0_splitter_vr_noc_rdy;
    
            count_next = (splitter_dst0_vr_noc_val & dst0_splitter_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_TYPE0;
        end
        COUNT_TYPE1: begin
            splitter_dst1_vr_noc_val = src_splitter_vr_noc_val;
            splitter_src_vr_noc_rdy = dst1_splitter_vr_noc_rdy;
    
            count_next = (splitter_dst1_vr_noc_val & dst1_splitter_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_TYPE1;
        end
        COUNT_TYPE2: begin
            splitter_dst2_vr_noc_val = src_splitter_vr_noc_val;
            splitter_src_vr_noc_rdy = dst2_splitter_vr_noc_rdy;
    
            count_next = (splitter_dst2_vr_noc_val & dst2_splitter_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_TYPE2;
        end
        COUNT_TYPE3: begin
            splitter_dst3_vr_noc_val = src_splitter_vr_noc_val;
            splitter_src_vr_noc_rdy = dst3_splitter_vr_noc_rdy;
    
            count_next = (splitter_dst3_vr_noc_val & dst3_splitter_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_TYPE3;
        end
        COUNT_TYPE4: begin
            splitter_dst4_vr_noc_val = src_splitter_vr_noc_val;
            splitter_src_vr_noc_rdy = dst4_splitter_vr_noc_rdy;
    
            count_next = (splitter_dst4_vr_noc_val & dst4_splitter_vr_noc_rdy) ? (count_reg - 1'b1) : count_reg;
            state_next = (count_next == {MSG_PAYLOAD_LEN{1'b0}}) ? IDLE : COUNT_TYPE4;
        end
        default: begin
            count_next = {MSG_PAYLOAD_LEN{1'b0}};
            splitter_src_vr_noc_rdy = 1'b0;
            state_next = IDLE;
        end
        endcase
    end
    
endmodule
