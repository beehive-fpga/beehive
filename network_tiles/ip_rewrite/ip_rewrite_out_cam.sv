`include "ip_rewrite_noc_pipe_defs.svh"
module ip_rewrite_rx_out_cam (
     input clk
    ,input rst
    
    ,input  logic                           rd_cam_val
    ,input  logic   [`PROTOCOL_W-1:0]       rd_cam_tag  
    ,output logic   [(`XY_WIDTH * 2)-1:0]   rd_cam_data
    ,output logic                           rd_cam_hit
);


    localparam IP_REWRITE_RX_NUM_DST = 1;

    
    logic   [IP_REWRITE_RX_NUM_DST-1:0][`PROTOCOL_W-1:0]   ip_proto_tags;
    logic   [IP_REWRITE_RX_NUM_DST-1:0][(`XY_WIDTH*2)-1:0] ip_cam_data;
    logic   [IP_REWRITE_RX_NUM_DST-1:0]                    one_hot_sel_mux_sel;
    
    assign rd_cam_hit = rd_cam_val & (|one_hot_sel_mux_sel);
    
    always_ff @(posedge clk) begin
        if (rst) begin
        ip_proto_tags[0] <= `IPPROTO_UDP;
            ip_cam_data[0] <= {UDP_RX_TILE_X,
                               UDP_RX_TILE_Y};

        end
    end
    
    genvar i;
    generate
        for (i = 0; i < IP_REWRITE_RX_NUM_DST; i++) begin: one_hot_proto_sel
            assign one_hot_sel_mux_sel[i] = ip_proto_tags[i] == rd_cam_tag;
        end
    endgenerate

    bsg_mux_one_hot #(
         .width_p   (2*`XY_WIDTH            )
        ,.els_p     (IP_REWRITE_RX_NUM_DST  )
    ) mux_proto_dst (
         .data_i        (ip_cam_data        )
        ,.sel_one_hot_i (one_hot_sel_mux_sel)
        ,.data_o        (rd_cam_data        )
    );


endmodule
