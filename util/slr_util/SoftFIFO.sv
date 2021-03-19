/*
Copied from https://github.com/JoshuaLandgraf/cascade

	FIFO not using block RAM, needed for simulation

	Author: Ahmed Khawaja


*/

module SoftFIFO  #(parameter WIDTH = 512, LOG_DEPTH = 9)
(
	// General signals
	input  clock,
	input  reset_n,
	// Data in and write enable
	input  wrreq, //enq					
	input[WIDTH-1:0] data,// data in            
	output full,                   
	output[WIDTH-1:0] q, // data out
	output empty,              
	input  rdreq // deq    
);

//parameter WIDTH     = 64; // bits wide
//parameter LOG_DEPTH = 9;  // 2^LOG_DEPTH slots

logic[WIDTH-1:0] buffer[(1 << LOG_DEPTH)-1:0];

logic[LOG_DEPTH:0] counter;
logic[LOG_DEPTH:0]  new_counter;
logic[LOG_DEPTH-1:0] rd_ptr, wr_ptr; 
logic[LOG_DEPTH-1:0]  new_rd_ptr, new_wr_ptr;
logic empty_reg, new_empty_reg;

assign empty = empty_reg;
assign full  = counter[LOG_DEPTH];
assign q     = buffer[rd_ptr];

always @(posedge clock) begin
	if (!reset_n) begin
		counter <= 0;
		rd_ptr  <= 0;
		wr_ptr  <= 0;
		empty_reg <= 1;
	end else begin
		counter <= new_counter;
		rd_ptr  <= new_rd_ptr;
		wr_ptr  <= new_wr_ptr;
		empty_reg <= new_empty_reg;
	end
end

always @(posedge clock) begin
	if (!full && wrreq) begin
		buffer[wr_ptr] <= data;
	end
end

always_comb begin
	if (!full && wrreq) begin
		new_wr_ptr = wr_ptr + 1;
	end else begin
		new_wr_ptr = wr_ptr;
	end

	if (!empty && rdreq) begin
		new_rd_ptr = rd_ptr + 1;
	end else begin
		new_rd_ptr = rd_ptr;
	end
	
	if ((!full && wrreq) && (!empty && rdreq)) begin
		new_counter = counter;
		new_empty_reg = 0;
	end	else if (!full && wrreq) begin
		new_counter = counter + 1;
		new_empty_reg = 0;
	end else if (!empty && rdreq) begin
		new_counter = counter - 1;
		new_empty_reg = (counter == 1);
	end else begin
		new_counter = counter;
		new_empty_reg =	empty_reg;
	end
end

endmodule 
