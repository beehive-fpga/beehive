`include "packet_defs.vh"
module eth_filter_cam #(
     parameter ETH_NUM_DST = 1
    ,parameter DST_ID_W = 1
)(
     input clk
    ,input rst
    
    ,input  logic                           rd_cam_val
    ,input  logic   [`ETH_TYPE_W-1:0]       rd_cam_tag  
    ,output logic   [DST_ID_W-1:0]          rd_cam_data
    ,output logic                           rd_cam_hit
);



    logic   [ETH_NUM_DST-1:0][`ETH_TYPE_W-1:0]  eth_proto_tags;
    logic   [ETH_NUM_DST-1:0][DST_ID_W-1:0]     eth_cam_data;
    logic   [ETH_NUM_DST-1:0]                   one_hot_sel_mux_sel;

    assign rd_cam_hit = rd_cam_val & (|one_hot_sel_mux_sel);

    always_ff @(posedge clk) begin
        if (rst) begin
            eth_proto_tags[0] <= `ETH_TYPE_IPV4;
            eth_cam_data[0] <= 1'b0;
        end
    end
    
    genvar i;
    generate
        for (i = 0; i < ETH_NUM_DST; i++) begin: one_hot_proto_sel
            assign one_hot_sel_mux_sel[i] = eth_proto_tags[i] == rd_cam_tag;
        end
    endgenerate

    bsg_mux_one_hot #(
         .width_p   (DST_ID_W       )
        ,.els_p     (ETH_NUM_DST    )
    ) mux_proto_dst (
         .data_i        (eth_cam_data       )
        ,.sel_one_hot_i (one_hot_sel_mux_sel)
        ,.data_o        (rd_cam_data        )
    );
endmodule
