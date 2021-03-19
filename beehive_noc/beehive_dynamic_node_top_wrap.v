/*
Copyright (c) 2015 Princeton University
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Princeton University nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//File: beehive_dynamic_node_top_wrap.v
////Creator: Michael McKeown
////Created: Sept. 21, 2014
////
////Function: This wraps the dynamic_node top and ties off signals
//            we will not be using at the tile level
////
////State: 
////
////Instantiates: beehive_dynamic_node_top
////
////

module beehive_dynamic_node_top_wrap #(
     parameter NOC_DATA_W = 512
    ,parameter XY_COORD_W = 8
    ,parameter CHIP_ID_W = 14
    ,parameter MSG_PAYLOAD_LEN = 22
)(
    input                   clk
    ,input                   reset_in
       
    ,input  [NOC_DATA_W-1:0]    src_router_data_N   // data inputs from neighboring tiles
    ,input  [NOC_DATA_W-1:0]    src_router_data_E
    ,input  [NOC_DATA_W-1:0]    src_router_data_S
    ,input  [NOC_DATA_W-1:0]    src_router_data_W
    ,input  [NOC_DATA_W-1:0]    src_router_data_P   // data input from processor
       
    ,input                      src_router_val_N        // valid signals from neighboring tiles
    ,input                      src_router_val_E
    ,input                      src_router_val_S
    ,input                      src_router_val_W
    ,input                      src_router_val_P        // valid signal from processor
    
    ,output                     router_src_yummy_N      // yummy signal to neighbors' output buffers
    ,output                     router_src_yummy_E
    ,output                     router_src_yummy_S
    ,output                     router_src_yummy_W
    ,output                     router_src_yummy_P      // yummy signal to processor's output buffer
       
       
    ,input  [XY_COORD_W-1:0]    myLocX       // this tile's position
    ,input  [XY_COORD_W-1:0]    myLocY
    ,input  [CHIP_ID_W-1:0]     myChipID

    ,output [NOC_DATA_W-1:0]    router_dst_data_N // data outputs to neighbors
    ,output [NOC_DATA_W-1:0]    router_dst_data_E
    ,output [NOC_DATA_W-1:0]    router_dst_data_S
    ,output [NOC_DATA_W-1:0]    router_dst_data_W
    ,output [NOC_DATA_W-1:0]    router_dst_data_P // data output to processor
    
    ,output                     router_dst_val_N      // valid outputs to neighbors
    ,output                     router_dst_val_E
    ,output                     router_dst_val_S
    ,output                     router_dst_val_W
    ,output                     router_dst_val_P      // valid output to processor
    
    ,input                      dst_router_yummy_N        // neighbor consumed output data
    ,input                      dst_router_yummy_E
    ,input                      dst_router_yummy_S
    ,input                      dst_router_yummy_W
    ,input                      dst_router_yummy_P        // processor consumed output data
    
    ,output router_src_thanks_P      // thanksIn to processor's space_avail
);

    beehive_dynamic_node_top #(
         .NOC_DATA_W        (NOC_DATA_W     )
        ,.XY_COORD_W        (XY_COORD_W     )
        ,.CHIP_ID_W         (CHIP_ID_W      )
        ,.MSG_PAYLOAD_LEN   (MSG_PAYLOAD_LEN)
    ) beehive_dynamic_node_top (
        .clk(clk),
        .reset_in(reset_in),
        .dataIn_N(src_router_data_N),
        .dataIn_E(src_router_data_E),
        .dataIn_S(src_router_data_S),
        .dataIn_W(src_router_data_W),
        .dataIn_P(src_router_data_P),
        .validIn_N(src_router_val_N),
        .validIn_E(src_router_val_E),
        .validIn_S(src_router_val_S),
        .validIn_W(src_router_val_W),
        .validIn_P(src_router_val_P),
        .yummyIn_N(dst_router_yummy_N),
        .yummyIn_E(dst_router_yummy_E),
        .yummyIn_S(dst_router_yummy_S),
        .yummyIn_W(dst_router_yummy_W),
        .yummyIn_P(dst_router_yummy_P),
        .myLocX(myLocX),
        .myLocY(myLocY),
        .myChipID(myChipID),
        .ec_cfg(15'b0),
        .store_meter_partner_address_X(5'b0),
        .store_meter_partner_address_Y(5'b0),
        .dataOut_N(router_dst_data_N),
        .dataOut_E(router_dst_data_E),
        .dataOut_S(router_dst_data_S),
        .dataOut_W(router_dst_data_W),
        .dataOut_P(router_dst_data_P),
        .validOut_N(router_dst_val_N),
        .validOut_E(router_dst_val_E),
        .validOut_S(router_dst_val_S),
        .validOut_W(router_dst_val_W),
        .validOut_P(router_dst_val_P),
        .yummyOut_N(router_src_yummy_N),
        .yummyOut_E(router_src_yummy_E),
        .yummyOut_W(router_src_yummy_W),
        .yummyOut_S(router_src_yummy_S),
        .yummyOut_P(router_src_yummy_P),
        .thanksIn_P(router_src_thanks_P),
        .external_interrupt(),
        .store_meter_ack_partner(),
        .store_meter_ack_non_partner(),
        .ec_out()
    ); 

endmodule
