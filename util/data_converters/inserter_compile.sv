// NOTE: insert data should be held stable until the first line of data is used

// This is for when the insert width is known at compile time. For dynamic
// insert, you need to mask: basically shift the new line down (which shifts in
// 0s), make sure the remnant reg has all 0s in the bottom bits and then or

module inserter_compile #(
     parameter INSERT_W = -1
    ,parameter DATA_W = -1
    ,parameter DATA_PADBYTES = DATA_W/8
    ,parameter DATA_PADBYTES_W = $clog2(DATA_PADBYTES)
)(
     input clk
    ,input rst

    ,input  logic   [INSERT_W-1:0]          insert_data
    
    ,input  logic                           src_insert_data_val
    ,input  logic   [DATA_W-1:0]            src_insert_data
    ,input  logic   [DATA_PADBYTES_W-1:0]   src_insert_data_padbytes 
    ,input  logic                           src_insert_data_last
    ,output logic                           insert_src_data_rdy

    ,output logic                           insert_dst_data_val
    ,output logic   [DATA_W-1:0]            insert_dst_data
    ,output logic   [DATA_PADBYTES_W-1:0]   insert_dst_data_padbytes
    ,output logic                           insert_dst_data_last
    ,input  logic                           dst_insert_data_rdy
);

    localparam INSERT_BYTES = INSERT_W/8;
    localparam USE_DATA_W = DATA_W - INSERT_W;
    localparam USE_BYTES = USE_DATA_W/8;
    typedef enum logic [1:0] {
        INJECT_DATA = 2'b0,
        PASS_DATA = 2'b1,
        LAST_DATA = 2'd2,
        UND = 'X
    } state_e;
    
    typedef enum logic {
        INSERT_DATA = 1'b0,
        REM_DATA = 1'b1
    } out_mux_sel_e;
    
    typedef enum logic[1:0] {
        ZERO = 2'd0,
        INPUT = 2'd1,
        REG = 2'd2
    } padbytes_out_mux_sel_e;

    state_e state_reg;
    state_e state_next;

    logic   [INSERT_W-1:0]  rem_reg;
    logic   [INSERT_W-1:0]  rem_next;
    logic                   store_rem;

    logic   [DATA_PADBYTES_W-1:0]   padbytes_reg;
    logic   [DATA_PADBYTES_W-1:0]   padbytes_next;
    logic                           store_padbytes;

    out_mux_sel_e out_mux_sel;
    padbytes_out_mux_sel_e padbytes_out_mux_sel;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= INJECT_DATA;
        end
        else begin
            state_reg <= state_next;
            rem_reg <= rem_next;
            padbytes_reg <= padbytes_next;
        end
    end

    assign padbytes_next = store_padbytes
                        ? src_insert_data_padbytes
                        : padbytes_reg;

    assign rem_next = store_rem
                    ? src_insert_data[INSERT_W-1:0]
                    : rem_reg;

generate
    if (DATA_W == INSERT_W) begin
        always_comb begin
            if (out_mux_sel == INSERT_DATA) begin
                insert_dst_data = insert_data;
            end
            else begin
                insert_dst_data = rem_reg;
            end
        end
    end
    else begin
        always_comb begin
            if (out_mux_sel == INSERT_DATA) begin
                insert_dst_data = {insert_data, src_insert_data[DATA_W-1 -: USE_DATA_W]};
            end
            else begin
                insert_dst_data = {rem_reg, src_insert_data[DATA_W-1 -: USE_DATA_W]};
            end
        end
    end
endgenerate

    always_comb begin
        if (padbytes_out_mux_sel == INPUT) begin
            insert_dst_data_padbytes = src_insert_data_padbytes + USE_BYTES;
        end
        else if (padbytes_out_mux_sel == REG) begin
            insert_dst_data_padbytes = padbytes_reg + USE_BYTES;
        end
        else begin
            insert_dst_data_padbytes = '0;
        end
    end

    always_comb begin
        insert_src_data_rdy = 1'b0;
        insert_dst_data_val = 1'b0;
        insert_dst_data_last = 1'b0;

        store_padbytes = 1'b0;
        store_rem = 1'b0;

        out_mux_sel = INSERT_DATA;
        padbytes_out_mux_sel = ZERO;

        state_next = state_reg;
        case (state_reg) 
            INJECT_DATA: begin
                insert_src_data_rdy = dst_insert_data_rdy;
                insert_dst_data_val = src_insert_data_val;
                out_mux_sel = INSERT_DATA;
                padbytes_out_mux_sel = ZERO;

                if (src_insert_data_val & dst_insert_data_rdy) begin
                    store_rem = 1'b1;
                    if (src_insert_data_last) begin
                        // the incoming line has too much data to output in
                        // this cycle along with the saved data, so go to drain
                        if (src_insert_data_padbytes < INSERT_BYTES) begin
                            store_padbytes = 1'b1;
                            state_next = LAST_DATA;
                        end
                        else begin
                            insert_dst_data_last = 1'b1;
                            padbytes_out_mux_sel = INPUT;
                        end
                    end
                    else begin
                        state_next = PASS_DATA;
                    end
                end
            end
            PASS_DATA: begin
                insert_src_data_rdy = dst_insert_data_rdy;
                insert_dst_data_val = src_insert_data_val;
                out_mux_sel = REM_DATA;
                padbytes_out_mux_sel = ZERO;

                if (dst_insert_data_rdy & src_insert_data_val) begin
                    store_rem = 1'b1;

                    if (src_insert_data_last) begin
                        if (src_insert_data_padbytes < INSERT_BYTES) begin
                            store_padbytes = 1'b1;
                            state_next = LAST_DATA;
                        end
                        else begin
                            insert_dst_data_last = 1'b1;
                            padbytes_out_mux_sel = INPUT;
                            state_next = INJECT_DATA;
                        end
                    end
                end
            end
            LAST_DATA: begin
                insert_dst_data_val = 1'b1;
                out_mux_sel = REM_DATA;
                padbytes_out_mux_sel = REG;
                insert_dst_data_last = 1'b1;
                if (dst_insert_data_rdy) begin
                    state_next = INJECT_DATA;
                end
            end
            default: begin
                insert_src_data_rdy = 'X;
                insert_dst_data_val = 'X;
                insert_dst_data_last = 'X;

                store_padbytes = 'X;
                store_rem = 'X;

                out_mux_sel = INSERT_DATA;
                padbytes_out_mux_sel = ZERO;

                state_next = UND;
            end
        endcase
    end

    generate
        if (INSERT_W > DATA_W) begin
            $error("Insert data wider than data line width not supported");
        end
    endgenerate
endmodule
