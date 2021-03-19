`include "packet_defs.vh"
`include "soc_defs.vh"
`include "mrp_defs.svh"
module early_mrp_logger (
     input clk
    ,input rst

    ,input                          src_early_logger_rx_data_val
    ,input  [`MAC_INTERFACE_W-1:0]  src_early_logger_rx_data    
    ,input                          src_early_logger_rx_last    
    ,input  [`MAC_PADBYTES_W-1:0]   src_early_logger_rx_padbytes
    ,input                          src_early_logger_rx_rdy
    ,input  [`UDP_CHKSUM_W-1:0]     src_early_logger_chksum
        
    ,input                          early_logger_rd_cmd_queue_empty
    ,output                         early_logger_rd_cmd_queue_rd_req
    ,input          [63:0]          early_logger_rd_cmd_queue_rd_data

    ,output                         early_logger_rd_resp_val
    ,output logic   [63:0]          early_logger_shell_reg_rd_data
);

typedef enum logic {
    READY = 1'b0,
    WAIT = 1'b1,
    UND = 'X
} state_e;

    state_e state_reg;
    state_e state_next;

    logic   wr_log_entry_next;
    logic   wr_log_entry_reg;

    logic   [MRP_PKT_HDR_W-1:0] log_entry_next;
    logic   [MRP_PKT_HDR_W-1:0] log_entry_reg;

    logic   [31:0]              pkts_recv_reg;
    logic   [31:0]              pkts_recv_next;
    logic   [31:0]              pkts_dropped_reg;
    logic   [31:0]              pkts_dropped_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            wr_log_entry_reg <= '0;
            log_entry_reg <= '0;
            pkts_recv_reg <= '0;
            pkts_dropped_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            wr_log_entry_reg <= wr_log_entry_next;
            log_entry_reg <= log_entry_next;
            pkts_recv_reg <= pkts_recv_next;
            pkts_dropped_reg <= pkts_dropped_next;
        end
    end

    assign log_entry_next = src_early_logger_rx_data[0 +: MRP_PKT_HDR_W];

    always_comb begin            
        wr_log_entry_next = 1'b0;
        pkts_recv_next = pkts_recv_reg;
        pkts_dropped_next = pkts_dropped_reg;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                if (src_early_logger_rx_data_val & src_early_logger_rx_rdy) begin
                    wr_log_entry_next = 1'b1;
                    pkts_recv_next = pkts_recv_reg + 1'b1;
                    if (src_early_logger_chksum != 0) begin
                        pkts_dropped_next = pkts_dropped_reg + 1'b1;
                    end
                    if (src_early_logger_rx_last) begin
                        state_next = READY;    
                    end
                    else begin
                        state_next = WAIT;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            WAIT: begin
                if (src_early_logger_rx_data_val & src_early_logger_rx_rdy
                            & src_early_logger_rx_last) begin
                    state_next = READY;
                end
                else begin
                    state_next = WAIT; 
                end
            end
        endcase
    end

    mrp_logger #(
        .LOG_DEPTH_LOG2 (8)
    ) mrp_log_early (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.recv_mrp_hdr_val      (wr_log_entry_reg   )
        ,.mrp_pkts_recved       (pkts_recv_reg      )
        ,.mrp_pkts_dropped      (pkts_dropped_reg   )
        ,.recv_mrp_hdr          (log_entry_reg      )

        ,.rd_cmd_queue_empty    (early_logger_rd_cmd_queue_empty    )
        ,.rd_cmd_queue_rd_req   (early_logger_rd_cmd_queue_rd_req   )
        ,.rd_cmd_queue_rd_data  (early_logger_rd_cmd_queue_rd_data  )

        ,.rd_resp_val           (early_logger_rd_resp_val           )
        ,.shell_reg_rd_data     (early_logger_shell_reg_rd_data     )
    );
endmodule
