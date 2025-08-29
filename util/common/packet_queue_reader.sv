// just a little helper module to encapsulate the logic of when to read from the size queue
// to keep everything in sync with the data queue
`include "packet_defs.vh"
module packet_size_queue_reader (
    // is the main interface reading from the data queue
     input                                      data_queue_engine_rx_val
    ,input                                      data_queue_engine_rx_startframe
    ,input  logic                               engine_data_queue_rx_rdy
   
    // how we request from the size queue
    ,output logic                               reader_size_queue_rd_req
    ,input  logic   [`MTU_SIZE_W-1:0]           size_queue_reader_rd_data

    ,output logic   [`MTU_SIZE_W-1:0]           mac_engine_rx_frame_size
);

    assign mac_engine_rx_frame_size = size_queue_reader_rd_data;

    assign reader_size_queue_rd_req = data_queue_engine_rx_val 
                                    & engine_data_queue_rx_rdy 
                                    & data_queue_engine_rx_startframe;

endmodule
