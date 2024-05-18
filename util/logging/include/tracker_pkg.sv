package tracker_pkg;
    import beehive_noc_msg::*;

    localparam TRACKER_ADDR_W = 10;

    typedef struct packed {
        packet_id_struct                packet_id;
        logic   [MSG_TIMESTAMP_W-1:0]   timestamp;
    } tracker_stats_struct;
    localparam TRACKER_STATS_W = $bits(tracker_stats_struct);
    localparam TRACKER_STATS_BYTES = TRACKER_STATS_W/8;

    typedef enum logic[1:0] {
        READ_REQ = 2'b0,
        READ_RESP = 2'b1,
        META_REQ = 2'd2,
        META_RESP = 2'd3
    } tracker_req_type;


    typedef struct packed {
        tracker_req_type                req_type;
        logic   [TRACKER_ADDR_W-1:0]    start_addr;
        logic   [TRACKER_ADDR_W-1:0]    end_addr;
    } tracker_flit;
    localparam TRACKER_FLIT_W = $bits(tracker_flit);

    typedef enum logic[1:0] {
        HDR_1 = 2'd0,
        HDR_2 = 2'd1,
        TRACKER = 2'd2,
        DATA = 2'd3
    } flit_sel_e;

endpackage
