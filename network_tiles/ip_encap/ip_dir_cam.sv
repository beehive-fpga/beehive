`include "ip_encap_tx_defs.svh"
module ip_dir_cam #(
    parameter CAM_ELS = -1
)(
     input clk
    ,input rst
    
    ,input  logic   [CAM_ELS-1:0]           wr_cam_val
    ,input  logic   [`IP_ADDR_W-1:0]        wr_tag 
    ,input  logic   [`IP_ADDR_W-1:0]        wr_data
    ,output logic                           wr_cam_rdy

    ,input  logic                           rd_cam_val
    ,input  logic   [`PROTOCOL_W-1:0]       rd_cam_tag  
    ,output logic   [(`XY_WIDTH * 2)-1:0]   rd_cam_data
    ,output logic                           rd_cam_hit
    ,output logic                           rd_cam_rdy
);
    
    logic   [IP_RX_NUM_DST-1:0][`IP_ADDR_W-1:0] ip_addr_tags;
    logic   [IP_RX_NUM_DST-1:0][`IP_ADDR_W-1:0] ip_addr_data;
    logic   [IP_RX_NUM_DST-1:0]                 one_hot_sel_mux_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
        end
        else begin
        end
    end
endmodule
