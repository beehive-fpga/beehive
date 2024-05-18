`include "tcp_rx_tile_defs.svh"
module tcp_app_notif_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]   tcp_rx_notif_if_noc0_vrtoc_data
    
    ,input  logic   [FLOWID_W-1:0]          app_new_flow_flowid
    ,input          four_tuple_struct       app_new_flow_entry
    
    ,input  logic                           ctrl_datap_store_inputs
    ,input  logic                           ctrl_datap_read_cam
);

    logic   [FLOWID_W-1:0]      flowid_reg;
    logic   [FLOWID_W-1:0]      flowid_next;
    four_tuple_struct           lookup_reg;
    four_tuple_struct           lookup_next;

    tcp_notif_cam_entry cam_dst;

    logic   [`XY_WIDTH-1:0]         cam_dst_x;
    logic   [`XY_WIDTH-1:0]         cam_dst_y;
    logic   [`NOC_FBITS_WIDTH-1:0]  cam_dst_fbits;
    
    tcp_noc_hdr_flit tcp_hdr_flit;

    assign tcp_rx_notif_if_noc0_vrtoc_data = tcp_hdr_flit;

    always_ff @(posedge clk) begin
        if (rst) begin
            flowid_reg <= '0;
            lookup_reg <= '0;
        end
        else begin
            flowid_reg <= flowid_next;
            lookup_reg <= lookup_next;
        end
    end

    assign flowid_next = ctrl_datap_store_inputs
                        ? app_new_flow_flowid
                        : flowid_reg;

    assign lookup_next = ctrl_datap_store_inputs
                        ? app_new_flow_entry
                        : lookup_reg;

    tcp_app_notif_cam notif_cam (
         .clk   (clk)
        ,.rst   (rst)

        ,.dst_addr      (lookup_reg.host_ip     )
        ,.dst_port      (lookup_reg.host_port   )
        ,.rd_cam_val    (ctrl_datap_read_cam    )
        
        ,.rd_cam_data   (cam_dst                )
        ,.rd_cam_hit    ()
    );



    always_comb begin
        tcp_hdr_flit = '0; 
       
        tcp_hdr_flit.core.dst_x_coord = cam_dst.dst_x;
        tcp_hdr_flit.core.dst_y_coord = cam_dst.dst_y;
        tcp_hdr_flit.core.dst_fbits = cam_dst.dst_fbits;

        tcp_hdr_flit.core.msg_len = 0;
        tcp_hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        tcp_hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        tcp_hdr_flit.core.src_fbits = TCP_RX_APP_NOTIF_FBITS;

        tcp_hdr_flit.core.msg_type = TCP_NEW_FLOW_NOTIF;

        tcp_hdr_flit.inner.flowid = flowid_reg;
    end

endmodule
