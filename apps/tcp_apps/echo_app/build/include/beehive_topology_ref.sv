package beehive_topology;
    `include "packet_defs.vh"
    `include "noc_defs.vh"
    localparam SERVER_IP = `IP_ADDR_W'hc6_13_64_0f;
    localparam APP_PORT = `PORT_NUM_W'd65432;

    localparam [`XY_WIDTH-1:0]  ETH_RX_X = 0;
    localparam [`XY_WIDTH-1:0]  ETH_RX_Y = 0;
    
    localparam [`XY_WIDTH-1:0]  ETH_TX_X = 0;
    localparam [`XY_WIDTH-1:0]  ETH_TX_Y = 1;

    localparam [`XY_WIDTH-1:0]  IP_RX_X = 1;
    localparam [`XY_WIDTH-1:0]  IP_RX_Y = 0;

    localparam [`XY_WIDTH-1:0]  IP_TX_X = 1;
    localparam [`XY_WIDTH-1:0]  IP_TX_Y = 1;

    localparam [`XY_WIDTH-1:0]  TCP_RX_X = 2;
    localparam [`XY_WIDTH-1:0]  TCP_RX_Y = 0;
    
    localparam [`XY_WIDTH-1:0]  TCP_TX_X = 2;
    localparam [`XY_WIDTH-1:0]  TCP_TX_Y = 1;

    localparam [`XY_WIDTH-1:0]  DRAM_RX_X = 3;
    localparam [`XY_WIDTH-1:0]  DRAM_RX_Y = 0;
    
    localparam [`XY_WIDTH-1:0]  DRAM_TX_X = 3;
    localparam [`XY_WIDTH-1:0]  DRAM_TX_Y = 1;
    
    localparam [`XY_WIDTH-1:0]  APP_RX_X = 4;
    localparam [`XY_WIDTH-1:0]  APP_RX_Y = 0;

    localparam [`XY_WIDTH-1:0]  APP_TX_X = 4;
    localparam [`XY_WIDTH-1:0]  APP_TX_Y = 1;
endpackage
