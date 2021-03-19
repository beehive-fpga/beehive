module packet_gen_wrap 
    import beehive_noc_msg::*;
    import packet_gen_pkg::*;
    import beehive_topology::*;
#(
     parameter NOC_DATA_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input  logic                       noc_pkt_gen_in_val
    ,input  logic   [NOC_DATA_W-1:0]    noc_pkt_gen_in_data
    ,output logic                       pkt_gen_in_noc_rdy

    ,output logic                       pkt_gen_out_noc_val
    ,output logic   [NOC_DATA_W-1:0]    pkt_gen_out_noc_data
    ,input  logic                       noc_pkt_gen_out_rdy
);

    localparam NOC_DATA_BYTES = NOC_DATA_W/8;
    localparam NOC_DATA_BYTES_W = $clog2(NOC_DATA_BYTES);
    localparam PACKET_NUM_W = 64;
    localparam PAYLOAD_REPS = NOC_DATA_W/PACKET_NUM_W;

    typedef enum logic[3:0] {
        READY = 4'd0,
        META_FLIT = 4'd1,
        STORE_SETUP = 4'd2,
        GEN_HDR_FLIT = 4'd3,
        GEN_META_FLIT = 4'd4,
        GEN_DATA = 4'd5,
        SEND_DONE_HDR = 4'd6,
        SEND_DONE_META = 4'd7,
        SEND_DONE_DATA = 4'd8,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    beehive_noc_hdr_flit    hdr_out_cast;
    udp_tx_metadata_flit    meta_out_cast;

    beehive_noc_hdr_flit    hdr_flit_reg;
    beehive_noc_hdr_flit    hdr_flit_next;
    logic                   store_hdr_flit;

    udp_rx_metadata_flit    meta_in_cast;
    udp_info                runner_info_reg;
    udp_info                runner_info_next;
    logic                   store_runner_info;

    setup_data_struct       setup_opts_reg;
    setup_data_struct       setup_opts_next;
    logic                   store_setup_opts;

    logic   [CYCLES_W-1:0]  cycle_count_reg;
    logic   [CYCLES_W-1:0]  cycle_count_next;
    logic                   reset_cycle_count;

    logic   [PACKET_NUM_W-1:0]  packet_count_reg;
    logic   [PACKET_NUM_W-1:0]  packet_count_next;
    logic                       incr_packet_count;

    logic   [PACKET_SIZE_W-1:0] payload_size;
    logic   [PACKET_SIZE_W-1:0] num_data_lines;
    
    logic   [PACKET_SIZE_W-1:0] data_lines_sent_reg;
    logic   [PACKET_SIZE_W-1:0] data_lines_sent_next;
    logic                       incr_data_lines;
    logic                       reset_data_lines;

    assign data_lines_sent_next = reset_data_lines
                                ? '0
                                : incr_data_lines
                                    ? data_lines_sent_reg + 1'b1
                                    : data_lines_sent_reg;

    logic[63:0] remainder;
    assign remainder = payload_size[NOC_DATA_BYTES_W-1:0];
    logic[63:0] width;
    assign width = NOC_DATA_BYTES_W;
    assign num_data_lines = payload_size[NOC_DATA_BYTES_W-1:0] == 0
                            ? payload_size >> NOC_DATA_BYTES_W
                            : (payload_size >> NOC_DATA_BYTES_W) + 1'b1;

    assign packet_count_next = store_hdr_flit
                            ? '0
                            : incr_packet_count
                                ? packet_count_reg + 1'b1
                                : packet_count_reg;

    assign payload_size = setup_opts_reg.packet_size;

    assign cycle_count_next = reset_cycle_count
                            ? '0
                            : cycle_count_reg + 1'b1;

    assign meta_in_cast = noc_pkt_gen_in_data;

    assign setup_opts_next = store_setup_opts
                             ? noc_pkt_gen_in_data[NOC_DATA_W-1 -: SETUP_DATA_STRUCT_W]
                            : setup_opts_reg;

    always_comb begin
        if (store_runner_info) begin
            runner_info_next.src_ip = meta_in_cast.src_ip;
            runner_info_next.dst_ip = meta_in_cast.dst_ip;
            runner_info_next.src_port = meta_in_cast.src_port;
            runner_info_next.dst_port = meta_in_cast.dst_port;
            runner_info_next.data_length = meta_in_cast.data_length;
        end
        else begin
            runner_info_next = runner_info_reg;
        end
    end


    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            hdr_flit_reg <= hdr_flit_next;
            runner_info_reg <= runner_info_next;
            setup_opts_reg <= setup_opts_next;
            cycle_count_reg <= cycle_count_next;
            data_lines_sent_reg <= data_lines_sent_next;
            packet_count_reg <= packet_count_next;
        end
    end

    always_comb begin
        store_hdr_flit = 1'b0;
        store_setup_opts = 1'b0;
        store_runner_info = 1'b0;
        reset_cycle_count = 1'b0;
        reset_data_lines = 1'b0;
        incr_packet_count = 1'b0;
        incr_data_lines = 1'b0;

        pkt_gen_in_noc_rdy = 1'b0;
        pkt_gen_out_noc_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                pkt_gen_in_noc_rdy = 1'b1;
                store_hdr_flit = 1'b1;
                if (noc_pkt_gen_in_val) begin
                    state_next = META_FLIT;
                end
            end
            META_FLIT: begin
                pkt_gen_in_noc_rdy = 1'b1;
                store_runner_info = 1'b1;
                if (noc_pkt_gen_in_val) begin
                    state_next = STORE_SETUP;
                end
            end
            STORE_SETUP: begin
                store_setup_opts = 1'b1;
                reset_cycle_count = 1'b1;
                pkt_gen_in_noc_rdy = 1'b1;

                if (noc_pkt_gen_in_val) begin
                    state_next = GEN_HDR_FLIT;
                end
            end
            GEN_HDR_FLIT: begin
                pkt_gen_out_noc_val = 1'b1;
                reset_data_lines = 1'b1;
                if (noc_pkt_gen_out_rdy) begin
                    state_next = GEN_META_FLIT;
                end
            end
            GEN_META_FLIT: begin
                pkt_gen_out_noc_val = 1'b1;
                if (noc_pkt_gen_out_rdy) begin
                    state_next = GEN_DATA;
                end
            end
            GEN_DATA: begin
                pkt_gen_out_noc_val = 1'b1;
                if (noc_pkt_gen_out_rdy) begin
                    incr_data_lines = 1'b1;
                    if (data_lines_sent_reg + 1'b1 == num_data_lines) begin
                        incr_packet_count = 1'b1;
                        // we're done, go back to the start
                        if (cycle_count_reg >= setup_opts_reg.runtime) begin
                            state_next = SEND_DONE_HDR;
                        end
                        else begin
                            state_next = GEN_HDR_FLIT;
                        end
                    end
                end
            end
            SEND_DONE_HDR: begin
                pkt_gen_out_noc_val = 1'b1;
                if (noc_pkt_gen_out_rdy) begin
                    state_next = SEND_DONE_META;
                end
            end
            SEND_DONE_META: begin
                pkt_gen_out_noc_val = 1'b1;
                if (noc_pkt_gen_out_rdy) begin
                    state_next = SEND_DONE_DATA;
                end
            end
            SEND_DONE_DATA: begin
                pkt_gen_out_noc_val = 1'b1;
                if (noc_pkt_gen_out_rdy) begin
                    state_next = READY;
                end
            end
            default: begin
                store_hdr_flit = 'X;
                store_setup_opts = 'X;
                reset_cycle_count = 'X;
                reset_data_lines = 'X;
                incr_packet_count = 'X;
                incr_data_lines = 'X;

                pkt_gen_in_noc_rdy = 'X;
                pkt_gen_out_noc_val = 'X;

                state_next = UND;
            end
        endcase
    end

    always_comb begin
        pkt_gen_out_noc_data = hdr_out_cast;
        case (state_reg) 
            GEN_HDR_FLIT: begin
                pkt_gen_out_noc_data = hdr_out_cast;
            end
            GEN_META_FLIT: begin
                pkt_gen_out_noc_data = meta_out_cast;
            end
            GEN_DATA: begin
                pkt_gen_out_noc_data = {(PAYLOAD_REPS){packet_count_reg}};
            end
            SEND_DONE_HDR: begin
                pkt_gen_out_noc_data = hdr_out_cast;
            end
            SEND_DONE_META: begin
                pkt_gen_out_noc_data = meta_out_cast;
            end
            SEND_DONE_DATA: begin
                pkt_gen_out_noc_data = {(PAYLOAD_REPS){64'd1}};
            end
            default: begin
                pkt_gen_out_noc_data = hdr_out_cast;
            end
        endcase
    end

    always_comb begin
        hdr_out_cast = '0;
        hdr_out_cast.core.dst_x_coord = UDP_TX_TILE_X;
        hdr_out_cast.core.dst_y_coord = UDP_TX_TILE_Y;
        hdr_out_cast.core.dst_fbits = PKT_IF_FBITS;

        hdr_out_cast.core.msg_type = UDP_TX_SEGMENT;
        // plus 1 for the metadata
        hdr_out_cast.core.src_x_coord = SRC_X;
        hdr_out_cast.core.src_y_coord = SRC_Y;
        hdr_out_cast.core.src_fbits = PKT_IF_FBITS;

        hdr_out_cast.core.metadata_flits = 1;

        if (state_reg == GEN_HDR_FLIT) begin
            hdr_out_cast.core.msg_len = num_data_lines + 1;
        end
        else begin
            hdr_out_cast.core.msg_len = 1 + 1;
        end
    end

    always_comb begin
        meta_out_cast = '0;
        if (state_reg == GEN_META_FLIT) begin
            meta_out_cast.src_ip = runner_info_reg.dst_ip;
            meta_out_cast.dst_ip = setup_opts_reg.dst_ip;
            // send the echo to a junk port
            meta_out_cast.src_port = APP_PORT + 10;
            meta_out_cast.dst_port = setup_opts_reg.dst_port;
            meta_out_cast.data_length = setup_opts_reg.packet_size;
        end
        else begin
            meta_out_cast.src_ip = runner_info_reg.dst_ip;
            meta_out_cast.dst_ip = runner_info_reg.src_ip;
            meta_out_cast.src_port = SETUP_PORT;
            meta_out_cast.dst_port = runner_info_reg.src_port;
            meta_out_cast.data_length = NOC_DATA_BYTES;
        end
    end
endmodule
