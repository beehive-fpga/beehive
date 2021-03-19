package beehive_echo_app_logger_msg;
    `include "noc_defs.vh"

    localparam ECHO_APP_READ_IF_FBITS_VALUE = 32'd3;

    localparam [`NOC_FBITS_WIDTH-1:0] ECHO_APP_READ_IF_FBITS = {1'b1, ECHO_APP_READ_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};


endpackage
