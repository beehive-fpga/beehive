package beehive_topology;
    `include "packet_defs.vh"
    `include "noc_defs.vh"
    
    localparam SERVER_IP = `IP_ADDR_W'hc6_13_64_12;
    localparam APP_PORT = `PORT_NUM_W'd65432;

    localparam [`XY_WIDTH-1:0]  ETH_RX_TILE_X = 0;
    localparam [`XY_WIDTH-1:0]  ETH_RX_TILE_Y = 0;

    localparam [`XY_WIDTH-1:0]  ETH_TX_TILE_X = 1;
    localparam [`XY_WIDTH-1:0]  ETH_TX_TILE_Y = 0;

    localparam [`XY_WIDTH-1:0]  IP_RX_TILE_X = 0;
    localparam [`XY_WIDTH-1:0]  IP_RX_TILE_Y = 1;

    localparam [`XY_WIDTH-1:0]  IP_TX_TILE_X = 1;
    localparam [`XY_WIDTH-1:0]  IP_TX_TILE_Y = 1;

    localparam [`XY_WIDTH-1:0]  TCP_RX_TILE_X = 0;
    localparam [`XY_WIDTH-1:0]  TCP_RX_TILE_Y = 2;

    localparam [`XY_WIDTH-1:0]  TCP_TX_TILE_X = 1;
    localparam [`XY_WIDTH-1:0]  TCP_TX_TILE_Y = 2;

    localparam [`XY_WIDTH-1:0]  DRAM_RX_TILE_X = 0;
    localparam [`XY_WIDTH-1:0]  DRAM_RX_TILE_Y = 3;

    localparam [`XY_WIDTH-1:0]  DRAM_TX_TILE_X = 1;
    localparam [`XY_WIDTH-1:0]  DRAM_TX_TILE_Y = 3;

    localparam [`XY_WIDTH-1:0]  APP_TILE_RX_X = 0;
    localparam [`XY_WIDTH-1:0]  APP_TILE_RX_Y = 4;

    localparam [`XY_WIDTH-1:0]  APP_TILE_TX_X = 1;
    localparam [`XY_WIDTH-1:0]  APP_TILE_TX_Y = 4;

endpackage
