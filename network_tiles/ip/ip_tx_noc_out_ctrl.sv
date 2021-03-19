`include "ip_tx_tile_defs.svh"
module ip_tx_noc_out_ctrl (
     input clk
    ,input rst
    
    ,output logic                                   ip_tx_out_noc0_vrtoc_val
    ,input  logic                                   noc0_vrtoc_ip_tx_out_rdy
    
    ,input  logic                                   ip_to_ethstream_ip_tx_out_hdr_val
    ,output logic                                   ip_tx_out_ip_to_ethstream_hdr_rdy

    ,input  logic                                   ip_to_ethstream_ip_tx_out_data_val
    ,output logic                                   ip_tx_out_ip_to_ethstream_data_rdy

    ,output ip_tx_tile_pkg::noc_out_flit_mux_sel    ctrl_datap_flit_sel
    ,output logic                                   ctrl_datap_store_inputs

    ,input  logic                                   datap_ctrl_last_output
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
        ip_tx_out_ip_to_ethstream_hdr_rdy = 1'b0;
        ip_tx_out_ip_to_ethstream_data_rdy = 1'b0;
        ip_tx_out_noc0_vrtoc_val = 1'b0;

        ctrl_datap_flit_sel = ip_tx_tile_pkg::SEL_HDR_FLIT;
        ctrl_datap_store_inputs = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ip_tx_out_ip_to_ethstream_hdr_rdy = noc0_vrtoc_ip_tx_out_rdy;
                ip_tx_out_noc0_vrtoc_val = ip_to_ethstream_ip_tx_out_hdr_val;

                ctrl_datap_flit_sel = ip_tx_tile_pkg::SEL_HDR_FLIT;
                if (ip_to_ethstream_ip_tx_out_hdr_val & noc0_vrtoc_ip_tx_out_rdy) begin
                    ctrl_datap_store_inputs = 1'b1;
                    state_next = META_FLIT_OUT;
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT_OUT: begin
                ip_tx_out_noc0_vrtoc_val = 1'b1;
                ctrl_datap_flit_sel = ip_tx_tile_pkg::SEL_META_FLIT;
                
                if (noc0_vrtoc_ip_tx_out_rdy) begin
                    state_next = DATA_FLIT_OUT;
                end
                else begin
                    state_next = META_FLIT_OUT;
                end
            end
            DATA_FLIT_OUT: begin
                ctrl_datap_flit_sel = ip_tx_tile_pkg::SEL_DATA_FLIT;

                ip_tx_out_ip_to_ethstream_data_rdy = noc0_vrtoc_ip_tx_out_rdy;
                ip_tx_out_noc0_vrtoc_val = ip_to_ethstream_ip_tx_out_data_val;

                if (noc0_vrtoc_ip_tx_out_rdy & ip_to_ethstream_ip_tx_out_data_val) begin
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
                ip_tx_out_ip_to_ethstream_hdr_rdy = 'X;
                ip_tx_out_ip_to_ethstream_data_rdy = 'X;
                ip_tx_out_noc0_vrtoc_val = 'X;

                ctrl_datap_flit_sel = ip_tx_tile_pkg::SEL_HDR_FLIT;
                ctrl_datap_store_inputs = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule
