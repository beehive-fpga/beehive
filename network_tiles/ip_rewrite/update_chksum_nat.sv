// be super careful with this. two cycle delay (as in the output you want
// appears on the second cycle)
// 0          |    1     |    2
// inputs set | compute  | checksum appears
`include "packet_defs.vh"
module update_chksum_nat (
     input clk

    ,input  [`TCP_CHKSUM_W-1:0] old_chksum
    ,input  [`IP_ADDR_W-1:0]    old_ip_addr
    ,input  [`IP_ADDR_W-1:0]    new_ip_addr

    ,output [`TCP_CHKSUM_W-1:0] new_chksum
);

    logic   [`TCP_CHKSUM_W:0]   old_ip_addr_sum_tmp_c;
    logic   [`TCP_CHKSUM_W-1:0] old_ip_addr_sum_final_c;
    logic   [`TCP_CHKSUM_W:0]   new_ip_addr_sum_tmp_c;
    logic   [`TCP_CHKSUM_W-1:0] new_ip_addr_sum_final_c;
    
    logic   [`TCP_CHKSUM_W:0]   combine_sums_tmp_c;
    logic   [`TCP_CHKSUM_W-1:0] combine_sums_final_c;
    logic   [`TCP_CHKSUM_W-1:0] old_ip_sum_inv_c;
    
    logic   [`TCP_CHKSUM_W-1:0] checksum_diff_reg_u;
    logic   [`TCP_CHKSUM_W-1:0] old_chksum_reg_u;

    logic   [`TCP_CHKSUM_W:0]   chksum_update_tmp_u;
    logic   [`TCP_CHKSUM_W-1:0] chksum_update_final_u;
    logic   [`TCP_CHKSUM_W-1:0] chksum_update_final_inv_u;
    logic   [`TCP_CHKSUM_W-1:0] old_chksum_inv_u;

    logic   [`TCP_CHKSUM_W-1:0] chksum_update_reg_o;

    always_ff @(posedge clk) begin
        checksum_diff_reg_u <= combine_sums_final_c;
        old_chksum_reg_u <= old_chksum;

        chksum_update_reg_o <= chksum_update_final_inv_u;
    end

    // sum for the old ip addr
    assign old_ip_addr_sum_tmp_c = {1'b0, old_ip_addr[15:0]} + {1'b0, old_ip_addr[31:16]};
    // add the carry back in
    assign old_ip_addr_sum_final_c = old_ip_addr_sum_tmp_c[15:0] 
                                     + old_ip_addr_sum_tmp_c[16];

    assign new_ip_addr_sum_tmp_c = {1'b0, new_ip_addr[15:0]} + {1'b0, new_ip_addr[31:16]};
    // add the carry back in
    assign new_ip_addr_sum_final_c = new_ip_addr_sum_tmp_c[15:0] 
                                     + new_ip_addr_sum_tmp_c[16];

    // calculate the checksum "difference"
    assign old_ip_sum_inv_c = ~old_ip_addr_sum_final_c;
    assign combine_sums_tmp_c = {1'b0, old_ip_sum_inv_c} +
                              {1'b0, new_ip_addr_sum_final_c};
    assign combine_sums_final_c = combine_sums_tmp_c[15:0] + combine_sums_tmp_c[16];

    /*******************************************************
     * Update
     ******************************************************/
    // okay now update the checksum
    assign old_chksum_inv_u = ~old_chksum_reg_u;
    assign chksum_update_tmp_u = {1'b0, old_chksum_inv_u} + {1'b0, checksum_diff_reg_u};
    assign chksum_update_final_u = chksum_update_tmp_u[15:0] + chksum_update_tmp_u[16];
    assign chksum_update_final_inv_u = ~chksum_update_final_u;


    /*******************************************************
     * Output
     ******************************************************/
    assign new_chksum = chksum_update_reg_o;

endmodule
