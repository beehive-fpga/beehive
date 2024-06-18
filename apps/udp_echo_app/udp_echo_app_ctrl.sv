`include "udp_echo_app_defs.svh"
module udp_echo_app_ctrl (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_udp_app_in_val
    ,output logic                           udp_app_in_noc0_ctovr_rdy
    
    ,output logic                           udp_app_out_noc0_vrtoc_val
    ,input                                  noc0_vrtoc_udp_app_out_rdy
    
    ,output logic                           in_store_hdr_flit
    ,output logic                           in_store_meta_flit

    ,output         udp_app_out_mux_sel_e   out_data_mux_sel

    ,output logic                           app_stats_do_log
    ,output logic                           app_stats_incr_bytes_sent
    ,output logic   [`NOC_DATA_BYTES_W:0]   app_stats_num_bytes_sent

    ,output logic                           app_stats_do_log
    ,output logic                           app_stats_incr_bytes_sent
    ,output logic   [`NOC_DATA_BYTES_W:0]   app_stats_num_bytes_sent

    ,input          [`MSG_LENGTH_WIDTH-1:0] total_flits
    ,input  logic   [`UDP_LENGTH_W-1:0]     data_length
);

    logic               hdr_flit_val_reg;
    logic               hdr_flit_val_next;

    logic                   meta_flit_val_reg;
    logic                   meta_flit_val_next;

    logic   out_data_rdy;
    logic   in_data_val;

    logic                           reset_flit_vals;

    always_ff @(posedge clk) begin
        if (rst) begin
            hdr_flit_val_reg <= '0;
            meta_flit_val_reg <= '0;
        end
        else begin
            hdr_flit_val_reg <= hdr_flit_val_next;
            meta_flit_val_reg <= meta_flit_val_next;
        end
    end

    always_comb begin
        hdr_flit_val_next = hdr_flit_val_reg;
        if (reset_flit_vals) begin
            hdr_flit_val_next = '0;
        end
        else if (in_store_hdr_flit) begin
            hdr_flit_val_next = 1'b1;
        end
        else begin
            hdr_flit_val_next = hdr_flit_val_reg;
        end
    end

    always_comb begin
        meta_flit_val_next = meta_flit_val_reg;
        if (reset_flit_vals) begin
            meta_flit_val_next = '0;
        end
        else if (in_store_meta_flit) begin
            meta_flit_val_next = 1'b1;
        end
        else begin
            meta_flit_val_next = meta_flit_val_reg;
        end
    end

    udp_echo_app_in_ctrl in_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_udp_app_in_val (noc0_ctovr_udp_app_in_val  )
        ,.udp_app_in_noc0_ctovr_rdy (udp_app_in_noc0_ctovr_rdy  )

        ,.app_stats_do_log          (app_stats_do_log           )
        ,.app_stats_incr_bytes_sent (app_stats_incr_bytes_sent  )
        ,.app_stats_num_bytes_sent  (app_stats_num_bytes_sent   )

        ,.in_data_val               (in_data_val                )
        ,.out_data_rdy              (out_data_rdy               )
                                                                
        ,.in_store_hdr_flit         (in_store_hdr_flit          )
        ,.in_store_meta_flit        (in_store_meta_flit         )
        ,.reset_flit_vals           (reset_flit_vals            )
                                                                
        ,.total_flits               (total_flits                )
        ,.data_length               (data_length                )
    );

    udp_echo_app_out_ctrl out_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.udp_app_out_noc0_vrtoc_val    (udp_app_out_noc0_vrtoc_val )
        ,.noc0_vrtoc_udp_app_out_rdy    (noc0_vrtoc_udp_app_out_rdy )
                                                                    
        ,.in_data_val                   (in_data_val                )
        ,.out_data_rdy                  (out_data_rdy               )
                                                                    
        ,.hdr_flit_val                  (hdr_flit_val_reg           )
        ,.meta_flit_val                 (meta_flit_val_reg          )
                                                                    
        ,.total_flits                   (total_flits                )
                                                                    
        ,.out_data_mux_sel              (out_data_mux_sel           )
    );

endmodule
