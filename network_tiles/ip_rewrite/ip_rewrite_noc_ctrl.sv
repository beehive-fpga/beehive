`include "ip_rewrite_noc_pipe_defs.svh"
module ip_rewrite_noc_pipe_ctrl (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_ip_rewrite_in_val
    ,output logic                           ip_rewrite_in_noc0_ctovr_rdy
    
    ,output logic                           ip_rewrite_out_noc0_vrtoc_val
    ,input  logic                           noc0_vrtoc_ip_rewrite_out_rdy

    ,output logic                           lookup_rd_table_val
    ,input  logic                           lookup_rd_table_rdy

    ,output logic                           ctrl_cam_lookup_val
    
    ,output logic                           ctrl_datap_store_hdr
    ,output logic                           ctrl_datap_store_meta
    ,output logic                           ctrl_datap_store_lookup
    ,output logic                           ctrl_datap_store_dst
    ,output ip_rewrite_out_sel_e            ctrl_datap_noc_out_sel
    ,output logic                           ctrl_datap_init_flit_cnt
    ,output logic                           ctrl_datap_incr_flit_cnt
    ,output logic                           ctrl_datap_use_rewrite_chksum
    
    ,input  logic                           datap_ctrl_last_flit
);

    localparam DELAY_CYCLES = 20;
    typedef enum logic[2:0] {
        READY = 3'd0,
        META = 3'd1,
        FLOW_LOOKUP = 3'd3,
        HDR_OUT = 3'd4,
        META_OUT = 3'd5,
        DATA_PASS = 3'd6,
        DELAY = 3'd7,
        UND = 'X
    } state_e;
    
    state_e state_reg;
    state_e state_next;

    logic   use_rewrite_chksum_reg;
    logic   use_rewrite_chksum_next;

    assign ctrl_datap_use_rewrite_chksum = use_rewrite_chksum_reg;

    logic [63:0]    delay_reg;
    logic [63:0]    delay_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            use_rewrite_chksum_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            use_rewrite_chksum_reg <= use_rewrite_chksum_next;
            delay_reg <= delay_next;
        end
    end

    always_comb begin
        ip_rewrite_in_noc0_ctovr_rdy = 1'b0;
        ip_rewrite_out_noc0_vrtoc_val = 1'b0;

        ctrl_datap_store_hdr = 1'b0;
        ctrl_datap_store_meta = 1'b0;
        ctrl_datap_store_lookup = 1'b0;
        ctrl_datap_noc_out_sel = ip_rewrite_noc_pipe_pkg::HDR_OUT;
        ctrl_datap_init_flit_cnt = 1'b0;
        ctrl_datap_incr_flit_cnt = 1'b0;
        ctrl_datap_store_dst = 1'b0;
        ctrl_cam_lookup_val = 1'b0;

        lookup_rd_table_val = 1'b0;
        use_rewrite_chksum_next = use_rewrite_chksum_reg;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                use_rewrite_chksum_next = 1'b0;
                ctrl_datap_store_hdr = 1'b1;
                ip_rewrite_in_noc0_ctovr_rdy = 1'b1;
                ctrl_datap_init_flit_cnt = 1'b1;
                delay_next = '0;
                if (noc0_ctovr_ip_rewrite_in_val) begin
                    state_next = META;
                end
            end
            META: begin
                ip_rewrite_in_noc0_ctovr_rdy = 1'b1;
                ctrl_datap_store_meta = 1'b1;
                if (noc0_ctovr_ip_rewrite_in_val) begin
                    state_next = FLOW_LOOKUP;
                end
            end
            FLOW_LOOKUP: begin
                lookup_rd_table_val = noc0_ctovr_ip_rewrite_in_val;
                ctrl_datap_store_dst = 1'b1;
                ctrl_cam_lookup_val = 1'b1;
                ctrl_datap_store_lookup = 1'b1;
                if (lookup_rd_table_rdy) begin
                    state_next = HDR_OUT;
                end
            end
            HDR_OUT: begin
                ctrl_datap_noc_out_sel = ip_rewrite_noc_pipe_pkg::HDR_OUT;
                ip_rewrite_out_noc0_vrtoc_val = 1'b1;
                if (noc0_vrtoc_ip_rewrite_out_rdy) begin
                    state_next = META_OUT;
                end
            end
            META_OUT: begin
                ctrl_datap_noc_out_sel = ip_rewrite_noc_pipe_pkg::META_OUT;
                ip_rewrite_out_noc0_vrtoc_val = 1'b1;
                use_rewrite_chksum_next = 1'b1;
                if (noc0_vrtoc_ip_rewrite_out_rdy) begin
                    ctrl_datap_incr_flit_cnt = 1'b1;
                    state_next = DATA_PASS;
                end
            end
            DATA_PASS: begin
                ctrl_datap_noc_out_sel = ip_rewrite_noc_pipe_pkg::DATA_OUT;
                ip_rewrite_out_noc0_vrtoc_val = noc0_ctovr_ip_rewrite_in_val;
                ip_rewrite_in_noc0_ctovr_rdy = noc0_vrtoc_ip_rewrite_out_rdy;

                if (noc0_ctovr_ip_rewrite_in_val & noc0_vrtoc_ip_rewrite_out_rdy) begin
                    use_rewrite_chksum_next = 1'b0;
                    ctrl_datap_incr_flit_cnt = 1'b1;
                    if (datap_ctrl_last_flit) begin
                        state_next = DELAY;
                    end
                end
            end
            DELAY: begin
                delay_next = delay_reg + 1'b1;
                if (delay_reg == DELAY_CYCLES) begin
                    state_next = READY;
                end
            end
            default: begin
                ip_rewrite_in_noc0_ctovr_rdy = 'X;
                ip_rewrite_out_noc0_vrtoc_val = 'X;

                ctrl_datap_store_hdr = 'X;
                ctrl_datap_store_meta = 'X;
                ctrl_datap_store_lookup = 'X;
                ctrl_datap_init_flit_cnt = 'X;
                ctrl_datap_incr_flit_cnt = 'X;
                ctrl_datap_store_dst = 'X;
                ctrl_cam_lookup_val = 'X;

                lookup_rd_table_val = 'X;

                use_rewrite_chksum_next = 'X;

                ctrl_datap_noc_out_sel = ip_rewrite_noc_pipe_pkg::HDR_OUT;
                state_next = state_reg;
            end
        endcase
    end
endmodule
