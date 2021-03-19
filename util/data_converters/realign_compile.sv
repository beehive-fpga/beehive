module realign_compile #(
     parameter REALIGN_W = -1
    ,parameter DATA_W = -1
    ,parameter BUF_STAGES = -1
    ,parameter DATA_PADBYTES = DATA_W/8
    ,parameter DATA_PADBYTES_W = $clog2(DATA_PADBYTES)
)(
     input clk
    ,input rst

    ,input  logic                           src_realign_data_val
    ,input  logic   [DATA_W-1:0]            src_realign_data
    ,input  logic   [DATA_PADBYTES_W-1:0]   src_realign_data_padbytes 
    ,input  logic                           src_realign_data_last
    ,output logic                           realign_src_data_rdy

    ,output logic                           realign_dst_data_val
    ,output logic   [DATA_W-1:0]            realign_dst_data
    ,output logic   [DATA_PADBYTES_W-1:0]   realign_dst_data_padbytes
    ,output logic                           realign_dst_data_last
    ,input  logic                           dst_realign_data_rdy

    ,output logic   [REALIGN_W-1:0]         realign_dst_removed_data
);

    localparam USE_WIDTH = DATA_W - REALIGN_W;
    localparam USE_BYTES = USE_WIDTH/8;
    localparam REALIGN_BYTES = REALIGN_W/8;
    localparam BUF_STAGES_W = $clog2(BUF_STAGES);

    typedef struct packed {
        logic   [DATA_W-1:0]            data;
        logic                           last;
        logic   [DATA_PADBYTES_W-1:0]   padbytes;
    } fifo_data;
    localparam FIFO_DATA_W = $bits(fifo_data);

    typedef enum logic {
        RD_DATA = 1'b0,
        RD_DATA_NEXT = 1'b1
    } padbytes_out_mux_sel_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        READING_DATA = 2'd1,
        DRAIN_ELEMENT = 2'd2,
        UNDEF = 'X
    } out_state_e;

    out_state_e out_state_reg;
    out_state_e out_state_next;
    padbytes_out_mux_sel_e padbytes_out_mux_sel;
    
    logic                       fifo_rd_req;
    logic   [BUF_STAGES_W:0]    fifo_num_els;
    fifo_data                   fifo_rd_data;
    fifo_data                   fifo_rd_data_next;

    logic                       fifo_wr_req;
    logic                       fifo_full;
    fifo_data                   fifo_wr_data;
    logic                       clear_fifo;

    always_ff @(posedge clk) begin
        if (rst) begin
            out_state_reg <= READING_DATA;
        end
        else begin
            out_state_reg <= out_state_next;
        end
    end

    assign fifo_wr_data.data = src_realign_data;
    assign fifo_wr_data.last = src_realign_data_last;
    assign fifo_wr_data.padbytes = src_realign_data_padbytes;

    assign fifo_wr_req = src_realign_data_val & ~fifo_full;
    assign realign_src_data_rdy = ~fifo_full;

    peek_fifo_1r1w #(
         .DATA_W    (FIFO_DATA_W    )
        ,.ELS       (BUF_STAGES     )
    ) realign_fifo (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.rd_req        (fifo_rd_req        )
        ,.rd_data       (fifo_rd_data       )
        ,.rd_data_next  (fifo_rd_data_next  )
        ,.num_els       (fifo_num_els       )
    
        ,.wr_req        (fifo_wr_req        )
        ,.wr_data       (fifo_wr_data       )
        ,.full          (fifo_full          )
        ,.clear_fifo    (1'b0               )
    );

    assign realign_dst_removed_data = fifo_rd_data.data[DATA_W-1 -: REALIGN_W];
    assign realign_dst_data = {fifo_rd_data.data[USE_WIDTH-1:0], fifo_rd_data_next.data[DATA_W-1 -: REALIGN_W]};
    always_comb begin
        if (padbytes_out_mux_sel == RD_DATA) begin
            realign_dst_data_padbytes = fifo_rd_data.padbytes + REALIGN_BYTES;
        end
        else begin
            realign_dst_data_padbytes = fifo_rd_data_next.padbytes + REALIGN_BYTES;
        end
    end


    always_comb begin
        fifo_rd_req = 1'b0;
        realign_dst_data_val = 1'b0;
        realign_dst_data_last = 1'b0;

        padbytes_out_mux_sel = RD_DATA;

        out_state_next = out_state_reg;
        case (out_state_reg) 
            READING_DATA: begin
                // first check there's even valid fifo data to read
                if (fifo_num_els >= 1) begin
                    // check if we're looking at the last data line
                    if (fifo_rd_data.last) begin
                        padbytes_out_mux_sel = RD_DATA;
                        fifo_rd_req = dst_realign_data_rdy;
                        realign_dst_data_val = 1'b1;
                        realign_dst_data_last = 1'b1;
                    end
                    // check that there's a second valid data line that we can use for
                    // the realignment
                    else if (fifo_num_els >= 2) begin
                        fifo_rd_req = dst_realign_data_rdy;
                        realign_dst_data_val = 1'b1;
                        // figure out if we consumed all of the next line for this output
                        if (fifo_rd_req) begin
                            if (fifo_rd_data_next.last) begin
                                // we are using all the valid data in the next line, just drain the
                                // last element
                                if (fifo_rd_data_next.padbytes >= USE_BYTES) begin
                                    padbytes_out_mux_sel = RD_DATA_NEXT;
                                    realign_dst_data_last = 1'b1;
                                    out_state_next = DRAIN_ELEMENT;
                                end
                            end
                        end
                    end
                end
            end
            DRAIN_ELEMENT: begin
                // if we got here, we already know there's a valid element to drain (we just
                // don't want to use its data)
                fifo_rd_req = 1'b1;
                out_state_next = READING_DATA;
            end
        endcase
    end

    generate
        if (REALIGN_W >= DATA_W) begin
            $error("Realign width too large");
        end
        else if (REALIGN_W == 0) begin
            $error("Realign width 0 not supported");
        end
    endgenerate

endmodule
