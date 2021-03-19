`include "mrp_defs.svh"
module timeout_engine #(
     parameter NUM_CONNS = 64
    ,parameter CONN_ID_W = $clog2(NUM_CONNS)
    ,parameter TIMESTAMP_W = 64
)(
     input  clk
    ,input  rst

    ,input                                  src_timeout_set_bit
    ,input                                  src_timeout_clear_bit
    ,input          [CONN_ID_W-1:0]         src_timeout_bit_addr
    ,input          [TIMESTAMP_W-1:0]       src_timeout_next_time

    ,output logic                           timeout_conn_id_map_rd_req_val
    ,output logic   [CONN_ID_W-1:0]         timeout_conn_id_map_rd_req_addr

    ,input                                  conn_id_map_timeout_rd_resp_val
    ,input          mrp_req_key             conn_id_map_timeout_rd_resp_data

    ,input          [TIMESTAMP_W-1:0]       curr_time

    ,output logic                           timeout_val
    ,output         mrp_req_key             timeout_conn_key
    ,output         [CONN_ID_W-1:0]         timeout_conn_id
    ,input                                  timeout_rdy

);  

    typedef enum logic[2:0] {
        READ_BITMAP = 3'd0,
        READ_TIMER_VALUE = 3'd1,
        TIMEOUT_CHECK = 3'd2,
        TIMEOUT_OUTPUT = 3'd3,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   store_conn_key;
    mrp_req_key conn_key_reg;
    mrp_req_key conn_key_next;

    logic                   incr_conn_id;
    logic   [CONN_ID_W-1:0] curr_conn_id_reg;
    logic   [CONN_ID_W-1:0] curr_conn_id_next;

    logic   [NUM_CONNS-1:0] test_set_bitmask;
    logic   [NUM_CONNS-1:0] timer_flags;

    logic                   timer_value_rd_req_val;
    logic   [CONN_ID_W-1:0] timer_value_rd_req_addr;

    logic   [TIMESTAMP_W-1:0]   timer_value_rd_resp_data;

    assign timeout_conn_key = conn_key_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READ_BITMAP;
            curr_conn_id_reg <= '0;
            conn_key_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            curr_conn_id_reg <= curr_conn_id_next;
            conn_key_reg <= conn_key_next;
        end
    end

    assign timeout_conn_id_map_rd_req_addr = curr_conn_id_reg;

    assign conn_key_next = store_conn_key
                            ? conn_id_map_timeout_rd_resp_data
                            : conn_key_reg;

    assign timeout_conn_id = curr_conn_id_reg;

    assign curr_conn_id_next = incr_conn_id
                                ? curr_conn_id_reg + 1'b1
                                : curr_conn_id_reg;
    assign timer_value_rd_req_addr = curr_conn_id_reg;

    assign test_set_bitmask = {{(NUM_CONNS-1){1'b0}}, 1'b1} << curr_conn_id_reg;



    always_comb begin
        incr_conn_id = 1'b0;
        timer_value_rd_req_val = 1'b0;
        timeout_val = 1'b0;

        timeout_conn_id_map_rd_req_val = 1'b0;
        store_conn_key = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READ_BITMAP: begin
                timeout_conn_id_map_rd_req_val = 1'b1;
                if (timer_flags & test_set_bitmask) begin
                    state_next = READ_TIMER_VALUE;
                end
                else begin
                    incr_conn_id = 1'b1;
                    state_next = READ_BITMAP;
                end
            end
            READ_TIMER_VALUE: begin
                store_conn_key = 1'b1;
                if ((src_timeout_set_bit | src_timeout_clear_bit) &&
                        (src_timeout_bit_addr != timer_value_rd_req_addr)) begin
                    state_next = READ_TIMER_VALUE;
                end
                else begin
                    timer_value_rd_req_val = 1'b1;
                    state_next =  TIMEOUT_CHECK;
                end
            end
            TIMEOUT_CHECK: begin
                if (timer_value_rd_resp_data < curr_time) begin
                    state_next = TIMEOUT_OUTPUT;
                end
                else begin
                    incr_conn_id = 1'b1;

                    state_next = READ_BITMAP;
                end
            end
            TIMEOUT_OUTPUT: begin
                timeout_val = 1'b1;
                if (timeout_rdy) begin
                    state_next = READ_BITMAP;
                end
                else begin
                    state_next = TIMEOUT_OUTPUT;
                end
            end
            default: begin
                incr_conn_id = 'X;
                timer_value_rd_req_val = 'X;
                timeout_val = 'X;

                state_next = UND;
            end
        endcase
    end


    valid_bitvector #(
         .BITVECTOR_SIZE    (NUM_CONNS  )
       ,.BITVECTOR_INDEX_W (CONN_ID_W  )
    ) timers_set (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.set_val           (src_timeout_set_bit    )
        ,.set_index         (src_timeout_bit_addr   )
    
        ,.clear_val         (src_timeout_clear_bit  )
        ,.clear_index       (src_timeout_bit_addr   )
    
        ,.valid_bitvector   (timer_flags            )
    );

    bsg_mem_1r1w_sync #(
         .width_p   (TIMESTAMP_W    )
        ,.els_p     (NUM_CONNS)
    ) timer_values (
         .clk_i     (clk    )
        ,.reset_i   (rst    )

        ,.w_v_i     (src_timeout_set_bit        )
        ,.w_addr_i  (src_timeout_bit_addr       )
        ,.w_data_i  (src_timeout_next_time      )

        ,.r_v_i     (timer_value_rd_req_val     )
        ,.r_addr_i  (timer_value_rd_req_addr    )

        ,.r_data_o  (timer_value_rd_resp_data   )
    );
endmodule
