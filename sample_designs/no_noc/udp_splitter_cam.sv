`include "packet_defs.vh"
module udp_splitter_cam #(
     parameter UDP_NUM_DST = 3
    ,parameter UDP_DST_ID_W = $clog2(UDP_NUM_DST)
    ,parameter UDP_APP_ID = 0
    ,parameter UDP_LOG_ID = 1
    ,parameter ETH_LAT_LOG_ID = 2
    ,parameter UDP_APP_PORT = 65432
    ,parameter UDP_LOG_PORT = 60000
    ,parameter ETH_LAT_LOG_PORT = 60001
)(
     input clk
    ,input rst

    ,input  logic                       rd_cam_val
    ,input  logic   [`PORT_NUM_W-1:0]   rd_cam_tag  
    ,output logic   [UDP_DST_ID_W-1:0]  rd_cam_data
    ,output logic                       rd_cam_hit
);
    
    logic   [UDP_NUM_DST-1:0][`PORT_NUM_W-1:0]  udp_port_tags;
    logic   [UDP_NUM_DST-1:0][UDP_DST_ID_W-1:0] udp_cam_data;
    logic   [UDP_NUM_DST-1:0]                   one_hot_sel_mux_sel;

    assign rd_cam_hit = rd_cam_val & (|one_hot_sel_mux_sel);
    
    always_ff @(posedge clk) begin
        if (rst) begin
            udp_port_tags[0] <= UDP_APP_PORT;
            udp_cam_data[0] <= UDP_APP_ID;
            udp_port_tags[1] <= UDP_LOG_PORT;
            udp_cam_data[1] <= UDP_LOG_ID;
            udp_port_tags[2] <= ETH_LAT_LOG_PORT;
            udp_cam_data[2] <= ETH_LAT_LOG_ID;
        end
    end
    
    genvar i;
    generate
        for (i = 0; i < UDP_NUM_DST; i++) begin: one_hot_proto_sel
            assign one_hot_sel_mux_sel[i] = udp_port_tags[i] == rd_cam_tag;
        end
    endgenerate

    bsg_mux_one_hot #(
         .width_p   (UDP_DST_ID_W   )
        ,.els_p     (UDP_NUM_DST    )
    ) mux_proto_dst (
         .data_i        (udp_cam_data       )
        ,.sel_one_hot_i (one_hot_sel_mux_sel)
        ,.data_o        (rd_cam_data        )
    );
endmodule
