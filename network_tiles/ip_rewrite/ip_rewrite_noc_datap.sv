`include "ip_rewrite_noc_pipe_defs.svh"
module ip_rewrite_noc_pipe_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter RX_REWRITE = 1
)(
     input clk
    ,input rst

    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_ip_rewrite_in_data
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_out_noc0_vrtoc_data    
    
    ,output flow_lookup_tuple               lookup_rd_table_read_tuple

    ,input                                  lookup_rd_table_rewrite_hit
    ,input          [`IP_ADDR_W-1:0]        lookup_rd_table_rewrite_addr

    ,output logic   [`PROTOCOL_W-1:0]       datap_cam_lookup_protocol
    ,input  logic   [`NOC_X_WIDTH-1:0]      cam_datap_dst_x
    ,input  logic   [`NOC_Y_WIDTH-1:0]      cam_datap_dst_y
    
    ,input  logic                           ctrl_datap_store_hdr
    ,input  logic                           ctrl_datap_store_meta
    ,input  logic                           ctrl_datap_store_lookup
    ,input  logic                           ctrl_datap_store_dst
    ,input  ip_rewrite_out_sel_e            ctrl_datap_noc_out_sel
    ,input  logic                           ctrl_datap_init_flit_cnt
    ,input  logic                           ctrl_datap_incr_flit_cnt
    ,input  logic                           ctrl_datap_use_rewrite_chksum
    
    ,output logic                           datap_ctrl_last_flit
);

    typedef struct packed {
        logic   [`PORT_NUM_W-1:0]    src_port;
        logic   [`PORT_NUM_W-1:0]    dst_port;
    } port_cast_struct;
    localparam PORT_CAST_W = $bits(port_cast_struct);

    beehive_noc_hdr_flit    hdr_flit_reg;
    beehive_noc_hdr_flit    hdr_flit_next;
    beehive_noc_hdr_flit    hdr_flit_cast;

    ip_rx_metadata_flit     meta_flit_reg;
    ip_rx_metadata_flit     meta_flit_next;
    ip_rx_metadata_flit     meta_flit_cast;

    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] flit_cnt_next;

    logic   [`NOC_X_WIDTH-1:0]  dst_x_reg;
    logic   [`NOC_X_WIDTH-1:0]  dst_x_next;
    logic   [`NOC_Y_WIDTH-1:0]  dst_y_reg;
    logic   [`NOC_Y_WIDTH-1:0]  dst_y_next;

    logic                       rewrite_hit_reg;
    logic                       rewrite_hit_next;
    logic   [`IP_ADDR_W-1:0]    rewrite_addr_reg;
    logic   [`IP_ADDR_W-1:0]    rewrite_addr_next;
    
    logic   [`IP_ADDR_W-1:0]    old_ip_addr;
    logic   [`IP_ADDR_W-1:0]    new_ip_addr;
    logic   [`TCP_CHKSUM_W-1:0] new_chksum;

    tcp_pkt_hdr tcp_hdr_reg;
    tcp_pkt_hdr tcp_hdr_next;
    tcp_pkt_hdr out_hdr_cast;

    port_cast_struct port_cast;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_reg <= '0;
            meta_flit_reg <= '0;
            flit_cnt_reg <= '0;
            dst_x_reg <= '0;
            dst_y_reg <= '0;
            rewrite_hit_reg <= '0;
            rewrite_addr_reg <= '0;
        end
        else begin
            hdr_flit_reg <= hdr_flit_next;
            meta_flit_reg <= meta_flit_next;
            flit_cnt_reg <= flit_cnt_next;
            dst_x_reg <= dst_x_next;
            dst_y_reg <= dst_y_next;
            rewrite_hit_reg <= rewrite_hit_next;
            rewrite_addr_reg <= rewrite_addr_next;
            tcp_hdr_reg <= tcp_hdr_next;
        end
    end

    assign datap_cam_lookup_protocol = meta_flit_reg.protocol;

    always_comb begin
        if (RX_REWRITE) begin
            lookup_rd_table_read_tuple.their_addr = meta_flit_reg.src_ip;
            lookup_rd_table_read_tuple.their_port = port_cast.src_port;
            lookup_rd_table_read_tuple.our_port = port_cast.dst_port;
        end
        else begin
            lookup_rd_table_read_tuple.their_addr = meta_flit_reg.dst_ip;
            lookup_rd_table_read_tuple.their_port = port_cast.dst_port;
            lookup_rd_table_read_tuple.our_port = port_cast.src_port;
        end
    end

    assign datap_ctrl_last_flit = flit_cnt_reg == (hdr_flit_reg.core.core.msg_len - 1);

    assign hdr_flit_next = ctrl_datap_store_hdr
                        ? noc0_ctovr_ip_rewrite_in_data
                        : hdr_flit_reg;
    assign meta_flit_next = ctrl_datap_store_meta
                        ? noc0_ctovr_ip_rewrite_in_data
                        : meta_flit_reg;

    assign port_cast = noc0_ctovr_ip_rewrite_in_data[`NOC_DATA_WIDTH - 1 -: PORT_CAST_W];

    assign flit_cnt_next = ctrl_datap_init_flit_cnt
                        ? '0
                        : ctrl_datap_incr_flit_cnt
                            ? flit_cnt_reg + 1'b1
                            : flit_cnt_reg;

    assign dst_x_next = ctrl_datap_store_dst
                        ? cam_datap_dst_x
                        : dst_x_reg;
    assign dst_y_next = ctrl_datap_store_dst
                        ? cam_datap_dst_y
                        : dst_y_reg;

    assign rewrite_addr_next = ctrl_datap_store_lookup
                            ? lookup_rd_table_rewrite_addr
                            : rewrite_addr_reg;
    assign rewrite_hit_next = ctrl_datap_store_lookup
                            ? lookup_rd_table_rewrite_hit
                            : rewrite_hit_reg;

    assign tcp_hdr_next = ctrl_datap_store_lookup
                        ? noc0_ctovr_ip_rewrite_in_data[`NOC_DATA_WIDTH-1 -: TCP_HDR_W]
                        : tcp_hdr_reg;


    always_comb begin
        if (ctrl_datap_noc_out_sel == ip_rewrite_noc_pipe_pkg::HDR_OUT) begin
            ip_rewrite_out_noc0_vrtoc_data = hdr_flit_cast;
        end
        else if (ctrl_datap_noc_out_sel == ip_rewrite_noc_pipe_pkg::META_OUT) begin
            ip_rewrite_out_noc0_vrtoc_data = meta_flit_cast;
        end
        else begin
            ip_rewrite_out_noc0_vrtoc_data = noc0_ctovr_ip_rewrite_in_data;
            if (ctrl_datap_use_rewrite_chksum) begin
                ip_rewrite_out_noc0_vrtoc_data[`NOC_DATA_WIDTH - 1 -: TCP_HDR_W] = 
                    out_hdr_cast;
            end
        end
    end

    always_comb begin
        hdr_flit_cast = hdr_flit_reg;
        hdr_flit_cast.core.core.dst_x_coord = dst_x_reg;
        hdr_flit_cast.core.core.dst_y_coord = dst_y_reg;
        hdr_flit_cast.core.core.src_x_coord = SRC_X;
        hdr_flit_cast.core.core.src_y_coord = SRC_Y;
    end

    always_comb begin
        meta_flit_cast = meta_flit_reg;
        if (rewrite_hit_reg) begin
            if (RX_REWRITE) begin
                meta_flit_cast.src_ip = rewrite_addr_reg;
            end
            else begin
                meta_flit_cast.dst_ip = rewrite_addr_reg;
            end
        end
    end
    
    assign old_ip_addr = RX_REWRITE == 1
                        ? meta_flit_reg.src_ip
                        : meta_flit_reg.dst_ip;

    assign new_ip_addr = rewrite_hit_reg
                        ? rewrite_addr_reg
                        : old_ip_addr;

    always_comb begin
        out_hdr_cast = tcp_hdr_reg;
        out_hdr_cast.chksum = new_chksum;
    end

    update_chksum_nat chksum_recalc (
         .clk   (clk    )
    
        ,.old_chksum    (tcp_hdr_reg.chksum )
        ,.old_ip_addr   (old_ip_addr        )
        ,.new_ip_addr   (new_ip_addr        )
    
        ,.new_chksum    (new_chksum         )
    );

endmodule
