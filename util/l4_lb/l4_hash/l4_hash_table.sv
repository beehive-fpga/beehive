module l4_hash_table 
    import hash_pkg::*;
#(
     parameter TABLE_DATA_W = -1
    ,parameter TABLE_ELS_LOG_2 = -1
)(
     input clk
    ,input rst


    ,input                                  rd_tuple_val
    ,input          hash_struct             rd_tuple_data
    ,input                                  wr_en
    ,input          [TABLE_ELS_LOG_2-1:0]   wr_index
    ,input          hash_table_data         wr_data
    ,output logic                           hash_table_rdy

    ,output logic                           table_data_val
    ,output logic                           table_data_wr_en
    ,output logic   [TABLE_ELS_LOG_2-1:0]   table_rd_index
    ,output         hash_table_data         table_data 
    ,input  logic                           table_data_rdy
);

    localparam PIPELINE_STAGES = 8;

    logic   [TABLE_DATA_W-1:0]      wr_data_regs[PIPELINE_STAGES-1:0];
    logic   [TABLE_ELS_LOG_2-1:0]   wr_index_regs[PIPELINE_STAGES-1:0];
    logic                           wr_en_regs[PIPELINE_STAGES-1:0];

    logic                           stall_hash;

    logic                           stall_r;
    logic                           hash_val_r;
    logic   [31:0]                  hash_r;
    logic                           hash_table_wr_r;
    logic                           hash_table_rd_r;
    logic                           hash_table_rd_rdy_r;
    logic   [TABLE_ELS_LOG_2-1:0]   hash_table_wr_addr_r;
    hash_table_data                 hash_table_wr_data_r;

    logic                           stall_o;
    logic                           hash_table_wr_val_reg_o;
    logic                           table_mem_rd_val_o;
    logic   [TABLE_ELS_LOG_2-1:0]   table_rd_index_reg_o;
   
    assign hash_table_rdy = ~stall_hash;

    integer rst_index;
    integer set_i;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (rst_index = 0; rst_index < PIPELINE_STAGES; rst_index = rst_index + 1) begin
                wr_en_regs[rst_index] <= '0;
            end
        end
        else begin
            if (~stall_hash) begin
                wr_en_regs[0] <= wr_en;
                wr_data_regs[0] <= wr_data;
                wr_index_regs[0] <= wr_index;
                for (set_i = 1; set_i < PIPELINE_STAGES; set_i = set_i + 1) begin
                    wr_en_regs[set_i] <= wr_en_regs[set_i-1];
                    wr_data_regs[set_i] <= wr_data_regs[set_i-1];
                    wr_index_regs[set_i] <= wr_index_regs[set_i-1];
                end
            end
        end
    end


    // hash stages
    hash_func hash_index (
         .clk   (clk    )
        ,.rst   (rst    )
        ,.stall             (stall_hash     )
        ,.initval           ('0)
        ,.tuple_in          (rd_tuple_data  )
        ,.tuple_in_valid    (rd_tuple_val   )
        ,.hashed_valid      (hash_val_r     )
        ,.hashed            (hash_r         )
    );

    assign stall_hash = stall_r;

    // (r)ead stage
    assign stall_r = ~hash_table_rd_rdy_r;


    assign hash_table_wr_r = wr_en_regs[PIPELINE_STAGES-1];

    assign hash_table_wr_addr_r = wr_index_regs[PIPELINE_STAGES-1];
    assign hash_table_wr_data_r = wr_data_regs[PIPELINE_STAGES-1];

    // index table read/write
    ram_1r1w_sync_backpressure #(
         .width_p   (TABLE_DATA_W       )
        ,.els_p     (2**TABLE_ELS_LOG_2 )
    ) hash_table_mem (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.wr_req_val    (hash_table_wr_r        )
        ,.wr_req_addr   (hash_table_wr_addr_r   )
        ,.wr_req_data   (hash_table_wr_data_r   )
        ,.wr_req_rdy    ()
    
        ,.rd_req_val    (hash_val_r             )
        ,.rd_req_addr   (hash_r[TABLE_ELS_LOG_2-1:0]    )
        ,.rd_req_rdy    (hash_table_rd_rdy_r    )
    
        ,.rd_resp_val   (table_mem_rd_val_o     )
        ,.rd_resp_data  (table_data             )
        ,.rd_resp_rdy   (table_data_rdy         )
    );
   
    // output stage
    assign stall_o = ~table_data_rdy;

    always_ff @(posedge clk) begin
        if (rst) begin
            hash_table_wr_val_reg_o <= '0;
        end
        else begin
            if (~stall_o | ~table_data_val) begin
                hash_table_wr_val_reg_o <= wr_en_regs[PIPELINE_STAGES-1];
                table_rd_index_reg_o <= hash_r;
            end
        end
    end

    assign table_data_val = hash_table_wr_val_reg_o | table_mem_rd_val_o;
    assign table_data_wr_en = hash_table_wr_val_reg_o;
    assign table_rd_index = table_rd_index_reg_o;


endmodule
