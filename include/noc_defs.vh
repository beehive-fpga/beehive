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

//==================================================================================================
//  Filename      : define.h
//  Created On    : 2014-02-20
//  Last Modified : 2018-11-16 17:14:11
//  Revision      :
//  Author        : Yaosheng Fu
//  Company       : Princeton University
//  Email         : yfu@princeton.edu
//
//  Description   : main header file defining global architecture parameters
//
//
//==================================================================================================

`ifndef NOC_DEFS_VH
`define NOC_DEFS_VH

`define    XY_WIDTH 8
`define    CHIP_ID_WIDTH 14
`define    PAYLOAD_LEN 22
`define    DATA_WIDTH 512
`define    OFF_CHIP_NODE_X 0
`define    OFF_CHIP_NODE_Y 0
`define    FINAL_BITS 4

`define CTRL_NOC_DATA_W 64

//whether the routing is based on chipid or x y position
//`define    ROUTING_CHIP_ID
`define    ROUTING_XY

//defines for different topology, only one should be active
`define    NETWORK_TOPO_2D_MESH
//`define    NETWORK_TOPO_3D_MESH
//`define    NETWORK_TOPO_XBAR
    //
`define CTRL_NOC_DATA_W 64
`define CTRL_NOC1_DATA_W    `CTRL_NOC_DATA_W
`define CTRL_NOC2_DATA_W    `CTRL_NOC_DATA_W

// NoC interface
// Core fields for the routers
// This field ordering must be maintained
`define NOC_DATA_WIDTH      `DATA_WIDTH
`define NOC_CHIPID_WIDTH    `CHIP_ID_WIDTH
`define NOC_X_WIDTH         `XY_WIDTH
`define NOC_Y_WIDTH         `XY_WIDTH
`define NOC_FBITS_WIDTH     `FINAL_BITS

`define CTRL_NOC1_DATA_W    `CTRL_NOC_DATA_W
`define CTRL_NOC2_DATA_W    `CTRL_NOC_DATA_W

`define MSG_DST_CHIPID_WIDTH    `NOC_CHIPID_WIDTH
`define MSG_DST_X_WIDTH         `NOC_X_WIDTH
`define MSG_DST_Y_WIDTH         `NOC_Y_WIDTH
`define MSG_DST_FBITS_WIDTH     `NOC_FBITS_WIDTH
`define MSG_LENGTH_WIDTH        22
`define MSG_TYPE_WIDTH          8

`define NOC_OFF_CHIP_NODE_X `OFF_CHIP_NODE_X
`define NOC_OFF_CHIP_NODE_Y `OFF_CHIP_NODE_Y


    //`define NOC_FBITS_RESERVED  4'd1
//`define NOC_FBITS_L1        4'd0
//`define NOC_FBITS_L2        4'd0
//`define NOC_FBITS_FP        4'd0
//`define NOC_FBITS_MEM       4'd2

//`define NOC_NODEID_WIDTH    34
//`define NOC_DATACOUNT_WIDTH 5
//`define NOC_EC_WIDTH        5

`define NOC_DATA_BITS_W ($clog2(`NOC_DATA_WIDTH))
`define NOC_DATA_BYTES (`NOC_DATA_WIDTH >> 3)
`define NOC_DATA_BYTES_W ($clog2(`NOC_DATA_BYTES))
`define NOC_PADBYTES_WIDTH  `NOC_DATA_BYTES_W

//========================
//Packet format
//=========================

//Header decomposition
//`define MSG_HEADER_WIDTH        192

//`define MSG_TYPE                455:448
//`define MSG_TYPE_LO             448
//`define MSG_LENGTH              477:456
//`define MSG_LENGTH_LO           456 
//`define MSG_DST_FBITS           481:478
//`define MSG_DST_Y               489:482
//`define MSG_DST_X               497:490
//`define MSG_DST_CHIPID          511:498
//`define MSG_DST_CHIPID_HI       511

