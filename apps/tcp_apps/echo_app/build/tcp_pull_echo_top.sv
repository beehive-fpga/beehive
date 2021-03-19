`include "packet_defs.vh"
`include "state_defs.vh"
`include "noc_defs.vh"
`include "soc_defs.vh"
import beehive_topology::*;
module tcp_pull_echo_top #(
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
	,output logic                               engine_mac_tx_startframe
	,output logic   [`MTU_SIZE_W-1:0]           engine_mac_tx_frame_size
	,output logic                               engine_mac_tx_endframe 
	,output logic   [`MAC_INTERFACE_W-1:0]      engine_mac_tx_data     
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


// main tile connection wires

    logic                           endpoint_0_0_endpoint_1_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_0_endpoint_1_0_data;
    logic                           endpoint_1_0_endpoint_0_0_yummy;
    
    logic                           endpoint_0_0_endpoint_0_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_0_endpoint_0_1_data;
    logic                           endpoint_0_1_endpoint_0_0_yummy;
    

    logic                           endpoint_1_0_endpoint_1_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_0_endpoint_1_1_data;
    logic                           endpoint_1_1_endpoint_1_0_yummy;
    
    logic                           endpoint_1_0_endpoint_0_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_0_endpoint_0_0_data;
    logic                           endpoint_0_0_endpoint_1_0_yummy;
    

    logic                           endpoint_0_1_endpoint_0_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_1_endpoint_0_0_data;
    logic                           endpoint_0_0_endpoint_0_1_yummy;
    
    logic                           endpoint_0_1_endpoint_1_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_1_endpoint_1_1_data;
    logic                           endpoint_1_1_endpoint_0_1_yummy;
    
    logic                           endpoint_0_1_endpoint_0_2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_1_endpoint_0_2_data;
    logic                           endpoint_0_2_endpoint_0_1_yummy;
    

    logic                           endpoint_1_1_endpoint_1_0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_1_endpoint_1_0_data;
    logic                           endpoint_1_0_endpoint_1_1_yummy;
    
    logic                           endpoint_1_1_endpoint_1_2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_1_endpoint_1_2_data;
    logic                           endpoint_1_2_endpoint_1_1_yummy;
    
    logic                           endpoint_1_1_endpoint_0_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_1_endpoint_0_1_data;
    logic                           endpoint_0_1_endpoint_1_1_yummy;
    

    logic                           endpoint_0_2_endpoint_0_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_2_endpoint_0_1_data;
    logic                           endpoint_0_1_endpoint_0_2_yummy;
    
    logic                           endpoint_0_2_endpoint_1_2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_2_endpoint_1_2_data;
    logic                           endpoint_1_2_endpoint_0_2_yummy;
    
    logic                           endpoint_0_2_endpoint_0_3_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_2_endpoint_0_3_data;
    logic                           endpoint_0_3_endpoint_0_2_yummy;
    

    logic                           endpoint_1_2_endpoint_1_1_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_2_endpoint_1_1_data;
    logic                           endpoint_1_1_endpoint_1_2_yummy;
    
    logic                           endpoint_1_2_endpoint_1_3_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_2_endpoint_1_3_data;
    logic                           endpoint_1_3_endpoint_1_2_yummy;
    
    logic                           endpoint_1_2_endpoint_0_2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_2_endpoint_0_2_data;
    logic                           endpoint_0_2_endpoint_1_2_yummy;
    

    logic                           endpoint_0_3_endpoint_0_2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_3_endpoint_0_2_data;
    logic                           endpoint_0_2_endpoint_0_3_yummy;
    
    logic                           endpoint_0_3_endpoint_1_3_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_3_endpoint_1_3_data;
    logic                           endpoint_1_3_endpoint_0_3_yummy;
    
    logic                           endpoint_0_3_endpoint_0_4_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_3_endpoint_0_4_data;
    logic                           endpoint_0_4_endpoint_0_3_yummy;
    

    logic                           endpoint_1_3_endpoint_1_2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_3_endpoint_1_2_data;
    logic                           endpoint_1_2_endpoint_1_3_yummy;
    
    logic                           endpoint_1_3_endpoint_1_4_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_3_endpoint_1_4_data;
    logic                           endpoint_1_4_endpoint_1_3_yummy;
    
    logic                           endpoint_1_3_endpoint_0_3_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_3_endpoint_0_3_data;
    logic                           endpoint_0_3_endpoint_1_3_yummy;
    

    logic                           endpoint_0_4_endpoint_0_3_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_4_endpoint_0_3_data;
    logic                           endpoint_0_3_endpoint_0_4_yummy;
    
    logic                           endpoint_0_4_endpoint_1_4_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_0_4_endpoint_1_4_data;
    logic                           endpoint_1_4_endpoint_0_4_yummy;
    

    logic                           endpoint_1_4_endpoint_1_3_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_4_endpoint_1_3_data;
    logic                           endpoint_1_3_endpoint_1_4_yummy;
    
    logic                           endpoint_1_4_endpoint_0_4_val;
    logic   [`NOC_DATA_WIDTH-1:0]   endpoint_1_4_endpoint_0_4_data;
    logic                           endpoint_0_4_endpoint_1_4_yummy;
    

    eth_rx_tile #(
         .SRC_X (ETH_RX_TILE_X  )
        ,.SRC_Y (ETH_RX_TILE_Y  )
    ) eth_rx_0_0 (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_eth_rx_noc0_data_N    ('0  )
        ,.src_eth_rx_noc0_data_E    (endpoint_1_0_endpoint_0_0_data  )
        ,.src_eth_rx_noc0_data_S    (endpoint_0_1_endpoint_0_0_data  )
        ,.src_eth_rx_noc0_data_W    ('0  )

        ,.src_eth_rx_noc0_val_N     ('0   )
        ,.src_eth_rx_noc0_val_E     (endpoint_1_0_endpoint_0_0_val   )
        ,.src_eth_rx_noc0_val_S     (endpoint_0_1_endpoint_0_0_val   )
        ,.src_eth_rx_noc0_val_W     ('0   )

        ,.eth_rx_src_noc0_yummy_N   ( )
        ,.eth_rx_src_noc0_yummy_E   (endpoint_0_0_endpoint_1_0_yummy )
        ,.eth_rx_src_noc0_yummy_S   (endpoint_0_0_endpoint_0_1_yummy )
        ,.eth_rx_src_noc0_yummy_W   ( )

        ,.eth_rx_dst_noc0_data_N    (  )
        ,.eth_rx_dst_noc0_data_E    (endpoint_0_0_endpoint_1_0_data  )
        ,.eth_rx_dst_noc0_data_S    (endpoint_0_0_endpoint_0_1_data  )
        ,.eth_rx_dst_noc0_data_W    (  )

        ,.eth_rx_dst_noc0_val_N     (   )
        ,.eth_rx_dst_noc0_val_E     (endpoint_0_0_endpoint_1_0_val   )
        ,.eth_rx_dst_noc0_val_S     (endpoint_0_0_endpoint_0_1_val   )
        ,.eth_rx_dst_noc0_val_W     (   )

        ,.dst_eth_rx_noc0_yummy_N   ('0 )
        ,.dst_eth_rx_noc0_yummy_E   (endpoint_1_0_endpoint_0_0_yummy )
        ,.dst_eth_rx_noc0_yummy_S   (endpoint_0_1_endpoint_0_0_yummy )
        ,.dst_eth_rx_noc0_yummy_W   ('0 )

		,.mac_engine_rx_val         (mac_engine_rx_val          )
		,.mac_engine_rx_data        (mac_engine_rx_data         )
		,.mac_engine_rx_startframe  (mac_engine_rx_startframe   )
		,.mac_engine_rx_frame_size  (mac_engine_rx_frame_size   )
		,.mac_engine_rx_endframe    (mac_engine_rx_endframe     )
		,.mac_engine_rx_padbytes    (mac_engine_rx_padbytes     )
		,.engine_mac_rx_rdy         (engine_mac_rx_rdy          )
    );

	eth_tx_tile #(
	     .SRC_X (ETH_TX_TILE_X  )
	    ,.SRC_Y (ETH_TX_TILE_Y  )
	) eth_tx_1_0 (
		 .clk   (clk)
		,.rst   (rst)

        ,.src_eth_tx_noc0_data_N    ('0  )
        ,.src_eth_tx_noc0_data_E    ('0  )
        ,.src_eth_tx_noc0_data_S    (endpoint_1_1_endpoint_1_0_data  )
        ,.src_eth_tx_noc0_data_W    (endpoint_0_0_endpoint_1_0_data  )

        ,.src_eth_tx_noc0_val_N     ('0   )
        ,.src_eth_tx_noc0_val_E     ('0   )
        ,.src_eth_tx_noc0_val_S     (endpoint_1_1_endpoint_1_0_val   )
        ,.src_eth_tx_noc0_val_W     (endpoint_0_0_endpoint_1_0_val   )

        ,.eth_tx_src_noc0_yummy_N   ( )
        ,.eth_tx_src_noc0_yummy_E   ( )
        ,.eth_tx_src_noc0_yummy_S   (endpoint_1_0_endpoint_1_1_yummy )
        ,.eth_tx_src_noc0_yummy_W   (endpoint_1_0_endpoint_0_0_yummy )

        ,.eth_tx_dst_noc0_data_N    (  )
        ,.eth_tx_dst_noc0_data_E    (  )
        ,.eth_tx_dst_noc0_data_S    (endpoint_1_0_endpoint_1_1_data  )
        ,.eth_tx_dst_noc0_data_W    (endpoint_1_0_endpoint_0_0_data  )

        ,.eth_tx_dst_noc0_val_N     (   )
        ,.eth_tx_dst_noc0_val_E     (   )
        ,.eth_tx_dst_noc0_val_S     (endpoint_1_0_endpoint_1_1_val   )
        ,.eth_tx_dst_noc0_val_W     (endpoint_1_0_endpoint_0_0_val   )

        ,.dst_eth_tx_noc0_yummy_N   ('0 )
        ,.dst_eth_tx_noc0_yummy_E   ('0 )
        ,.dst_eth_tx_noc0_yummy_S   (endpoint_1_1_endpoint_1_0_yummy )
        ,.dst_eth_tx_noc0_yummy_W   (endpoint_0_0_endpoint_1_0_yummy )

		,.engine_mac_tx_val         (engine_mac_tx_val          )
		,.mac_engine_tx_rdy         (mac_engine_tx_rdy          )
		,.engine_mac_tx_startframe  (engine_mac_tx_startframe   )
		,.engine_mac_tx_frame_size  (engine_mac_tx_frame_size   )
		,.engine_mac_tx_endframe    (engine_mac_tx_endframe     )
		,.engine_mac_tx_data        (engine_mac_tx_data         )
		,.engine_mac_tx_padbytes    (engine_mac_tx_padbytes     )
	);

    ip_rx_tile #(
	     .SRC_X (IP_RX_TILE_X   )
	    ,.SRC_Y (IP_RX_TILE_Y   )
	) ip_rx_0_1 (
		 .clk   (clk)
		,.rst   (rst)

        ,.src_ip_rx_noc0_data_N    (endpoint_0_0_endpoint_0_1_data  )
        ,.src_ip_rx_noc0_data_E    (endpoint_1_1_endpoint_0_1_data  )
        ,.src_ip_rx_noc0_data_S    (endpoint_0_2_endpoint_0_1_data  )
        ,.src_ip_rx_noc0_data_W    ('0  )

        ,.src_ip_rx_noc0_val_N     (endpoint_0_0_endpoint_0_1_val   )
        ,.src_ip_rx_noc0_val_E     (endpoint_1_1_endpoint_0_1_val   )
        ,.src_ip_rx_noc0_val_S     (endpoint_0_2_endpoint_0_1_val   )
        ,.src_ip_rx_noc0_val_W     ('0   )

        ,.ip_rx_src_noc0_yummy_N   (endpoint_0_1_endpoint_0_0_yummy )
        ,.ip_rx_src_noc0_yummy_E   (endpoint_0_1_endpoint_1_1_yummy )
        ,.ip_rx_src_noc0_yummy_S   (endpoint_0_1_endpoint_0_2_yummy )
        ,.ip_rx_src_noc0_yummy_W   ( )

        ,.ip_rx_dst_noc0_data_N    (endpoint_0_1_endpoint_0_0_data  )
        ,.ip_rx_dst_noc0_data_E    (endpoint_0_1_endpoint_1_1_data  )
        ,.ip_rx_dst_noc0_data_S    (endpoint_0_1_endpoint_0_2_data  )
        ,.ip_rx_dst_noc0_data_W    (  )

        ,.ip_rx_dst_noc0_val_N     (endpoint_0_1_endpoint_0_0_val   )
        ,.ip_rx_dst_noc0_val_E     (endpoint_0_1_endpoint_1_1_val   )
        ,.ip_rx_dst_noc0_val_S     (endpoint_0_1_endpoint_0_2_val   )
        ,.ip_rx_dst_noc0_val_W     (   )

        ,.dst_ip_rx_noc0_yummy_N   (endpoint_0_0_endpoint_0_1_yummy )
        ,.dst_ip_rx_noc0_yummy_E   (endpoint_1_1_endpoint_0_1_yummy )
        ,.dst_ip_rx_noc0_yummy_S   (endpoint_0_2_endpoint_0_1_yummy )
        ,.dst_ip_rx_noc0_yummy_W   ('0 )

	);

    ip_tx_tile #(
	     .SRC_X (IP_TX_TILE_X   )
	    ,.SRC_Y (IP_TX_TILE_Y   )
	) ip_tx_1_1 (
		 .clk   (clk)
		,.rst   (rst)

        ,.src_ip_tx_noc0_data_N    (endpoint_1_0_endpoint_1_1_data  )
        ,.src_ip_tx_noc0_data_E    ('0  )
        ,.src_ip_tx_noc0_data_S    (endpoint_1_2_endpoint_1_1_data  )
        ,.src_ip_tx_noc0_data_W    (endpoint_0_1_endpoint_1_1_data  )

        ,.src_ip_tx_noc0_val_N     (endpoint_1_0_endpoint_1_1_val   )
        ,.src_ip_tx_noc0_val_E     ('0   )
        ,.src_ip_tx_noc0_val_S     (endpoint_1_2_endpoint_1_1_val   )
        ,.src_ip_tx_noc0_val_W     (endpoint_0_1_endpoint_1_1_val   )

        ,.ip_tx_src_noc0_yummy_N   (endpoint_1_1_endpoint_1_0_yummy )
        ,.ip_tx_src_noc0_yummy_E   ( )
        ,.ip_tx_src_noc0_yummy_S   (endpoint_1_1_endpoint_1_2_yummy )
        ,.ip_tx_src_noc0_yummy_W   (endpoint_1_1_endpoint_0_1_yummy )

        ,.ip_tx_dst_noc0_data_N    (endpoint_1_1_endpoint_1_0_data  )
        ,.ip_tx_dst_noc0_data_E    (  )
        ,.ip_tx_dst_noc0_data_S    (endpoint_1_1_endpoint_1_2_data  )
        ,.ip_tx_dst_noc0_data_W    (endpoint_1_1_endpoint_0_1_data  )

        ,.ip_tx_dst_noc0_val_N     (endpoint_1_1_endpoint_1_0_val   )
        ,.ip_tx_dst_noc0_val_E     (   )
        ,.ip_tx_dst_noc0_val_S     (endpoint_1_1_endpoint_1_2_val   )
        ,.ip_tx_dst_noc0_val_W     (endpoint_1_1_endpoint_0_1_val   )

        ,.dst_ip_tx_noc0_yummy_N   (endpoint_1_0_endpoint_1_1_yummy )
        ,.dst_ip_tx_noc0_yummy_E   ('0 )
        ,.dst_ip_tx_noc0_yummy_S   (endpoint_1_2_endpoint_1_1_yummy )
        ,.dst_ip_tx_noc0_yummy_W   (endpoint_0_1_endpoint_1_1_yummy )

	);

    tcp_tiles_wrap #(
         .TCP_RX_SRC_X  (TCP_RX_TILE_X  )
        ,.TCP_RX_SRC_Y  (TCP_RX_TILE_Y  )
        ,.TCP_RX_DRAM_X (DRAM_RX_TILE_X )
        ,.TCP_RX_DRAM_Y (DRAM_RX_TILE_Y )
        ,.TCP_TX_SRC_X  (TCP_TX_TILE_X  )
        ,.TCP_TX_SRC_Y  (TCP_TX_TILE_Y  )
        ,.TCP_TX_DRAM_X (DRAM_TX_TILE_X )
        ,.TCP_TX_DRAM_Y (DRAM_TX_TILE_Y )
    ) tcp_rx_0_2_tcp_tx_1_2 (
		 .clk   (clk)
		,.rst   (rst)

        ,.src_tcp_rx_noc0_data_N    (endpoint_0_1_endpoint_0_2_data  )
        ,.src_tcp_rx_noc0_data_E    (endpoint_1_2_endpoint_0_2_data  )
        ,.src_tcp_rx_noc0_data_S    (endpoint_0_3_endpoint_0_2_data  )
        ,.src_tcp_rx_noc0_data_W    ('0  )

        ,.src_tcp_rx_noc0_val_N     (endpoint_0_1_endpoint_0_2_val   )
        ,.src_tcp_rx_noc0_val_E     (endpoint_1_2_endpoint_0_2_val   )
        ,.src_tcp_rx_noc0_val_S     (endpoint_0_3_endpoint_0_2_val   )
        ,.src_tcp_rx_noc0_val_W     ('0   )

        ,.tcp_rx_src_noc0_yummy_N   (endpoint_0_2_endpoint_0_1_yummy )
        ,.tcp_rx_src_noc0_yummy_E   (endpoint_0_2_endpoint_1_2_yummy )
        ,.tcp_rx_src_noc0_yummy_S   (endpoint_0_2_endpoint_0_3_yummy )
        ,.tcp_rx_src_noc0_yummy_W   ( )

        ,.tcp_rx_dst_noc0_data_N    (endpoint_0_2_endpoint_0_1_data  )
        ,.tcp_rx_dst_noc0_data_E    (endpoint_0_2_endpoint_1_2_data  )
        ,.tcp_rx_dst_noc0_data_S    (endpoint_0_2_endpoint_0_3_data  )
        ,.tcp_rx_dst_noc0_data_W    (  )

        ,.tcp_rx_dst_noc0_val_N     (endpoint_0_2_endpoint_0_1_val   )
        ,.tcp_rx_dst_noc0_val_E     (endpoint_0_2_endpoint_1_2_val   )
        ,.tcp_rx_dst_noc0_val_S     (endpoint_0_2_endpoint_0_3_val   )
        ,.tcp_rx_dst_noc0_val_W     (   )

        ,.dst_tcp_rx_noc0_yummy_N   (endpoint_0_1_endpoint_0_2_yummy )
        ,.dst_tcp_rx_noc0_yummy_E   (endpoint_1_2_endpoint_0_2_yummy )
        ,.dst_tcp_rx_noc0_yummy_S   (endpoint_0_3_endpoint_0_2_yummy )
        ,.dst_tcp_rx_noc0_yummy_W   ('0 )


        ,.src_tcp_tx_noc0_data_N    (endpoint_1_1_endpoint_1_2_data  )
        ,.src_tcp_tx_noc0_data_E    ('0  )
        ,.src_tcp_tx_noc0_data_S    (endpoint_1_3_endpoint_1_2_data  )
        ,.src_tcp_tx_noc0_data_W    (endpoint_0_2_endpoint_1_2_data  )

        ,.src_tcp_tx_noc0_val_N     (endpoint_1_1_endpoint_1_2_val   )
        ,.src_tcp_tx_noc0_val_E     ('0   )
        ,.src_tcp_tx_noc0_val_S     (endpoint_1_3_endpoint_1_2_val   )
        ,.src_tcp_tx_noc0_val_W     (endpoint_0_2_endpoint_1_2_val   )

        ,.tcp_tx_src_noc0_yummy_N   (endpoint_1_2_endpoint_1_1_yummy )
        ,.tcp_tx_src_noc0_yummy_E   ( )
        ,.tcp_tx_src_noc0_yummy_S   (endpoint_1_2_endpoint_1_3_yummy )
        ,.tcp_tx_src_noc0_yummy_W   (endpoint_1_2_endpoint_0_2_yummy )

        ,.tcp_tx_dst_noc0_data_N    (endpoint_1_2_endpoint_1_1_data  )
        ,.tcp_tx_dst_noc0_data_E    (  )
        ,.tcp_tx_dst_noc0_data_S    (endpoint_1_2_endpoint_1_3_data  )
        ,.tcp_tx_dst_noc0_data_W    (endpoint_1_2_endpoint_0_2_data  )

        ,.tcp_tx_dst_noc0_val_N     (endpoint_1_2_endpoint_1_1_val   )
        ,.tcp_tx_dst_noc0_val_E     (   )
        ,.tcp_tx_dst_noc0_val_S     (endpoint_1_2_endpoint_1_3_val   )
        ,.tcp_tx_dst_noc0_val_W     (endpoint_1_2_endpoint_0_2_val   )

        ,.dst_tcp_tx_noc0_yummy_N   (endpoint_1_1_endpoint_1_2_yummy )
        ,.dst_tcp_tx_noc0_yummy_E   ('0 )
        ,.dst_tcp_tx_noc0_yummy_S   (endpoint_1_3_endpoint_1_2_yummy )
        ,.dst_tcp_tx_noc0_yummy_W   (endpoint_0_2_endpoint_1_2_yummy )

    );

    dram_tile #(
         .SRC_X             (DRAM_RX_TILE_X     )
        ,.SRC_Y             (DRAM_RX_TILE_Y     )
        ,.MEM_ADDR_W        (MEM_ADDR_W         )
        ,.MEM_DATA_W        (MEM_DATA_W         )
        ,.MEM_BURST_CNT_W   (MEM_BURST_CNT_W    )
    ) dram_rx_0_3 (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_dram_tile_noc0_data_N    (endpoint_0_2_endpoint_0_3_data  )
        ,.src_dram_tile_noc0_data_E    (endpoint_1_3_endpoint_0_3_data  )
        ,.src_dram_tile_noc0_data_S    (endpoint_0_4_endpoint_0_3_data  )
        ,.src_dram_tile_noc0_data_W    ('0  )

        ,.src_dram_tile_noc0_val_N     (endpoint_0_2_endpoint_0_3_val   )
        ,.src_dram_tile_noc0_val_E     (endpoint_1_3_endpoint_0_3_val   )
        ,.src_dram_tile_noc0_val_S     (endpoint_0_4_endpoint_0_3_val   )
        ,.src_dram_tile_noc0_val_W     ('0   )

        ,.dram_tile_src_noc0_yummy_N   (endpoint_0_3_endpoint_0_2_yummy )
        ,.dram_tile_src_noc0_yummy_E   (endpoint_0_3_endpoint_1_3_yummy )
        ,.dram_tile_src_noc0_yummy_S   (endpoint_0_3_endpoint_0_4_yummy )
        ,.dram_tile_src_noc0_yummy_W   ( )

        ,.dram_tile_dst_noc0_data_N    (endpoint_0_3_endpoint_0_2_data  )
        ,.dram_tile_dst_noc0_data_E    (endpoint_0_3_endpoint_1_3_data  )
        ,.dram_tile_dst_noc0_data_S    (endpoint_0_3_endpoint_0_4_data  )
        ,.dram_tile_dst_noc0_data_W    (  )

        ,.dram_tile_dst_noc0_val_N     (endpoint_0_3_endpoint_0_2_val   )
        ,.dram_tile_dst_noc0_val_E     (endpoint_0_3_endpoint_1_3_val   )
        ,.dram_tile_dst_noc0_val_S     (endpoint_0_3_endpoint_0_4_val   )
        ,.dram_tile_dst_noc0_val_W     (   )

        ,.dst_dram_tile_noc0_yummy_N   (endpoint_0_2_endpoint_0_3_yummy )
        ,.dst_dram_tile_noc0_yummy_E   (endpoint_1_3_endpoint_0_3_yummy )
        ,.dst_dram_tile_noc0_yummy_S   (endpoint_0_4_endpoint_0_3_yummy )
        ,.dst_dram_tile_noc0_yummy_W   ('0 )

        ,.controller_mem_read_en        (memA_read_out         )
        ,.controller_mem_write_en       (memA_write_out        )
        ,.controller_mem_addr           (memA_address_out      )
        ,.controller_mem_wr_data        (memA_writedata_out    )
        ,.controller_mem_byte_en        (memA_byteenable_out   )
        ,.controller_mem_burst_cnt      (memA_burstcount_out   )
        ,.mem_controller_rdy            (memA_ready_in         )

        ,.mem_controller_rd_data_val    (memA_readdatavalid_in )
        ,.mem_controller_rd_data        (memA_readdata_in      )
    );

    dram_tile #(
         .SRC_X (DRAM_TX_TILE_X)
        ,.SRC_Y (DRAM_TX_TILE_Y)
        ,.MEM_ADDR_W        (MEM_ADDR_W         )
        ,.MEM_DATA_W        (MEM_DATA_W         )
        ,.MEM_BURST_CNT_W   (MEM_BURST_CNT_W    )
    ) dram_tx_1_3 (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_dram_tile_noc0_data_N    (endpoint_1_2_endpoint_1_3_data  )
        ,.src_dram_tile_noc0_data_E    ('0  )
        ,.src_dram_tile_noc0_data_S    (endpoint_1_4_endpoint_1_3_data  )
        ,.src_dram_tile_noc0_data_W    (endpoint_0_3_endpoint_1_3_data  )

        ,.src_dram_tile_noc0_val_N     (endpoint_1_2_endpoint_1_3_val   )
        ,.src_dram_tile_noc0_val_E     ('0   )
        ,.src_dram_tile_noc0_val_S     (endpoint_1_4_endpoint_1_3_val   )
        ,.src_dram_tile_noc0_val_W     (endpoint_0_3_endpoint_1_3_val   )

        ,.dram_tile_src_noc0_yummy_N   (endpoint_1_3_endpoint_1_2_yummy )
        ,.dram_tile_src_noc0_yummy_E   ( )
        ,.dram_tile_src_noc0_yummy_S   (endpoint_1_3_endpoint_1_4_yummy )
        ,.dram_tile_src_noc0_yummy_W   (endpoint_1_3_endpoint_0_3_yummy )

        ,.dram_tile_dst_noc0_data_N    (endpoint_1_3_endpoint_1_2_data  )
        ,.dram_tile_dst_noc0_data_E    (  )
        ,.dram_tile_dst_noc0_data_S    (endpoint_1_3_endpoint_1_4_data  )
        ,.dram_tile_dst_noc0_data_W    (endpoint_1_3_endpoint_0_3_data  )

        ,.dram_tile_dst_noc0_val_N     (endpoint_1_3_endpoint_1_2_val   )
        ,.dram_tile_dst_noc0_val_E     (   )
        ,.dram_tile_dst_noc0_val_S     (endpoint_1_3_endpoint_1_4_val   )
        ,.dram_tile_dst_noc0_val_W     (endpoint_1_3_endpoint_0_3_val   )

        ,.dst_dram_tile_noc0_yummy_N   (endpoint_1_2_endpoint_1_3_yummy )
        ,.dst_dram_tile_noc0_yummy_E   ('0 )
        ,.dst_dram_tile_noc0_yummy_S   (endpoint_1_4_endpoint_1_3_yummy )
        ,.dst_dram_tile_noc0_yummy_W   (endpoint_0_3_endpoint_1_3_yummy )

        ,.controller_mem_read_en        (memB_read_out         )
        ,.controller_mem_write_en       (memB_write_out        )
        ,.controller_mem_addr           (memB_address_out      )
        ,.controller_mem_wr_data        (memB_writedata_out    )
        ,.controller_mem_byte_en        (memB_byteenable_out   )
        ,.controller_mem_burst_cnt      (memB_burstcount_out   )
        ,.mem_controller_rdy            (memB_ready_in         )

        ,.mem_controller_rd_data_val    (memB_readdatavalid_in )
        ,.mem_controller_rd_data        (memB_readdata_in      )
    );
    
    echo_app_tiles #(
         .APP_TILE_RX_SRC_X     (APP_TILE_RX_X  )
        ,.APP_TILE_RX_SRC_Y     (APP_TILE_RX_Y  )
        ,.APP_TILE_TX_SRC_X     (APP_TILE_TX_X  )
        ,.APP_TILE_TX_SRC_Y     (APP_TILE_TX_Y  )
        ,.APP_TILE_TX_DST_BUF_X (DRAM_TX_TILE_X )
        ,.APP_TILE_TX_DST_BUF_Y (DRAM_TX_TILE_Y )
        ,.APP_TILE_RX_DST_BUF_X (DRAM_RX_TILE_X )
        ,.APP_TILE_RX_DST_BUF_Y (DRAM_RX_TILE_Y )
    ) app_rx_0_4_app_tx_1_4 (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_app_tile_rx_noc0_data_N    (endpoint_0_3_endpoint_0_4_data  )
        ,.src_app_tile_rx_noc0_data_E    (endpoint_1_4_endpoint_0_4_data  )
        ,.src_app_tile_rx_noc0_data_S    ('0  )
        ,.src_app_tile_rx_noc0_data_W    ('0  )

        ,.src_app_tile_rx_noc0_val_N     (endpoint_0_3_endpoint_0_4_val   )
        ,.src_app_tile_rx_noc0_val_E     (endpoint_1_4_endpoint_0_4_val   )
        ,.src_app_tile_rx_noc0_val_S     ('0   )
        ,.src_app_tile_rx_noc0_val_W     ('0   )

        ,.app_tile_rx_src_noc0_yummy_N   (endpoint_0_4_endpoint_0_3_yummy )
        ,.app_tile_rx_src_noc0_yummy_E   (endpoint_0_4_endpoint_1_4_yummy )
        ,.app_tile_rx_src_noc0_yummy_S   ( )
        ,.app_tile_rx_src_noc0_yummy_W   ( )

        ,.app_tile_rx_dst_noc0_data_N    (endpoint_0_4_endpoint_0_3_data  )
        ,.app_tile_rx_dst_noc0_data_E    (endpoint_0_4_endpoint_1_4_data  )
        ,.app_tile_rx_dst_noc0_data_S    (  )
        ,.app_tile_rx_dst_noc0_data_W    (  )

        ,.app_tile_rx_dst_noc0_val_N     (endpoint_0_4_endpoint_0_3_val   )
        ,.app_tile_rx_dst_noc0_val_E     (endpoint_0_4_endpoint_1_4_val   )
        ,.app_tile_rx_dst_noc0_val_S     (   )
        ,.app_tile_rx_dst_noc0_val_W     (   )

        ,.dst_app_tile_rx_noc0_yummy_N   (endpoint_0_3_endpoint_0_4_yummy )
        ,.dst_app_tile_rx_noc0_yummy_E   (endpoint_1_4_endpoint_0_4_yummy )
        ,.dst_app_tile_rx_noc0_yummy_S   ('0 )
        ,.dst_app_tile_rx_noc0_yummy_W   ('0 )

        ,.src_app_tile_tx_noc0_data_N    (endpoint_1_3_endpoint_1_4_data  )
        ,.src_app_tile_tx_noc0_data_E    ('0  )
        ,.src_app_tile_tx_noc0_data_S    ('0  )
        ,.src_app_tile_tx_noc0_data_W    (endpoint_0_4_endpoint_1_4_data  )

        ,.src_app_tile_tx_noc0_val_N     (endpoint_1_3_endpoint_1_4_val   )
        ,.src_app_tile_tx_noc0_val_E     ('0   )
        ,.src_app_tile_tx_noc0_val_S     ('0   )
        ,.src_app_tile_tx_noc0_val_W     (endpoint_0_4_endpoint_1_4_val   )

        ,.app_tile_tx_src_noc0_yummy_N   (endpoint_1_4_endpoint_1_3_yummy )
        ,.app_tile_tx_src_noc0_yummy_E   ( )
        ,.app_tile_tx_src_noc0_yummy_S   ( )
        ,.app_tile_tx_src_noc0_yummy_W   (endpoint_1_4_endpoint_0_4_yummy )

        ,.app_tile_tx_dst_noc0_data_N    (endpoint_1_4_endpoint_1_3_data  )
        ,.app_tile_tx_dst_noc0_data_E    (  )
        ,.app_tile_tx_dst_noc0_data_S    (  )
        ,.app_tile_tx_dst_noc0_data_W    (endpoint_1_4_endpoint_0_4_data  )

        ,.app_tile_tx_dst_noc0_val_N     (endpoint_1_4_endpoint_1_3_val   )
        ,.app_tile_tx_dst_noc0_val_E     (   )
        ,.app_tile_tx_dst_noc0_val_S     (   )
        ,.app_tile_tx_dst_noc0_val_W     (endpoint_1_4_endpoint_0_4_val   )

        ,.dst_app_tile_tx_noc0_yummy_N   (endpoint_1_3_endpoint_1_4_yummy )
        ,.dst_app_tile_tx_noc0_yummy_E   ('0 )
        ,.dst_app_tile_tx_noc0_yummy_S   ('0 )
        ,.dst_app_tile_tx_noc0_yummy_W   (endpoint_0_4_endpoint_1_4_yummy )

    );


endmodule
