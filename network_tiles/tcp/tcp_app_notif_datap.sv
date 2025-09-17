`include "noc_defs.vh"
module tcp_app_notif_datap 
import tcp_pkg::*;
import packet_struct_pkg::*;
import tcp_rx_tile_pkg::*;
import op_helper_pkg::*;
import mem_manage_pkg::*;
import mem_msg_pkg::*;
import apiary_noc_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter MONITOR_DATA_W = -1
)(
     input clk
    ,input rst
    
    ,input  app_new_flow_info               app_new_flow_notif_info
    
    ,input  logic                           ctrl_datap_store_inputs
    ,input  logic                           ctrl_datap_read_cam
    ,input  cap_sel_e                       ctrl_datap_sel_cap
    
    ,output logic   [MONITOR_DATA_W-1:0]    app_notif_monitor_noc_data

    ,input  logic   [MONITOR_DATA_W-1:0]    monitor_app_notif_noc_data
);
    localparam REQ_CAP_LINE_PADDING = `NOC_DATA_WIDTH - APP_CAP_SEND_W_CAP_STRUCT - (2 * APP_CAP_SEND_CMD_STRUCT_W);
    tcp_notif_cam_entry cam_dst;

    tcp_noc_hdr_flit tcp_hdr_flit;

    apiary_hdr_flit req_hdr_flit;
    app_cap_send_w_cap_struct req_cap_data;
    logic   [MONITOR_DATA_W-1:0]    req_cap_line;
    app_cap_send_cmd_struct rx_cmd;
    app_cap_send_cmd_struct tx_cmd;

    app_new_flow_info new_flow_info_reg;
    app_new_flow_info new_flow_info_next;

    always_ff @(posedge clk) begin
        new_flow_info_reg <= new_flow_info_next;
    end

    assign new_flow_info_next = ctrl_datap_store_inputs
                            ? app_new_flow_notif_info
                            : new_flow_info_reg;

    assign req_cap_line = {req_cap_data, rx_cmd, tx_cmd, {REQ_CAP_LINE_PADDING{1'b0}}};

    always_comb begin
        app_notif_monitor_noc_data = req_hdr_flit;
        if (ctrl_datap_sel_cap == REQ) begin
            app_notif_monitor_noc_data = req_cap_line;
        end
    end

    tcp_app_notif_cam notif_cam (
         .clk   (clk)
        ,.rst   (rst)

        ,.dst_addr      (new_flow_info_reg.flow_entry.host_ip   )
        ,.dst_port      (new_flow_info_reg.flow_entry.host_port )
        ,.rd_cam_val    (ctrl_datap_read_cam                    )
        
        ,.rd_cam_data   (cam_dst                                )
        ,.rd_cam_hit    ()
    );

    always_comb begin
        req_hdr_flit = 0;
        req_hdr_flit.core.dst_x_coord = '1;
        req_hdr_flit.core.dst_y_coord = '1;
        req_hdr_flit.core.dst_fbits = MEM_MANAGE_FBITS;
        req_hdr_flit.core.msg_len = 2;
        req_hdr_flit.core.msg_type = SEND_CAP;
        req_hdr_flit.core.src_fbits = TCP_RX_APP_NOTIF_FBITS;
    end

    always_comb begin
        req_cap_data = '0;
        req_cap_data.sendto_x = cam_dst.dst_x;
        req_cap_data.sendto_y = cam_dst.dst_y;
        req_cap_data.sendto_fbits = TCP_RX_APP_NOTIF_FBITS;
        req_cap_data.num_cmds = 2;
    end

    always_comb begin
        rx_cmd = '0;
        tx_cmd = '0;

        rx_cmd.base_addr = app_new_flow_notif_info.rx_cap_buffer.addr;
        rx_cmd.new_size = app_new_flow_notif_info.rx_cap_buffer.size;
        rx_cmd.new_perms = PERM_READ;
        rx_cmd.sendto_x = cam_dst.dst_x;
        rx_cmd.sendto_y = cam_dst.dst_y;
        
        tx_cmd.base_addr = app_new_flow_notif_info.tx_cap_buffer.addr;
        tx_cmd.new_size = app_new_flow_notif_info.tx_cap_buffer.size;
        tx_cmd.new_perms = PERM_WRITE;
        tx_cmd.sendto_x = cam_dst.dst_x;
        tx_cmd.sendto_y = cam_dst.dst_y;
    end


endmodule
