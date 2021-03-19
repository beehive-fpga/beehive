`include "mrp_tx_defs.svh"
module mrp_tx_noc_out_ctrl (
     input clk
    ,input rst
    
    ,output logic                       mrp_tx_out_noc0_vrtoc_val
    ,input  logic                       noc0_vrtoc_mrp_tx_out_rdy
    
    ,input  logic                       mrp_mrp_tx_out_tx_meta_val
    ,output logic                       mrp_tx_out_mrp_tx_meta_rdy

    ,input  logic                       mrp_mrp_tx_out_tx_data_val
    ,output logic                       mrp_tx_out_mrp_tx_data_rdy

    ,output mrp_noc_out_flit_mux_sel    ctrl_datap_flit_sel
    ,output logic                       ctrl_datap_store_inputs

    ,input  logic                       datap_ctrl_last_output
);
    
    typedef enum logic[1:0] {
        READY = 2'd0,
        META_FLIT_OUT = 2'd1,
        DATA_FLIT_OUT = 2'd2,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        mrp_tx_out_mrp_tx_meta_rdy = 1'b0;
        mrp_tx_out_mrp_tx_data_rdy = 1'b0;

        mrp_tx_out_noc0_vrtoc_val = 1'b0;

        ctrl_datap_flit_sel = mrp_tx_pkg::SEL_HDR_FLIT;
        ctrl_datap_store_inputs = 1'b0;

        state_next = state_reg;

        case (state_reg)
            READY: begin
                mrp_tx_out_mrp_tx_meta_rdy = noc0_vrtoc_mrp_tx_out_rdy;
                mrp_tx_out_noc0_vrtoc_val = mrp_mrp_tx_out_tx_meta_val;

                ctrl_datap_flit_sel = mrp_tx_pkg::SEL_HDR_FLIT;

                if (mrp_mrp_tx_out_tx_meta_val & noc0_vrtoc_mrp_tx_out_rdy) begin
                    ctrl_datap_store_inputs = 1'b1;

                    state_next = META_FLIT_OUT;
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT_OUT: begin
                mrp_tx_out_noc0_vrtoc_val = 1'b1;
                ctrl_datap_flit_sel = mrp_tx_pkg::SEL_META_FLIT;

                if (noc0_vrtoc_mrp_tx_out_rdy) begin
                    state_next = DATA_FLIT_OUT;
                end
                else begin
                    state_next = META_FLIT_OUT;
                end
            end
            DATA_FLIT_OUT: begin
                ctrl_datap_flit_sel = mrp_tx_pkg::SEL_DATA_FLIT;

                mrp_tx_out_mrp_tx_data_rdy = noc0_vrtoc_mrp_tx_out_rdy;
                mrp_tx_out_noc0_vrtoc_val = mrp_mrp_tx_out_tx_data_val;

                if (noc0_vrtoc_mrp_tx_out_rdy & mrp_mrp_tx_out_tx_data_val) begin
                    if (datap_ctrl_last_output) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_FLIT_OUT;
                    end
                end
                else begin
                    state_next = DATA_FLIT_OUT;
                end
            end
            default: begin
                mrp_tx_out_mrp_tx_meta_rdy = 'X;
                mrp_tx_out_mrp_tx_data_rdy = 'X;

                mrp_tx_out_noc0_vrtoc_val = 'X;

                ctrl_datap_store_inputs = 'X;
                
                ctrl_datap_flit_sel = mrp_tx_pkg::SEL_HDR_FLIT;

                state_next = state_reg;
            end
        endcase
    end
endmodule
