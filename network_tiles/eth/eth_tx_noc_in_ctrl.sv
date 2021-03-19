`include "eth_tx_tile_defs.svh"
module eth_tx_noc_in_ctrl (
     input clk
    ,input rst
    
    ,input                                      noc0_ctovr_eth_tx_in_val
    ,output logic                               eth_tx_in_noc0_ctovr_rdy

    ,output logic                               eth_tx_in_eth_tostream_eth_hdr_val
    ,input                                      eth_tostream_eth_tx_in_eth_hdr_rdy

    ,output logic                               eth_tx_in_eth_tostream_data_val
    ,input                                      eth_tostream_eth_tx_in_data_rdy

    ,output logic                               ctrl_datap_store_hdr_flit
    ,output logic                               ctrl_datap_store_meta_flit
    ,output logic                               ctrl_datap_init_num_flits
    ,output logic                               ctrl_datap_decr_num_flits

    ,input                                      datap_ctrl_last_flit

    ,output logic                               eth_wr_log
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        META_FLIT = 2'd1,
        DATA_FLITS = 2'd2,
        DATA_TX_WAIT = 2'd3,
        UND = 'X
    } data_state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        HDR_OUTPUT = 2'd1,
        HDR_OUTPUT_REG = 2'd2,
        HDR_TX_WAIT = 2'd3,
        HDR_UND = 'X
    } hdr_state_e;

    data_state_e data_state_reg;
    data_state_e data_state_next;

    hdr_state_e hdr_state_reg;
    hdr_state_e hdr_state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            data_state_reg <= READY;
            hdr_state_reg <= WAITING;
        end
        else begin
            data_state_reg <= data_state_next;
            hdr_state_reg <= hdr_state_next;
        end
    end

    always_comb begin
        ctrl_datap_store_hdr_flit = 1'b0;
        ctrl_datap_store_meta_flit = 1'b0;
        ctrl_datap_init_num_flits = 1'b0;
        ctrl_datap_decr_num_flits = 1'b0;

        eth_tx_in_noc0_ctovr_rdy = 1'b0;
        eth_tx_in_eth_tostream_data_val = 1'b0;

        data_state_next = data_state_reg;

        eth_wr_log = 1'b0;
        case (data_state_reg)
            READY: begin
                eth_tx_in_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_eth_tx_in_val) begin
                    ctrl_datap_store_hdr_flit = 1'b1;
                    ctrl_datap_init_num_flits = 1'b1;
                    data_state_next = META_FLIT;
                end
                else begin
                    data_state_next = READY;
                end
            end
            META_FLIT: begin
                eth_tx_in_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_eth_tx_in_val) begin
                    ctrl_datap_store_meta_flit = 1'b1;
                    ctrl_datap_decr_num_flits = 1'b1;
                    data_state_next = DATA_FLITS;
                end
                else begin
                    data_state_next = META_FLIT;
                end
            end
            DATA_FLITS: begin
                eth_tx_in_eth_tostream_data_val = noc0_ctovr_eth_tx_in_val;
                eth_tx_in_noc0_ctovr_rdy = eth_tostream_eth_tx_in_data_rdy;
                if (noc0_ctovr_eth_tx_in_val & eth_tostream_eth_tx_in_data_rdy) begin
                    ctrl_datap_decr_num_flits = 1'b1;
                    if (datap_ctrl_last_flit) begin
                        eth_wr_log = 1'b1;
                        data_state_next = DATA_TX_WAIT;
                    end
                    else begin
                        data_state_next = DATA_FLITS;
                    end
                end
                else begin
                    data_state_next = DATA_FLITS;
                end
            end
            DATA_TX_WAIT: begin
                if (hdr_state_reg == HDR_TX_WAIT) begin
                    data_state_next = READY;
                end
                else begin
                    data_state_next = DATA_TX_WAIT;
                end
            end
            default: begin
                ctrl_datap_store_hdr_flit = 'X;
                ctrl_datap_store_meta_flit = 'X;
                ctrl_datap_init_num_flits = 'X;
                ctrl_datap_decr_num_flits = 'X;

                eth_tx_in_noc0_ctovr_rdy = 'X;
                eth_tx_in_eth_tostream_data_val = 'X;

                data_state_next = UND;
            end
        endcase
    end

    always_comb begin
        eth_tx_in_eth_tostream_eth_hdr_val = 1'b0;

        hdr_state_next = hdr_state_reg;
        case (hdr_state_reg) 
            WAITING: begin
                if (data_state_next == META_FLIT) begin
                    hdr_state_next = HDR_OUTPUT;
                end
                else begin
                    hdr_state_next = WAITING;
                end
            end
            HDR_OUTPUT: begin
                eth_tx_in_eth_tostream_eth_hdr_val = noc0_ctovr_eth_tx_in_val;

                if (noc0_ctovr_eth_tx_in_val) begin
                    if (eth_tostream_eth_tx_in_eth_hdr_rdy) begin
                        hdr_state_next = HDR_TX_WAIT;
                    end
                    else begin
                        hdr_state_next = HDR_OUTPUT_REG;
                    end
                end
                else begin
                    hdr_state_next = HDR_OUTPUT;
                end
            end
            HDR_OUTPUT_REG: begin
                eth_tx_in_eth_tostream_eth_hdr_val = 1'b1;
                if (eth_tostream_eth_tx_in_eth_hdr_rdy) begin
                    hdr_state_next = HDR_TX_WAIT;
                end
                else begin
                    hdr_state_next = HDR_OUTPUT;
                end
            end
            HDR_TX_WAIT: begin
                if (data_state_reg == DATA_TX_WAIT) begin
                    hdr_state_next = WAITING;
                end
                else begin
                    hdr_state_next = HDR_TX_WAIT;
                end
            end
            default: begin
                eth_tx_in_eth_tostream_eth_hdr_val = 'X;

                hdr_state_next = HDR_UND;
            end
        endcase
    end


endmodule
