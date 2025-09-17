`include "packet_defs.vh"
module fixed_parser 
import packet_struct_pkg::*;
import parser_pkg::*;
#(
     parameter DATA_W=-1
    ,parameter DATA_BYTES=DATA_W/8
    ,parameter PADBYTES_W=$clog2(DATA_BYTES)
    ,parameter HAS_ETH_HDR=1
    ,parameter HAS_IP_HDR=1
)(
     input clk
    ,input rst
    
    ,input                              src_parser_data_val
    ,input  logic   [DATA_W-1:0]        src_parser_data
    ,input  logic   [PADBYTES_W-1:0]    src_parser_padbytes
    ,input  logic                       src_parser_last
    ,input  logic                       src_parser_start
    ,input  logic   [`MTU_SIZE_W-1:0]   src_parser_framesize
    ,output logic                       parser_src_data_rdy

    ,output logic                       parser_dst_meta_val
    ,output logic                       parser_dst_hash_val
    ,output         tuple_struct        parser_dst_hash_data
    ,input  logic                       dst_parser_meta_rdy

    ,output logic                       parser_dst_data_val
    ,output logic   [DATA_W-1:0]        parser_dst_data
    ,output logic   [PADBYTES_W-1:0]    parser_dst_padbytes
    ,output logic                       parser_dst_last
    ,output logic                       parser_dst_start
    ,output logic   [`MTU_SIZE_W-1:0]   parser_dst_framesize
    ,input  logic                       dst_parser_data_rdy
);

    localparam IP_ADDR_BYTES = `IP_ADDR_W/8;

    typedef enum logic[1:0] {
        PKT_START = 2'd0,
        PKT_BODY  = 2'd1,
        HASH_OUTPUT = 2'd2,
        UND = 'X
    } in_state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        HASH_OUT = 2'd1,
        DATA_WAIT = 2'd2,
        UNDEF = 'X
    } hash_out_state_e;

    typedef struct packed {
        eth_hdr eth;
        ip_pkt_hdr ip;
        logic   [`PORT_NUM_W-1:0]   src_port;
        logic   [`PORT_NUM_W-1:0]   dst_port;
    } eth_hdr_stack;
    localparam ETH_HDR_STACK_W = (ETH_HDR_W + IP_HDR_W + (2*`PORT_NUM_W));
    
    typedef struct packed {
        ip_pkt_hdr ip;
        logic   [`PORT_NUM_W-1:0]   src_port;
        logic   [`PORT_NUM_W-1:0]   dst_port;
    } ip_hdr_stack;
    localparam IP_HDR_STACK_W = (IP_HDR_W + (2*`PORT_NUM_W));

    localparam IP_HDR_OFFSET = HAS_ETH_HDR ? (ETH_HDR_BYTES) : '0;
    localparam IP_ADDR_OFFSET = IP_HDR_BYTES - (2 * IP_ADDR_BYTES);
    localparam IP_FIELD_OFFSET = IP_HDR_OFFSET + IP_ADDR_OFFSET;
    localparam L4_PORTS_OFFSET = IP_HDR_OFFSET + IP_HDR_BYTES;
    localparam IP_FIELD_BITS_OFFSET = IP_FIELD_OFFSET * 8;

    in_state_e in_state_reg;
    in_state_e in_state_next;

    hash_out_state_e hash_out_state_reg;
    hash_out_state_e hash_out_state_next;

    tuple_struct    hash_reg;
    logic           hash_val_reg;
    tuple_struct    hash_next;
    logic           hash_val_next;
    logic           protos_right;
    logic           store_hash;
    logic           meta_out;
    tuple_struct    hash_cast;

    eth_hdr_stack   stack_cast;
    ip_hdr_stack    ip_stack_cast;

    assign stack_cast = src_parser_data[DATA_W-1 -: ETH_HDR_STACK_W];
    assign ip_stack_cast = src_parser_data[DATA_W-1 -: IP_HDR_STACK_W];
    assign hash_next = store_hash
                    ? src_parser_data[DATA_W-1 - IP_FIELD_BITS_OFFSET -: HASH_STRUCT_W]
                    : hash_reg;
    assign hash_val_next = store_hash
                    ? protos_right
                    : hash_val_reg;

    assign parser_dst_hash_data = hash_reg;
    assign parser_dst_hash_val = hash_val_reg;

    generate
        if (HAS_ETH_HDR) begin
            always_comb begin
                hash_cast = '0;
                hash_cast.src_ip = stack_cast.ip.source_addr;
                hash_cast.dst_ip = stack_cast.ip.dest_addr;
                hash_cast.src_port = stack_cast.src_port;
                hash_cast.dst_port = stack_cast.dst_port;
            end
        end
        else begin
            always_comb begin
                hash_cast = '0;
                hash_cast.src_ip = ip_stack_cast.ip.source_addr;
                hash_cast.dst_ip = ip_stack_cast.ip.dest_addr;
                hash_cast.src_port = ip_stack_cast.src_port;
                hash_cast.dst_port = ip_stack_cast.dst_port;
            end
        end
    endgenerate

    generate
        if (HAS_ETH_HDR) begin
            assign protos_right = (stack_cast.eth.eth_type == `ETH_TYPE_IPV4) &&
                                   ((stack_cast.ip.protocol_no == `IPPROTO_TCP) ||
                                    (stack_cast.ip.protocol_no == `IPPROTO_UDP));
        end
        else begin
            assign protos_right = (ip_stack_cast.ip.protocol_no == `IPPROTO_TCP) ||
                                   (ip_stack_cast.ip.protocol_no == `IPPROTO_UDP);
        end
    endgenerate

    always_ff @(posedge clk) begin
        if (rst) begin
            in_state_reg <= PKT_START;
            hash_out_state_reg <= WAITING;
            hash_val_reg <= 1'b0;
        end
        else begin
            in_state_reg <= in_state_next;
            hash_out_state_reg <= hash_out_state_next;
            hash_val_reg <= hash_val_next;
            hash_reg <= hash_next;
        end
    end

    assign parser_dst_data = src_parser_data;
    assign parser_dst_last = src_parser_last;
    assign parser_dst_padbytes = src_parser_padbytes;
    assign parser_dst_start = src_parser_start;
    assign parser_dst_framesize = src_parser_framesize;

    always_comb begin
        parser_dst_data_val = 1'b0;
        parser_src_data_rdy = 1'b0;

        store_hash = 1'b0;
        meta_out = 1'b0;

        in_state_next = in_state_reg;
        case (in_state_reg)
            PKT_START: begin
                if (src_parser_data_val) begin
                    store_hash = 1'b1;
                    meta_out = 1'b1;
                    in_state_next = PKT_BODY;
                end
            end
            PKT_BODY: begin
                parser_dst_data_val = src_parser_data_val;
                parser_src_data_rdy = dst_parser_data_rdy;

                if (src_parser_data_val & dst_parser_data_rdy & src_parser_last) begin
                    in_state_next = HASH_OUTPUT;
                end
            end
            HASH_OUTPUT: begin
                if (hash_out_state_reg == DATA_WAIT) begin
                    in_state_next = PKT_START;
                end
            end
        endcase
    end

    always_comb begin
        parser_dst_meta_val = 1'b0;
        hash_out_state_next = hash_out_state_reg;
        case (hash_out_state_reg)
            WAITING: begin
                if (meta_out) begin
                    hash_out_state_next = HASH_OUT;
                end
            end
            HASH_OUT: begin
                parser_dst_meta_val = 1'b1;
                if (dst_parser_meta_rdy) begin
                    hash_out_state_next = DATA_WAIT;
                end
            end
            DATA_WAIT: begin
                if (in_state_reg == HASH_OUTPUT) begin
                    hash_out_state_next = WAITING;
                end
            end
        endcase
    end
endmodule
