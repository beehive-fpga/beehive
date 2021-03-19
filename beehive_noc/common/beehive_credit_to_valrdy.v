// Copyright (c) 2015 Princeton University
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

/****************************************************************************
 *
 *   FILE: beehive_credit_to_valrdy.v
 *
 *   Modified: Yaosheng Fu
 *   Date: May 2 2014

 ***************************************************************************/

module beehive_credit_to_valrdy #(
    parameter NOC_DATA_W = 512
)(
   clk,
   reset,
   //credit based interface	
   src_ctovr_data,
   src_ctovr_val,
   ctovr_src_yummy,
            
   //val/rdy interface
   ctovr_dst_data,
   ctovr_dst_val,
   dst_ctovr_rdy
);

    input   clk;
    input   reset;
    input   [NOC_DATA_W-1:0]    src_ctovr_data;
    input	src_ctovr_val;
    input   dst_ctovr_rdy;
     
    output	ctovr_src_yummy;
    output	ctovr_dst_val;
    output  [NOC_DATA_W-1:0] ctovr_dst_data;
    
    wire	 thanksIn;

    wire ctovr_dst_val_temp;

    assign ctovr_dst_val = ctovr_dst_val_temp;

    beehive_network_input_blk_multi_out #(
         .LOG2_NUMBER_FIFO_ELEMENTS (4          )
        ,.NOC_DATA_W                (NOC_DATA_W )
    ) data (
       .clk(clk),
       .reset(reset),
       .data_in(src_ctovr_data),
       .valid_in(src_ctovr_val),
    
       .thanks_in(ctovr_dst_val & dst_ctovr_rdy),
    
       .yummy_out(ctovr_src_yummy),
       .data_val(ctovr_dst_data),
       .data_val1(/*not used*/),
       .data_avail(ctovr_dst_val_temp));

endmodule



