`include "eth_rx_tile_defs.svh"
module eth_rx_noc_out_ctrl(
     input clk
    ,input rst
    
    ,output logic                                   eth_rx_out_noc0_vrtoc_val
    ,input                                          noc0_vrtoc_eth_rx_out_rdy
    
    ,input  logic                                   eth_format_eth_rx_out_hdr_val
    ,output logic                                   eth_rx_out_eth_format_hdr_rdy

    ,input  logic                                   eth_format_eth_rx_out_data_val
    ,input                                          eth_format_eth_rx_out_data_last
    ,output logic                                   eth_rx_out_eth_format_data_rdy

    ,output eth_rx_tile_pkg::noc_out_flit_mux_sel   ctrl_datap_flit_sel
    ,output logic                                   ctrl_datap_store_inputs 
    
    ,output logic                                   ctrl_cam_rd_cam
    ,input  logic                                   cam_ctrl_rd_hit 
);
    
    
    typedef enum logic[1:0] {
        READY = 2'd0,
        METADATA_FLIT_OUT = 2'd1,
        DATA_FLITS_OUT = 2'd2,
        DROP_PKT = 2'd3,
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
        ctrl_datap_store_inputs = 1'b0; 
        ctrl_datap_flit_sel = eth_rx_tile_pkg::SEL_HDR_FLIT;

        ctrl_cam_rd_cam = 1'b0;

        eth_rx_out_eth_format_hdr_rdy = 1'b0;
        eth_rx_out_eth_format_data_rdy = 1'b0;

        eth_rx_out_noc0_vrtoc_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                eth_rx_out_eth_format_hdr_rdy = noc0_vrtoc_eth_rx_out_rdy;
                eth_rx_out_noc0_vrtoc_val = eth_format_eth_rx_out_hdr_val 
                                            & cam_ctrl_rd_hit;

                ctrl_datap_flit_sel = eth_rx_tile_pkg::SEL_HDR_FLIT;
                ctrl_cam_rd_cam = 1'b1;

                if (eth_format_eth_rx_out_hdr_val & eth_rx_out_eth_format_hdr_rdy) begin
                    ctrl_datap_store_inputs = 1'b1;
                    if (cam_ctrl_rd_hit) begin
                        state_next = METADATA_FLIT_OUT;
                    end
                    else begin
                        state_next = DROP_PKT;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            METADATA_FLIT_OUT: begin
                ctrl_datap_flit_sel = eth_rx_tile_pkg::SEL_META_FLIT;

                eth_rx_out_noc0_vrtoc_val = 1'b1;

                if (noc0_vrtoc_eth_rx_out_rdy) begin
                    state_next = DATA_FLITS_OUT;
                end
                else begin
                    state_next = METADATA_FLIT_OUT;
                end
            end
            DATA_FLITS_OUT: begin
                ctrl_datap_flit_sel = eth_rx_tile_pkg::SEL_DATA_FLIT;
                eth_rx_out_noc0_vrtoc_val = eth_format_eth_rx_out_data_val;
                eth_rx_out_eth_format_data_rdy = noc0_vrtoc_eth_rx_out_rdy;

                if (noc0_vrtoc_eth_rx_out_rdy & eth_rx_out_noc0_vrtoc_val) begin
                    if (eth_format_eth_rx_out_data_last) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA_FLITS_OUT;
                    end
                end
                else begin
                    state_next = DATA_FLITS_OUT;
                end
            end
            DROP_PKT: begin
                eth_rx_out_eth_format_data_rdy = 1'b1;
                if (eth_format_eth_rx_out_data_val & eth_format_eth_rx_out_data_last) begin
                    state_next = READY;
                end
                else begin
                    state_next = DROP_PKT;
                end
            end
            default: begin
            end
        endcase
    end
endmodule
