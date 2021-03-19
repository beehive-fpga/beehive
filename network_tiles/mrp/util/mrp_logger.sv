`include "mrp_defs.svh"
module mrp_logger #(
    parameter LOG_DEPTH_LOG2 = 8
) (
     input clk
    ,input rst

    ,input                  recv_mrp_hdr_val
    ,input  [31:0]          mrp_pkts_recved
    ,input  [31:0]          mrp_pkts_dropped
    ,input  [MRP_PKT_HDR_W-1:0] recv_mrp_hdr
    
    ,input                  rd_cmd_queue_empty
    ,output                 rd_cmd_queue_rd_req
    ,input          [63:0]  rd_cmd_queue_rd_data
    
    ,output                 rd_resp_val
    ,output logic   [63:0]  shell_reg_rd_data
);
    localparam LOG_DATA_W = 32 + 32 + MRP_ID_W + MRP_PKT_NUM_W;
    localparam LOG_W_CEIL_POW = (LOG_DATA_W & (LOG_DATA_W - 1)) == 0
                                ? LOG_DATA_W
                                : 2 ** ($clog2(LOG_DATA_W));
    localparam PADDING_W = LOG_W_CEIL_POW - LOG_DATA_W;

    localparam MEM_DATA_W_BYTES = (LOG_DATA_W + PADDING_W)/8;
    localparam MEM_CAPACITY = (MEM_DATA_W_BYTES) * (2**LOG_DEPTH_LOG2);
    localparam MEM_ADDR_W = $clog2(MEM_CAPACITY);
    
    typedef struct packed {
        logic   [31:0]              pkts_recved;
        logic   [31:0]              pkts_dropped;
        logic   [MRP_ID_W-1:0]      req_id;
        logic   [MRP_PKT_NUM_W-1:0] pkt_num;
    } log_struct;

    logic has_looped;
    logic   [MEM_ADDR_W-1:0]    logger_curr_wr_addr;

    logic                       log_rd_req_val;
    logic   [MEM_ADDR_W-1:0]    log_rd_req_addr;
    logic                       log_rd_resp_val;
    logic   [63:0]              log_rd_resp_data;
    
    log_struct log_next;

    always_comb begin
        log_next = '0;
        log_next.pkts_recved = mrp_pkts_recved;
        log_next.pkts_dropped = mrp_pkts_dropped;
        log_next.req_id = recv_mrp_hdr[MRP_PKT_HDR_W-1 -: MRP_ID_W];
        log_next.pkt_num = recv_mrp_hdr[MRP_PKT_HDR_W-1 - MRP_ID_W -: MRP_PKT_NUM_W];
    end
    
    logger_addr_mux #(
        .LOG_ADDR_W (MEM_ADDR_W)
    ) log_addr_mux (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.rd_cmd_queue_empty    (rd_cmd_queue_empty )
        ,.rd_cmd_queue_rd_req   (rd_cmd_queue_rd_req)
        ,.rd_cmd_queue_rd_data  (rd_cmd_queue_rd_data)

        ,.rd_resp_val           (rd_resp_val        )
        ,.rd_cmd_resp           (shell_reg_rd_data  )

        ,.curr_log_wr_addr  (logger_curr_wr_addr    )
        ,.has_wrapped       (has_looped             )

        ,.log_rd_req_val    (log_rd_req_val         )
        ,.log_rd_req_addr   (log_rd_req_addr        )

        ,.log_rd_resp_val   (log_rd_resp_val        )
        ,.log_rd_resp_data  (log_rd_resp_data       )
    );

    mini_logger #(
         .INPUT_W           (LOG_DATA_W )
        ,.LOG_DATA_W        (LOG_DATA_W )
        ,.MEM_DEPTH_LOG2    (LOG_DEPTH_LOG2)
        ,.OUTPUT_W          (64)
        ,.PADDING_W         (PADDING_W)
    ) logger (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.logging_active    (1'b1)

        ,.wr_val            (recv_mrp_hdr_val       )
        ,.wr_data           (log_next               )

        ,.rd_req_val        (log_rd_req_val         )
        ,.rd_req_addr       (log_rd_req_addr        )

        ,.rd_resp_val       (log_rd_resp_val        )
        ,.rd_resp_data      (log_rd_resp_data       )
    
        ,.curr_wr_addr      (logger_curr_wr_addr    )
        ,.has_looped        (has_looped             )
    );

endmodule
