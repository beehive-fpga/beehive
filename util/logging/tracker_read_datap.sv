module tracker_read_datap 
    import tracker_pkg::*;
    import beehive_noc_msg::*;
    import beehive_ctrl_noc_msg::*;
#(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter ADDR_W = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter REQ_NOC_W = -1
    ,parameter RESP_NOC_W = -1
)(
     input clk
    ,input rst
     
    ,input          [REQ_NOC_W-1:0]             noc_reader_in_data
    
    ,output logic   [RESP_NOC_W-1:0]            reader_out_noc_data
    
    ,output logic   [ADDR_W-1:0]                log_rd_req_addr

    ,input  logic   [RESP_NOC_W-1:0]            width_fix_datap_data

    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped
    
    ,input  logic                               ctrl_datap_incr_rd_addr
    ,input  logic                               ctrl_datap_store_req
    ,input  logic                               ctrl_datap_store_flit_2
    ,input  flit_sel_e                          ctrl_datap_output_flit_sel

    ,output tracker_req_type                    datap_ctrl_req_type
    ,output logic                               datap_ctrl_last_entry
);

    localparam TRACKER_FLIT_PADDING = RESP_NOC_W - TRACKER_FLIT_W;
    localparam FLITS_PER_LINE = RESP_DATA_STRUCT_W % RESP_NOC_W == 0
                            ? RESP_DATA_STRUCT_W/RESP_NOC_W
                            : (RESP_DATA_STRUCT_W/RESP_NOC_W) + 1'b1;
    localparam FLITS_SHIFT = $clog2(FLITS_PER_LINE);

    logic   [ADDR_W-1:0]    curr_read_reg;
    logic   [ADDR_W-1:0]    curr_read_next;
    
    logic   [TRACKER_ADDR_W:0]  num_entries;

    tracker_flit            flit_req_reg;
    tracker_flit            flit_req_next;

    misc_hdr_flit           misc_flit_req_reg;
    misc_hdr_flit           misc_flit_req_next;

    tracker_flit            meta_resp_flit_cast;
    tracker_flit            read_resp_flit_cast;

    routing_hdr_flit        hdr_flit_1_cast;
    misc_hdr_flit           hdr_flit_2_cast;

    always_ff @(posedge clk) begin
        curr_read_reg <= curr_read_next;
        flit_req_reg <= flit_req_next;
        misc_flit_req_reg <= misc_flit_req_next;
    end

    assign log_rd_req_addr = curr_read_next;
    assign datap_ctrl_req_type = flit_req_reg.req_type;

    assign curr_read_next = ctrl_datap_store_req
                            ? flit_req_next.start_addr
                            : ctrl_datap_incr_rd_addr
                                ? curr_read_reg + 1'b1
                                : curr_read_reg;

    assign flit_req_next = ctrl_datap_store_req
                            ? noc_reader_in_data[REQ_NOC_W - 1 -: TRACKER_FLIT_W]
                            : flit_req_reg;

    assign misc_flit_req_next = ctrl_datap_store_flit_2
                                ? noc_reader_in_data
                                : misc_flit_req_reg;
    
    assign num_entries = {has_wrapped, read_resp_flit_cast.end_addr} - {1'b0, read_resp_flit_cast.start_addr};

    assign datap_ctrl_last_entry = curr_read_next == flit_req_reg.end_addr;

    always_comb begin
        if (ctrl_datap_output_flit_sel == HDR_1) begin
            reader_out_noc_data = hdr_flit_1_cast;
        end
        else if (ctrl_datap_output_flit_sel == HDR_2) begin
            reader_out_noc_data = hdr_flit_2_cast;
        end
        else if (ctrl_datap_output_flit_sel == TRACKER) begin
            if (datap_ctrl_req_type == READ_REQ) begin
                reader_out_noc_data = {read_resp_flit_cast, {TRACKER_FLIT_PADDING{1'b0}}};
            end
            else begin
                reader_out_noc_data = {meta_resp_flit_cast, {TRACKER_FLIT_PADDING{1'b0}}};
            end
        end
        else begin
            reader_out_noc_data = width_fix_datap_data;
        end
    end

    always_comb begin
        meta_resp_flit_cast = '0;
        meta_resp_flit_cast.req_type = META_RESP;
        meta_resp_flit_cast.start_addr = has_wrapped
                                    ? curr_wr_addr + 1'b1
                                    : '0;
        meta_resp_flit_cast.end_addr = curr_wr_addr;
    end

    always_comb begin
        read_resp_flit_cast = '0;
        read_resp_flit_cast.req_type = READ_RESP;
        read_resp_flit_cast.start_addr = flit_req_reg.start_addr;
        read_resp_flit_cast.end_addr = flit_req_reg.end_addr;
    end

    always_comb begin
        hdr_flit_1_cast = '0;
        hdr_flit_1_cast.dst_chip_id = misc_flit_req_reg.src_chip_id;
        hdr_flit_1_cast.dst_x_coord = misc_flit_req_reg.src_x_coord;
        hdr_flit_1_cast.dst_y_coord = misc_flit_req_reg.src_y_coord;
        hdr_flit_1_cast.dst_fbits = misc_flit_req_reg.src_fbits;
        // one for the second header flit, one for the req flit, the rest are data flits
        hdr_flit_1_cast.msg_len = datap_ctrl_req_type == READ_REQ
                                ? 2 + (num_entries << FLITS_SHIFT)
                                : 2;
        hdr_flit_1_cast.msg_type = TRACKER_MSG;
    end

    always_comb begin
        hdr_flit_2_cast = '0;
        hdr_flit_2_cast.src_x_coord = SRC_X;
        hdr_flit_2_cast.src_y_coord = SRC_Y;
        hdr_flit_2_cast.metadata_flits = 1;
    end



endmodule