`define MSG_DST_CHIPID_HI       (`NOC_DATA_WIDTH-1)
`define MSG_DST_CHIPID_LO       (`MSG_DST_CHIPID_HI - (`CHIP_ID_WIDTH - 1))
`define MSG_DST_CHIPID          `MSG_DST_CHIPID_HI:`MSG_DST_CHIPID_LO

`define MSG_DST_Y_HI            (`MSG_DST_CHIPID_LO-1)
`define MSG_DST_Y_LO            (`MSG_DST_Y_HI - (`XY_WIDTH-1))
`define MSG_DST_Y               `MSG_DST_Y_HI:`MSG_DST_Y_LO

`define MSG_DST_X_HI            (`MSG_DST_Y_LO-1)
`define MSG_DST_X_LO            (`MSG_DST_X_HI - (`XY_WIDTH-1))
`define MSG_DST_X               `MSG_DST_X_HI:`MSG_DST_X_LO

`define MSG_DST_FBITS_HI        (`MSG_DST_X_LO - 1)
`define MSG_DST_FBITS_LO        (`MSG_DST_FBITS_HI - (`NOC_FBITS_WIDTH-1))
`define MSG_DST_FBITS           `MSG_DST_FBITS_HI:`MSG_DST_FBITS_LO

`define MSG_LENGTH_HI           (`MSG_DST_FBITS_LO - 1)
`define MSG_LENGTH_LO           (`MSG_LENGTH_HI - (`MSG_LENGTH_WIDTH - 1))
`define MSG_LENGTH              `MSG_LENGTH_HI:`MSG_LENGTH_LO

`define MSG_TYPE_HI             (`MSG_LENGTH_LO - 1)
`define MSG_TYPE_LO             (`MSG_TYPE_HI - (`MSG_TYPE_WIDTH-1))
`define MSG_TYPE                `MSG_TYPE_HI:`MSG_TYPE_LO

`define CTRL_MSG_DST_CHIPID_HI       (`CTRL_NOC_DATA_W-1)
`define CTRL_MSG_DST_CHIPID_LO       (`CTRL_MSG_DST_CHIPID_HI - (`CHIP_ID_WIDTH - 1))
`define CTRL_MSG_DST_CHIPID          `CTRL_MSG_DST_CHIPID_HI:`CTRL_MSG_DST_CHIPID_LO

`define CTRL_MSG_DST_Y_HI            (`CTRL_MSG_DST_CHIPID_LO-1)
`define CTRL_MSG_DST_Y_LO            (`CTRL_MSG_DST_Y_HI - (`XY_WIDTH-1))
`define CTRL_MSG_DST_Y               `CTRL_MSG_DST_Y_HI:`CTRL_MSG_DST_Y_LO

`define CTRL_MSG_DST_X_HI            (`CTRL_MSG_DST_Y_LO-1)
`define CTRL_MSG_DST_X_LO            (`CTRL_MSG_DST_X_HI - (`XY_WIDTH-1))
`define CTRL_MSG_DST_X               `CTRL_MSG_DST_X_HI:`CTRL_MSG_DST_X_LO

`define CTRL_MSG_DST_FBITS_HI        (`CTRL_MSG_DST_X_LO - 1)
`define CTRL_MSG_DST_FBITS_LO        (`CTRL_MSG_DST_FBITS_HI - (`NOC_FBITS_WIDTH-1))
`define CTRL_MSG_DST_FBITS           `CTRL_MSG_DST_FBITS_HI:`CTRL_MSG_DST_FBITS_LO

`define CTRL_MSG_LENGTH_HI           (`CTRL_MSG_DST_FBITS_LO - 1)
`define CTRL_MSG_LENGTH_LO           (`CTRL_MSG_LENGTH_HI - (`MSG_LENGTH_WIDTH - 1))
`define CTRL_MSG_LENGTH              `CTRL_MSG_LENGTH_HI:`CTRL_MSG_LENGTH_LO

`define CTRL_MSG_TYPE_HI             (`CTRL_MSG_LENGTH_LO - 1)
`define CTRL_MSG_TYPE_LO             (`CTRL_MSG_TYPE_HI - (`MSG_TYPE_WIDTH-1))
`define CTRL_MSG_TYPE                `CTRL_MSG_TYPE_HI:`CTRL_MSG_TYPE_LO

//`define MSG_ADDR                119:80

//`define MSG_SRC_FBITS           161:158
//`define MSG_SRC_Y               169:162
//`define MSG_SRC_X               177:170
//`define MSG_SRC_CHIPID          191:178

// these shifted fields are added for convienience
// HEADER 2
//`define MSG_OPTIONS_2_           15:0
//`define MSG_ADDR_LO_             16
//`define MSG_ADDR_HI_             (`MSG_ADDR_LO_ + `PHY_ADDR_WIDTH - 1)
//`define MSG_ADDR_                (`MSG_ADDR_HI_):(`MSG_ADDR_LO_)

// HEADER 3
//`define MSG_OPTIONS_3_           29:0
//`define MSG_SRC_FBITS_           33:30
//`define MSG_SRC_Y_               41:34
//`define MSG_SRC_X_               49:42
//`define MSG_SRC_CHIPID_          63:50

//NoC header information

//`define MSG_DST_NODEID_WIDTH    `NOC_NODEID_WIDTH

// Header 1
`define MSG_FLIT_WIDTH          `NOC_DATA_WIDTH

// Header 2
// Width of MSG_ADDR field - you're probably looking for PHY_ADDR_WIDTH
`define MSG_ADDR_WIDTH          48
`define MSG_OPTIONS_2_WIDTH     16

// Header 3
`define MSG_SRC_CHIPID_WIDTH    `NOC_CHIPID_WIDTH
`define MSG_SRC_X_WIDTH         `NOC_X_WIDTH
`define MSG_SRC_Y_WIDTH         `NOC_Y_WIDTH
`define MSG_SRC_FBITS_WIDTH     `NOC_FBITS_WIDTH
`define MEM_REQ_ADDR_W          30
`define MSG_DATA_SIZE_WIDTH     30


`define MSG_SRC_NODEID_WIDTH    `NOC_NODEID_WIDTH

//Memory requests from L2 to DRAM
`define MSG_TYPE_LOAD_MEM           8'd19
`define MSG_TYPE_STORE_MEM          8'd20

`define MSG_TYPE_LOAD_MEM_ACK       8'd24
`define MSG_TYPE_STORE_MEM_ACK      8'd25


//`define MSG_CACHE_TYPE_WIDTH        1
//`define MSG_CACHE_TYPE_DATA         1'b0
//`define MSG_CACHE_TYPE_INS          1'b1

`endif

