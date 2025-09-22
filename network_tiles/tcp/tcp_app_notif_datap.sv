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
    ,input  logic                           ctrl_datap_do_tx
    
    ,output logic   [MONITOR_DATA_W-1:0]    app_notif_monitor_noc_data

    ,input  logic   [MONITOR_DATA_W-1:0]    monitor_app_notif_noc_data
    
    ,output [MONITOR_DATA_W-1:0]            app_notif_tx_monitor_data

    ,input  [MONITOR_DATA_W-1:0]            tx_monitor_app_notif_data
);
    localparam REQ_CAP_LINE_PADDING = `NOC_DATA_WIDTH - APP_CAP_SEND_W_CAP_STRUCT - (APP_CAP_SEND_CMD_STRUCT_W);
    localparam FLOW_NOTIF_PADDING = `NOC_DATA_WIDTH - TCP_NOTIF_FLOW_INFO_W;

    tcp_notif_flow_info flow_info_cast;

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

    always_comb begin
        if (ctrl_datap_do_tx) begin
            req_cap_line = {req_cap_data, tx_cmd, {REQ_CAP_LINE_PADDING{1'b0}}};
        end
        else begin
            req_cap_line = {req_cap_data, rx_cmd, {REQ_CAP_LINE_PADDING{1'b0}}};
        end
    end

    always_comb begin
        flow_info_cast.flowid = new_flow_info_reg.flowid;
        if (ctrl_datap_do_tx) begin
            flow_info_cast.buf_dir = TX;
            flow_info_cast.size = new_flow_info_reg.tx_cap_buffer.size;
            flow_info_cast.base_offset = new_flow_info_reg.tx_cap_buffer.addr.offset;
        end
        else begin
            flow_info_cast.buf_dir = RX;
            flow_info_cast.size = new_flow_info_reg.rx_cap_buffer.size;
            flow_info_cast.base_offset = new_flow_info_reg.rx_cap_buffer.addr.offset;
        end
    end

    assign app_notif_tx_monitor_data = app_notif_monitor_noc_data;

    always_comb begin
        app_notif_monitor_noc_data = req_hdr_flit;
        if (ctrl_datap_sel_cap == REQ) begin
            app_notif_monitor_noc_data = req_cap_line;
        end
        else if (ctrl_datap_sel_cap == NOTIF) begin
            app_notif_monitor_noc_data = {flow_info_cast, {FLOW_NOTIF_PADDING{1'b0}}};
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
        req_cap_data.num_cmds = 1;
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
