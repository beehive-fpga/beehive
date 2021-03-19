module simple_log_no_noc_reader_datap #(
     parameter ADDR_W = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter CLIENT_ADDR_W = -1
)(
     input clk
    ,input rst
    
    ,input  logic   [`IP_ADDR_W-1:0]            udp_log_rx_src_ip
    ,input  logic   [`IP_ADDR_W-1:0]            udp_log_rx_dst_ip
    ,input  udp_pkt_hdr                         udp_log_rx_udp_hdr

    ,input  logic   [`MAC_INTERFACE_W-1:0]      udp_log_rx_data
    ,input  logic                               udp_log_rx_last
    ,input  logic   [`MAC_PADBYTES_W-1:0]       udp_log_rx_padbytes
    
    ,output logic   [`IP_ADDR_W-1:0]            log_udp_tx_src_ip
    ,output logic   [`IP_ADDR_W-1:0]            log_udp_tx_dst_ip
    ,output udp_pkt_hdr                         log_udp_tx_udp_hdr

    ,output logic   [`MAC_INTERFACE_W-1:0]      log_udp_tx_data
    ,output logic   [`MAC_PADBYTES_W-1:0]       log_udp_tx_padbytes

    ,output logic   [ADDR_W-1:0]                log_rd_req_addr

    ,input  logic   [RESP_DATA_STRUCT_W-1:0]    log_rd_resp_data            
   
    ,input  logic                               ctrl_datap_store_hdr
    ,input  logic                               ctrl_datap_store_req
    ,input  logic                               ctrl_datap_store_log_resp

    ,output logic                               datap_ctrl_rd_meta
    
    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped
);
    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0] req_addr;
    } simple_log_req_struct;
    localparam SIMPLE_LOG_REQ_STRUCT_W = CLIENT_ADDR_W;
    
    localparam RESP_PAYLOAD_W = `MAC_INTERFACE_W - CLIENT_ADDR_W;
    typedef struct packed {
        logic   [CLIENT_ADDR_W-1:0]     resp_addr;
        logic   [RESP_PAYLOAD_W-1:0]    resp_payload;
    } simple_log_resp_struct;
    localparam SIMPLE_LOG_RESP_STRUCT_BYTES = `MAC_INTERFACE_W/8;

    simple_log_req_struct                   log_req_reg;
    simple_log_req_struct                   log_req_next;

    logic   [RESP_DATA_STRUCT_W-1:0]        entry_reg;
    logic   [RESP_DATA_STRUCT_W-1:0]        entry_next;

    udp_pkt_hdr                             resp_hdr_cast;

    simple_log_resp_struct                  log_resp_cast;

    logic   [`IP_ADDR_W-1:0]    src_ip_reg;
    logic   [`IP_ADDR_W-1:0]    dst_ip_reg;
    udp_pkt_hdr                 pkt_hdr_reg;
    logic   [`IP_ADDR_W-1:0]    src_ip_next;
    logic   [`IP_ADDR_W-1:0]    dst_ip_next;
    udp_pkt_hdr                 pkt_hdr_next;
    
    logic   [CLIENT_ADDR_W-1:0] padded_addr_reg;
    logic   [CLIENT_ADDR_W-1:0] padded_addr_next;
    logic   [CLIENT_ADDR_W-1:0] padded_curr_addr;

    logic   [`MAC_PADBYTES_W:0] padbytes_calc;
    
    assign datap_ctrl_rd_meta = log_req_reg.req_addr[ADDR_W];
    assign log_rd_req_addr = log_req_reg.req_addr[ADDR_W-1:0];

    assign padded_curr_addr = {{(CLIENT_ADDR_W-ADDR_W-1){1'b0}}, 
                                    has_wrapped, curr_wr_addr};

    assign log_udp_tx_src_ip = dst_ip_reg;
    assign log_udp_tx_dst_ip = src_ip_reg;
    assign log_udp_tx_udp_hdr = resp_hdr_cast;

    assign log_udp_tx_data = log_resp_cast;

    assign padbytes_calc = `MAC_INTERFACE_BYTES - 
                            SIMPLE_LOG_RESP_STRUCT_BYTES[`MAC_PADBYTES_W-1:0];
    assign log_udp_tx_padbytes = SIMPLE_LOG_RESP_STRUCT_BYTES[`MAC_PADBYTES_W-1:0] == '0
                                ? '0
                                : padbytes_calc[`MAC_PADBYTES_W-1:0];

    always_ff @(posedge clk) begin
        if (rst) begin
            src_ip_reg <= '0;
            dst_ip_reg <= '0;
            pkt_hdr_reg <= '0;
            entry_reg <= '0;
            padded_addr_reg <= '0;
            log_req_reg <= '0;
        end
        else begin
            src_ip_reg <= src_ip_next;
            dst_ip_reg <= dst_ip_next;
            pkt_hdr_reg <= pkt_hdr_next;
            entry_reg <= entry_next;
            padded_addr_reg <= padded_addr_next;
            log_req_reg <= log_req_next;
        end
    end

    always_comb begin
        if (ctrl_datap_store_hdr) begin
            src_ip_next = udp_log_rx_src_ip;
            dst_ip_next = udp_log_rx_dst_ip;
            pkt_hdr_next = udp_log_rx_udp_hdr;
        end
        else begin
            src_ip_next = src_ip_reg;
            dst_ip_next = dst_ip_reg;
            pkt_hdr_next = pkt_hdr_reg;
        end
    end

    assign log_req_next = ctrl_datap_store_req
                        ? udp_log_rx_data[`MAC_INTERFACE_W-1 -: SIMPLE_LOG_REQ_STRUCT_W]
                        : log_req_reg;
    assign entry_next = ctrl_datap_store_log_resp
                        ? log_rd_resp_data
                        : entry_reg;

    assign padded_addr_next = ctrl_datap_store_log_resp
                            ? padded_curr_addr
                            : padded_addr_reg;

    always_comb begin
        log_resp_cast = '0;
        log_resp_cast.resp_addr = log_req_reg.req_addr;
        if (datap_ctrl_rd_meta) begin
            log_resp_cast.resp_payload[RESP_PAYLOAD_W-1 -: CLIENT_ADDR_W] = 
                padded_addr_reg;
        end
        else begin
            log_resp_cast.resp_payload[RESP_PAYLOAD_W-1 -: RESP_DATA_STRUCT_W] = 
                entry_reg;
        end
    end

    always_comb begin
        resp_hdr_cast = '0;
        resp_hdr_cast.src_port = pkt_hdr_reg.dst_port;
        resp_hdr_cast.dst_port = pkt_hdr_reg.src_port;
        resp_hdr_cast.length = SIMPLE_LOG_RESP_STRUCT_BYTES + UDP_HDR_BYTES;
    end

endmodule
