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

//File: beehive_valrdy_to_credit.v (modified from beehive_space_avail_top.v)
//
//Modified: Yaosheng Fu
//May 2, 2014
//
//Function: This module keeps track of how many spots are free in the NIB that
//	we are sending to
//
//State: count_f, dst_vrtoc_yummy_f, src_vrtoc_val_f
//
//Instantiates: 
//
module beehive_valrdy_to_credit #(
     parameter BUFFER_SIZE = 16
    ,parameter BUFFER_BITS = 5
    ,parameter NOC_DATA_W = 512
)(
            clk,
            reset,
                
            //val/rdy interface
            src_vrtoc_data,
            src_vrtoc_val,
            vrtoc_src_rdy,

			//credit based interface	
            vrtoc_dst_data,
            vrtoc_dst_val,
		    dst_vrtoc_yummy);

   
input clk;
input reset;

 
input [NOC_DATA_W-1:0]	 src_vrtoc_data;
 input src_vrtoc_val;			// sending data to the output
 input dst_vrtoc_yummy;			// output consumed data

output [NOC_DATA_W-1:0]  vrtoc_dst_data;
 output vrtoc_dst_val;
 output vrtoc_src_rdy;		// is there space available?


//This is the state
 reg dst_vrtoc_yummy_f;
 reg valid_temp_f;
 reg [BUFFER_BITS-1:0] count_f;

reg is_one_f;
 reg is_two_or_more_f;

//wires
 wire [BUFFER_BITS-1:0] count_plus_1;
 wire [BUFFER_BITS-1:0] count_minus_1;
 wire up;
 wire down;

 wire valid_temp;

//wire regs
  reg [BUFFER_BITS-1:0] count_temp;


//assigns
assign vrtoc_dst_data = src_vrtoc_data;
assign valid_temp = src_vrtoc_val & vrtoc_src_rdy;
assign vrtoc_dst_val = valid_temp;

assign count_plus_1 = count_f + 1'b1;
assign count_minus_1 = count_f - 1'b1;
assign vrtoc_src_rdy = is_two_or_more_f;
assign up = dst_vrtoc_yummy_f & ~valid_temp_f;
assign down = ~dst_vrtoc_yummy_f & valid_temp_f;

always @ (count_f or count_plus_1 or count_minus_1 or up or down)
begin
	case (count_f)
	0:
		begin
			if(up)
			begin
				count_temp <= count_plus_1;
			end
			else
			begin
				count_temp <= count_f;
			end
		end
	BUFFER_SIZE:
		begin
			if(down)
			begin
				count_temp <= count_minus_1;
			end
			else
			begin
				count_temp <= count_f;
			end
		end
	default:
		begin
			case ({up, down})
				2'b10:	count_temp <= count_plus_1;
				2'b01:	count_temp <= count_minus_1;
				default:	count_temp <= count_f;
			endcase
		end
	endcase
end

//wire top_bits_zero_temp = ~| count_temp[BUFFER_BITS-1:1];
 wire top_bits_zero_temp = count_temp < 2 ? 1 : 0;

always @ (posedge clk)
begin
	if(reset)
	begin
	   count_f <= BUFFER_SIZE;
	   dst_vrtoc_yummy_f <= 1'b0;
	   valid_temp_f <= 1'b0;
	   is_one_f <= (BUFFER_SIZE == 1);
	   is_two_or_more_f <= (BUFFER_SIZE >= 2);
	end
	else
	begin
	   count_f <= count_temp;
	   dst_vrtoc_yummy_f <= dst_vrtoc_yummy;
	   valid_temp_f <= valid_temp;
	   is_one_f         <= top_bits_zero_temp & count_temp[0];
   	   is_two_or_more_f <= ~top_bits_zero_temp;
	end
end

endmodule
      
