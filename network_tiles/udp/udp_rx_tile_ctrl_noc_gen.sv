`include "udp_rx_tile_defs.svh"

module udp_rx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst


    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_rx_data_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_rx_data_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_rx_data_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_rx_data_noc0_data_W

    ,input                                  src_udp_rx_data_noc0_val_N
    ,input                                  src_udp_rx_data_noc0_val_E
    ,input                                  src_udp_rx_data_noc0_val_S
    ,input                                  src_udp_rx_data_noc0_val_W

    ,output                                 udp_rx_src_data_noc0_yummy_N
    ,output                                 udp_rx_src_data_noc0_yummy_E
    ,output                                 udp_rx_src_data_noc0_yummy_S
    ,output                                 udp_rx_src_data_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]          udp_rx_dst_data_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]          udp_rx_dst_data_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]          udp_rx_dst_data_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]          udp_rx_dst_data_noc0_data_W

    ,output                                 udp_rx_dst_data_noc0_val_N
    ,output                                 udp_rx_dst_data_noc0_val_E
    ,output                                 udp_rx_dst_data_noc0_val_S
    ,output                                 udp_rx_dst_data_noc0_val_W

    ,input                                  dst_udp_rx_data_noc0_yummy_N
    ,input                                  dst_udp_rx_data_noc0_yummy_E
    ,input                                  dst_udp_rx_data_noc0_yummy_S
    ,input                                  dst_udp_rx_data_noc0_yummy_W
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_rx_ctrl_noc1_data_N
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_rx_ctrl_noc1_data_E
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_rx_ctrl_noc1_data_S
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_rx_ctrl_noc1_data_W

    ,input                                  src_udp_rx_ctrl_noc1_val_N
    ,input                                  src_udp_rx_ctrl_noc1_val_E
    ,input                                  src_udp_rx_ctrl_noc1_val_S
    ,input                                  src_udp_rx_ctrl_noc1_val_W

    ,output                                 udp_rx_src_ctrl_noc1_yummy_N
    ,output                                 udp_rx_src_ctrl_noc1_yummy_E
    ,output                                 udp_rx_src_ctrl_noc1_yummy_S
    ,output                                 udp_rx_src_ctrl_noc1_yummy_W

    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_rx_dst_ctrl_noc1_data_N
    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_rx_dst_ctrl_noc1_data_E
    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_rx_dst_ctrl_noc1_data_S
    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_rx_dst_ctrl_noc1_data_W

    ,output                                 udp_rx_dst_ctrl_noc1_val_N
    ,output                                 udp_rx_dst_ctrl_noc1_val_E
    ,output                                 udp_rx_dst_ctrl_noc1_val_S
    ,output                                 udp_rx_dst_ctrl_noc1_val_W

    ,input                                  dst_udp_rx_ctrl_noc1_yummy_N
    ,input                                  dst_udp_rx_ctrl_noc1_yummy_E
    ,input                                  dst_udp_rx_ctrl_noc1_yummy_S
    ,input                                  dst_udp_rx_ctrl_noc1_yummy_W
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_rx_ctrl_noc2_data_N
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_rx_ctrl_noc2_data_E
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_rx_ctrl_noc2_data_S
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_rx_ctrl_noc2_data_W

    ,input                                  src_udp_rx_ctrl_noc2_val_N
    ,input                                  src_udp_rx_ctrl_noc2_val_E
    ,input                                  src_udp_rx_ctrl_noc2_val_S
    ,input                                  src_udp_rx_ctrl_noc2_val_W

    ,output                                 udp_rx_src_ctrl_noc2_yummy_N
    ,output                                 udp_rx_src_ctrl_noc2_yummy_E
    ,output                                 udp_rx_src_ctrl_noc2_yummy_S
    ,output                                 udp_rx_src_ctrl_noc2_yummy_W

    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_rx_dst_ctrl_noc2_data_N
    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_rx_dst_ctrl_noc2_data_E
    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_rx_dst_ctrl_noc2_data_S
    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_rx_dst_ctrl_noc2_data_W

    ,output                                 udp_rx_dst_ctrl_noc2_val_N
    ,output                                 udp_rx_dst_ctrl_noc2_val_E
    ,output                                 udp_rx_dst_ctrl_noc2_val_S
    ,output                                 udp_rx_dst_ctrl_noc2_val_W

    ,input                                  dst_udp_rx_ctrl_noc2_yummy_N
    ,input                                  dst_udp_rx_ctrl_noc2_yummy_E
    ,input                                  dst_udp_rx_ctrl_noc2_yummy_S
    ,input                                  dst_udp_rx_ctrl_noc2_yummy_W

);


    logic                           vrtoc_router_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]  vrtoc_router_data_noc0_data;
    logic                           router_vrtoc_data_noc0_yummy;

    logic                           router_ctovr_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]  router_ctovr_data_noc0_data;
    logic                           ctovr_router_data_noc0_yummy;
    
    logic                           vrtoc_router_ctrl_noc1_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]  vrtoc_router_ctrl_noc1_data;
    logic                           router_vrtoc_ctrl_noc1_yummy;

    logic                           router_ctovr_ctrl_noc1_val;
    logic   [`CTRL_NOC1_DATA_W-1:0]  router_ctovr_ctrl_noc1_data;
    logic                           ctovr_router_ctrl_noc1_yummy;
    
    logic                           vrtoc_router_ctrl_noc2_val;
    logic   [`CTRL_NOC2_DATA_W-1:0]  vrtoc_router_ctrl_noc2_data;
    logic                           router_vrtoc_ctrl_noc2_yummy;

    logic                           router_ctovr_ctrl_noc2_val;
    logic   [`CTRL_NOC2_DATA_W-1:0]  router_ctovr_ctrl_noc2_data;
    logic                           ctovr_router_ctrl_noc2_yummy;
    

    
    logic                           steer_vrtoc_ctrl_noc1_val;
    logic   [`CTRL_NOC1_DATA_W-1:0] steer_vrtoc_ctrl_noc1_data;
    logic                           vrtoc_steer_ctrl_noc1_rdy;

    logic                           steer_vrtoc_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   steer_vrtoc_data_noc0_data;
    logic                           vrtoc_steer_data_noc0_rdy;
    
    logic                           udp_rx_out_steer_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_rx_out_steer_data_noc0_data;
    logic                           steer_udp_rx_out_data_noc0_rdy;

    logic                           ctovr_udp_rx_in_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ctovr_udp_rx_in_data_noc0_data;
    logic                           udp_rx_in_ctovr_data_noc0_rdy;

    logic                           udp_rx_in_udp_formatter_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_rx_in_udp_formatter_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_rx_in_udp_formatter_rx_dst_ip;
    logic   [`TOT_LEN_W-1:0]        udp_rx_in_udp_formatter_rx_udp_len;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_rx_in_udp_formatter_rx_timestamp;
    logic                           udp_formatter_udp_rx_in_rx_hdr_rdy;

    logic                           udp_rx_in_udp_formatter_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_rx_in_udp_formatter_rx_data;
    logic                           udp_rx_in_udp_formatter_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_rx_in_udp_formatter_rx_padbytes;
    logic                           udp_formatter_udp_rx_in_rx_data_rdy;

    logic                           udp_formatter_udp_rx_out_rx_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_formatter_udp_rx_out_rx_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_formatter_udp_rx_out_rx_dst_ip;
    udp_pkt_hdr                     udp_formatter_udp_rx_out_rx_udp_hdr;
    logic   [`PKT_TIMESTAMP_W-1:0]  udp_formatter_udp_rx_out_rx_timestamp;
    logic                           udp_rx_out_udp_formatter_rx_hdr_rdy;

    logic                           udp_formatter_udp_rx_out_rx_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_formatter_udp_rx_out_rx_data;
    logic                           udp_formatter_udp_rx_out_rx_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_formatter_udp_rx_out_rx_padbytes;
    logic                           udp_rx_out_udp_formatter_rx_data_rdy;
    
    noc_router_block #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) udp_rx_noc_router_block (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_router_block_data_noc0_data_N  (src_udp_rx_data_noc0_data_N )
        ,.src_router_block_data_noc0_data_E  (src_udp_rx_data_noc0_data_E )
        ,.src_router_block_data_noc0_data_S  (src_udp_rx_data_noc0_data_S )
        ,.src_router_block_data_noc0_data_W  (src_udp_rx_data_noc0_data_W )

        ,.src_router_block_data_noc0_val_N   (src_udp_rx_data_noc0_val_N  )
        ,.src_router_block_data_noc0_val_E   (src_udp_rx_data_noc0_val_E  )
        ,.src_router_block_data_noc0_val_S   (src_udp_rx_data_noc0_val_S  )
        ,.src_router_block_data_noc0_val_W   (src_udp_rx_data_noc0_val_W  )

        ,.router_block_src_data_noc0_yummy_N (udp_rx_src_data_noc0_yummy_N)
        ,.router_block_src_data_noc0_yummy_E (udp_rx_src_data_noc0_yummy_E)
        ,.router_block_src_data_noc0_yummy_S (udp_rx_src_data_noc0_yummy_S)
        ,.router_block_src_data_noc0_yummy_W (udp_rx_src_data_noc0_yummy_W)

        ,.router_block_dst_data_noc0_data_N  (udp_rx_dst_data_noc0_data_N )
        ,.router_block_dst_data_noc0_data_E  (udp_rx_dst_data_noc0_data_E )
        ,.router_block_dst_data_noc0_data_S  (udp_rx_dst_data_noc0_data_S )
        ,.router_block_dst_data_noc0_data_W  (udp_rx_dst_data_noc0_data_W )

        ,.router_block_dst_data_noc0_val_N   (udp_rx_dst_data_noc0_val_N  )
        ,.router_block_dst_data_noc0_val_E   (udp_rx_dst_data_noc0_val_E  )
        ,.router_block_dst_data_noc0_val_S   (udp_rx_dst_data_noc0_val_S  )
        ,.router_block_dst_data_noc0_val_W   (udp_rx_dst_data_noc0_val_W  )

        ,.dst_router_block_data_noc0_yummy_N (dst_udp_rx_data_noc0_yummy_N)
        ,.dst_router_block_data_noc0_yummy_E (dst_udp_rx_data_noc0_yummy_E)
        ,.dst_router_block_data_noc0_yummy_S (dst_udp_rx_data_noc0_yummy_S)
        ,.dst_router_block_data_noc0_yummy_W (dst_udp_rx_data_noc0_yummy_W)
        ,.src_router_block_ctrl_noc1_data_N  (src_udp_rx_ctrl_noc1_data_N )
        ,.src_router_block_ctrl_noc1_data_E  (src_udp_rx_ctrl_noc1_data_E )
        ,.src_router_block_ctrl_noc1_data_S  (src_udp_rx_ctrl_noc1_data_S )
        ,.src_router_block_ctrl_noc1_data_W  (src_udp_rx_ctrl_noc1_data_W )

        ,.src_router_block_ctrl_noc1_val_N   (src_udp_rx_ctrl_noc1_val_N  )
        ,.src_router_block_ctrl_noc1_val_E   (src_udp_rx_ctrl_noc1_val_E  )
        ,.src_router_block_ctrl_noc1_val_S   (src_udp_rx_ctrl_noc1_val_S  )
        ,.src_router_block_ctrl_noc1_val_W   (src_udp_rx_ctrl_noc1_val_W  )

        ,.router_block_src_ctrl_noc1_yummy_N (udp_rx_src_ctrl_noc1_yummy_N)
        ,.router_block_src_ctrl_noc1_yummy_E (udp_rx_src_ctrl_noc1_yummy_E)
        ,.router_block_src_ctrl_noc1_yummy_S (udp_rx_src_ctrl_noc1_yummy_S)
        ,.router_block_src_ctrl_noc1_yummy_W (udp_rx_src_ctrl_noc1_yummy_W)

        ,.router_block_dst_ctrl_noc1_data_N  (udp_rx_dst_ctrl_noc1_data_N )
        ,.router_block_dst_ctrl_noc1_data_E  (udp_rx_dst_ctrl_noc1_data_E )
        ,.router_block_dst_ctrl_noc1_data_S  (udp_rx_dst_ctrl_noc1_data_S )
        ,.router_block_dst_ctrl_noc1_data_W  (udp_rx_dst_ctrl_noc1_data_W )

        ,.router_block_dst_ctrl_noc1_val_N   (udp_rx_dst_ctrl_noc1_val_N  )
        ,.router_block_dst_ctrl_noc1_val_E   (udp_rx_dst_ctrl_noc1_val_E  )
        ,.router_block_dst_ctrl_noc1_val_S   (udp_rx_dst_ctrl_noc1_val_S  )
        ,.router_block_dst_ctrl_noc1_val_W   (udp_rx_dst_ctrl_noc1_val_W  )

        ,.dst_router_block_ctrl_noc1_yummy_N (dst_udp_rx_ctrl_noc1_yummy_N)
        ,.dst_router_block_ctrl_noc1_yummy_E (dst_udp_rx_ctrl_noc1_yummy_E)
        ,.dst_router_block_ctrl_noc1_yummy_S (dst_udp_rx_ctrl_noc1_yummy_S)
        ,.dst_router_block_ctrl_noc1_yummy_W (dst_udp_rx_ctrl_noc1_yummy_W)
        ,.src_router_block_ctrl_noc2_data_N  (src_udp_rx_ctrl_noc2_data_N )
        ,.src_router_block_ctrl_noc2_data_E  (src_udp_rx_ctrl_noc2_data_E )
        ,.src_router_block_ctrl_noc2_data_S  (src_udp_rx_ctrl_noc2_data_S )
        ,.src_router_block_ctrl_noc2_data_W  (src_udp_rx_ctrl_noc2_data_W )

        ,.src_router_block_ctrl_noc2_val_N   (src_udp_rx_ctrl_noc2_val_N  )
        ,.src_router_block_ctrl_noc2_val_E   (src_udp_rx_ctrl_noc2_val_E  )
        ,.src_router_block_ctrl_noc2_val_S   (src_udp_rx_ctrl_noc2_val_S  )
        ,.src_router_block_ctrl_noc2_val_W   (src_udp_rx_ctrl_noc2_val_W  )

        ,.router_block_src_ctrl_noc2_yummy_N (udp_rx_src_ctrl_noc2_yummy_N)
        ,.router_block_src_ctrl_noc2_yummy_E (udp_rx_src_ctrl_noc2_yummy_E)
        ,.router_block_src_ctrl_noc2_yummy_S (udp_rx_src_ctrl_noc2_yummy_S)
        ,.router_block_src_ctrl_noc2_yummy_W (udp_rx_src_ctrl_noc2_yummy_W)

        ,.router_block_dst_ctrl_noc2_data_N  (udp_rx_dst_ctrl_noc2_data_N )
        ,.router_block_dst_ctrl_noc2_data_E  (udp_rx_dst_ctrl_noc2_data_E )
        ,.router_block_dst_ctrl_noc2_data_S  (udp_rx_dst_ctrl_noc2_data_S )
        ,.router_block_dst_ctrl_noc2_data_W  (udp_rx_dst_ctrl_noc2_data_W )

        ,.router_block_dst_ctrl_noc2_val_N   (udp_rx_dst_ctrl_noc2_val_N  )
        ,.router_block_dst_ctrl_noc2_val_E   (udp_rx_dst_ctrl_noc2_val_E  )
        ,.router_block_dst_ctrl_noc2_val_S   (udp_rx_dst_ctrl_noc2_val_S  )
        ,.router_block_dst_ctrl_noc2_val_W   (udp_rx_dst_ctrl_noc2_val_W  )

        ,.dst_router_block_ctrl_noc2_yummy_N (dst_udp_rx_ctrl_noc2_yummy_N)
        ,.dst_router_block_ctrl_noc2_yummy_E (dst_udp_rx_ctrl_noc2_yummy_E)
        ,.dst_router_block_ctrl_noc2_yummy_S (dst_udp_rx_ctrl_noc2_yummy_S)
        ,.dst_router_block_ctrl_noc2_yummy_W (dst_udp_rx_ctrl_noc2_yummy_W)

        ,.router_block_process_data_noc0_val    (router_ctovr_data_noc0_val     )
        ,.router_block_process_data_noc0_data   (router_ctovr_data_noc0_data    )
        ,.process_router_block_data_noc0_yummy  (ctovr_router_data_noc0_yummy   )

        ,.process_router_block_data_noc0_val    (vrtoc_router_data_noc0_val     )
        ,.process_router_block_data_noc0_data   (vrtoc_router_data_noc0_data    )
        ,.router_block_process_data_noc0_yummy  (router_vrtoc_data_noc0_yummy   )
        ,.router_block_process_ctrl_noc1_val    (router_ctovr_ctrl_noc1_val     )
        ,.router_block_process_ctrl_noc1_data   (router_ctovr_ctrl_noc1_data    )
        ,.process_router_block_ctrl_noc1_yummy  (ctovr_router_ctrl_noc1_yummy   )

        ,.process_router_block_ctrl_noc1_val    (vrtoc_router_ctrl_noc1_val     )
        ,.process_router_block_ctrl_noc1_data   (vrtoc_router_ctrl_noc1_data    )
        ,.router_block_process_ctrl_noc1_yummy  (router_vrtoc_ctrl_noc1_yummy   )
        ,.router_block_process_ctrl_noc2_val    (router_ctovr_ctrl_noc2_val     )
        ,.router_block_process_ctrl_noc2_data   (router_ctovr_ctrl_noc2_data    )
        ,.process_router_block_ctrl_noc2_yummy  (ctovr_router_ctrl_noc2_yummy   )

        ,.process_router_block_ctrl_noc2_val    (vrtoc_router_ctrl_noc2_val     )
        ,.process_router_block_ctrl_noc2_data   (vrtoc_router_ctrl_noc2_data    )
        ,.router_block_process_ctrl_noc2_yummy  (router_vrtoc_ctrl_noc2_yummy   )

    );

    assign ctovr_router_ctrl_noc2_yummy = 1'b0;
    assign ctovr_router_ctrl_noc1_yummy = 1'b0;
    assign vrtoc_router_ctrl_noc2_val = 1'b0;
    assign vrtoc_router_ctrl_noc2_data = '0;
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) data_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        
        ,.src_ctovr_data    (router_ctovr_data_noc0_data        )
        ,.src_ctovr_val     (router_ctovr_data_noc0_val         )
        ,.ctovr_src_yummy   (ctovr_router_data_noc0_yummy       )

        ,.ctovr_dst_data    (ctovr_udp_rx_in_data_noc0_data     )
        ,.ctovr_dst_val     (ctovr_udp_rx_in_data_noc0_val      )
        ,.dst_ctovr_rdy     (udp_rx_in_ctovr_data_noc0_rdy      )
    );

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) data_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        ,.src_vrtoc_data    (steer_vrtoc_data_noc0_data    )
        ,.src_vrtoc_val     (steer_vrtoc_data_noc0_val     )
        ,.vrtoc_src_rdy     (vrtoc_steer_data_noc0_rdy     )

        ,.vrtoc_dst_data    (vrtoc_router_data_noc0_data    )
        ,.vrtoc_dst_val     (vrtoc_router_data_noc0_val     )
		,.dst_vrtoc_yummy   (router_vrtoc_data_noc0_yummy   )
    );
    
    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`CTRL_NOC1_DATA_W  )
    ) ctrl_noc1_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        ,.src_vrtoc_data    (steer_vrtoc_ctrl_noc1_data     )
        ,.src_vrtoc_val     (steer_vrtoc_ctrl_noc1_val      )
        ,.vrtoc_src_rdy     (vrtoc_steer_ctrl_noc1_rdy      )

        ,.vrtoc_dst_data    (vrtoc_router_ctrl_noc1_data    )
        ,.vrtoc_dst_val     (vrtoc_router_ctrl_noc1_val     )
		,.dst_vrtoc_yummy   (router_vrtoc_ctrl_noc1_yummy   )
    );
    
    udp_rx_noc_in udp_rx_noc_in (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_rx_in_val              (ctovr_udp_rx_in_data_noc0_val          )
        ,.noc0_ctovr_udp_rx_in_data             (ctovr_udp_rx_in_data_noc0_data         )
        ,.udp_rx_in_noc0_ctovr_rdy              (udp_rx_in_ctovr_data_noc0_rdy          )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_hdr_val    (udp_rx_in_udp_formatter_rx_hdr_val     )
        ,.udp_rx_in_udp_formatter_rx_src_ip     (udp_rx_in_udp_formatter_rx_src_ip      )
        ,.udp_rx_in_udp_formatter_rx_dst_ip     (udp_rx_in_udp_formatter_rx_dst_ip      )
        ,.udp_rx_in_udp_formatter_rx_udp_len    (udp_rx_in_udp_formatter_rx_udp_len     )
        ,.udp_rx_in_udp_formatter_rx_timestamp  (udp_rx_in_udp_formatter_rx_timestamp   )
        ,.udp_formatter_udp_rx_in_rx_hdr_rdy    (udp_formatter_udp_rx_in_rx_hdr_rdy     )
                                                                                        
        ,.udp_rx_in_udp_formatter_rx_data_val   (udp_rx_in_udp_formatter_rx_data_val    )
        ,.udp_rx_in_udp_formatter_rx_data       (udp_rx_in_udp_formatter_rx_data        )
        ,.udp_rx_in_udp_formatter_rx_last       (udp_rx_in_udp_formatter_rx_last        )
        ,.udp_rx_in_udp_formatter_rx_padbytes   (udp_rx_in_udp_formatter_rx_padbytes    )
        ,.udp_formatter_udp_rx_in_rx_data_rdy   (udp_formatter_udp_rx_in_rx_data_rdy    )
    );

    udp_stream_format #(
        .DATA_WIDTH (`NOC_DATA_WIDTH)
    ) rx_udp_formatter (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_udp_formatter_rx_hdr_val  (udp_rx_in_udp_formatter_rx_hdr_val     )
        ,.src_udp_formatter_rx_src_ip   (udp_rx_in_udp_formatter_rx_src_ip      )
        ,.src_udp_formatter_rx_dst_ip   (udp_rx_in_udp_formatter_rx_dst_ip      )
        ,.src_udp_formatter_rx_udp_len  (udp_rx_in_udp_formatter_rx_udp_len     )
        ,.src_udp_formatter_rx_timestamp(udp_rx_in_udp_formatter_rx_timestamp   )
        ,.udp_formatter_src_rx_hdr_rdy  (udp_formatter_udp_rx_in_rx_hdr_rdy     )
                                                                                
        ,.src_udp_formatter_rx_data_val (udp_rx_in_udp_formatter_rx_data_val    )
        ,.src_udp_formatter_rx_data     (udp_rx_in_udp_formatter_rx_data        )
        ,.src_udp_formatter_rx_last     (udp_rx_in_udp_formatter_rx_last        )
        ,.src_udp_formatter_rx_padbytes (udp_rx_in_udp_formatter_rx_padbytes    )
        ,.udp_formatter_src_rx_data_rdy (udp_formatter_udp_rx_in_rx_data_rdy    )
        
        ,.udp_formatter_dst_rx_hdr_val  (udp_formatter_udp_rx_out_rx_hdr_val    )
        ,.udp_formatter_dst_rx_src_ip   (udp_formatter_udp_rx_out_rx_src_ip     )
        ,.udp_formatter_dst_rx_dst_ip   (udp_formatter_udp_rx_out_rx_dst_ip     )
        ,.udp_formatter_dst_rx_udp_hdr  (udp_formatter_udp_rx_out_rx_udp_hdr    )
        ,.udp_formatter_dst_rx_timestamp(udp_formatter_udp_rx_out_rx_timestamp  )
        ,.dst_udp_formatter_rx_hdr_rdy  (udp_rx_out_udp_formatter_rx_hdr_rdy    )
                                                                                 
        ,.udp_formatter_dst_rx_data_val (udp_formatter_udp_rx_out_rx_data_val   )
        ,.udp_formatter_dst_rx_data     (udp_formatter_udp_rx_out_rx_data       )
        ,.udp_formatter_dst_rx_last     (udp_formatter_udp_rx_out_rx_last       )
        ,.udp_formatter_dst_rx_padbytes (udp_formatter_udp_rx_out_rx_padbytes   )
        ,.dst_udp_formatter_rx_data_rdy (udp_rx_out_udp_formatter_rx_data_rdy   )
    );

    udp_rx_noc_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) udp_rx_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_formatter_udp_rx_out_rx_hdr_val   (udp_formatter_udp_rx_out_rx_hdr_val    )
        ,.udp_formatter_udp_rx_out_rx_src_ip    (udp_formatter_udp_rx_out_rx_src_ip     )
        ,.udp_formatter_udp_rx_out_rx_dst_ip    (udp_formatter_udp_rx_out_rx_dst_ip     )
        ,.udp_formatter_udp_rx_out_rx_udp_hdr   (udp_formatter_udp_rx_out_rx_udp_hdr    )
        ,.udp_formatter_udp_rx_out_rx_timestamp (udp_formatter_udp_rx_out_rx_timestamp  )
        ,.udp_rx_out_udp_formatter_rx_hdr_rdy   (udp_rx_out_udp_formatter_rx_hdr_rdy    )
                                                                                        
        ,.udp_formatter_udp_rx_out_rx_data_val  (udp_formatter_udp_rx_out_rx_data_val   )
        ,.udp_formatter_udp_rx_out_rx_data      (udp_formatter_udp_rx_out_rx_data       )
        ,.udp_formatter_udp_rx_out_rx_last      (udp_formatter_udp_rx_out_rx_last       )
        ,.udp_formatter_udp_rx_out_rx_padbytes  (udp_formatter_udp_rx_out_rx_padbytes   )
        ,.udp_rx_out_udp_formatter_rx_data_rdy  (udp_rx_out_udp_formatter_rx_data_rdy   )
                                                                                        
        ,.udp_rx_out_noc0_vrtoc_val             (udp_rx_out_steer_data_noc0_val         )
        ,.udp_rx_out_noc0_vrtoc_data            (udp_rx_out_steer_data_noc0_data        )
        ,.noc0_vrtoc_udp_rx_out_rdy             (steer_udp_rx_out_data_noc0_rdy         )
    );

    udp_rx_out_steer steering (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.src_steer_data_noc0_val   (udp_rx_out_steer_data_noc0_val     )
        ,.src_steer_data_noc0_data  (udp_rx_out_steer_data_noc0_data    )
        ,.steer_src_data_noc0_rdy   (steer_udp_rx_out_data_noc0_rdy     )
    
        ,.steer_dst_data_noc0_val   (steer_vrtoc_data_noc0_val          )
        ,.steer_dst_data_noc0_data  (steer_vrtoc_data_noc0_data         )
        ,.dst_steer_data_noc0_rdy   (vrtoc_steer_data_noc0_rdy          )
    
        ,.steer_dst_ctrl_noc1_val   (steer_vrtoc_ctrl_noc1_val          )
        ,.steer_dst_ctrl_noc1_data  (steer_vrtoc_ctrl_noc1_data         )
        ,.dst_steer_ctrl_noc1_rdy   (vrtoc_steer_ctrl_noc1_rdy          )
    );

endmodule
