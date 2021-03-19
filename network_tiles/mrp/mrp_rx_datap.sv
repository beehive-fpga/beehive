`include "mrp_defs.svh"
module mrp_rx_datap (
     input clk
    ,input rst

    ,input          [`IP_ADDR_W-1:0]                src_mrp_rx_src_ip
    ,input          [`IP_ADDR_W-1:0]                src_mrp_rx_dst_ip
    ,input          [`PORT_NUM_W-1:0]               src_mrp_rx_src_port
    ,input          [`PORT_NUM_W-1:0]               src_mrp_rx_dst_port
    
    ,input          [`MAC_INTERFACE_W-1:0]          src_mrp_rx_data
    ,input          [`MAC_PADBYTES_W-1:0]           src_mrp_rx_data_padbytes

    ,output logic   [`MAC_INTERFACE_W-1:0]          mrp_dst_rx_outstream_data
    ,output logic   [CONN_ID_W-1:0]                 mrp_dst_rx_outstream_id
    ,output logic   [`MAC_PADBYTES_W-1:0]           mrp_dst_rx_outstream_padbytes
    ,input  logic                                   mrp_dst_rx_outstream_last
    
    ,output         mrp_req_key                     datap_cam_wr_tag
    ,output logic   [CONN_ID_W-1:0]                 datap_cam_wr_data

    ,output logic                                   datap_ctrl_new_flow_val

    ,input                                          ctrl_datap_store_meta
    ,input                                          ctrl_datap_store_hdr
    ,input                                          ctrl_datap_store_fifo_conn_id
    ,input                                          ctrl_datap_store_cam_result

    ,input                                          ctrl_datap_store_hold

    ,output logic                                   datap_ctrl_pkt_expected

    ,output logic   [CONN_ID_W-1:0]                 datap_state_rd_req_addr
    ,input          mrp_rx_state                    state_datap_rd_resp_data

    ,output logic   [CONN_ID_W-1:0]                 datap_state_wr_req_addr
    ,output         mrp_rx_state                    datap_state_wr_req_data

    ,output         mrp_req_key                     datap_cam_lookup_key
    ,input                                          cam_datap_lookup_hit
    ,input          [CONN_ID_W-1:0]                 cam_datap_conn_id 

    ,output                                         datap_ctrl_cam_hit

    ,input          [TIMESTAMP_W-1:0]               curr_time
    ,output logic   [CONN_ID_W-1:0]                 update_timer_conn_id
    ,output logic   [TIMESTAMP_W-1:0]               update_timer_time

    ,input  logic                                   ctrl_datap_store_padbytes
    
    ,output         mrp_flags                       datap_ctrl_mrp_flags

    ,input          [CONN_ID_W-1:0]                 conn_id_fifo_datap_conn_id

    ,output logic   [CONN_ID_W-1:0]                 datap_conn_id_wr_conn_id

    ,output                                         datap_ctrl_last_data
    
    ,output logic   [CONN_ID_W-1:0]                 mrp_rx_conn_id_table_wr_addr
    ,output         mrp_req_key                     mrp_rx_conn_id_table_wr_data
    
    ,output         [MRP_PKT_HDR_W-1:0]             datap_log_pkt_hdr
);
    localparam USE_BYTES = MRP_PKT_HDR_BYTES;
    localparam USE_W = USE_BYTES * 8;
    localparam HOLD_BYTES = `MAC_INTERFACE_BYTES - USE_BYTES;
    localparam HOLD_W = HOLD_BYTES * 8;

    logic   [`IP_ADDR_W-1:0]    src_ip_reg;
    logic   [`IP_ADDR_W-1:0]    src_ip_next;
    
    logic   [`IP_ADDR_W-1:0]    dst_ip_reg;
    logic   [`IP_ADDR_W-1:0]    dst_ip_next;

    logic   [`PORT_NUM_W-1:0]   src_port_reg;
    logic   [`PORT_NUM_W-1:0]   src_port_next;
    
    logic   [`PORT_NUM_W-1:0]   dst_port_reg;
    logic   [`PORT_NUM_W-1:0]   dst_port_next;

    mrp_pkt_hdr                 pkt_hdr_reg;
    mrp_pkt_hdr                 pkt_hdr_next;
    
    logic   [MRP_PKT_HDR_W-1:0] log_pkt_hdr_reg;
    logic   [MRP_PKT_HDR_W-1:0] log_pkt_hdr_next;

    logic   [HOLD_W-1:0]        hold_reg;
    logic   [HOLD_W-1:0]        hold_next;

    logic                       cam_hit_reg;
    logic                       cam_hit_next;

    logic   [CONN_ID_W-1:0]     conn_id_reg;
    logic   [CONN_ID_W-1:0]     conn_id_next;

    logic   [`MAC_PADBYTES_W-1:0]   padbytes_reg;
    logic   [`MAC_PADBYTES_W-1:0]   padbytes_next;
    logic   [`MAC_PADBYTES_W:0]     padbytes_calc;


    assign datap_log_pkt_hdr = log_pkt_hdr_next;


    always_ff @(posedge clk) begin
        if (rst) begin
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            src_port_reg <= '0;
            dst_port_reg <= '0;
            pkt_hdr_reg <= '0;
            log_pkt_hdr_reg <= '0;
            cam_hit_reg <= '0;
            conn_id_reg <= '0;
            padbytes_reg <= '0;
        end
        else begin
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            src_port_reg <= src_port_next;
            dst_port_reg <= dst_port_next;
            pkt_hdr_reg <= pkt_hdr_next;
            log_pkt_hdr_reg <= log_pkt_hdr_next;
            hold_reg <= hold_next;
            cam_hit_reg <= cam_hit_next;
            conn_id_reg <= conn_id_next;
            padbytes_reg <= padbytes_next;
        end
    end

    always_comb begin
        if (ctrl_datap_store_meta) begin
            src_ip_next = src_mrp_rx_src_ip;
            dst_ip_next = src_mrp_rx_dst_ip;
            src_port_next = src_mrp_rx_src_port;
            dst_port_next = src_mrp_rx_dst_port;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            src_port_next = src_port_reg;
            dst_port_next = dst_port_reg;
        end
    end

    assign pkt_hdr_next = ctrl_datap_store_hdr
                        ? src_mrp_rx_data[`MAC_INTERFACE_W-1 -: MRP_PKT_HDR_W]
                          : pkt_hdr_reg;
    
    assign log_pkt_hdr_next = ctrl_datap_store_hdr
                        ? src_mrp_rx_data[`MAC_INTERFACE_W-1 -: MRP_PKT_HDR_W]
                          : log_pkt_hdr_reg;

    assign hold_next = ctrl_datap_store_hold
                        ? src_mrp_rx_data[HOLD_W-1:0]
                        : hold_reg;

    assign cam_hit_next = ctrl_datap_store_cam_result
                            ? cam_datap_lookup_hit
                            : cam_hit_reg;

    always_comb begin
        if (ctrl_datap_store_cam_result) begin
            conn_id_next = cam_datap_conn_id;
        end
        else if (ctrl_datap_store_fifo_conn_id) begin
            conn_id_next = conn_id_fifo_datap_conn_id;
        end
        else begin
            conn_id_next = conn_id_reg;
        end
    end

    assign datap_ctrl_new_flow_val = (~cam_hit_reg) & (pkt_hdr_reg.pkt_num == 0);

    assign datap_ctrl_cam_hit = cam_hit_reg;
    assign datap_ctrl_pkt_expected = datap_ctrl_new_flow_val 
                                     | (state_datap_rd_resp_data.pkt_num == pkt_hdr_reg.pkt_num);

    assign datap_state_rd_req_addr = conn_id_reg;

    assign datap_ctrl_last_data = src_mrp_rx_data_padbytes >= HOLD_BYTES;

    assign datap_conn_id_wr_conn_id = conn_id_reg;

    always_comb begin
        datap_cam_lookup_key.src_ip = src_ip_reg;
        datap_cam_lookup_key.dst_ip = dst_ip_reg;
        datap_cam_lookup_key.src_port = src_port_reg;
        datap_cam_lookup_key.dst_port = dst_port_reg;
        datap_cam_lookup_key.req_id = pkt_hdr_reg.req_id;
    end

    assign datap_cam_wr_tag = datap_cam_lookup_key;
    assign datap_cam_wr_data = conn_id_next;

    assign datap_ctrl_mrp_flags = pkt_hdr_reg.flags;

    assign datap_state_wr_req_addr = conn_id_next;

    assign mrp_rx_conn_id_table_wr_addr = conn_id_next;
    assign mrp_rx_conn_id_table_wr_data =  datap_cam_lookup_key;

   // logic [MRP_PKT_NUM_W-1:0]   incr_pkt_num;
   // assign incr_pkt_num = pkt_hdr_reg.pkt_num + 1'b1;

    always_comb begin
        datap_state_wr_req_data = '0;
        datap_state_wr_req_data.pkt_num = pkt_hdr_reg.pkt_num + 1'b1;
    end

    assign update_timer_conn_id = conn_id_next;
    assign update_timer_time = curr_time + TIMEOUT_CYCLES;

    assign padbytes_next = ctrl_datap_store_padbytes
                            ? src_mrp_rx_data_padbytes
                            : padbytes_reg;
    assign padbytes_calc = padbytes_next + USE_BYTES;

    assign mrp_dst_rx_outstream_padbytes = mrp_dst_rx_outstream_last
                                            ? padbytes_calc[`MAC_PADBYTES_W-1:0]
                                            : '0;

    assign mrp_dst_rx_outstream_id = conn_id_reg;

    assign mrp_dst_rx_outstream_data = {hold_reg, src_mrp_rx_data[`MAC_INTERFACE_W-1 -: USE_W]};

endmodule
