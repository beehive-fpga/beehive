// a parser for things using the IP flit format
module ip_lb_parse 
    import hash_pkg::*;
    import beehive_ip_msg::*;
(
     input clk
    ,input rst

    ,input  logic                           src_ip_lb_parse_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   src_ip_lb_parse_data
    ,output logic                           ip_lb_parse_src_rdy
    
    ,output logic                           ip_lb_parse_dst_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   ip_lb_parse_dst_data
    ,output logic                           ip_lb_parse_dst_last
    ,input                                  dst_ip_lb_parse_rdy

    ,output logic                           ip_lb_parse_dst_tuple_val
    ,output         hash_struct             ip_lb_parse_dst_tuple
    ,input  logic                           dst_ip_lb_parse_tuple_rdy
);

    typedef enum logic[1:0] {
        HDR_FLIT = 2'b0,
        META_FLIT = 2'b1,
        REM_FLIT = 2'd2,
        META_PASS_WAIT = 2'd3,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        WAIT = 2'b0,
        TUPLE_OUT = 2'd1,
        DATA_PASS_WAIT = 2'd2,
        UNDEF = 'X
    } tuple_state_e;

    state_e state_reg;
    state_e state_next;

    tuple_state_e tuple_state_reg;
    tuple_state_e tuple_state_next;

    beehive_noc_hdr_flit hdr_flit_cast;
    ip_rx_metadata_flit meta_flit_cast;

    hash_struct out_hash_reg;
    hash_struct out_hash_next;
    logic       store_ips;
    logic       store_ports;
    logic       tuple_out;

    logic   [`MSG_LENGTH_WIDTH-1:0] meta_flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] meta_flit_cnt_next;
    logic   [`MSG_LENGTH_WIDTH-1:0] meta_len_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] meta_len_next;
    logic                           set_meta_data;
    logic                           incr_meta_flit_cnt;
    
    logic   [`MSG_LENGTH_WIDTH-1:0] msg_flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] msg_flit_cnt_next;
    logic                           decr_msg_flit_cnt;
    
    logic   [`MSG_LENGTH_WIDTH-1:0] data_flit_cnt_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] data_flit_cnt_next;
    logic                           incr_data_flit_cnt;


    assign hdr_flit_cast = src_ip_lb_parse_data;
    assign meta_flit_cast = src_ip_lb_parse_data;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= HDR_FLIT;
            tuple_state_reg <= WAIT;
        end
        else begin
            state_reg <= state_next;
            tuple_state_reg <= tuple_state_next;

            out_hash_reg <= out_hash_next;
            meta_len_reg <= meta_len_next;
            meta_flit_cnt_reg <= meta_flit_cnt_next;
            msg_flit_cnt_reg <= msg_flit_cnt_next;
            data_flit_cnt_reg <= data_flit_cnt_next;
        end
    end

    assign ip_lb_parse_dst_tuple = out_hash_reg;

    assign meta_len_next = set_meta_data
                        ? hdr_flit_cast.core.metadata_flits
                        : meta_len_reg;

    assign meta_flit_cnt_next = set_meta_data
                                ? '0
                                : incr_meta_flit_cnt
                                    ? meta_flit_cnt_reg + 1'b1
                                    : meta_flit_cnt_reg;

    assign msg_flit_cnt_next = set_meta_data
                            ? hdr_flit_cast.core.msg_len
                            : decr_msg_flit_cnt
                                ? msg_flit_cnt_reg - 1'b1
                                : msg_flit_cnt_reg;

    assign data_flit_cnt_next = set_meta_data
                            ? '0
                            : incr_data_flit_cnt
                                ? data_flit_cnt_reg + 1'b1
                                : data_flit_cnt_reg;

    always_comb begin
        out_hash_next = out_hash_reg;
        if (store_ips) begin
            out_hash_next.src_ip = meta_flit_cast.src_ip;
            out_hash_next.dst_ip = meta_flit_cast.dst_ip;
        end
        if (store_ports) begin
            out_hash_next.src_port = src_ip_lb_parse_data[`NOC_DATA_WIDTH-1 -: `PORT_NUM_W];
            out_hash_next.dst_port = src_ip_lb_parse_data[`NOC_DATA_WIDTH-`PORT_NUM_W-1 -: `PORT_NUM_W];
        end
    end

    assign ip_lb_parse_dst_data = src_ip_lb_parse_data;


    always_comb begin
        ip_lb_parse_dst_val = 1'b0;
        ip_lb_parse_dst_last = 1'b0;
        ip_lb_parse_src_rdy = 1'b0;

        set_meta_data = 1'b0;
        incr_meta_flit_cnt = 1'b0;
        incr_data_flit_cnt = 1'b0;
        decr_msg_flit_cnt = 1'b0;

        store_ports = 1'b0;
        store_ips = 1'b0;
        tuple_out = 1'b0;

        state_next = state_reg;
        case (state_reg)
            HDR_FLIT: begin
                ip_lb_parse_dst_val = src_ip_lb_parse_val;
                ip_lb_parse_src_rdy = dst_ip_lb_parse_rdy;
                set_meta_data = 1'b1;
                if (src_ip_lb_parse_val & dst_ip_lb_parse_rdy) begin
                    state_next = META_FLIT;
                end
            end
            META_FLIT: begin
                ip_lb_parse_dst_val = src_ip_lb_parse_val;
                ip_lb_parse_src_rdy = dst_ip_lb_parse_rdy;
                ip_lb_parse_dst_last = msg_flit_cnt_reg == 1;

                store_ips = meta_flit_cnt_reg == '0;
                if (src_ip_lb_parse_val & dst_ip_lb_parse_rdy) begin
                    incr_meta_flit_cnt = 1'b1;
                    decr_msg_flit_cnt = 1'b1;
                    if (meta_flit_cnt_reg == (meta_len_reg - 1'b1)) begin
                        if (ip_lb_parse_dst_last) begin
                            state_next = HDR_FLIT;
                        end
                        else begin
                            state_next = REM_FLIT;
                        end
                    end
                end
            end
            REM_FLIT: begin
                ip_lb_parse_dst_val = src_ip_lb_parse_val;
                ip_lb_parse_src_rdy = dst_ip_lb_parse_rdy;
                store_ports = data_flit_cnt_reg == '0;
                ip_lb_parse_dst_last = msg_flit_cnt_reg == 1;

                if (src_ip_lb_parse_val & dst_ip_lb_parse_rdy) begin
                    incr_data_flit_cnt = 1'b1;
                    decr_msg_flit_cnt = 1'b1;
                    tuple_out = data_flit_cnt_reg == '0;                    
                    if (ip_lb_parse_dst_last) begin
                        if (tuple_state_reg == DATA_PASS_WAIT) begin
                            state_next = HDR_FLIT;
                        end
                        else begin
                            state_next = META_PASS_WAIT;
                        end
                    end
                end
            end
            META_PASS_WAIT: begin
                if (tuple_state_reg == DATA_PASS_WAIT) begin
                    state_next = HDR_FLIT;
                end
            end
            default: begin
                ip_lb_parse_dst_val = 'X;
                ip_lb_parse_src_rdy = 'X;

                set_meta_data = 'X;
                incr_meta_flit_cnt = 'X;
                incr_data_flit_cnt = 'X;
                decr_msg_flit_cnt = 'X;

                store_ports = 'X;
                store_ips = 'X;

                state_next = UND;
            end
        endcase
    end

    always_comb begin
        ip_lb_parse_dst_tuple_val = 1'b0;

        tuple_state_next = tuple_state_reg;
        case (tuple_state_reg)
            WAIT: begin
                if (tuple_out) begin
                    tuple_state_next = TUPLE_OUT;
                end
            end
            TUPLE_OUT: begin
                ip_lb_parse_dst_tuple_val = 1'b1;
                if (dst_ip_lb_parse_tuple_rdy) begin
                    tuple_state_next = DATA_PASS_WAIT;
                end
            end
            DATA_PASS_WAIT: begin
                if (state_next == HDR_FLIT) begin
                    tuple_state_next = WAIT;
                end
            end
        endcase
    end
endmodule
