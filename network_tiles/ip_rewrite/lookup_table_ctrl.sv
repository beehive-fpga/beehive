`include "ip_rewrite_noc_pipe_defs.svh"
module lookup_table_ctrl 
    import beehive_ip_rewrite_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter TABLE_ENTRIES = -1
)(
     input clk
    ,input rst

    ,input                                  noc_lookup_ctrl_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc_lookup_ctrl_in_data
    ,output logic                           lookup_ctrl_in_noc_rdy
    
    ,output logic                           lookup_ctrl_out_noc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   lookup_ctrl_out_noc_data    
    ,input  logic                           noc_lookup_ctrl_out_rdy

    ,output logic   [TABLE_ENTRIES-1:0]     lookup_wr_table_val
    ,output flow_lookup_tuple               lookup_wr_table_tuple
    ,output logic   [`IP_ADDR_W-1:0]        lookup_wr_table_addr
    ,output logic                           lookup_wr_table_set
);

    localparam TABLE_ENTRIES_W = $clog2(TABLE_ENTRIES);

    typedef enum logic[2:0] {
        READY = 3'd0,
        REQ_DATA = 3'd1,
        FIND_ENTRY = 3'd2,
        WR_TABLE = 3'd3,
        SEND_RESP = 3'd4,
        UND = 'X
    } state_e;

    state_e state_reg; 
    state_e state_next;
    
    beehive_noc_hdr_flit    hdr_cast;
    beehive_noc_hdr_flit    resp_cast;

    logic                   store_req;
    ip_rewrite_table_req    req_reg;
    ip_rewrite_table_req    req_next;

    logic   [`MSG_DST_X_WIDTH-1:0]      src_x_reg;
    logic   [`MSG_DST_Y_WIDTH-1:0]      src_y_reg;
    logic   [`MSG_DST_X_WIDTH-1:0]      src_x_next;
    logic   [`MSG_DST_Y_WIDTH-1:0]      src_y_next;
    logic   [`MSG_DST_FBITS_WIDTH-1:0]  src_fbits_reg;
    logic   [`MSG_DST_FBITS_WIDTH-1:0]  src_fbits_next;
    logic                               store_src;

    logic   [TABLE_ENTRIES-1:0]         free_reg;
    logic   [TABLE_ENTRIES-1:0]         match_reg;
    logic   [TABLE_ENTRIES-1:0]         free_next;
    logic   [TABLE_ENTRIES-1:0]         match_next;
    logic                               store_tuple_index_results;
    logic                               any_match;

    logic   [TABLE_ENTRIES-1:0]         tuple_index_wr_val;
    flow_lookup_tuple                   tuple_index_wr_tag;
    logic   [TABLE_ENTRIES-1:0]         tuple_index_empty_entries;
    logic   [TABLE_ENTRIES-1:0]         tuple_index_empty_one_hot;

    logic                               tuple_index_rd_val;
    flow_lookup_tuple                   tuple_index_rd_tag;
    logic   [TABLE_ENTRIES-1:0]         tuple_index_rd_match;

    assign lookup_wr_table_tuple.their_addr = req_reg.their_ip;
    assign lookup_wr_table_tuple.their_port = req_reg.their_port;
    assign lookup_wr_table_tuple.our_port = req_reg.our_port;

    assign tuple_index_rd_tag.their_addr = req_reg.their_ip;
    assign tuple_index_rd_tag.their_port = req_reg.their_port;
    assign tuple_index_rd_tag.our_port = req_reg.our_port;

    // setup the tag array to match the actual cam
    assign tuple_index_wr_val = lookup_wr_table_val;
    assign tuple_index_wr_tag = lookup_wr_table_tuple;

    assign lookup_wr_table_addr = req_reg.rewrite_addr;

    assign lookup_wr_table_set = 1'b1;

    assign hdr_cast = noc_lookup_ctrl_in_data;
    assign lookup_ctrl_out_noc_data = resp_cast;
    
    assign any_match = |match_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
            src_x_reg <= src_x_next;
            src_y_reg <= src_y_next;
            src_fbits_reg <= src_fbits_next;
            req_reg <= req_next;
            free_reg <= free_next;
            match_reg <= match_next;
        end
    end

    assign free_next = store_tuple_index_results
                    ? tuple_index_empty_one_hot
                    : free_reg;

    assign match_next = store_tuple_index_results
                    ? tuple_index_rd_match
                    : match_reg;

    assign src_x_next = store_src
                        ? hdr_cast.core.core.src_x_coord
                        : src_x_reg;
    assign src_y_next = store_src
                        ? hdr_cast.core.core.src_y_coord
                        : src_y_reg;
    assign src_fbits_next = store_src
                            ? hdr_cast.core.core.src_fbits
                            : src_fbits_reg;

    assign req_next = store_req
            ? noc_lookup_ctrl_in_data[`NOC_DATA_WIDTH-1 -: IP_REWRITE_TABLE_REQ_W]
            : req_reg;

    always_comb begin
        lookup_ctrl_in_noc_rdy = 1'b0;
        lookup_ctrl_out_noc_val = 1'b0;

        store_src = 1'b0;
        store_req = 1'b0;

        lookup_wr_table_val = 1'b0;

        tuple_index_rd_val = 1'b0;
        store_tuple_index_results = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                lookup_ctrl_in_noc_rdy = 1'b1;
                if (noc_lookup_ctrl_in_val) begin
                    store_src = 1'b1;
                    state_next = REQ_DATA;
                end
            end
            REQ_DATA: begin
                store_req = 1'b1;
                lookup_ctrl_in_noc_rdy = 1'b1;
                if (noc_lookup_ctrl_in_val) begin
                    state_next = FIND_ENTRY;
                end
            end
            FIND_ENTRY: begin
                tuple_index_rd_val = 1'b1;
                store_tuple_index_results = 1'b1;
                state_next = WR_TABLE;
            end
            WR_TABLE: begin
                if (any_match) begin
                    lookup_wr_table_val = match_reg;
                end
                else begin
                    lookup_wr_table_val = free_reg;
                end
                state_next = SEND_RESP;
            end
            SEND_RESP: begin
                lookup_ctrl_out_noc_val = 1'b1;
                if (noc_lookup_ctrl_out_rdy) begin
                    state_next = READY;
                end
            end
            default: begin
                lookup_ctrl_in_noc_rdy = 'X;
                lookup_ctrl_out_noc_val = 'X;

                store_src = 'X;
                store_req = 'X;

                lookup_wr_table_val = 'X;
        
                tuple_index_rd_val = 'X;
                store_tuple_index_results = 'X;

                state_next = state_reg;
            end
        endcase
    end

    always_comb begin
        resp_cast = '0;
        resp_cast.core.core.dst_x_coord = src_x_reg;
        resp_cast.core.core.dst_y_coord = src_y_reg;
        resp_cast.core.core.dst_fbits = src_fbits_reg;
        resp_cast.core.core.msg_len = '0;
        resp_cast.core.core.msg_type = IP_REWRITE_ADJUST_TABLE;
        resp_cast.core.core.src_x_coord = SRC_X[`MSG_SRC_X_WIDTH-1:0];
        resp_cast.core.core.src_y_coord = SRC_Y[`MSG_SRC_X_WIDTH-1:0];
        resp_cast.core.core.src_fbits = IP_REWRITE_TABLE_CTRL_FBITS;
    end

    bsg_cam_1r1w_tag_array #(
        .width_p    (FLOW_LOOKUP_TUPLE_W)
       ,.els_p      (TABLE_ENTRIES      )
    ) tuple_index_tags (
        .clk_i      (clk    )
       ,.reset_i    (rst    )
       
       ,.w_v_i              ()
       ,.w_set_not_clear_i  (1'b1)
       ,.w_tag_i            (tuple_index_wr_tag         )
       ,.w_empty_o          (tuple_index_empty_entries  )
       
       ,.r_v_i              (tuple_index_rd_val         )
       ,.r_tag_i            (tuple_index_rd_tag         )
       ,.r_match_o          (tuple_index_rd_match       )
    );

    bsg_priority_encode_one_hot_out #(
         .width_p   (TABLE_ENTRIES  )
        ,.lo_to_hi_p(1              )
    ) free_entry_find (
         .i     (tuple_index_empty_entries  )
        ,.o     (tuple_index_empty_one_hot  )
        ,.v_o   ()
    );

endmodule
