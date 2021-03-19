`include "ip_rewrite_manager_defs.svh"
module ip_rewrite_manager_tiles #(
     parameter RX_SRC_X = -1
    ,parameter RX_SRC_Y = -1
    ,parameter TX_SRC_X = -1
    ,parameter TX_SRC_Y = -1
)(
     input clk
    ,input rst

    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_rx_noc0_data_W

    ,input                                          src_ip_rewrite_manager_rx_noc0_val_N
    ,input                                          src_ip_rewrite_manager_rx_noc0_val_E
    ,input                                          src_ip_rewrite_manager_rx_noc0_val_S
    ,input                                          src_ip_rewrite_manager_rx_noc0_val_W

    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_N
    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_E
    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_S
    ,output                                         ip_rewrite_manager_rx_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_rx_dst_noc0_data_W

    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_N
    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_E
    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_S
    ,output                                         ip_rewrite_manager_rx_dst_noc0_val_W

    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_N
    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_E
    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_S
    ,input                                          dst_ip_rewrite_manager_rx_noc0_yummy_W
    
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_N
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_E
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_S
    ,input [`NOC_DATA_WIDTH-1:0]                    src_ip_rewrite_manager_tx_noc0_data_W

    ,input                                          src_ip_rewrite_manager_tx_noc0_val_N
    ,input                                          src_ip_rewrite_manager_tx_noc0_val_E
    ,input                                          src_ip_rewrite_manager_tx_noc0_val_S
    ,input                                          src_ip_rewrite_manager_tx_noc0_val_W

    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_N
    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_E
    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_S
    ,output                                         ip_rewrite_manager_tx_src_noc0_yummy_W

    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_N
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_E
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_S
    ,output [`NOC_DATA_WIDTH-1:0]                   ip_rewrite_manager_tx_dst_noc0_data_W

    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_N
    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_E
    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_S
    ,output                                         ip_rewrite_manager_tx_dst_noc0_val_W

    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_N
    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_E
    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_S
    ,input                                          dst_ip_rewrite_manager_tx_noc0_yummy_W
);
    
    
    logic                           ip_rewrite_manager_rx_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_manager_rx_merger_data;    
    logic                           merger_ip_rewrite_manager_rx_rdy;
    
    logic                           splitter_ip_rewrite_manager_rx_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_ip_rewrite_manager_rx_data;
    logic                           ip_rewrite_manager_rx_splitter_rdy;     
    
    logic                           ip_rewrite_manager_tx_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   ip_rewrite_manager_tx_merger_data;    
    logic                           merger_ip_rewrite_manager_tx_rdy;
    
    logic                           splitter_ip_rewrite_manager_tx_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_ip_rewrite_manager_tx_data;
    logic                           ip_rewrite_manager_tx_splitter_rdy;     
    
    logic                           rd_rx_buf_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   rd_rx_buf_merger_data;    
    logic                           merger_rd_rx_buf_rdy;
    
    logic                           splitter_rd_rx_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_rd_rx_buf_data;
    logic                           rd_rx_buf_splitter_rdy;     

    logic                           wr_tx_buf_merger_val;
    logic   [`NOC_DATA_WIDTH-1:0]   wr_tx_buf_merger_data;    
    logic                           merger_wr_tx_buf_rdy;
    
    logic                           splitter_wr_tx_buf_val;
    logic   [`NOC_DATA_WIDTH-1:0]   splitter_wr_tx_buf_data;
    logic                           wr_tx_buf_splitter_rdy;     
   
    
    ip_rewrite_manager_noc_if #(
         .RX_SRC_X  (RX_SRC_X   )
        ,.RX_SRC_Y  (RX_SRC_Y   )
        ,.TX_SRC_X  (TX_SRC_X   )
        ,.TX_SRC_Y  (TX_SRC_Y   )
    ) noc_if (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_ip_rewrite_manager_rx_noc0_data_N     (src_ip_rewrite_manager_rx_noc0_data_N )
        ,.src_ip_rewrite_manager_rx_noc0_data_E     (src_ip_rewrite_manager_rx_noc0_data_E )
        ,.src_ip_rewrite_manager_rx_noc0_data_S     (src_ip_rewrite_manager_rx_noc0_data_S )
        ,.src_ip_rewrite_manager_rx_noc0_data_W     (src_ip_rewrite_manager_rx_noc0_data_W )
                                                                                           
        ,.src_ip_rewrite_manager_rx_noc0_val_N      (src_ip_rewrite_manager_rx_noc0_val_N  )
        ,.src_ip_rewrite_manager_rx_noc0_val_E      (src_ip_rewrite_manager_rx_noc0_val_E  )
        ,.src_ip_rewrite_manager_rx_noc0_val_S      (src_ip_rewrite_manager_rx_noc0_val_S  )
        ,.src_ip_rewrite_manager_rx_noc0_val_W      (src_ip_rewrite_manager_rx_noc0_val_W  )
                                                                                           
        ,.ip_rewrite_manager_rx_src_noc0_yummy_N    (ip_rewrite_manager_rx_src_noc0_yummy_N)
        ,.ip_rewrite_manager_rx_src_noc0_yummy_E    (ip_rewrite_manager_rx_src_noc0_yummy_E)
        ,.ip_rewrite_manager_rx_src_noc0_yummy_S    (ip_rewrite_manager_rx_src_noc0_yummy_S)
        ,.ip_rewrite_manager_rx_src_noc0_yummy_W    (ip_rewrite_manager_rx_src_noc0_yummy_W)
                                                                                           
        ,.ip_rewrite_manager_rx_dst_noc0_data_N     (ip_rewrite_manager_rx_dst_noc0_data_N )
        ,.ip_rewrite_manager_rx_dst_noc0_data_E     (ip_rewrite_manager_rx_dst_noc0_data_E )
        ,.ip_rewrite_manager_rx_dst_noc0_data_S     (ip_rewrite_manager_rx_dst_noc0_data_S )
        ,.ip_rewrite_manager_rx_dst_noc0_data_W     (ip_rewrite_manager_rx_dst_noc0_data_W )
                                                                                           
        ,.ip_rewrite_manager_rx_dst_noc0_val_N      (ip_rewrite_manager_rx_dst_noc0_val_N  )
        ,.ip_rewrite_manager_rx_dst_noc0_val_E      (ip_rewrite_manager_rx_dst_noc0_val_E  )
        ,.ip_rewrite_manager_rx_dst_noc0_val_S      (ip_rewrite_manager_rx_dst_noc0_val_S  )
        ,.ip_rewrite_manager_rx_dst_noc0_val_W      (ip_rewrite_manager_rx_dst_noc0_val_W  )
                                                                                           
        ,.dst_ip_rewrite_manager_rx_noc0_yummy_N    (dst_ip_rewrite_manager_rx_noc0_yummy_N)
        ,.dst_ip_rewrite_manager_rx_noc0_yummy_E    (dst_ip_rewrite_manager_rx_noc0_yummy_E)
        ,.dst_ip_rewrite_manager_rx_noc0_yummy_S    (dst_ip_rewrite_manager_rx_noc0_yummy_S)
        ,.dst_ip_rewrite_manager_rx_noc0_yummy_W    (dst_ip_rewrite_manager_rx_noc0_yummy_W)
                                                                                           
        ,.src_ip_rewrite_manager_tx_noc0_data_N     (src_ip_rewrite_manager_tx_noc0_data_N )
        ,.src_ip_rewrite_manager_tx_noc0_data_E     (src_ip_rewrite_manager_tx_noc0_data_E )
        ,.src_ip_rewrite_manager_tx_noc0_data_S     (src_ip_rewrite_manager_tx_noc0_data_S )
        ,.src_ip_rewrite_manager_tx_noc0_data_W     (src_ip_rewrite_manager_tx_noc0_data_W )
                                                                                           
        ,.src_ip_rewrite_manager_tx_noc0_val_N      (src_ip_rewrite_manager_tx_noc0_val_N  )
        ,.src_ip_rewrite_manager_tx_noc0_val_E      (src_ip_rewrite_manager_tx_noc0_val_E  )
        ,.src_ip_rewrite_manager_tx_noc0_val_S      (src_ip_rewrite_manager_tx_noc0_val_S  )
        ,.src_ip_rewrite_manager_tx_noc0_val_W      (src_ip_rewrite_manager_tx_noc0_val_W  )
                                                                                           
        ,.ip_rewrite_manager_tx_src_noc0_yummy_N    (ip_rewrite_manager_tx_src_noc0_yummy_N)
        ,.ip_rewrite_manager_tx_src_noc0_yummy_E    (ip_rewrite_manager_tx_src_noc0_yummy_E)
        ,.ip_rewrite_manager_tx_src_noc0_yummy_S    (ip_rewrite_manager_tx_src_noc0_yummy_S)
        ,.ip_rewrite_manager_tx_src_noc0_yummy_W    (ip_rewrite_manager_tx_src_noc0_yummy_W)
                                                                                           
        ,.ip_rewrite_manager_tx_dst_noc0_data_N     (ip_rewrite_manager_tx_dst_noc0_data_N )
        ,.ip_rewrite_manager_tx_dst_noc0_data_E     (ip_rewrite_manager_tx_dst_noc0_data_E )
        ,.ip_rewrite_manager_tx_dst_noc0_data_S     (ip_rewrite_manager_tx_dst_noc0_data_S )
        ,.ip_rewrite_manager_tx_dst_noc0_data_W     (ip_rewrite_manager_tx_dst_noc0_data_W )
                                                                                           
        ,.ip_rewrite_manager_tx_dst_noc0_val_N      (ip_rewrite_manager_tx_dst_noc0_val_N  )
        ,.ip_rewrite_manager_tx_dst_noc0_val_E      (ip_rewrite_manager_tx_dst_noc0_val_E  )
        ,.ip_rewrite_manager_tx_dst_noc0_val_S      (ip_rewrite_manager_tx_dst_noc0_val_S  )
        ,.ip_rewrite_manager_tx_dst_noc0_val_W      (ip_rewrite_manager_tx_dst_noc0_val_W  )
                                                                                           
        ,.dst_ip_rewrite_manager_tx_noc0_yummy_N    (dst_ip_rewrite_manager_tx_noc0_yummy_N)
        ,.dst_ip_rewrite_manager_tx_noc0_yummy_E    (dst_ip_rewrite_manager_tx_noc0_yummy_E)
        ,.dst_ip_rewrite_manager_tx_noc0_yummy_S    (dst_ip_rewrite_manager_tx_noc0_yummy_S)
        ,.dst_ip_rewrite_manager_tx_noc0_yummy_W    (dst_ip_rewrite_manager_tx_noc0_yummy_W)
                                                                                           
        ,.splitter_ip_rewrite_manager_rx_val        (splitter_ip_rewrite_manager_rx_val    )
        ,.splitter_ip_rewrite_manager_rx_data       (splitter_ip_rewrite_manager_rx_data   )
        ,.ip_rewrite_manager_rx_splitter_rdy        (ip_rewrite_manager_rx_splitter_rdy    )
                                                                                           
        ,.ip_rewrite_manager_rx_merger_val          (ip_rewrite_manager_rx_merger_val      )
        ,.ip_rewrite_manager_rx_merger_data         (ip_rewrite_manager_rx_merger_data     )
        ,.merger_ip_rewrite_manager_rx_rdy          (merger_ip_rewrite_manager_rx_rdy      )
                                                                                           
        ,.splitter_ip_rewrite_manager_tx_val        (splitter_ip_rewrite_manager_tx_val    )
        ,.splitter_ip_rewrite_manager_tx_data       (splitter_ip_rewrite_manager_tx_data   )
        ,.ip_rewrite_manager_tx_splitter_rdy        (ip_rewrite_manager_tx_splitter_rdy    )
                                                                                           
        ,.ip_rewrite_manager_tx_merger_val          (ip_rewrite_manager_tx_merger_val      )
        ,.ip_rewrite_manager_tx_merger_data         (ip_rewrite_manager_tx_merger_data     )
        ,.merger_ip_rewrite_manager_tx_rdy          (merger_ip_rewrite_manager_tx_rdy      )
                                                                                           
        ,.splitter_rd_rx_buf_val                    (splitter_rd_rx_buf_val                )
        ,.splitter_rd_rx_buf_data                   (splitter_rd_rx_buf_data               )
        ,.rd_rx_buf_splitter_rdy                    (rd_rx_buf_splitter_rdy                )
                                                                                           
        ,.rd_rx_buf_merger_val                      (rd_rx_buf_merger_val                  )
        ,.rd_rx_buf_merger_data                     (rd_rx_buf_merger_data                 )
        ,.merger_rd_rx_buf_rdy                      (merger_rd_rx_buf_rdy                  )
                                                                                           
        ,.splitter_wr_tx_buf_val                    (splitter_wr_tx_buf_val                )
        ,.splitter_wr_tx_buf_data                   (splitter_wr_tx_buf_data               )
        ,.wr_tx_buf_splitter_rdy                    (wr_tx_buf_splitter_rdy                )
                                                                                           
        ,.wr_tx_buf_merger_val                      (wr_tx_buf_merger_val                  )
        ,.wr_tx_buf_merger_data                     (wr_tx_buf_merger_data                 )
        ,.merger_wr_tx_buf_rdy                      (merger_wr_tx_buf_rdy                  )
    );

    ip_rewrite_manager #(
         .RX_SRC_X  (RX_SRC_X   )
        ,.RX_SRC_Y  (RX_SRC_Y   )
        ,.TX_SRC_X  (TX_SRC_X   )
        ,.TX_SRC_Y  (TX_SRC_Y   )
    ) ip_rewrite_manager (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_ip_rewrite_manager_rx_val  (splitter_ip_rewrite_manager_rx_val )
        ,.noc0_ctovr_ip_rewrite_manager_rx_data (splitter_ip_rewrite_manager_rx_data)
        ,.ip_rewrite_manager_rx_noc0_ctovr_rdy  (ip_rewrite_manager_rx_splitter_rdy )
        
        ,.ip_rewrite_manager_rx_noc0_vrtoc_val  (ip_rewrite_manager_rx_merger_val   )
        ,.ip_rewrite_manager_rx_noc0_vrtoc_data (ip_rewrite_manager_rx_merger_data  )
        ,.noc0_vrtoc_ip_rewrite_manager_rx_rdy  (merger_ip_rewrite_manager_rx_rdy   )
        
        ,.noc0_ctovr_ip_rewrite_manager_tx_val  (splitter_ip_rewrite_manager_tx_val )
        ,.noc0_ctovr_ip_rewrite_manager_tx_data (splitter_ip_rewrite_manager_tx_data)
        ,.ip_rewrite_manager_tx_noc0_ctovr_rdy  (ip_rewrite_manager_tx_splitter_rdy )
        
        ,.ip_rewrite_manager_tx_noc0_vrtoc_val  (ip_rewrite_manager_tx_merger_val   )
        ,.ip_rewrite_manager_tx_noc0_vrtoc_data (ip_rewrite_manager_tx_merger_data  )
        ,.noc0_vrtoc_ip_rewrite_manager_tx_rdy  (merger_ip_rewrite_manager_tx_rdy   )
        
        ,.noc0_ctovr_rd_rx_buf_val              (splitter_rd_rx_buf_val             )
        ,.noc0_ctovr_rd_rx_buf_data             (splitter_rd_rx_buf_data            )
        ,.rd_rx_buf_noc0_ctovr_rdy              (rd_rx_buf_splitter_rdy             )
        
        ,.rd_rx_buf_noc0_vrtoc_val              (rd_rx_buf_merger_val               )
        ,.rd_rx_buf_noc0_vrtoc_data             (rd_rx_buf_merger_data              )
        ,.noc0_vrtoc_rd_rx_buf_rdy              (merger_rd_rx_buf_rdy               )
        
        ,.noc0_ctovr_wr_tx_buf_val              (splitter_wr_tx_buf_val             )
        ,.noc0_ctovr_wr_tx_buf_data             (splitter_wr_tx_buf_data            )
        ,.wr_tx_buf_noc0_ctovr_rdy              (wr_tx_buf_splitter_rdy             )
        
        ,.wr_tx_buf_noc0_vrtoc_val              (wr_tx_buf_merger_val               )
        ,.wr_tx_buf_noc0_vrtoc_data             (wr_tx_buf_merger_data              )
        ,.noc0_vrtoc_wr_tx_buf_rdy              (merger_wr_tx_buf_rdy               )
    );

endmodule
