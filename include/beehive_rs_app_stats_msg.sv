package beehive_rs_app_stats_msg;
    `include "noc_defs.vh"
    localparam RS_APP_STATS_IF_FBITS_VALUE = 32'd1;

    localparam [`NOC_FBITS_WIDTH-1:0] RS_APP_STATS_IF_FBITS = {1'b1, RS_APP_STATS_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};
endpackage
