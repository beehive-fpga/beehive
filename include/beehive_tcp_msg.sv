package beehive_tcp_msg;
    `include "packet_defs.vh"
    `include "noc_defs.vh"

    import beehive_noc_msg::*;
   
    // Look...Verilog number literals are hard okay? This is the only way we
    // can get the values so that we can size them some way and guarantee the 
    // actual fbits number has a 1 in the top bit. I mean I guess we could also
    // work out the actual number, but this is more in line with what we actually want.
    // Except for the part where this number constructing stuff is ugly. We don't want
    // that
    localparam TCP_RX_BUF_IF_FBITS_VALUE = 32'd1;
    localparam TCP_RX_APP_PTR_IF_FBITS_VALUE = 32'd2;
    localparam TCP_RX_APP_NOTIF_FBITS_VALUE = 32'd3;

    localparam TCP_TX_BUF_IF_FBITS_VALUE = 32'd1;
    localparam TCP_TX_APP_PTR_IF_FBITS_VALUE = 32'd2;

    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_RX_BUF_IF_FBITS = {1'b1, TCP_RX_BUF_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_RX_APP_PTR_IF_FBITS = {1'b1, TCP_RX_APP_PTR_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_RX_APP_NOTIF_FBITS = {1'b1, TCP_RX_APP_NOTIF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_TX_BUF_IF_FBITS = {1'b1, TCP_TX_BUF_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
    localparam [`NOC_FBITS_WIDTH-1:0]   TCP_TX_APP_PTR_IF_FBITS = {1'b1, TCP_TX_APP_PTR_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

    localparam MAX_PAYLOAD_PTR_W = 32;
    localparam MAX_NUM_BUFS = 8; // i think 8 buffers per flow is enough... who knows?. this is per flow.
    localparam MAX_PAYLOAD_IDX_W = $clog2(MAX_NUM_BUFS);
    localparam RX_PAYLOAD_IDX_W = MAX_PAYLOAD_IDX_W;

// TODO: what to do about these ptr type lengths being longer than the real ones used? do i need to declare 2 types now, one for the one in the pkt and one for the one here?
// TODO: convert sram write req stuff (e.g. store buf commit ptr rd req) all to idx instead. but what type/bit width?
    typedef struct packed {
        logic   [MAX_PAYLOAD_PTR_W-1:0] ptr;
        // these need to be one bit longer to save the wrap-around bit
        logic   [MAX_PAYLOAD_PTR_W:0] len;
        logic   [MAX_PAYLOAD_PTR_W:0] cap;
    } tcp_buf;
    localparam TCP_BUF_W = $bits(tcp_buf);

    typedef struct packed {
        logic   [MAX_PAYLOAD_IDX_W:0] idx;
    } tcp_buf_idx;

    typedef struct packed {
        tcp_buf buf_info;
        tcp_buf_idx idx;
    } tcp_buf_with_idx;
    localparam TCP_BUF_WITH_IDX_W = $bits(tcp_buf_with_idx);

    // typedef struct packed {
    //     logic [MAX_PAYLOAD_PTR_W:0] leftover_bytes_consumed; // assumed to be 0 at the moment (e.g. you use the entire buffer we give you)
    //     logic [MAX_PAYLOAD_IDX_W:0] bufs_consumed; // assumed to be 1 at the moment (e.g. you use the entire buffer we give you)
    //     tcp_buf_with_idx prev_buf;
    // } tcp_buf_update;
    // localparam TCP_BUF_UPDATE_W = $bits(tcp_buf_update);

// has to be sorted biggest to smallest to make padding calculation work
    typedef struct packed {
        // tcp_buf_update update_info;
        tcp_buf_with_idx old_buf;
    } tcp_adjust_idx;
    localparam TCP_ADJUST_IDX_W = $bits(tcp_adjust_idx);

    typedef struct packed {
        logic   [MAX_PAYLOAD_PTR_W:0]       __length; // unused at the moment, we just return 1 buf unilaterally (bc we can't return more than 1 yet.)
        logic   [TCP_ADJUST_IDX_W-MAX_PAYLOAD_PTR_W-2:0] padding;
    } tcp_msg_req;
    localparam TCP_MSG_REQ_W = $bits(tcp_msg_req);

    typedef struct packed {
        tcp_buf_with_idx resp_buf;
        // logic [TCP_ADJUST_IDX_W-TCP_BUF_WITH_IDX_W-1:0] padding;
    } tcp_msg_resp;
    localparam TCP_MSG_RESP_W = $bits(tcp_msg_resp);

    // problem: what does the mechanism to update a ptr look like? ideally it would be incr(amt), but that requires a rd req to first read it and then update.
    // maybe incr(amt, old_data)? then the tcp_slow module adds amt to old.ptr, if it's > len, it will know to incr idx. and for now assert that it should always be == len.
    // that's the most flexible interface bc if we just had idx_update_req then it wouldn't support compaction, if we just did ptr_update_to then it wouldn't really be what it's doing

    // TODO: update tcp.sv interface to have ptr reads and writes be the right way

    // this is a TCP specific NoC flit
    typedef union packed {
        tcp_msg_req tcp_msg_req;
        tcp_msg_resp tcp_msg_resp;
        tcp_adjust_idx tcp_adjust_idx;
    } msg_specific;

    typedef struct packed {
        logic   [MAX_FLOWID_W-1:0]          flowid;
        msg_specific msg_specific;
    } tcp_flit_inner;
    localparam TCP_FLIT_INNER_W = $bits(tcp_flit_inner);
    
    // TODO: check to make sure this doesn't go below 0
    localparam TCP_HDR_FLIT_PAD_W = `NOC_DATA_WIDTH - BASE_FLIT_W - TCP_FLIT_INNER_W;
    localparam TCP_EXTRA_W = TCP_FLIT_INNER_W;

    typedef struct packed {
        base_noc_hdr_flit                   core;
        tcp_flit_inner                      inner;
        logic   [TCP_HDR_FLIT_PAD_W-1:0]    padding;
    } tcp_noc_hdr_flit;

endpackage
