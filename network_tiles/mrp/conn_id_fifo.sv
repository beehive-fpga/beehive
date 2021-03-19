module conn_id_fifo #(
    parameter CONN_ID_W = 6
)(
     input clk
    ,input rst

    ,input                              conn_id_ret_val
    ,input          [CONN_ID_W-1:0]    conn_id_ret_id
    ,output                             conn_id_ret_rdy

    ,input                              conn_id_req
    ,output logic                       conn_id_avail
    ,output logic   [CONN_ID_W-1:0]    conn_id
);
    logic   [CONN_ID_W-1:0]    conn_id_reg;
    logic   [CONN_ID_W-1:0]    conn_id_next;
    logic                       use_fifo_reg;
    logic                       use_fifo_next;
    
    logic                       fifo_rd_req;
    logic                       fifo_empty;
    logic   [CONN_ID_W-1:0]    fifo_rd_data;

    logic                       fifo_wr_req;
    logic   [CONN_ID_W-1:0]    fifo_wr_data;
    logic                       fifo_full;

    assign conn_id_avail = use_fifo_reg ? ~fifo_empty : 1'b1;
    assign conn_id = use_fifo_reg ? fifo_rd_data : conn_id_reg;
    assign fifo_rd_req = conn_id_req & use_fifo_reg;

    assign fifo_wr_req = conn_id_ret_val;
    assign fifo_wr_data = conn_id_ret_id;
    assign conn_id_ret_rdy = ~fifo_full;


    always_ff @(posedge clk) begin
        if (rst) begin
            conn_id_reg <= '0;
            use_fifo_reg <= '0;
        end
        else begin
            conn_id_reg <= conn_id_next;
            use_fifo_reg <= use_fifo_next;
        end
    end

    always_comb begin
        use_fifo_next = use_fifo_reg;
        conn_id_next = conn_id_reg;
        if (conn_id_req) begin
            if (conn_id_reg == {CONN_ID_W{1'b1}}) begin
                conn_id_next = '0;
                use_fifo_next = 1'b1;
            end
            else begin
                conn_id_next = conn_id_reg + 1'b1;
                use_fifo_next = 1'b0;
            end
        end
        else begin
            use_fifo_next = use_fifo_reg;
            conn_id_next = conn_id_reg;
        end
    end

    fifo_1r1w #(
         .width_p       (CONN_ID_W)
        ,.log2_els_p    (CONN_ID_W)
    ) reclaimed_conn_ids (
         .clk   (clk)
        ,.rst   (rst)

        ,.rd_req    (fifo_rd_req    )
        ,.empty     (fifo_empty     )
        ,.rd_data   (fifo_rd_data   )

        ,.wr_req    (fifo_wr_req    )
        ,.wr_data   (fifo_wr_data   )
        ,.full      (fifo_full      )
    );

endmodule
