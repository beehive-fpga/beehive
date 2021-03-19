module parser_wrap 
    import parser_pkg::*;
#(
     parameter DATA_W = 512
    ,parameter PADBYTES_W = $clog2(DATA_W/8)
)(
     input clk
    ,input rst

    ,input                              src_parser_data_val
    ,input  logic   [DATA_W-1:0]        src_parser_data
    ,input  logic   [PADBYTES_W-1:0]    src_parser_padbytes
    ,input  logic                       src_parser_last
    ,output logic                       parser_src_data_rdy

    ,output logic                       parser_dst_meta_val
    ,output logic                       parser_dst_hash_val
    ,output logic   [HASH_STRUCT_W-1:0] parser_dst_hash_data
    ,input  logic                       dst_parser_meta_rdy

    ,output logic                       parser_dst_data_val
    ,output logic   [DATA_W-1:0]        parser_dst_data
    ,output logic   [PADBYTES_W-1:0]    parser_dst_padbytes
    ,output logic                       parser_dst_last
    ,input  logic                       dst_parser_data_rdy

);

    fixed_parser #(
         .DATA_W        (DATA_W )
        ,.HAS_ETH_HDR   (1      )
        ,.HAS_IP_HDR    (1      )
    ) DUT (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_parser_data_val   (src_parser_data_val    )
        ,.src_parser_data       (src_parser_data        )
        ,.src_parser_padbytes   (src_parser_padbytes    )
        ,.src_parser_last       (src_parser_last        )
        ,.parser_src_data_rdy   (parser_src_data_rdy    )
                                                        
        ,.parser_dst_meta_val   (parser_dst_meta_val    )
        ,.parser_dst_hash_val   (parser_dst_hash_val    )
        ,.parser_dst_hash_data  (parser_dst_hash_data   )
        ,.dst_parser_meta_rdy   (dst_parser_meta_rdy    )
                                                        
        ,.parser_dst_data_val   (parser_dst_data_val    )
        ,.parser_dst_data       (parser_dst_data        )
        ,.parser_dst_padbytes   (parser_dst_padbytes    )
        ,.parser_dst_last       (parser_dst_last        )
        ,.dst_parser_data_rdy   (dst_parser_data_rdy    )
    );
endmodule
