`include "packet_defs.vh"
`include "state_defs.vh"
`include "noc_defs.vh"
`include "soc_defs.vh"
import beehive_topology::*;
module beehive_top #(
     parameter MEM_ADDR_W = 0
    ,parameter MEM_DATA_W = 0
    ,parameter MEM_WR_MASK_W = MEM_DATA_W/8
    ,parameter MEM_BURST_CNT_W = 0

)(
     input clk
    ,input rst
    
    ,input                                      mac_engine_rx_val
    ,input          [`MAC_INTERFACE_W-1:0]      mac_engine_rx_data
    ,input                                      mac_engine_rx_startframe
    ,input          [`MTU_SIZE_W-1:0]           mac_engine_rx_frame_size
    ,input                                      mac_engine_rx_endframe
    ,input          [`MAC_PADBYTES_W-1:0]       mac_engine_rx_padbytes
    ,output logic                               engine_mac_rx_rdy
    
    ,output logic                               engine_mac_tx_val
    ,input                                      mac_engine_tx_rdy
    ,output logic   [`MAC_INTERFACE_W-1:0]      engine_mac_tx_data
    ,output logic                               engine_mac_tx_last
    ,output logic   [`MAC_PADBYTES_W-1:0]       engine_mac_tx_padbytes
    
    ,input  logic                               memA_ready_in
    ,output logic                               memA_read_out
    ,output logic                               memA_write_out
    ,output logic   [MEM_ADDR_W-1:0]            memA_address_out
    ,input  logic   [MEM_DATA_W-1:0]            memA_readdata_in
    ,output logic   [MEM_DATA_W-1:0]            memA_writedata_out
    ,output logic   [MEM_BURST_CNT_W-1:0]       memA_burstcount_out
    ,output logic   [MEM_WR_MASK_W-1:0]         memA_byteenable_out
    ,input  logic                               memA_readdatavalid_in
    
    ,input  logic                               memB_ready_in
    ,output logic                               memB_read_out
    ,output logic                               memB_write_out
    ,output logic   [MEM_ADDR_W-1:0]            memB_address_out
    ,input  logic   [MEM_DATA_W-1:0]            memB_readdata_in
    ,output logic   [MEM_DATA_W-1:0]            memB_writedata_out
    ,output logic   [MEM_BURST_CNT_W-1:0]       memB_burstcount_out
    ,output logic   [MEM_WR_MASK_W-1:0]         memB_byteenable_out
    ,input  logic                               memB_readdatavalid_in
);

    assign memA_read_out = 1'b0;
    assign memA_write_out = 1'b0;

    assign memB_read_out = 1'b0;
    assign memB_write_out = 1'b0;
    logic                           tile_0_0_tile_0_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_0_0_tile_0_1_data;
    logic                           tile_0_1_tile_0_0_yummy;
    
    logic                           tile_0_1_tile_0_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_0_1_tile_0_0_data;
    logic                           tile_0_0_tile_0_1_yummy;
    
    logic                           tile_0_0_tile_1_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_0_0_tile_1_0_data;
    logic                           tile_1_0_tile_0_0_yummy;
    
    logic                           tile_1_0_tile_0_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_1_0_tile_0_0_data;
    logic                           tile_0_0_tile_1_0_yummy;
    
    logic                           tile_1_1_tile_1_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_1_1_tile_1_0_data;
    logic                           tile_1_0_tile_1_1_yummy;
    
    logic                           tile_1_0_tile_1_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_1_0_tile_1_1_data;
    logic                           tile_1_1_tile_1_0_yummy;
    
    logic                           tile_1_1_tile_0_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_1_1_tile_0_1_data;
    logic                           tile_0_1_tile_1_1_yummy;
    
    logic                           tile_0_1_tile_1_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_0_1_tile_1_1_data;
    logic                           tile_1_1_tile_0_1_yummy;
    
    logic                           tile_2_0_tile_1_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_2_0_tile_1_0_data;
    logic                           tile_1_0_tile_2_0_yummy;
    
    logic                           tile_1_0_tile_2_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_1_0_tile_2_0_data;
    logic                           tile_2_0_tile_1_0_yummy;
    
    logic                           tile_2_0_tile_2_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_2_0_tile_2_1_data;
    logic                           tile_2_1_tile_2_0_yummy;
    
    logic                           tile_2_1_tile_2_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_2_1_tile_2_0_data;
    logic                           tile_2_0_tile_2_1_yummy;
    
    logic                           tile_1_1_tile_2_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_1_1_tile_2_1_data;
    logic                           tile_2_1_tile_1_1_yummy;
    
    logic                           tile_2_1_tile_1_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_2_1_tile_1_1_data;
    logic                           tile_1_1_tile_2_1_yummy;

    logic                           tile_2_0_tile_3_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_2_0_tile_3_0_data;
    logic                           tile_3_0_tile_2_0_yummy;
    
    logic                           tile_3_0_tile_2_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_3_0_tile_2_0_data;
    logic                           tile_2_0_tile_3_0_yummy;
    
    logic                           tile_3_1_tile_3_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_3_1_tile_3_0_data;
    logic                           tile_3_0_tile_3_1_yummy;
    
    logic                           tile_3_0_tile_3_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_3_0_tile_3_1_data;
    logic                           tile_3_1_tile_3_0_yummy;
    
    logic                           tile_3_1_tile_2_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_3_1_tile_2_1_data;
    logic                           tile_2_1_tile_3_1_yummy;
    
    logic                           tile_2_1_tile_3_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   tile_2_1_tile_3_1_data;
    logic                           tile_3_1_tile_2_1_yummy;

    eth_rx_tile #(
         .SRC_X (ETH_RX_X)
        ,.SRC_Y (ETH_RX_Y)
    ) eth_rx_0_0 (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.mac_engine_rx_val         (mac_engine_rx_val          )
        ,.mac_engine_rx_data        (mac_engine_rx_data         )
        ,.mac_engine_rx_startframe  (mac_engine_rx_startframe   )
        ,.mac_engine_rx_frame_size  (mac_engine_rx_frame_size   )
        ,.mac_engine_rx_endframe    (mac_engine_rx_endframe     )
        ,.mac_engine_rx_padbytes    (mac_engine_rx_padbytes     )
        ,.engine_mac_rx_rdy         (engine_mac_rx_rdy          )
        
        ,.src_eth_rx_noc0_data_N    ('0)
        ,.src_eth_rx_noc0_data_E    (tile_1_0_tile_0_0_data     )
        ,.src_eth_rx_noc0_data_S    (tile_0_1_tile_0_0_data     )
        ,.src_eth_rx_noc0_data_W    ('0)

        ,.src_eth_rx_noc0_val_N     ('0)
        ,.src_eth_rx_noc0_val_E     (tile_1_0_tile_0_0_val      )
        ,.src_eth_rx_noc0_val_S     (tile_0_1_tile_0_0_val      )
        ,.src_eth_rx_noc0_val_W     ('0)

        ,.eth_rx_src_noc0_yummy_N   ()
        ,.eth_rx_src_noc0_yummy_E   (tile_0_0_tile_1_0_yummy    )
        ,.eth_rx_src_noc0_yummy_S   (tile_0_0_tile_0_1_yummy    )
        ,.eth_rx_src_noc0_yummy_W   ()

        ,.eth_rx_dst_noc0_data_N    ()
        ,.eth_rx_dst_noc0_data_E    (tile_0_0_tile_1_0_data     )
        ,.eth_rx_dst_noc0_data_S    (tile_0_0_tile_0_1_data     )
        ,.eth_rx_dst_noc0_data_W    ()

        ,.eth_rx_dst_noc0_val_N     ()
        ,.eth_rx_dst_noc0_val_E     (tile_0_0_tile_1_0_val      )
        ,.eth_rx_dst_noc0_val_S     (tile_0_0_tile_0_1_val      )
        ,.eth_rx_dst_noc0_val_W     ()

        ,.dst_eth_rx_noc0_yummy_N   ('0)
        ,.dst_eth_rx_noc0_yummy_E   (tile_1_0_tile_0_0_yummy    )
        ,.dst_eth_rx_noc0_yummy_S   (tile_0_1_tile_0_0_yummy    )
        ,.dst_eth_rx_noc0_yummy_W   ('0)
    );

    eth_tx_tile #(
         .SRC_X (ETH_TX_X)
        ,.SRC_Y (ETH_TX_Y)
    ) eth_tx_0_1 (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.engine_mac_tx_val         (engine_mac_tx_val          )
        ,.mac_engine_tx_rdy         (mac_engine_tx_rdy          )
        ,.engine_mac_tx_data        (engine_mac_tx_data         )
        ,.engine_mac_tx_last        (engine_mac_tx_last         )
        ,.engine_mac_tx_padbytes    (engine_mac_tx_padbytes     )
        
        ,.src_eth_tx_noc0_data_N    (tile_0_0_tile_0_1_data     )
        ,.src_eth_tx_noc0_data_E    (tile_1_1_tile_0_1_data     )
        ,.src_eth_tx_noc0_data_S    ('0)
        ,.src_eth_tx_noc0_data_W    ('0)

        ,.src_eth_tx_noc0_val_N     (tile_0_0_tile_0_1_val      )
        ,.src_eth_tx_noc0_val_E     (tile_1_1_tile_0_1_val      )
        ,.src_eth_tx_noc0_val_S     ('0)
        ,.src_eth_tx_noc0_val_W     ('0)

        ,.eth_tx_src_noc0_yummy_N   (tile_0_1_tile_0_0_yummy    )
        ,.eth_tx_src_noc0_yummy_E   (tile_0_1_tile_1_1_yummy    )
        ,.eth_tx_src_noc0_yummy_S   ()
        ,.eth_tx_src_noc0_yummy_W   ()

        ,.eth_tx_dst_noc0_data_N    (tile_0_1_tile_0_0_data     )
        ,.eth_tx_dst_noc0_data_E    (tile_0_1_tile_1_1_data     )
        ,.eth_tx_dst_noc0_data_S    ()
        ,.eth_tx_dst_noc0_data_W    ()

        ,.eth_tx_dst_noc0_val_N     (tile_0_1_tile_0_0_val      )
        ,.eth_tx_dst_noc0_val_E     (tile_0_1_tile_1_1_val      )
        ,.eth_tx_dst_noc0_val_S     ()
        ,.eth_tx_dst_noc0_val_W     ()

        ,.dst_eth_tx_noc0_yummy_N   (tile_0_0_tile_0_1_yummy    )
        ,.dst_eth_tx_noc0_yummy_E   (tile_1_1_tile_0_1_yummy    )
        ,.dst_eth_tx_noc0_yummy_S   ('0)
        ,.dst_eth_tx_noc0_yummy_W   ('0)
    );

    ip_rx_tile #(
         .SRC_X (IP_RX_X    )
        ,.SRC_Y (IP_RX_Y    )
    ) ip_rx_1_0 (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.src_ip_rx_noc0_data_N     ('0)
        ,.src_ip_rx_noc0_data_E     (tile_2_0_tile_1_0_data     )
        ,.src_ip_rx_noc0_data_S     (tile_1_1_tile_1_0_data     )
        ,.src_ip_rx_noc0_data_W     (tile_0_0_tile_1_0_data     )

        ,.src_ip_rx_noc0_val_N      ('0)
        ,.src_ip_rx_noc0_val_E      (tile_2_0_tile_1_0_val      )
        ,.src_ip_rx_noc0_val_S      (tile_1_1_tile_1_0_val      )
        ,.src_ip_rx_noc0_val_W      (tile_0_0_tile_1_0_val      )

        ,.ip_rx_src_noc0_yummy_N    ()
        ,.ip_rx_src_noc0_yummy_E    (tile_1_0_tile_2_0_yummy    )
        ,.ip_rx_src_noc0_yummy_S    (tile_1_0_tile_1_1_yummy    )
        ,.ip_rx_src_noc0_yummy_W    (tile_1_0_tile_0_0_yummy    )

        ,.ip_rx_dst_noc0_data_N     ()
        ,.ip_rx_dst_noc0_data_E     (tile_1_0_tile_2_0_data     )
        ,.ip_rx_dst_noc0_data_S     (tile_1_0_tile_1_1_data     )
        ,.ip_rx_dst_noc0_data_W     (tile_1_0_tile_0_0_data     )

        ,.ip_rx_dst_noc0_val_N      ()
        ,.ip_rx_dst_noc0_val_E      (tile_1_0_tile_2_0_val      )
        ,.ip_rx_dst_noc0_val_S      (tile_1_0_tile_1_1_val      )
        ,.ip_rx_dst_noc0_val_W      (tile_1_0_tile_0_0_val      )

        ,.dst_ip_rx_noc0_yummy_N    ('0)
        ,.dst_ip_rx_noc0_yummy_E    (tile_2_0_tile_1_0_yummy    )
        ,.dst_ip_rx_noc0_yummy_S    (tile_1_1_tile_0_1_yummy    )
        ,.dst_ip_rx_noc0_yummy_W    (tile_0_0_tile_1_0_yummy    )
    );

    ip_tx_tile #(
         .SRC_X (IP_TX_X    )
        ,.SRC_Y (IP_TX_Y    )
    ) ip_tx_1_1 (
         .clk   (clk)
        ,.rst   (rst)
        
        ,.src_ip_tx_noc0_data_N     (tile_1_0_tile_1_1_data     )
        ,.src_ip_tx_noc0_data_E     (tile_2_1_tile_1_1_data     )
        ,.src_ip_tx_noc0_data_S     ('0)
        ,.src_ip_tx_noc0_data_W     (tile_0_1_tile_1_1_data     )

        ,.src_ip_tx_noc0_val_N      (tile_1_0_tile_1_1_val      )
        ,.src_ip_tx_noc0_val_E      (tile_2_1_tile_1_1_val      )
        ,.src_ip_tx_noc0_val_S      ('0)
        ,.src_ip_tx_noc0_val_W      (tile_0_1_tile_1_1_val      )

        ,.ip_tx_src_noc0_yummy_N    (tile_1_1_tile_1_0_yummy    )
        ,.ip_tx_src_noc0_yummy_E    (tile_1_1_tile_2_1_yummy    )
        ,.ip_tx_src_noc0_yummy_S    ()
        ,.ip_tx_src_noc0_yummy_W    (tile_1_1_tile_0_1_yummy    )

        ,.ip_tx_dst_noc0_data_N     (tile_1_1_tile_1_0_data     )
        ,.ip_tx_dst_noc0_data_E     (tile_1_1_tile_2_1_data     )
        ,.ip_tx_dst_noc0_data_S     ()
        ,.ip_tx_dst_noc0_data_W     (tile_1_1_tile_0_1_data     )

        ,.ip_tx_dst_noc0_val_N      (tile_1_1_tile_1_0_val      )
        ,.ip_tx_dst_noc0_val_E      (tile_1_1_tile_2_1_val      )
        ,.ip_tx_dst_noc0_val_S      ()
        ,.ip_tx_dst_noc0_val_W      (tile_1_1_tile_0_1_val      )

        ,.dst_ip_tx_noc0_yummy_N    (tile_1_0_tile_1_1_yummy    )
        ,.dst_ip_tx_noc0_yummy_E    (tile_2_1_tile_1_1_yummy    )
        ,.dst_ip_tx_noc0_yummy_S    ('0)
        ,.dst_ip_tx_noc0_yummy_W    (tile_0_1_tile_1_1_yummy    )
    );

    udp_rx_tile #(
         .SRC_X (UDP_RX_X   )
        ,.SRC_Y (UDP_RX_Y   )
    ) udp_rx_2_0 (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_rx_noc0_data_N    ('0)
        ,.src_udp_rx_noc0_data_E    (tile_3_0_tile_2_0_data     )
        ,.src_udp_rx_noc0_data_S    (tile_2_1_tile_2_0_data     )
        ,.src_udp_rx_noc0_data_W    (tile_1_0_tile_2_0_data     )

        ,.src_udp_rx_noc0_val_N     ('0)
        ,.src_udp_rx_noc0_val_E     (tile_3_0_tile_2_0_val      )
        ,.src_udp_rx_noc0_val_S     (tile_2_1_tile_2_0_val      )
        ,.src_udp_rx_noc0_val_W     (tile_1_0_tile_2_0_val      )

        ,.udp_rx_src_noc0_yummy_N   ()
        ,.udp_rx_src_noc0_yummy_E   (tile_2_0_tile_3_0_yummy    )
        ,.udp_rx_src_noc0_yummy_S   (tile_2_0_tile_2_1_yummy    )
        ,.udp_rx_src_noc0_yummy_W   (tile_2_0_tile_1_0_yummy    )

        ,.udp_rx_dst_noc0_data_N    ()
        ,.udp_rx_dst_noc0_data_E    (tile_2_0_tile_3_0_data     )
        ,.udp_rx_dst_noc0_data_S    (tile_2_0_tile_2_1_data     )
        ,.udp_rx_dst_noc0_data_W    (tile_2_0_tile_1_0_data     )

        ,.udp_rx_dst_noc0_val_N     ()
        ,.udp_rx_dst_noc0_val_E     (tile_2_0_tile_3_0_val      )
        ,.udp_rx_dst_noc0_val_S     (tile_2_0_tile_2_1_val      )
        ,.udp_rx_dst_noc0_val_W     (tile_2_0_tile_1_0_val      )

        ,.dst_udp_rx_noc0_yummy_N   ('0)
        ,.dst_udp_rx_noc0_yummy_E   (tile_3_0_tile_2_0_yummy    )
        ,.dst_udp_rx_noc0_yummy_S   (tile_2_1_tile_2_0_yummy    )
        ,.dst_udp_rx_noc0_yummy_W   (tile_1_0_tile_2_0_yummy    )
    );

    udp_tx_tile #(
         .SRC_X (UDP_TX_X   )
        ,.SRC_Y (UDP_TX_Y   )
    ) udp_tx_2_1 (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_tx_noc0_data_N    (tile_2_0_tile_2_1_data     )
        ,.src_udp_tx_noc0_data_E    ('0)
        ,.src_udp_tx_noc0_data_S    ('0)
        ,.src_udp_tx_noc0_data_W    (tile_1_1_tile_2_1_data     )

        ,.src_udp_tx_noc0_val_N     (tile_2_0_tile_2_1_val      )
        ,.src_udp_tx_noc0_val_E     ('0)
        ,.src_udp_tx_noc0_val_S     ('0)
        ,.src_udp_tx_noc0_val_W     (tile_1_1_tile_2_1_val      )

        ,.udp_tx_src_noc0_yummy_N   (tile_2_1_tile_2_0_yummy    )
        ,.udp_tx_src_noc0_yummy_E   ()
        ,.udp_tx_src_noc0_yummy_S   ()
        ,.udp_tx_src_noc0_yummy_W   (tile_2_1_tile_1_1_yummy    )

        ,.udp_tx_dst_noc0_data_N    (tile_2_1_tile_2_0_data     )
        ,.udp_tx_dst_noc0_data_E    ()
        ,.udp_tx_dst_noc0_data_S    ()
        ,.udp_tx_dst_noc0_data_W    (tile_2_1_tile_1_1_data     )

        ,.udp_tx_dst_noc0_val_N     (tile_2_1_tile_2_0_val      )
        ,.udp_tx_dst_noc0_val_E     ()
        ,.udp_tx_dst_noc0_val_S     ()
        ,.udp_tx_dst_noc0_val_W     (tile_2_1_tile_1_1_val      )

        ,.dst_udp_tx_noc0_yummy_N   (tile_2_0_tile_2_1_yummy    )
        ,.dst_udp_tx_noc0_yummy_E   ('0)
        ,.dst_udp_tx_noc0_yummy_S   ('0)
        ,.dst_udp_tx_noc0_yummy_W   (tile_1_1_tile_2_1_yummy    )
    );

    udp_echo_app_tile #(
         .SRC_X (APP_X  )
        ,.SRC_Y (APP_Y  )
    ) app_tile_3_0 (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_app_noc0_data_N   ('0)
        ,.src_udp_app_noc0_data_E   ('0)
        ,.src_udp_app_noc0_data_S   (tile_3_1_tile_3_0_data     )
        ,.src_udp_app_noc0_data_W   (tile_2_0_tile_3_0_data     )

        ,.src_udp_app_noc0_val_N    ('0)
        ,.src_udp_app_noc0_val_E    ('0)
        ,.src_udp_app_noc0_val_S    (tile_3_1_tile_3_0_val      )
        ,.src_udp_app_noc0_val_W    (tile_2_0_tile_3_0_val      )

        ,.udp_app_src_noc0_yummy_N  ()
        ,.udp_app_src_noc0_yummy_E  ()
        ,.udp_app_src_noc0_yummy_S  (tile_3_0_tile_3_1_yummy    )
        ,.udp_app_src_noc0_yummy_W  (tile_3_0_tile_2_0_yummy    )

        ,.udp_app_dst_noc0_data_N   ()
        ,.udp_app_dst_noc0_data_E   ()
        ,.udp_app_dst_noc0_data_S   (tile_3_0_tile_3_1_data     )
        ,.udp_app_dst_noc0_data_W   (tile_3_0_tile_2_0_data     )

        ,.udp_app_dst_noc0_val_N    ()
        ,.udp_app_dst_noc0_val_E    ()
        ,.udp_app_dst_noc0_val_S    (tile_3_0_tile_3_1_val      )
        ,.udp_app_dst_noc0_val_W    (tile_3_0_tile_2_0_val      )

        ,.dst_udp_app_noc0_yummy_N  ('0)
        ,.dst_udp_app_noc0_yummy_E  ('0)
        ,.dst_udp_app_noc0_yummy_S  (tile_3_1_tile_3_0_yummy    )
        ,.dst_udp_app_noc0_yummy_W  (tile_2_0_tile_3_0_yummy    )
    );

    empty_tile #(
         .SRC_X (EMPTY_X    )
        ,.SRC_Y (EMPTY_Y    )
    ) empty_tile_3_1 (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_empty_noc0_data_N     (tile_3_0_tile_3_1_data     )
        ,.src_empty_noc0_data_E     ('0)
        ,.src_empty_noc0_data_S     ('0)
        ,.src_empty_noc0_data_W     (tile_2_1_tile_3_1_data     )

        ,.src_empty_noc0_val_N      (tile_3_0_tile_3_1_val      )
        ,.src_empty_noc0_val_E      ('0)
        ,.src_empty_noc0_val_S      ('0)
        ,.src_empty_noc0_val_W      (tile_2_1_tile_3_1_val      )

        ,.empty_src_noc0_yummy_N    (tile_3_1_tile_3_0_yummy    )
        ,.empty_src_noc0_yummy_E    ()
        ,.empty_src_noc0_yummy_S    ()
        ,.empty_src_noc0_yummy_W    (tile_3_1_tile_2_1_yummy    )
        
        ,.empty_dst_noc0_data_N     (tile_3_1_tile_3_0_data     )
        ,.empty_dst_noc0_data_E     ()
        ,.empty_dst_noc0_data_S     ()
        ,.empty_dst_noc0_data_W     (tile_3_1_tile_2_1_data     )

        ,.empty_dst_noc0_val_N      (tile_3_1_tile_3_0_val      )
        ,.empty_dst_noc0_val_E      ()
        ,.empty_dst_noc0_val_S      ()
        ,.empty_dst_noc0_val_W      (tile_3_1_tile_2_1_val      )

        ,.dst_empty_noc0_yummy_N    (tile_3_0_tile_3_1_yummy    )
        ,.dst_empty_noc0_yummy_E    ()
        ,.dst_empty_noc0_yummy_S    ()
        ,.dst_empty_noc0_yummy_W    (tile_2_1_tile_3_1_yummy    )
    );

    
//    tcp_tiles_wrap #(
//         .RX_SRC_X  (TCP_RX_X   )
//        ,.RX_SRC_Y  (TCP_RX_Y   )
//        ,.RX_DRAM_X (DRAM_RX_X  )
//        ,.RX_DRAM_Y (DRAM_RX_Y  )
//        ,.TX_SRC_X  (TCP_TX_X   )
//        ,.TX_SRC_Y  (TCP_TX_Y   )
//        ,.TX_DRAM_X (DRAM_TX_X  )
//        ,.TX_DRAM_Y (DRAM_TX_Y  )
//    ) tcp_tiles_rx_2_0_tx_2_1 (
//         .clk   (clk    )
//        ,.rst   (rst    )
//        
//        ,.src_tcp_rx_noc0_data_N    ('0)
//        ,.src_tcp_rx_noc0_data_E    ('0)
//        ,.src_tcp_rx_noc0_data_S    (tile_2_1_tile_2_0_data     )
//        ,.src_tcp_rx_noc0_data_W    (tile_1_0_tile_2_0_data     )
//
//        ,.src_tcp_rx_noc0_val_N     ('0)
//        ,.src_tcp_rx_noc0_val_E     ('0)
//        ,.src_tcp_rx_noc0_val_S     (tile_2_1_tile_2_0_val      )
//        ,.src_tcp_rx_noc0_val_W     (tile_1_0_tile_2_0_val      )
//
//        ,.tcp_rx_src_noc0_yummy_N   ()
//        ,.tcp_rx_src_noc0_yummy_E   ()
//        ,.tcp_rx_src_noc0_yummy_S   (tile_2_0_tile_2_1_yummy    )
//        ,.tcp_rx_src_noc0_yummy_W   (tile_2_0_tile_1_0_yummy    )
//
//        ,.tcp_rx_dst_noc0_data_N    ()
//        ,.tcp_rx_dst_noc0_data_E    ()
//        ,.tcp_rx_dst_noc0_data_S    (tile_2_0_tile_2_1_data     )
//        ,.tcp_rx_dst_noc0_data_W    (tile_2_0_tile_1_0_data     )
//
//        ,.tcp_rx_dst_noc0_val_N     ()
//        ,.tcp_rx_dst_noc0_val_E     ()
//        ,.tcp_rx_dst_noc0_val_S     (tile_2_0_tile_2_1_val      )
//        ,.tcp_rx_dst_noc0_val_W     (tile_2_0_tile_1_0_val      )
//
//        ,.dst_tcp_rx_noc0_yummy_N   ('0)
//        ,.dst_tcp_rx_noc0_yummy_E   ('0)
//        ,.dst_tcp_rx_noc0_yummy_S   (tile_2_1_tile_2_0_yummy    )
//        ,.dst_tcp_rx_noc0_yummy_W   (tile_1_0_tile_2_0_yummy    )
//        
//        ,.src_tcp_tx_noc0_data_N    (tile_2_0_tile_2_1_data     )
//        ,.src_tcp_tx_noc0_data_E    ('0)
//        ,.src_tcp_tx_noc0_data_S    ('0)
//        ,.src_tcp_tx_noc0_data_W    (tile_1_1_tile_2_1_data     )
//
//        ,.src_tcp_tx_noc0_val_N     (tile_2_0_tile_2_1_val      )
//        ,.src_tcp_tx_noc0_val_E     ('0)
//        ,.src_tcp_tx_noc0_val_S     ('0)
//        ,.src_tcp_tx_noc0_val_W     (tile_1_1_tile_2_1_val      )
//
//        ,.tcp_tx_src_noc0_yummy_N   (tile_2_1_tile_2_0_yummy    )
//        ,.tcp_tx_src_noc0_yummy_E   ()
//        ,.tcp_tx_src_noc0_yummy_S   ()
//        ,.tcp_tx_src_noc0_yummy_W   (tile_2_1_tile_1_1_yummy    )
//
//        ,.tcp_tx_dst_noc0_data_N    (tile_2_1_tile_2_0_data     )
//        ,.tcp_tx_dst_noc0_data_E    ()
//        ,.tcp_tx_dst_noc0_data_S    ()
//        ,.tcp_tx_dst_noc0_data_W    (tile_2_1_tile_1_1_data     )
//
//        ,.tcp_tx_dst_noc0_val_N     (tile_2_1_tile_2_0_val      )
//        ,.tcp_tx_dst_noc0_val_E     ()
//        ,.tcp_tx_dst_noc0_val_S     ()
//        ,.tcp_tx_dst_noc0_val_W     (tile_2_1_tile_1_1_val      )
//
//        ,.dst_tcp_tx_noc0_yummy_N   (tile_2_0_tile_2_1_yummy    )
//        ,.dst_tcp_tx_noc0_yummy_E   ('0)
//        ,.dst_tcp_tx_noc0_yummy_S   ('0)
//        ,.dst_tcp_tx_noc0_yummy_W   (tile_1_1_tile_2_1_yummy    )
//    );
endmodule
