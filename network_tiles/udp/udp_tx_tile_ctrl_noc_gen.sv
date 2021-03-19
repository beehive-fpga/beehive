`include "udp_tx_tile_defs.svh"

module udp_tx_tile #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
)(
     input clk
    ,input rst

    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_tx_data_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_tx_data_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_tx_data_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]           src_udp_tx_data_noc0_data_W

    ,input                                  src_udp_tx_data_noc0_val_N
    ,input                                  src_udp_tx_data_noc0_val_E
    ,input                                  src_udp_tx_data_noc0_val_S
    ,input                                  src_udp_tx_data_noc0_val_W

    ,output                                 udp_tx_src_data_noc0_yummy_N
    ,output                                 udp_tx_src_data_noc0_yummy_E
    ,output                                 udp_tx_src_data_noc0_yummy_S
    ,output                                 udp_tx_src_data_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]          udp_tx_dst_data_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]          udp_tx_dst_data_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]          udp_tx_dst_data_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]          udp_tx_dst_data_noc0_data_W

    ,output                                 udp_tx_dst_data_noc0_val_N
    ,output                                 udp_tx_dst_data_noc0_val_E
    ,output                                 udp_tx_dst_data_noc0_val_S
    ,output                                 udp_tx_dst_data_noc0_val_W

    ,input                                  dst_udp_tx_data_noc0_yummy_N
    ,input                                  dst_udp_tx_data_noc0_yummy_E
    ,input                                  dst_udp_tx_data_noc0_yummy_S
    ,input                                  dst_udp_tx_data_noc0_yummy_W
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_tx_ctrl_noc1_data_N
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_tx_ctrl_noc1_data_E
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_tx_ctrl_noc1_data_S
    ,input [`CTRL_NOC1_DATA_W-1:0]           src_udp_tx_ctrl_noc1_data_W

    ,input                                  src_udp_tx_ctrl_noc1_val_N
    ,input                                  src_udp_tx_ctrl_noc1_val_E
    ,input                                  src_udp_tx_ctrl_noc1_val_S
    ,input                                  src_udp_tx_ctrl_noc1_val_W

    ,output                                 udp_tx_src_ctrl_noc1_yummy_N
    ,output                                 udp_tx_src_ctrl_noc1_yummy_E
    ,output                                 udp_tx_src_ctrl_noc1_yummy_S
    ,output                                 udp_tx_src_ctrl_noc1_yummy_W

    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_tx_dst_ctrl_noc1_data_N
    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_tx_dst_ctrl_noc1_data_E
    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_tx_dst_ctrl_noc1_data_S
    ,output [`CTRL_NOC1_DATA_W-1:0]          udp_tx_dst_ctrl_noc1_data_W

    ,output                                 udp_tx_dst_ctrl_noc1_val_N
    ,output                                 udp_tx_dst_ctrl_noc1_val_E
    ,output                                 udp_tx_dst_ctrl_noc1_val_S
    ,output                                 udp_tx_dst_ctrl_noc1_val_W

    ,input                                  dst_udp_tx_ctrl_noc1_yummy_N
    ,input                                  dst_udp_tx_ctrl_noc1_yummy_E
    ,input                                  dst_udp_tx_ctrl_noc1_yummy_S
    ,input                                  dst_udp_tx_ctrl_noc1_yummy_W
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_tx_ctrl_noc2_data_N
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_tx_ctrl_noc2_data_E
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_tx_ctrl_noc2_data_S
    ,input [`CTRL_NOC2_DATA_W-1:0]           src_udp_tx_ctrl_noc2_data_W

    ,input                                  src_udp_tx_ctrl_noc2_val_N
    ,input                                  src_udp_tx_ctrl_noc2_val_E
    ,input                                  src_udp_tx_ctrl_noc2_val_S
    ,input                                  src_udp_tx_ctrl_noc2_val_W

    ,output                                 udp_tx_src_ctrl_noc2_yummy_N
    ,output                                 udp_tx_src_ctrl_noc2_yummy_E
    ,output                                 udp_tx_src_ctrl_noc2_yummy_S
    ,output                                 udp_tx_src_ctrl_noc2_yummy_W

    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_tx_dst_ctrl_noc2_data_N
    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_tx_dst_ctrl_noc2_data_E
    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_tx_dst_ctrl_noc2_data_S
    ,output [`CTRL_NOC2_DATA_W-1:0]          udp_tx_dst_ctrl_noc2_data_W

    ,output                                 udp_tx_dst_ctrl_noc2_val_N
    ,output                                 udp_tx_dst_ctrl_noc2_val_E
    ,output                                 udp_tx_dst_ctrl_noc2_val_S
    ,output                                 udp_tx_dst_ctrl_noc2_val_W

    ,input                                  dst_udp_tx_ctrl_noc2_yummy_N
    ,input                                  dst_udp_tx_ctrl_noc2_yummy_E
    ,input                                  dst_udp_tx_ctrl_noc2_yummy_S
    ,input                                  dst_udp_tx_ctrl_noc2_yummy_W

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
    

    logic                           udp_tx_out_vrtoc_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   udp_tx_out_vrtoc_data_noc0_data;
    logic                           vrtoc_udp_tx_out_data_noc0_rdy;

    logic                           ctovr_merger_data_noc0_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ctovr_merger_data_noc0_data;
    logic                           merger_ctovr_data_noc0_rdy;
    
    logic                           merger_udp_tx_in_val;
    logic   [`NOC_DATA_WIDTH-1:0]   merger_udp_tx_in_data;
    logic                           udp_tx_in_merger_rdy;
    
    logic                           ctovr_ctd_ctrl_noc2_val;
    logic   [`CTRL_NOC2_DATA_W-1:0] ctovr_ctd_ctrl_noc2_data;
    logic                           ctd_ctovr_ctrl_noc2_rdy;
    
    logic                           full_line_ctd_merger_ctrl_noc2_val;
    logic   [`NOC_DATA_WIDTH-1:0]   full_line_ctd_merger_ctrl_noc2_data;
    logic                           full_line_merger_ctd_ctrl_noc2_rdy;
    
    logic                           udp_tx_in_udp_to_stream_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_src_ip_addr;
    logic   [`IP_ADDR_W-1:0]        udp_tx_in_udp_to_stream_dst_ip_addr;
    udp_pkt_hdr                     udp_tx_in_udp_to_stream_udp_hdr;
    logic   [MSG_TIMESTAMP_W-1:0]   udp_tx_in_udp_to_stream_timestamp;
    logic                           udp_to_stream_udp_tx_in_hdr_rdy;
    
    logic                           udp_tx_in_udp_to_stream_data_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_tx_in_udp_to_stream_data;
    logic                           udp_tx_in_udp_to_stream_data_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_tx_in_udp_to_stream_data_padbytes;
    logic                           udp_to_stream_udp_tx_in_data_rdy;
    
    logic                           udp_to_stream_udp_tx_out_hdr_val;
    logic   [`IP_ADDR_W-1:0]        udp_to_stream_udp_tx_out_src_ip;
    logic   [`IP_ADDR_W-1:0]        udp_to_stream_udp_tx_out_dst_ip;
    logic   [`TOT_LEN_W-1:0]        udp_to_stream_udp_tx_out_udp_len;
    logic   [`PROTOCOL_W-1:0]       udp_to_stream_udp_tx_out_protocol;
    logic   [MSG_TIMESTAMP_W-1:0]   udp_to_stream_udp_tx_out_timestamp;
    logic                           udp_tx_out_udp_to_stream_hdr_rdy;

    logic                           udp_to_stream_udp_tx_out_val;
    logic   [`MAC_INTERFACE_W-1:0]  udp_to_stream_udp_tx_out_data;
    logic                           udp_to_stream_udp_tx_out_last;
    logic   [`MAC_PADBYTES_W-1:0]   udp_to_stream_udp_tx_out_padbytes;
    logic                           udp_tx_out_udp_to_stream_rdy;

    noc_router_block #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) udp_tx_noc_router_block (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.src_router_block_data_noc0_data_N  (src_udp_tx_data_noc0_data_N )
        ,.src_router_block_data_noc0_data_E  (src_udp_tx_data_noc0_data_E )
        ,.src_router_block_data_noc0_data_S  (src_udp_tx_data_noc0_data_S )
        ,.src_router_block_data_noc0_data_W  (src_udp_tx_data_noc0_data_W )

        ,.src_router_block_data_noc0_val_N   (src_udp_tx_data_noc0_val_N  )
        ,.src_router_block_data_noc0_val_E   (src_udp_tx_data_noc0_val_E  )
        ,.src_router_block_data_noc0_val_S   (src_udp_tx_data_noc0_val_S  )
        ,.src_router_block_data_noc0_val_W   (src_udp_tx_data_noc0_val_W  )

        ,.router_block_src_data_noc0_yummy_N (udp_tx_src_data_noc0_yummy_N)
        ,.router_block_src_data_noc0_yummy_E (udp_tx_src_data_noc0_yummy_E)
        ,.router_block_src_data_noc0_yummy_S (udp_tx_src_data_noc0_yummy_S)
        ,.router_block_src_data_noc0_yummy_W (udp_tx_src_data_noc0_yummy_W)

        ,.router_block_dst_data_noc0_data_N  (udp_tx_dst_data_noc0_data_N )
        ,.router_block_dst_data_noc0_data_E  (udp_tx_dst_data_noc0_data_E )
        ,.router_block_dst_data_noc0_data_S  (udp_tx_dst_data_noc0_data_S )
        ,.router_block_dst_data_noc0_data_W  (udp_tx_dst_data_noc0_data_W )

        ,.router_block_dst_data_noc0_val_N   (udp_tx_dst_data_noc0_val_N  )
        ,.router_block_dst_data_noc0_val_E   (udp_tx_dst_data_noc0_val_E  )
        ,.router_block_dst_data_noc0_val_S   (udp_tx_dst_data_noc0_val_S  )
        ,.router_block_dst_data_noc0_val_W   (udp_tx_dst_data_noc0_val_W  )

        ,.dst_router_block_data_noc0_yummy_N (dst_udp_tx_data_noc0_yummy_N)
        ,.dst_router_block_data_noc0_yummy_E (dst_udp_tx_data_noc0_yummy_E)
        ,.dst_router_block_data_noc0_yummy_S (dst_udp_tx_data_noc0_yummy_S)
        ,.dst_router_block_data_noc0_yummy_W (dst_udp_tx_data_noc0_yummy_W)
        ,.src_router_block_ctrl_noc1_data_N  (src_udp_tx_ctrl_noc1_data_N )
        ,.src_router_block_ctrl_noc1_data_E  (src_udp_tx_ctrl_noc1_data_E )
        ,.src_router_block_ctrl_noc1_data_S  (src_udp_tx_ctrl_noc1_data_S )
        ,.src_router_block_ctrl_noc1_data_W  (src_udp_tx_ctrl_noc1_data_W )

        ,.src_router_block_ctrl_noc1_val_N   (src_udp_tx_ctrl_noc1_val_N  )
        ,.src_router_block_ctrl_noc1_val_E   (src_udp_tx_ctrl_noc1_val_E  )
        ,.src_router_block_ctrl_noc1_val_S   (src_udp_tx_ctrl_noc1_val_S  )
        ,.src_router_block_ctrl_noc1_val_W   (src_udp_tx_ctrl_noc1_val_W  )

        ,.router_block_src_ctrl_noc1_yummy_N (udp_tx_src_ctrl_noc1_yummy_N)
        ,.router_block_src_ctrl_noc1_yummy_E (udp_tx_src_ctrl_noc1_yummy_E)
        ,.router_block_src_ctrl_noc1_yummy_S (udp_tx_src_ctrl_noc1_yummy_S)
        ,.router_block_src_ctrl_noc1_yummy_W (udp_tx_src_ctrl_noc1_yummy_W)

        ,.router_block_dst_ctrl_noc1_data_N  (udp_tx_dst_ctrl_noc1_data_N )
        ,.router_block_dst_ctrl_noc1_data_E  (udp_tx_dst_ctrl_noc1_data_E )
        ,.router_block_dst_ctrl_noc1_data_S  (udp_tx_dst_ctrl_noc1_data_S )
        ,.router_block_dst_ctrl_noc1_data_W  (udp_tx_dst_ctrl_noc1_data_W )

        ,.router_block_dst_ctrl_noc1_val_N   (udp_tx_dst_ctrl_noc1_val_N  )
        ,.router_block_dst_ctrl_noc1_val_E   (udp_tx_dst_ctrl_noc1_val_E  )
        ,.router_block_dst_ctrl_noc1_val_S   (udp_tx_dst_ctrl_noc1_val_S  )
        ,.router_block_dst_ctrl_noc1_val_W   (udp_tx_dst_ctrl_noc1_val_W  )

        ,.dst_router_block_ctrl_noc1_yummy_N (dst_udp_tx_ctrl_noc1_yummy_N)
        ,.dst_router_block_ctrl_noc1_yummy_E (dst_udp_tx_ctrl_noc1_yummy_E)
        ,.dst_router_block_ctrl_noc1_yummy_S (dst_udp_tx_ctrl_noc1_yummy_S)
        ,.dst_router_block_ctrl_noc1_yummy_W (dst_udp_tx_ctrl_noc1_yummy_W)
        ,.src_router_block_ctrl_noc2_data_N  (src_udp_tx_ctrl_noc2_data_N )
        ,.src_router_block_ctrl_noc2_data_E  (src_udp_tx_ctrl_noc2_data_E )
        ,.src_router_block_ctrl_noc2_data_S  (src_udp_tx_ctrl_noc2_data_S )
        ,.src_router_block_ctrl_noc2_data_W  (src_udp_tx_ctrl_noc2_data_W )

        ,.src_router_block_ctrl_noc2_val_N   (src_udp_tx_ctrl_noc2_val_N  )
        ,.src_router_block_ctrl_noc2_val_E   (src_udp_tx_ctrl_noc2_val_E  )
        ,.src_router_block_ctrl_noc2_val_S   (src_udp_tx_ctrl_noc2_val_S  )
        ,.src_router_block_ctrl_noc2_val_W   (src_udp_tx_ctrl_noc2_val_W  )

        ,.router_block_src_ctrl_noc2_yummy_N (udp_tx_src_ctrl_noc2_yummy_N)
        ,.router_block_src_ctrl_noc2_yummy_E (udp_tx_src_ctrl_noc2_yummy_E)
        ,.router_block_src_ctrl_noc2_yummy_S (udp_tx_src_ctrl_noc2_yummy_S)
        ,.router_block_src_ctrl_noc2_yummy_W (udp_tx_src_ctrl_noc2_yummy_W)

        ,.router_block_dst_ctrl_noc2_data_N  (udp_tx_dst_ctrl_noc2_data_N )
        ,.router_block_dst_ctrl_noc2_data_E  (udp_tx_dst_ctrl_noc2_data_E )
        ,.router_block_dst_ctrl_noc2_data_S  (udp_tx_dst_ctrl_noc2_data_S )
        ,.router_block_dst_ctrl_noc2_data_W  (udp_tx_dst_ctrl_noc2_data_W )

        ,.router_block_dst_ctrl_noc2_val_N   (udp_tx_dst_ctrl_noc2_val_N  )
        ,.router_block_dst_ctrl_noc2_val_E   (udp_tx_dst_ctrl_noc2_val_E  )
        ,.router_block_dst_ctrl_noc2_val_S   (udp_tx_dst_ctrl_noc2_val_S  )
        ,.router_block_dst_ctrl_noc2_val_W   (udp_tx_dst_ctrl_noc2_val_W  )

        ,.dst_router_block_ctrl_noc2_yummy_N (dst_udp_tx_ctrl_noc2_yummy_N)
        ,.dst_router_block_ctrl_noc2_yummy_E (dst_udp_tx_ctrl_noc2_yummy_E)
        ,.dst_router_block_ctrl_noc2_yummy_S (dst_udp_tx_ctrl_noc2_yummy_S)
        ,.dst_router_block_ctrl_noc2_yummy_W (dst_udp_tx_ctrl_noc2_yummy_W)

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

    assign ctovr_router_ctrl_noc1_yummy = 1'b0;
    assign vrtoc_router_ctrl_noc1_val = 1'b0;
    assign vrtoc_router_ctrl_noc2_val = 1'b0;
    assign vrtoc_router_ctrl_noc2_data = '0;
    assign vrtoc_router_ctrl_noc1_data = '0;
    
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) data_noc0_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        
        ,.src_ctovr_data    (router_ctovr_data_noc0_data        )
        ,.src_ctovr_val     (router_ctovr_data_noc0_val         )
        ,.ctovr_src_yummy   (ctovr_router_data_noc0_yummy       )

        ,.ctovr_dst_data    (ctovr_merger_data_noc0_data        )
        ,.ctovr_dst_val     (ctovr_merger_data_noc0_val         )
        ,.dst_ctovr_rdy     (merger_ctovr_data_noc0_rdy         )
    );

    beehive_valrdy_to_credit #(
        .NOC_DATA_W (`NOC_DATA_WIDTH    )
    ) data_noc0_beehive_valrdy_to_credit (
         .clk       (clk)
        ,.reset     (rst)

        ,.src_vrtoc_data    (udp_tx_out_vrtoc_data_noc0_data    )
        ,.src_vrtoc_val     (udp_tx_out_vrtoc_data_noc0_val     )
        ,.vrtoc_src_rdy     (vrtoc_udp_tx_out_data_noc0_rdy     )

        ,.vrtoc_dst_data    (vrtoc_router_data_noc0_data        )
        ,.vrtoc_dst_val     (vrtoc_router_data_noc0_val         )
		,.dst_vrtoc_yummy   (router_vrtoc_data_noc0_yummy       )
    );
    
    beehive_credit_to_valrdy #(
        .NOC_DATA_W (`CTRL_NOC2_DATA_W  )
    ) ctrl_noc2_beehive_credit_to_valrdy (
         .clk   (clk)
        ,.reset (rst)
        
        ,.src_ctovr_data    (router_ctovr_ctrl_noc2_data        )
        ,.src_ctovr_val     (router_ctovr_ctrl_noc2_val         )
        ,.ctovr_src_yummy   (ctovr_router_ctrl_noc2_yummy       )

        ,.ctovr_dst_data    (ctovr_ctd_ctrl_noc2_data           )
        ,.ctovr_dst_val     (ctovr_ctd_ctrl_noc2_val            )
        ,.dst_ctovr_rdy     (ctd_ctovr_ctrl_noc2_rdy            )
    );

    noc_ctrl_to_data ctd (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_noc_ctd_val   (ctovr_ctd_ctrl_noc2_val            )
        ,.src_noc_ctd_data  (ctovr_ctd_ctrl_noc2_data           )
        ,.noc_ctd_src_rdy   (ctd_ctovr_ctrl_noc2_rdy            )
    
        ,.noc_ctd_dst_val   (full_line_ctd_merger_ctrl_noc2_val )
        ,.noc_ctd_dst_data  (full_line_ctd_merger_ctrl_noc2_data)
        ,.dst_noc_ctd_rdy   (full_line_merger_ctd_ctrl_noc2_rdy )
    );

    beehive_noc_prio_merger #(
         .NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`MSG_LENGTH_WIDTH  )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.num_sources       (2)
    ) merger (   
         .clk   (clk    )
        ,.rst_n (~rst   )
    
        ,.src0_merger_vr_noc_val    (full_line_ctd_merger_ctrl_noc2_val     )
        ,.src0_merger_vr_noc_dat    (full_line_ctd_merger_ctrl_noc2_data    )
        ,.merger_src0_vr_noc_rdy    (full_line_merger_ctd_ctrl_noc2_rdy     )
    
        ,.src1_merger_vr_noc_val    (ctovr_merger_data_noc0_val             )
        ,.src1_merger_vr_noc_dat    (ctovr_merger_data_noc0_data            )
        ,.merger_src1_vr_noc_rdy    (merger_ctovr_data_noc0_rdy             )
    
        ,.src2_merger_vr_noc_val    ()
        ,.src2_merger_vr_noc_dat    ()
        ,.merger_src2_vr_noc_rdy    ()
    
        ,.src3_merger_vr_noc_val    ()
        ,.src3_merger_vr_noc_dat    ()
        ,.merger_src3_vr_noc_rdy    ()
    
        ,.src4_merger_vr_noc_val    ()
        ,.src4_merger_vr_noc_dat    ()
        ,.merger_src4_vr_noc_rdy    ()
    
        ,.merger_dst_vr_noc_val     (merger_udp_tx_in_val                   )
        ,.merger_dst_vr_noc_dat     (merger_udp_tx_in_data                  )
        ,.dst_merger_vr_noc_rdy     (udp_tx_in_merger_rdy                   )
    );
    
   udp_tx_noc_in tx_noc_in (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_tx_in_val              (merger_udp_tx_in_val       )
        ,.noc0_ctovr_udp_tx_in_data             (merger_udp_tx_in_data      )
        ,.udp_tx_in_noc0_ctovr_rdy              (udp_tx_in_merger_rdy       )
        
        ,.udp_tx_in_udp_to_stream_hdr_val       (udp_tx_in_udp_to_stream_hdr_val        )
        ,.udp_tx_in_udp_to_stream_src_ip_addr   (udp_tx_in_udp_to_stream_src_ip_addr    )
        ,.udp_tx_in_udp_to_stream_dst_ip_addr   (udp_tx_in_udp_to_stream_dst_ip_addr    )
        ,.udp_tx_in_udp_to_stream_udp_hdr       (udp_tx_in_udp_to_stream_udp_hdr        )
        ,.udp_tx_in_udp_to_stream_timestamp     (udp_tx_in_udp_to_stream_timestamp      )
        ,.udp_to_stream_udp_tx_in_hdr_rdy       (udp_to_stream_udp_tx_in_hdr_rdy        )
                                                                                        
        ,.udp_tx_in_udp_to_stream_data_val      (udp_tx_in_udp_to_stream_data_val       )
        ,.udp_tx_in_udp_to_stream_data          (udp_tx_in_udp_to_stream_data           )
        ,.udp_tx_in_udp_to_stream_data_last     (udp_tx_in_udp_to_stream_data_last      )
        ,.udp_tx_in_udp_to_stream_data_padbytes (udp_tx_in_udp_to_stream_data_padbytes  )
        ,.udp_to_stream_udp_tx_in_data_rdy      (udp_to_stream_udp_tx_in_data_rdy       )
    );

    udp_to_stream #(
        .DATA_WIDTH (`MAC_INTERFACE_W   )
    ) udp_to_stream (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.src_udp_to_stream_hdr_val         (udp_tx_in_udp_to_stream_hdr_val        )
        ,.src_udp_to_stream_src_ip_addr     (udp_tx_in_udp_to_stream_src_ip_addr    )
        ,.src_udp_to_stream_dst_ip_addr     (udp_tx_in_udp_to_stream_dst_ip_addr    )
        ,.src_udp_to_stream_udp_hdr         (udp_tx_in_udp_to_stream_udp_hdr        )
        ,.src_udp_to_stream_timestamp       (udp_tx_in_udp_to_stream_timestamp      )
        ,.udp_to_stream_src_hdr_rdy         (udp_to_stream_udp_tx_in_hdr_rdy        )
        
        ,.src_udp_to_stream_data_val        (udp_tx_in_udp_to_stream_data_val       )
        ,.src_udp_to_stream_data            (udp_tx_in_udp_to_stream_data           )
        ,.src_udp_to_stream_data_last       (udp_tx_in_udp_to_stream_data_last      )
        ,.src_udp_to_stream_data_padbytes   (udp_tx_in_udp_to_stream_data_padbytes  )
        ,.udp_to_stream_src_data_rdy        (udp_to_stream_udp_tx_in_data_rdy       )
    
        ,.udp_to_stream_dst_hdr_val         (udp_to_stream_udp_tx_out_hdr_val       )
        ,.udp_to_stream_dst_src_ip          (udp_to_stream_udp_tx_out_src_ip        )
        ,.udp_to_stream_dst_dst_ip          (udp_to_stream_udp_tx_out_dst_ip        )
        ,.udp_to_stream_dst_udp_len         (udp_to_stream_udp_tx_out_udp_len       )
        ,.udp_to_stream_dst_protocol        (udp_to_stream_udp_tx_out_protocol      )
        ,.udp_to_stream_dst_timestamp       (udp_to_stream_udp_tx_out_timestamp     )
        ,.dst_udp_to_stream_hdr_rdy         (udp_tx_out_udp_to_stream_hdr_rdy       )
        
        ,.udp_to_stream_dst_val             (udp_to_stream_udp_tx_out_val           )
        ,.udp_to_stream_dst_data            (udp_to_stream_udp_tx_out_data          )
        ,.udp_to_stream_dst_last            (udp_to_stream_udp_tx_out_last          )
        ,.udp_to_stream_dst_padbytes        (udp_to_stream_udp_tx_out_padbytes      )
        ,.dst_udp_to_stream_rdy             (udp_tx_out_udp_to_stream_rdy           )
    );

    udp_tx_noc_out #(
         .SRC_X (SRC_X  )
        ,.SRC_Y (SRC_Y  )
    ) tx_noc_out (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_tx_out_noc0_vrtoc_val         (udp_tx_out_vrtoc_data_noc0_val     )
        ,.udp_tx_out_noc0_vrtoc_data        (udp_tx_out_vrtoc_data_noc0_data    )
        ,.noc0_vrtoc_udp_tx_out_rdy         (vrtoc_udp_tx_out_data_noc0_rdy     )
                                                                                
        ,.udp_to_stream_udp_tx_out_hdr_val  (udp_to_stream_udp_tx_out_hdr_val   )
        ,.udp_to_stream_udp_tx_out_src_ip   (udp_to_stream_udp_tx_out_src_ip    )
        ,.udp_to_stream_udp_tx_out_dst_ip   (udp_to_stream_udp_tx_out_dst_ip    )
        ,.udp_to_stream_udp_tx_out_udp_len  (udp_to_stream_udp_tx_out_udp_len   )
        ,.udp_to_stream_udp_tx_out_protocol (udp_to_stream_udp_tx_out_protocol  )
        ,.udp_to_stream_udp_tx_out_timestamp(udp_to_stream_udp_tx_out_timestamp )
        ,.udp_tx_out_udp_to_stream_hdr_rdy  (udp_tx_out_udp_to_stream_hdr_rdy   )
                                                                                
        ,.udp_to_stream_udp_tx_out_val      (udp_to_stream_udp_tx_out_val       )
        ,.udp_to_stream_udp_tx_out_data     (udp_to_stream_udp_tx_out_data      )
        ,.udp_to_stream_udp_tx_out_last     (udp_to_stream_udp_tx_out_last      )
        ,.udp_to_stream_udp_tx_out_padbytes (udp_to_stream_udp_tx_out_padbytes  )
        ,.udp_tx_out_udp_to_stream_rdy      (udp_tx_out_udp_to_stream_rdy       )
    );


endmodule
