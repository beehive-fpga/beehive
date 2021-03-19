package beehive_tcp_logger_msg;
    `include "noc_defs.vh"

    localparam TCP_LOGGER_READ_IF_FBITS_VALUE = 32'd1;

    localparam  [`NOC_FBITS_WIDTH-1:0]  TCP_LOGGER_READ_IF_FBITS = {1'b1, TCP_LOGGER_READ_IF_FBITS_VALUE[`NOC_FBITS_WIDTH-2:0]};

endpackage
