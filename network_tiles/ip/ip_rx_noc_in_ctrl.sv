// Parse incoming NoC messages for the module that will parse IP headers
// Really it just strips off the header & metadata flits
`include "ip_rx_tile_defs.svh"
module ip_rx_noc_in_ctrl (
     input clk
    ,input rst
    
    ,input                                      noc0_ctovr_ip_rx_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]       noc0_ctovr_ip_rx_in_data
    ,output logic                               ip_rx_in_noc0_ctovr_rdy

    ,output logic                               ip_rx_in_ip_format_rx_val
    ,input  logic                               ip_format_ip_rx_in_rx_rdy

    ,input  logic                               datap_ctrl_last_flit
    ,input  logic                               datap_ctrl_last_meta_flit

    ,output logic                               ctrl_datap_init_data
    ,output logic                               ctrl_datap_store_meta_flit
    ,output logic                               ctrl_datap_decr_meta_flits
    ,output logic                               ctrl_datap_decr_data_flits
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        META = 2'd1,
        DATA = 2'd2,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   no_meta_flit;
    beehive_noc_hdr_flit hdr_flit_cast;

    assign hdr_flit_cast = noc0_ctovr_ip_rx_in_data;
    assign no_meta_flit = hdr_flit_cast.core.metadata_flits == 0;


    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next;
        end
    end

    always_comb begin
        ip_rx_in_noc0_ctovr_rdy = 1'b0;
        ip_rx_in_ip_format_rx_val = 1'b0;

        ctrl_datap_init_data = 1'b0;
        ctrl_datap_store_meta_flit = 1'b0;
        ctrl_datap_decr_meta_flits = 1'b0;
        ctrl_datap_decr_data_flits = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ip_rx_in_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_ip_rx_in_val) begin
                    ctrl_datap_init_data = 1'b1;
                    if (no_meta_flit) begin
                        state_next = DATA;
                    end
                    else begin
                        state_next = META;
                    end
                end
                else begin
                    state_next = READY;
                end
            end
            META: begin
                ip_rx_in_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_ip_rx_in_val) begin
                    ctrl_datap_store_meta_flit = 1'b1;
                    ctrl_datap_decr_meta_flits = 1'b1;

                    if (datap_ctrl_last_meta_flit) begin
                        state_next = DATA;
                    end
                    else begin
                        state_next = META;
                    end
                end
                else begin
                    state_next = META;
                end
            end
            DATA: begin
                ip_rx_in_ip_format_rx_val = noc0_ctovr_ip_rx_in_val;
                ip_rx_in_noc0_ctovr_rdy = ip_format_ip_rx_in_rx_rdy;

                if (noc0_ctovr_ip_rx_in_val & ip_format_ip_rx_in_rx_rdy) begin
                    ctrl_datap_decr_data_flits = 1'b1;

                    if (datap_ctrl_last_flit) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = DATA;
                    end
                end
                else begin
                    state_next = DATA;
                end
            end
            default: begin
                ip_rx_in_noc0_ctovr_rdy = 'X;
                ip_rx_in_ip_format_rx_val = 'X;

                ctrl_datap_init_data = 'X;
                ctrl_datap_decr_meta_flits = 'X;
                ctrl_datap_decr_data_flits = 'X;

                state_next = UND;
            end
        endcase
    end

endmodule

