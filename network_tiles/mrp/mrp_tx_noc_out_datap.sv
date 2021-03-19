`include "mrp_tx_defs.svh"
module mrp_tx_noc_out_datap #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst
    
    ,output logic   [`NOC_DATA_WIDTH-1:0]   mrp_tx_out_noc0_vrtoc_data    
    
    ,input  logic   [`IP_ADDR_W-1:0]        mrp_mrp_tx_out_tx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]        mrp_mrp_tx_out_tx_dst_ip
    ,input  logic   [`PORT_NUM_W-1:0]       mrp_mrp_tx_out_tx_src_port
    ,input  logic   [`PORT_NUM_W-1:0]       mrp_mrp_tx_out_tx_dst_port
    ,input  logic   [`UDP_LENGTH_W-1:0]     mrp_mrp_tx_out_tx_len

    ,input  logic   [`MAC_INTERFACE_W-1:0]  mrp_mrp_tx_out_tx_data
    ,input  logic                           mrp_mrp_tx_out_tx_data_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]   mrp_mrp_tx_out_tx_data_padbytes
    
    ,input  mrp_noc_out_flit_mux_sel        ctrl_datap_flit_sel
    ,input  logic                           ctrl_datap_store_inputs

    ,output logic                           datap_ctrl_last_output
);
    logic   [`MSG_LENGTH_WIDTH-1:0] num_data_flits;
    
    beehive_noc_hdr_flit    hdr_flit;
    udp_tx_metadata_flit    meta_flit;
    
    logic   [`IP_ADDR_W-1:0]    src_ip_reg;
    logic   [`IP_ADDR_W-1:0]    dst_ip_reg;
    logic   [`PORT_NUM_W-1:0]   src_port_reg;
    logic   [`PORT_NUM_W-1:0]   dst_port_reg;
    logic   [`TOT_LEN_W-1:0]    data_len_reg;

    logic   [`IP_ADDR_W-1:0]    src_ip_next;
    logic   [`IP_ADDR_W-1:0]    dst_ip_next;
    logic   [`PORT_NUM_W-1:0]   src_port_next;
    logic   [`PORT_NUM_W-1:0]   dst_port_next;
    logic   [`TOT_LEN_W-1:0]    data_len_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            src_port_reg <= '0;
            dst_port_reg <= '0;
            data_len_reg <= '0;
        end
        else begin
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            src_port_reg <= src_port_next;
            dst_port_reg <= dst_port_next;
            data_len_reg <= data_len_next;
        end
    end

    assign num_data_flits = data_len_next[`NOC_DATA_BYTES_W-1:0] == 0
                            ? data_len_next >> `NOC_DATA_BYTES_W
                            : (data_len_next >> `NOC_DATA_BYTES_W) + 1'b1;

    assign datap_ctrl_last_output = mrp_mrp_tx_out_tx_data_last;

    always_comb begin
        if (ctrl_datap_store_inputs) begin
            src_ip_next = mrp_mrp_tx_out_tx_src_ip;
            dst_ip_next = mrp_mrp_tx_out_tx_dst_ip;
            src_port_next = mrp_mrp_tx_out_tx_src_port;
            dst_port_next = mrp_mrp_tx_out_tx_dst_port;
            data_len_next = mrp_mrp_tx_out_tx_len;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            src_port_next = src_port_reg;
            dst_port_next = dst_port_reg;
            data_len_next = data_len_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_flit_sel == mrp_tx_pkg::SEL_HDR_FLIT) begin
            mrp_tx_out_noc0_vrtoc_data = hdr_flit;
        end
        else if (ctrl_datap_flit_sel == mrp_tx_pkg::SEL_META_FLIT) begin
            mrp_tx_out_noc0_vrtoc_data = meta_flit;
        end
        else begin
            mrp_tx_out_noc0_vrtoc_data = mrp_mrp_tx_out_tx_data;
        end
    end

    always_comb begin
        hdr_flit = '0;
        
        // we always send thru UDP
        hdr_flit.core.dst_x_coord = UDP_TX_X[`XY_WIDTH-1:0];
        hdr_flit.core.dst_y_coord = UDP_TX_Y[`XY_WIDTH-1:0];
        
        // there's one metadata flit and then some number of data flits
        hdr_flit.core.msg_len = 1 + num_data_flits;
        hdr_flit.core.src_x_coord = SRC_X[`XY_WIDTH-1:0];
        hdr_flit.core.src_y_coord = SRC_Y[`XY_WIDTH-1:0];
        hdr_flit.core.metadata_flits = 1;
        hdr_flit.core.msg_type = UDP_TX_SEGMENT;
    end

    always_comb begin
        meta_flit = '0;
        meta_flit.src_ip = src_ip_reg;
        meta_flit.dst_ip = dst_ip_reg;
        meta_flit.src_port = src_port_reg;
        meta_flit.dst_port = dst_port_reg;
        meta_flit.data_length = data_len_reg;
    end
endmodule
