module realign_runtime #(
     parameter DATA_W = -1
    ,parameter BUF_STAGES = -1
    ,parameter DATA_PADBYTES = DATA_W/8
    ,parameter DATA_PADBYTES_W = $clog2(DATA_PADBYTES)
)(
     input clk
    ,input rst

    ,input          [DATA_PADBYTES_W-1:0]   realign_bytes

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

    ,output logic   [DATA_W-1:0]            full_line
);
    localparam BUF_STAGES_W = $clog2(BUF_STAGES);
    localparam DATA_W_W = $clog2(DATA_W);
    typedef enum logic {
        RD_DATA = 1'b0,
        RD_DATA_NEXT = 1'b1
    } padbytes_out_mux_sel_e;

    typedef struct packed {
        logic   [DATA_W-1:0]            data;
        logic                           last;
        logic   [DATA_PADBYTES_W-1:0]   padbytes;
        logic   [DATA_PADBYTES_W-1:0]   realign_bytes;
    } fifo_data;
    localparam FIFO_DATA_W = $bits(fifo_data);

    
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

    logic   [DATA_PADBYTES_W:0]   use_bytes;
    logic   [DATA_W_W:0]    realign_shift;
    logic   [(DATA_W*2)-1:0]    realign_data;

    logic                       new_packet_reg;
    logic                       new_packet_next;
    
    logic   [DATA_PADBYTES-1:0] realign_bytes_reg;
    logic   [DATA_PADBYTES-1:0] realign_bytes_next;

    assign use_bytes = DATA_PADBYTES - realign_bytes_next;

    assign realign_shift = realign_bytes_next << 3;
    assign full_line = fifo_rd_data.data;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            out_state_reg <= READING_DATA;
            // be careful, we reset this to 1 on purpose
            new_packet_reg <= '1;
        end
        else begin
            out_state_reg <= out_state_next;
            new_packet_reg <= new_packet_next;
            realign_bytes_reg <= realign_bytes_next;
        end
    end

    assign realign_bytes_next = new_packet_reg
                            ? fifo_rd_data.realign_bytes
                            : realign_bytes_reg;
    
    always_comb begin
        if (padbytes_out_mux_sel == RD_DATA) begin
            realign_dst_data_padbytes = fifo_rd_data.padbytes + realign_bytes_next;
        end
        else begin
            realign_dst_data_padbytes = fifo_rd_data_next.padbytes + realign_bytes_next;
        end
    end

    assign fifo_wr_data.data = src_realign_data;
    assign fifo_wr_data.last = src_realign_data_last;
    assign fifo_wr_data.padbytes = src_realign_data_padbytes;
    assign fifo_wr_data.realign_bytes = realign_bytes;

    assign realign_data = {fifo_rd_data.data, fifo_rd_data_next.data} << realign_shift;

    assign realign_dst_data = realign_data[(DATA_W*2)-1 -: DATA_W];

    assign fifo_wr_req = src_realign_data_val & ~fifo_full;
    assign realign_src_data_rdy = ~fifo_full;

    always_comb begin
        fifo_rd_req = 1'b0;
        realign_dst_data_val = 1'b0;
        realign_dst_data_last = 1'b0;

        padbytes_out_mux_sel = RD_DATA;
        out_state_next = out_state_reg;
        new_packet_next = new_packet_reg;

        case (out_state_reg)
            READING_DATA: begin
                // check if there's valid fifo data to read
                if (fifo_num_els >= 1) begin
                    new_packet_next = 1'b0;
                    if (fifo_rd_data.last) begin
                        new_packet_next = 1'b1;
                        padbytes_out_mux_sel = RD_DATA;
                        fifo_rd_req = dst_realign_data_rdy;

                        realign_dst_data_val = 1'b1;
                        realign_dst_data_last = 1'b1;
                    end
                    else if (fifo_num_els >= 2) begin
                        fifo_rd_req = dst_realign_data_rdy;
                        realign_dst_data_val = 1'b1;
                        if (fifo_rd_req) begin
                            // figure out if we consume all of the next line for this output
                            if (fifo_rd_data_next.last) begin
                                new_packet_next = 1'b1;
                                if (fifo_rd_data_next.padbytes >= use_bytes) begin
                                    new_packet_next = 1'b0;
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
                // if we got here, we know there's a valid element to drain (we've
                // just already outputted its data)
                new_packet_next = 1'b1;
                fifo_rd_req = 1'b1;
                out_state_next = READING_DATA;
            end
        endcase
    end

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

endmodule
