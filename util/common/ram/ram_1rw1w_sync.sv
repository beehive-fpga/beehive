`include "bsg_defines.v"
module ram_1rw1w_sync #(
     parameter width_p=-1
    ,parameter els_p=-1
    ,parameter read_write_same_addr_p=0
    ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
    ,parameter harden_p=0
    ,parameter use_1r1w=0
)
(
     input  clk_i
    ,input  reset_i

    ,input                      w0_i
    ,input [width_p-1:0]        w0_data_i

    ,input [addr_width_lp-1:0]  addr0_i
    ,input                      v0_i

    ,output logic [width_p-1:0] r0_data_o

    ,input                      w1_i
    ,input [width_p-1:0]        w1_data_i

    ,input [addr_width_lp-1:0]  addr1_i
    ,input                      v1_i
);

    
    logic                       bank0_w;
    logic   [width_p-1:0]       bank0_w_data;
    
    logic   [addr_width_lp-1:0] bank0_addr;
    logic                       bank0_val;
    
    logic   [width_p-1:0]       bank0_r_data;
    
    logic                       bank1_w;
    logic   [width_p-1:0]       bank1_w_data;
    
    logic   [addr_width_lp-1:0] bank1_addr;
    logic                       bank1_val;
    
    logic   [width_p-1:0]       bank1_r_data;
    
    logic                       r0_val;
    logic   [addr_width_lp-1:0] r0_addr;
    logic                       r0_bank;
    logic                       r0_bank_reg;

    logic                       w0_val;
    logic   [addr_width_lp-1:0] w0_addr;
    logic                       w0_bank;
    
    logic                       w1_val;
    logic   [addr_width_lp-1:0] w1_addr;
    logic                       w1_bank;

    assign r0_val = ~w0_i & v0_i;
    assign r0_addr = addr0_i;

    assign w0_val = w0_i & v0_i;
    assign w1_val = w1_i & v1_i;
    assign w0_addr = addr0_i;
    assign w1_addr = addr1_i;

    // if there is a pending read, select the opposite bank. Otherwise, have 0 go to 0 and 1 go to 1 
    assign w0_bank = r0_val ? ~r0_bank : 1'b0;
    assign w1_bank = r0_val ? ~r0_bank : 1'b1;

    assign r0_data_o = r0_bank_reg ? bank1_r_data : bank0_r_data;

    // either there's a read or some valid write to this bank
    assign bank0_val = (~r0_bank & r0_val) | (~w0_bank & w0_val) | (~w1_bank & w1_val);
    assign bank1_val = (r0_bank & r0_val) | (w0_bank & w0_val) | (w1_bank & w1_val);

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            r0_bank_reg <= 'b0;
        end
        else begin
            r0_bank_reg <= r0_bank;
        end
    end

    always_comb begin
        // There is a read, so assign to the appropriate address
        if (r0_val) begin
            if (r0_bank) begin
                bank1_addr = r0_addr;
                bank1_w = 'b0;

                // If there's also a pending write, we need to assign the other bank
                bank0_w = w0_val | w1_val;

                // We don't really care what this is, we just need a default value
                bank1_w_data = w1_data_i;
                
                if (w0_val) begin
                    bank0_w_data = w0_data_i;
                    bank0_addr = w0_addr;
                end
                else if (w1_val) begin
                    bank0_w_data = w1_data_i;
                    bank0_addr = w1_addr;
                end
                // There's no pending write
                // We don't really care what values these are, they just need a default value
                else begin
                    bank0_w_data = w0_data_i;
                    bank0_addr = w0_addr;
                end
            end
            else begin
                bank0_addr = r0_addr;
                bank0_w = 'b0;

                // If there's also a pending write, we need to assign the other bank's
                // address
                bank1_w = w0_val | w1_val;
               
                // We don't really care what this is, we just need a default value
                bank0_w_data = w0_data_i;

                if (w0_val) begin
                    bank1_w_data = w0_data_i;
                    bank1_addr = w0_addr;
                end
                else if (w1_val) begin
                    bank1_w_data = w1_data_i;
                    bank1_addr = w1_addr;
                end
                // There's no pending write
                // We don't really care what values these are, they just need a default value
                else begin
                    bank1_w_data = w1_data_i;
                    bank1_addr = w1_addr;
                end
            end
        end
        else begin
            // otherwise, there's either 2 writes or nothing at all
            // either way, just send them to the appropriate banks
            bank0_addr = w0_addr;
            bank0_w_data = w0_data_i;
            bank0_w = w0_val;

            bank1_addr = w1_addr;
            bank1_w_data = w1_data_i;
            bank1_w = w1_val;
        end
    end

generate
    if (use_1r1w) begin: gen_1r1w_mems
        bsg_mem_1r1w_sync #(
             .width_p(width_p)
            ,.els_p(els_p)
        ) bank0 (
             .clk_i(clk_i)
            ,.reset_i(reset_i)

            ,.w_v_i     (bank0_w & bank0_val    )
            ,.w_addr_i  (bank0_addr             )
            ,.w_data_i  (bank0_w_data           )   

            ,.r_v_i     (bank0_val & ~bank0_w   )
            ,.r_addr_i  (bank0_addr             )
            ,.r_data_o  (bank0_r_data           )
        
        );
        
        bsg_mem_1r1w_sync #(
             .width_p(width_p)
            ,.els_p(els_p)
        ) bank1 (
             .clk_i(clk_i)
            ,.reset_i(reset_i)

            ,.w_v_i     (bank1_w & bank1_val    )
            ,.w_addr_i  (bank1_addr             )
            ,.w_data_i  (bank1_w_data           )   

            ,.r_v_i     (bank1_val & ~bank1_w   )
            ,.r_addr_i  (bank1_addr             )
            ,.r_data_o  (bank1_r_data           )
        
        );
    end
    else begin: gen_1rw_mems
        bsg_mem_1rw_sync #(
             .width_p(width_p)
            ,.els_p(els_p)
        ) bank0 (
             .clk_i(clk_i)
            ,.reset_i(reset_i)
            // data and valid for write
            ,.data_i    (bank0_w_data   )
            ,.w_i       (bank0_w        )
    
            // addr for read and write
            ,.addr_i    (bank0_addr     )
            ,.v_i       (bank0_val      )
    
            // data for read
            ,.data_o    (bank0_r_data   )
        );
        
        bsg_mem_1rw_sync #(
             .width_p(width_p)
            ,.els_p(els_p)
        ) bank1 (
             .clk_i(clk_i)
            ,.reset_i(reset_i)
            // data and valid for write
            ,.data_i    (bank1_w_data   )
            ,.w_i       (bank1_w        )
    
            // addr for read and write
            ,.addr_i    (bank1_addr     )
            ,.v_i       (bank1_val      )
    
            // data for read
            ,.data_o    (bank1_r_data   )
        );
    end
endgenerate

    bank_valid_mem #(
        .els_p(els_p)
    ) valid_mem (
         .clk_i(clk_i)
        ,.reset_i(reset_i)
        
        ,.w0_val_i  (w0_val)
        ,.w0_addr_i (w0_addr)
        ,.w0_bank_i (w0_bank)

        ,.w1_val_i  (w1_val)
        ,.w1_addr_i (w1_addr)
        ,.w1_bank_i (w1_bank)

        ,.r_val_i   (r0_val)
        ,.r_addr_i  (r0_addr)
        ,.r_bank_o  (r0_bank)
    );

endmodule
