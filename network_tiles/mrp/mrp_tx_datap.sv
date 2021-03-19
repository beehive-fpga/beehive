`include "mrp_defs.svh"
module mrp_tx_datap (
     input clk
    ,input rst

    ,output logic   [CONN_ID_W-1:0]                 mrp_tx_conn_id_table_rd_req_addr

    ,input          mrp_req_key                     conn_id_table_mrp_tx_rd_resp_data

    
    ,input  logic   [`UDP_LENGTH_W-1:0]             src_mrp_tx_instream_req_len
    ,input                                          src_mrp_tx_instream_msg_done
    ,input          [CONN_ID_W-1:0]                 src_mrp_tx_instream_conn_id
    ,input          [`MAC_INTERFACE_W-1:0]          src_mrp_tx_instream_data
    ,input          [`MAC_PADBYTES_W-1:0]           src_mrp_tx_instream_padbytes

    
    ,output logic   [`IP_ADDR_W-1:0]                mrp_dst_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]                mrp_dst_tx_dst_ip
    ,output logic   [`PORT_NUM_W-1:0]               mrp_dst_tx_src_port
    ,output logic   [`PORT_NUM_W-1:0]               mrp_dst_tx_dst_port
    ,output logic   [`UDP_LENGTH_W-1:0]             mrp_dst_tx_len

    ,output logic   [`MAC_INTERFACE_W-1:0]          mrp_dst_tx_data
    ,output logic   [`MAC_PADBYTES_W-1:0]           mrp_dst_tx_data_padbytes
    
    ,input  logic                                   ctrl_datap_store_meta
    ,input  logic                                   ctrl_datap_store_conn_data
    ,input  logic                                   ctrl_datap_update_pkt_data
    ,input  logic                                   ctrl_datap_calc_pkt_len
    ,input  logic                                   ctrl_datap_decr_bytes_rem

    ,input  logic                                   ctrl_datap_store_hold
    ,input          tx_hold_mux_sel_e               ctrl_datap_hold_mux_sel

    ,output logic                                   datap_ctrl_drain_hold
    ,output logic                                   datap_ctrl_msg_end
    ,output logic                                   datap_ctrl_last_pkt_bytes
    ,output logic                                   datap_ctrl_last_pkt
    ,input  logic                                   ctrl_datap_store_padbytes
    ,input          tx_padbytes_mux_sel_e           ctrl_datap_padbytes_mux_sel

    ,output logic   [CONN_ID_W-1:0]                 datap_tx_state_rd_req_addr

    ,input          mrp_tx_state                    tx_state_datap_rd_resp_data
    
    ,output logic   [CONN_ID_W-1:0]                 datap_tx_state_wr_req_addr
    ,output         mrp_tx_state                    datap_tx_state_wr_req_data

    ,output         mrp_req_key                     mrp_tx_dealloc_msg_finalize_key
    ,output         [CONN_ID_W-1:0]                 mrp_tx_dealloc_msg_finalize_conn_id
);

    localparam HOLD_BYTES = MRP_PKT_HDR_BYTES;
    localparam HOLD_W = MRP_PKT_HDR_BYTES * 8;
    localparam USE_BYTES = `MAC_INTERFACE_BYTES - HOLD_BYTES;
    localparam USE_W = USE_BYTES * 8;
    

    logic   [`UDP_LENGTH_W-1:0]             total_len_reg;
    logic   [`UDP_LENGTH_W-1:0]             pkt_data_len_reg;
    logic   [`UDP_LENGTH_W-1:0]             pkt_bytes_rem_reg;
    logic   [CONN_ID_W-1:0]                 conn_id_reg;
    logic                                   last_msg_reg;

    logic   [`MAC_PADBYTES_W-1:0]           padbytes_reg;
    logic   [HOLD_W-1:0]                    hold_reg;

    logic   [`UDP_LENGTH_W-1:0]             total_len_next;
    logic   [`UDP_LENGTH_W-1:0]             pkt_data_len_next;
    logic   [`UDP_LENGTH_W-1:0]             pkt_bytes_rem_next;
    logic   [CONN_ID_W-1:0]                 conn_id_next;
    logic                                   last_msg_next;
    logic   [HOLD_W-1:0]                    hold_next;

    logic   [`MAC_PADBYTES_W-1:0]           padbytes_next;

    logic   [`MAC_PADBYTES_W:0]             padbytes_calc;


    mrp_tx_state                            tx_state_reg;
    mrp_tx_state                            tx_state_next;
    mrp_req_key                             conn_key_reg;
    mrp_req_key                             conn_key_next;

    mrp_pkt_hdr                             mrp_hdr_cast;

    assign datap_tx_state_wr_req_addr = conn_id_next;
    assign datap_tx_state_wr_req_data = tx_state_reg;

    assign datap_tx_state_rd_req_addr = conn_id_next;
    assign mrp_tx_conn_id_table_rd_req_addr = conn_id_next;

    assign datap_ctrl_msg_end = last_msg_reg;
    assign mrp_tx_dealloc_msg_finalize_key = conn_key_reg;
    assign mrp_tx_dealloc_msg_finalize_conn_id = conn_id_reg;

    assign mrp_dst_tx_data = {hold_reg, src_mrp_tx_instream_data[`MAC_INTERFACE_W-1 -: USE_W]};
    assign mrp_dst_tx_len = pkt_data_len_reg + MRP_PKT_HDR_BYTES;
    assign mrp_dst_tx_src_ip = conn_key_reg.dst_ip;
    assign mrp_dst_tx_dst_ip = conn_key_reg.src_ip;
    assign mrp_dst_tx_src_port = conn_key_reg.dst_port;
    assign mrp_dst_tx_dst_port = conn_key_reg.src_port;

    assign datap_ctrl_last_pkt = total_len_reg <= MRP_MAX_DATA_SIZE;
    assign datap_ctrl_last_pkt_bytes = pkt_bytes_rem_reg <= `MAC_INTERFACE_BYTES;
    assign datap_ctrl_drain_hold = src_mrp_tx_instream_padbytes < HOLD_BYTES;

    assign padbytes_calc = padbytes_next + USE_BYTES;
    assign mrp_dst_tx_data_padbytes = datap_ctrl_last_pkt_bytes
                                    ? padbytes_calc[`MAC_PADBYTES_W-1:0]
                                    : '0;

    always_comb begin
        mrp_hdr_cast = '0;
        mrp_hdr_cast.req_id = conn_key_next.req_id;
        mrp_hdr_cast.pkt_num = tx_state_next.pkt_num;
        mrp_hdr_cast.flags.last_pkt = datap_ctrl_last_pkt & last_msg_reg;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            conn_key_reg <= '0;

            total_len_reg <= '0;
            pkt_data_len_reg <= '0;
            pkt_bytes_rem_reg <= '0;
            conn_id_reg <= '0;
            last_msg_reg <= '0;

            padbytes_reg <= '0;

            tx_state_reg <= '0;

            hold_reg <= '0;
        end
        else begin            
            conn_key_reg <= conn_key_next;

            total_len_reg <= total_len_next;
            pkt_data_len_reg <= pkt_data_len_next;
            pkt_bytes_rem_reg <= pkt_bytes_rem_next;
            conn_id_reg <= conn_id_next;
            last_msg_reg <= last_msg_next;

            padbytes_reg <= padbytes_next;

            tx_state_reg <= tx_state_next;

            hold_reg <= hold_next;
        end
    end

    always_comb begin
        if (ctrl_datap_store_meta) begin
            conn_id_next = src_mrp_tx_instream_conn_id;
            last_msg_next = src_mrp_tx_instream_msg_done;
        end
        else begin
            conn_id_next = conn_id_reg;
            last_msg_next = last_msg_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_store_conn_data) begin
            conn_key_next = conn_id_table_mrp_tx_rd_resp_data;
        end
        else begin
            conn_key_next = conn_key_reg;
        end
    end

    always_comb begin
        tx_state_next = tx_state_reg;
        if (ctrl_datap_store_conn_data) begin
            tx_state_next = tx_state_datap_rd_resp_data;
        end
        else if (ctrl_datap_update_pkt_data) begin
            tx_state_next.pkt_num = tx_state_reg.pkt_num + 1'b1;
        end
        else begin
            tx_state_next = tx_state_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_store_hold) begin
            if (ctrl_datap_hold_mux_sel == HDR) begin
                hold_next = mrp_hdr_cast;
            end
            else begin
                hold_next = src_mrp_tx_instream_data[HOLD_W-1:0];
            end
        end
        else begin
            hold_next = hold_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_store_padbytes) begin
            if (ctrl_datap_padbytes_mux_sel == INPUT) begin
                padbytes_next = src_mrp_tx_instream_padbytes;
            end
            else begin
                padbytes_next = '0;
            end
        end
        else begin
            padbytes_next = padbytes_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_store_meta) begin
            total_len_next = src_mrp_tx_instream_req_len;
        end
        else if (ctrl_datap_update_pkt_data) begin
            total_len_next = total_len_reg - (pkt_data_len_reg);
        end
        else begin
            total_len_next = total_len_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_calc_pkt_len) begin
            if (total_len_reg >= MRP_MAX_DATA_SIZE) begin
                pkt_data_len_next = MRP_MAX_DATA_SIZE;
            end
            else begin
                pkt_data_len_next = total_len_reg;
            end
        end 
        else begin
            pkt_data_len_next = pkt_data_len_reg;
        end
    end

    always_comb begin
        if (ctrl_datap_calc_pkt_len) begin
            pkt_bytes_rem_next = pkt_data_len_next;
        end
        else if (ctrl_datap_decr_bytes_rem) begin
            if (pkt_bytes_rem_reg <= `MAC_INTERFACE_BYTES) begin
                pkt_bytes_rem_next = '0;
            end
            else begin
                pkt_bytes_rem_next = pkt_bytes_rem_reg - `MAC_INTERFACE_BYTES;
            end
        end
        else begin
            pkt_bytes_rem_next = pkt_bytes_rem_reg;
        end
    end





endmodule
