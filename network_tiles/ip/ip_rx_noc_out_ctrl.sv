`include "ip_rx_tile_defs.svh"
module ip_rx_noc_out_ctrl (
     input clk
    ,input rst
    
    ,input  logic                                   ip_format_ip_rx_out_rx_hdr_val
    ,output logic                                   ip_rx_out_ip_format_rx_hdr_rdy

    ,input  logic                                   ip_format_ip_rx_out_rx_data_val
    ,input  logic                                   ip_format_ip_rx_out_rx_last
    ,output logic                                   ip_rx_out_ip_format_rx_data_rdy
    
    ,output logic                                   ip_rx_out_noc0_vrtoc_val
    ,input                                          noc0_vrtoc_ip_rx_out_rdy
    
    ,output ip_rx_tile_pkg::noc_out_flit_mux_sel    ctrl_datap_flit_sel
    ,output logic                                   ctrl_datap_store_inputs
    
    ,input  logic                                   datap_ctrl_last_output

    ,output logic                                   ctrl_cam_rd_cam
    ,input  logic                                   cam_ctrl_rd_hit
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        META_FLIT_OUT = 2'd1,
        DATA_FLIT_OUT = 2'd2,
        DUMP_PKT = 2'd3,
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
        ip_rx_out_ip_format_rx_hdr_rdy = 1'b0;
        ip_rx_out_ip_format_rx_data_rdy = 1'b0;
        ip_rx_out_noc0_vrtoc_val = 1'b0;

        ctrl_datap_flit_sel = ip_rx_tile_pkg::SEL_HDR_FLIT;
        ctrl_datap_store_inputs = 1'b0;

        ctrl_cam_rd_cam = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ip_rx_out_ip_format_rx_hdr_rdy = noc0_vrtoc_ip_rx_out_rdy;
                ip_rx_out_noc0_vrtoc_val = ip_format_ip_rx_out_rx_hdr_val 
                                           & cam_ctrl_rd_hit;

                ctrl_datap_flit_sel = ip_rx_tile_pkg::SEL_HDR_FLIT;
                ctrl_cam_rd_cam = 1'b1;

                if (ip_format_ip_rx_out_rx_hdr_val & noc0_vrtoc_ip_rx_out_rdy) begin
                    ctrl_datap_store_inputs = 1'b1;

                    if (cam_ctrl_rd_hit) begin
                        state_next = META_FLIT_OUT;
                    end
                    else begin
                        state_next = DUMP_PKT;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            META_FLIT_OUT: begin
                ctrl_datap_flit_sel = ip_rx_tile_pkg::SEL_META_FLIT;

                ip_rx_out_noc0_vrtoc_val = 1'b1;

                if (noc0_vrtoc_ip_rx_out_rdy) begin
                    state_next = DATA_FLIT_OUT;
                end
                else begin
                    state_next = META_FLIT_OUT;
                end
            end
            DATA_FLIT_OUT: begin
                ctrl_datap_flit_sel = ip_rx_tile_pkg::SEL_DATA_FLIT;

                ip_rx_out_noc0_vrtoc_val = ip_format_ip_rx_out_rx_data_val;
                ip_rx_out_ip_format_rx_data_rdy = noc0_vrtoc_ip_rx_out_rdy;

                if (noc0_vrtoc_ip_rx_out_rdy & ip_format_ip_rx_out_rx_data_val) begin
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
            DUMP_PKT: begin
                ip_rx_out_ip_format_rx_data_rdy = 1'b1;

                if (ip_format_ip_rx_out_rx_data_val & ip_format_ip_rx_out_rx_last) begin
                    state_next = READY;
                end
                else begin
                    state_next = DUMP_PKT;
                end
            end
            default: begin
                ip_rx_out_ip_format_rx_hdr_rdy = 'X;
                ip_rx_out_ip_format_rx_data_rdy = 'X;
                ip_rx_out_noc0_vrtoc_val = 'X;

                ctrl_datap_flit_sel = ip_rx_tile_pkg::SEL_HDR_FLIT;
                ctrl_datap_store_inputs = 'X;

                state_next = UND;
            end
        endcase
    end


endmodule
