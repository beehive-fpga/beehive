module mrp_rx_noc_in_ctrl (
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_mrp_rx_in_val
    ,output logic                           mrp_rx_in_noc0_ctovr_rdy
    
    ,output logic                           mrp_rx_in_mrp_engine_rx_hdr_val
    ,input  logic                           mrp_engine_mrp_rx_in_rx_hdr_rdy

    ,output logic                           mrp_rx_in_mrp_engine_rx_data_val
    ,input  logic                           mrp_engine_mrp_rx_in_rx_data_rdy
    
    ,output logic                           ctrl_datap_store_hdr_flit
    ,output logic                           ctrl_datap_store_meta_flit
    ,output logic                           ctrl_datap_init_num_flits
    ,output logic                           ctrl_datap_decr_num_flits

    ,input                                  datap_ctrl_last_flit
);

    typedef enum logic [1:0] {
        READY = 2'd0,
        META_FLIT = 2'd1,
        DATA_FLITS = 2'd2,
        DATA_TX_WAIT = 2'd3,
        UND = 'X
    } data_state_e;
    
    typedef enum logic[1:0] {
        WAITING = 2'd0,
        META_OUTPUT = 2'd1,
        META_OUTPUT_REG = 2'd2,
        META_TX_WAIT = 2'd3,
        META_UND = 'X
    } meta_state_e;

    data_state_e data_state_reg;
    data_state_e data_state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            data_state_reg <= READY;
            meta_state_reg <= WAITING;
        end
        else begin
            data_state_reg <= data_state_next;
            meta_state_reg <= meta_state_next;
        end
    end

    always_comb begin
        ctrl_datap_store_hdr_flit = 1'b0;
        ctrl_datap_store_meta_flit = 1'b0;
        ctrl_datap_init_num_flits = 1'b0;
        ctrl_datap_decr_num_flits = 1'b0;

        mrp_rx_in_noc0_ctovr_rdy = 1'b0;
        mrp_rx_in_mrp_engine_rx_data_val = 1'b0;

        data_state_next = data_state_reg;

        case (data_state_reg)
            READY: begin
                mrp_rx_in_noc0_ctovr_rdy = 1'b1;

                if (noc0_ctovr_mrp_rx_in_val) begin
                    ctrl_datap_store_hdr_flit = 1'b1;
                    ctrl_datap_init_num_flits = 1'b1;

                    data_state_next = META_FLIT;
                end
                else begin
                    data_state_next = READY;
                end
            end
            META_FLIT: begin
                mrp_rx_in_noc0_ctovr_rdy = 1'b1;
                if (noc0_ctovr_mrp_rx_in_val) begin
                    ctrl_datap_store_meta_flit = 1'b1;
                    ctrl_datap_decr_num_flits = 1'b1;

                    data_state_next = DATA_FLITS;
                end
                else begin
                    data_state_next = META_FLIT;
                end
            end
            DATA_FLITS: begin
                mrp_rx_in_mrp_engine_rx_data_val = noc0_ctovr_mrp_rx_in_val;
                mrp_rx_in_noc0_ctovr_rdy = mrp_engine_mrp_rx_in_rx_data_rdy;

                if (noc0_ctovr_mrp_rx_in_val & mrp_engine_mrp_rx_in_rx_data_rdy) begin
                    ctrl_datap_decr_num_flits = 1'b1;

                    if (datap_ctrl_last_flit) begin
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
                if (meta_state_reg == META_TX_WAIT) begin
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

                mrp_rx_in_noc0_ctovr_rdy = 'X;
                mrp_rx_in_mrp_engine_rx_data_val = 'X;

                data_state_next = UND;
            end
        endcase
    end

    always_comb begin
        mrp_rx_in_mrp_engine_rx_hdr_val = 1'b0;

        meta_state_next = meta_state_reg;

        case (meta_state_reg)
            WAITING: begin
                if (data_state_next == META_FLIT) begin
                    meta_state_next = META_OUTPUT;
                end
                else begin
                    meta_state_next = WAITING;
                end
            end
            META_OUTPUT: begin
                if (noc0_ctovr_mrp_rx_in_val) begin
                    mrp_rx_in_mrp_engine_rx_hdr_val = 1'b1;

                    if (mrp_engine_mrp_rx_in_rx_hdr_rdy) begin
                        meta_state_next = META_TX_WAIT;
                    end
                    else begin
                        meta_state_next = META_OUTPUT_REG;
                    end
                end
                else begin
                    meta_state_next = META_OUTPUT;
                end
            end
            META_OUTPUT_REG: begin
                mrp_rx_in_mrp_engine_rx_hdr_val = 1'b1;
                if (mrp_engine_mrp_rx_in_rx_hdr_rdy) begin
                    meta_state_next = META_TX_WAIT;
                end
                else begin
                    meta_state_next = META_OUTPUT_REG;
                end
            end
            META_TX_WAIT: begin
                if (data_state_reg == DATA_TX_WAIT) begin
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = META_TX_WAIT;
                end
            end
            default: begin
                mrp_rx_in_mrp_engine_rx_hdr_val = 'X;

                meta_state_next = META_UND;
            end
        endcase
    end
endmodule
