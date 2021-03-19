module to_udp_ctrl
import app_udp_adapter_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic                       src_to_udp_meta_val
    ,output logic                       to_udp_src_meta_rdy

    ,input  logic                       src_to_udp_data_val
    ,output logic                       to_udp_src_data_rdy

    ,output logic                       to_udp_noc_vrtoc_val
    ,input  logic                       noc_vrtoc_to_udp_rdy

    ,output to_udp_mux_out_e            ctrl_datap_data_mux_sel
    ,output logic                       ctrl_datap_init_state
    ,output logic                       ctrl_datap_cnt_flit

    ,input  logic                       datap_ctrl_last_flit
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        HDR_FLIT_OUT = 2'd1,
        META_FLIT_OUT = 2'd2,
        DATA_PASSTHRU = 2'd3,
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
        to_udp_src_meta_rdy = 1'b0;
        to_udp_src_data_rdy = 1'b0;

        to_udp_noc_vrtoc_val = 1'b0;

        ctrl_datap_cnt_flit = 1'b0;
        ctrl_datap_data_mux_sel = HDR_OUT;
        ctrl_datap_init_state = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_init_state = 1'b1;
                to_udp_src_meta_rdy = 1'b1;

                if (src_to_udp_meta_val) begin
                    state_next = HDR_FLIT_OUT;
                end
            end
            HDR_FLIT_OUT: begin
                to_udp_noc_vrtoc_val = 1'b1;
                ctrl_datap_data_mux_sel = HDR_OUT;

                if (noc_vrtoc_to_udp_rdy) begin
                    state_next = META_FLIT_OUT;
                end
            end
            META_FLIT_OUT: begin
                ctrl_datap_data_mux_sel = META_OUT;
                to_udp_noc_vrtoc_val = 1'b1;

                if (noc_vrtoc_to_udp_rdy) begin
                    ctrl_datap_cnt_flit = 1'b1;
                    state_next = DATA_PASSTHRU;
                end
            end
            DATA_PASSTHRU: begin
                ctrl_datap_data_mux_sel = DATA_OUT;
                to_udp_noc_vrtoc_val = src_to_udp_data_val;
                to_udp_src_data_rdy = noc_vrtoc_to_udp_rdy;

                if (src_to_udp_data_val & noc_vrtoc_to_udp_rdy) begin
                    ctrl_datap_cnt_flit = 1'b1;
                    if (datap_ctrl_last_flit) begin
                        state_next = READY;
                    end
                end
            end
            default: begin
                to_udp_src_meta_rdy = 'X;
                to_udp_src_data_rdy = 'X;

                to_udp_noc_vrtoc_val = 'X;

                ctrl_datap_cnt_flit = 'X;
                ctrl_datap_init_state = 'X;
                
                ctrl_datap_data_mux_sel = HDR_OUT;

                state_next = UND;
            end
        endcase
    end

endmodule
