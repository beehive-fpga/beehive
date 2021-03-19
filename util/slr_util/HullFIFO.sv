/*
Modified from https://github.com/JoshuaLandgraf/cascade

    Author: Ahmed Khawaja and Joshua Landgraf
    
    This module abstracts the different types of FIFOs that can be used in the system
    
    TypeNum  Type
    0        SoftFIFO (in pure verilog)
    1        Catapult Hardened FIFO
    2        F1 Shifting flop FIFO
	3        Xilinx Auto FIFO

*/

module HullFIFO #(parameter TYPE = 0, WIDTH = 32, LOG_DEPTH = 2)
(
    // General signals
    input  clock,
    input  reset_n,
    // Data in and write enable
    input             wrreq, //enq
    input[WIDTH-1:0]  data,// data in
    output            full,
    output[WIDTH-1:0] q, // data out
    output logic      empty,
    input             rdreq // deq
);


    SoftFIFO
    #(
        .WIDTH                  (WIDTH),
        .LOG_DEPTH              (LOG_DEPTH)
    )
    softfifo_inst
    (
        .clock                  (clock),
        .reset_n                (reset_n),
        .wrreq                  (wrreq),
        .data                   (data),
        .full                   (full),
        .q                      (q),
        .empty                  (empty),
        .rdreq                  (rdreq)
    );

endmodule
