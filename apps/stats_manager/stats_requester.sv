// A wrapper to make requests of a stats recorder
// On a metadata request, will output just the metadata answer
// On a data request, will output just the payload, not including the confirmed metadata

module stats_requester 
import stats_manager_pkg::*;
import tracker_pkg::*;
#(
     parameter NOC_DATA_W = -1
    ,parameter NOC_DATA_BYTES = NOC_DATA_W/8
    ,parameter NOC_PADBYTES_W = $clog2(NOC_DATA_BYTES)
    ,parameter NOC1_DATA_W = -1
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input                              src_requester_hdr_val
    ,input  requester_input             src_requester_req
    ,output logic                       requester_src_hdr_rdy

    ,output logic                       requester_src_resp_val
    ,output logic   [NOC_DATA_W-1:0]    requester_src_resp_data
    ,output logic                       requester_src_resp_last
    ,input  logic                       src_requester_resp_rdy

    ,output logic                       requester_noc_val
    ,output logic   [NOC1_DATA_W-1:0]   requester_noc_data
    ,input  logic                       noc_requester_rdy

    ,input  logic                       noc_requester_val
    ,input  logic   [NOC1_DATA_W-1:0]   noc_requester_data
    ,output logic                       requester_noc_rdy
);

    localparam TRACKER_PADDING = NOC1_DATA_W - TRACKER_FLIT_W;

    typedef enum logic[3:0] {
        STORE_REQ = 4'd0,
        REQ_HDR_1 = 4'd1,
        REQ_HDR_2 = 4'd2,
        REQ_META = 4'd3,
        RESP_HDR_1 = 4'd4,
        RESP_HDR_2 = 4'd5,
        RESP_META = 4'd6,
        DATA_PASS = 4'd7,
        DRAIN = 4'd8,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    routing_hdr_flit    req_hdr_cast;
    misc_hdr_flit       misc_hdr_cast;
    tracker_flit        tracker_flit_req_cast; 
    
    routing_hdr_flit    resp_hdr_cast;

    requester_input req_reg;
    requester_input req_next;
    logic           store_dst;

    logic   [`MSG_LENGTH_WIDTH-1:0] num_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] num_flits_next;
    logic                           store_num_flits;

    logic   [`MSG_LENGTH_WIDTH-1:0] curr_flits_reg;
    logic   [`MSG_LENGTH_WIDTH-1:0] curr_flits_next;
    logic                           incr_curr_flits;

    logic                           ctrl_ntw_val;
    logic                           ctrl_ntw_last;
    logic                           ntw_ctrl_rdy;

    logic                           ntw_ctrl_val;
    logic   [NOC_DATA_W-1:0]        ntw_ctrl_data;
    logic                           ctrl_ntw_rdy;
    logic                           ntw_ctrl_last;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= STORE_REQ;
        end
        else begin
            state_reg <= state_next;
            req_reg <= req_next;
            num_flits_reg <= num_flits_next;
            curr_flits_reg <= curr_flits_next;
        end
    end

    assign resp_hdr_cast = noc_requester_data;
    
    assign req_next = store_dst
                    ? src_requester_req
                    : req_reg;

    assign num_flits_next = store_num_flits
                            ? resp_hdr_cast.msg_len
                            : num_flits_reg;
    
    assign curr_flits_next = store_num_flits
                            ? 1
                            : incr_curr_flits
                                ? curr_flits_reg + 1'b1
                                : curr_flits_reg;

    always_comb begin
        store_dst = 1'b0;
        store_num_flits = 1'b0;
        incr_curr_flits = 1'b0;
        requester_src_hdr_rdy = 1'b0;
        
        requester_noc_val = 1'b0;
        requester_src_resp_last = 1'b0;

        state_next = state_reg;
        case (state_reg)
            STORE_REQ: begin
                store_dst = 1'b1;
                requester_src_hdr_rdy = 1'b1;
                if (src_requester_hdr_val) begin
                    state_next = REQ_HDR_1;
                end
            end
            REQ_HDR_1: begin
                requester_noc_val = 1'b1;
                if (noc_requester_rdy) begin
                    state_next = REQ_HDR_2;
                end
            end
            REQ_HDR_2: begin
                requester_noc_val = 1'b1;
                if (noc_requester_rdy) begin
                    state_next = REQ_META;
                end
            end
            REQ_META: begin
                requester_noc_val = 1'b1;
                if (noc_requester_rdy) begin
                    state_next = RESP_HDR_1;
                end
            end
            RESP_HDR_1: begin
                store_num_flits = 1'b1;
                if (noc_requester_val & requester_noc_rdy) begin
                    state_next = RESP_HDR_2;
                end
            end
            RESP_HDR_2: begin
                if (noc_requester_val & requester_noc_rdy) begin
                    incr_curr_flits = 1'b1;
                    state_next = RESP_META;
                end
            end
            RESP_META: begin
                if (noc_requester_val & requester_noc_rdy) begin
                    incr_curr_flits = 1'b1;
                    if (req_reg.req_type == META_REQ) begin
                        state_next = STORE_REQ;
                    end
                    else begin
                        state_next = DATA_PASS;
                    end
                end
            end
            DATA_PASS: begin
                // are we done on the input
                if (noc_requester_val & requester_noc_rdy) begin
                    incr_curr_flits = 1'b1;
                    if (ctrl_ntw_last) begin
                        state_next = DRAIN;
                    end
                end
            end
            DRAIN: begin
                requester_src_resp_last = ntw_ctrl_last;
                if (ntw_ctrl_val & ctrl_ntw_rdy & ntw_ctrl_last) begin
                    state_next = STORE_REQ;
                end
            end
        endcase
    end

    assign ctrl_ntw_last = (curr_flits_reg) == num_flits_reg;

    always_comb begin
        requester_src_resp_val = 1'b0;
        requester_noc_rdy = 1'b0;
        ctrl_ntw_rdy = 1'b0;
        ctrl_ntw_val = 1'b0;
        
        requester_src_resp_data = ntw_ctrl_data;
        case (state_reg)
            RESP_HDR_1: begin
                requester_noc_rdy = 1'b1;
            end
            RESP_HDR_2: begin
                requester_noc_rdy = 1'b1;
            end
            RESP_META: begin
                requester_src_resp_data = {noc_requester_data, {(NOC_DATA_W-NOC1_DATA_W){1'b0}}}; 
                requester_src_resp_val = (req_reg.req_type == META_REQ) && noc_requester_val;
                requester_noc_rdy = src_requester_resp_rdy || (req_reg.req_type == READ_REQ);
            end
            DATA_PASS: begin 
                // inputs to the widener
                ctrl_ntw_val = noc_requester_val;
                requester_noc_rdy = ntw_ctrl_rdy;

                requester_src_resp_val = ntw_ctrl_val;
                ctrl_ntw_rdy = src_requester_resp_rdy;
                requester_src_resp_data = ntw_ctrl_data;
            end
            DRAIN: begin
                requester_src_resp_val = ntw_ctrl_val;
                ctrl_ntw_rdy = src_requester_resp_rdy;
                requester_src_resp_data = ntw_ctrl_data;
            end
        endcase
    end

    always_comb begin
        requester_noc_data = '0;
        case (state_reg)
            REQ_HDR_1: begin
                requester_noc_data = req_hdr_cast;
            end
            REQ_HDR_2: begin
                requester_noc_data = misc_hdr_cast;
            end
            REQ_META: begin
                requester_noc_data[NOC1_DATA_W-1 -: TRACKER_FLIT_W] = tracker_flit_req_cast;
            end
            default: begin
                requester_noc_data = '0;
            end
        endcase
    end

    always_comb begin
        req_hdr_cast = '0;
        req_hdr_cast.dst_x_coord = req_reg.dst_x;
        req_hdr_cast.dst_y_coord = req_reg.dst_y;
        req_hdr_cast.dst_fbits = req_reg.dst_fbits;
        req_hdr_cast.msg_type = TRACKER_MSG;
        req_hdr_cast.msg_len = 2;

        misc_hdr_cast = '0;
        misc_hdr_cast.src_x_coord = SRC_X;
        misc_hdr_cast.src_y_coord = SRC_Y;
        misc_hdr_cast.src_fbits = TRACKER_FBITS;
        misc_hdr_cast.metadata_flits = 1'b1;

        tracker_flit_req_cast = '0;
        tracker_flit_req_cast.req_type = req_reg.req_type;
        tracker_flit_req_cast.start_addr = req_reg.start_addr;
        tracker_flit_req_cast.end_addr = req_reg.end_addr;
    end 

    narrow_to_wide #(
         .IN_DATA_W     (NOC1_DATA_W    )
        ,.OUT_DATA_ELS  (NOC_DATA_W/NOC1_DATA_W)
    ) ntw (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_n_to_w_val    (ctrl_ntw_val       )
        ,.src_n_to_w_data   (noc_requester_data )
        ,.src_n_to_w_keep   ('1                 )
        ,.src_n_to_w_last   (ctrl_ntw_last      )
        ,.n_to_w_src_rdy    (ntw_ctrl_rdy       )
    
        ,.n_to_w_dst_val    (ntw_ctrl_val       )
        ,.n_to_w_dst_data   (ntw_ctrl_data      )
        ,.n_to_w_dst_keep   ()
        ,.n_to_w_dst_last   (ntw_ctrl_last      )
        ,.dst_n_to_w_rdy    (ctrl_ntw_rdy       )
    );
endmodule
