module from_udp_ctrl (
     input  clk
    ,input  rst

    ,input  logic                       noc_ctovr_fr_udp_val
    ,output logic                       fr_udp_noc_ctovr_rdy

    ,output logic                       fr_udp_dst_meta_val
    ,input                              dst_fr_udp_meta_rdy

    ,output logic                       fr_udp_dst_data_val
    ,output logic                       fr_udp_dst_data_last
    ,input  logic                       dst_fr_udp_data_rdy

    ,output logic                       ctrl_datap_store_hdr_data
    ,output logic                       ctrl_datap_store_meta_data
    ,output logic                       ctrl_datap_cnt_flit

    ,input  logic                       datap_ctrl_last_data
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        META = 2'd1,
        DATA_PASS = 2'd2,
        WAIT_META = 2'd3,
        UND = 'X
    } data_state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        META_OUT = 2'd1,
        WAIT_DATA = 2'd2,
        UNDEF = 'X
    } meta_state_e;

    data_state_e data_state_reg;
    data_state_e data_state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    logic       output_meta;

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
        fr_udp_noc_ctovr_rdy = 1'b0;
        fr_udp_dst_data_val = 1'b0;
        fr_udp_dst_data_last = 1'b0;

        ctrl_datap_store_hdr_data = 1'b0;
        ctrl_datap_store_meta_data = 1'b0;
        ctrl_datap_cnt_flit = 1'b0;

        output_meta = 1'b0;

        data_state_next = data_state_reg;
        case (data_state_reg)
            READY: begin
                fr_udp_noc_ctovr_rdy = 1'b1;
                ctrl_datap_store_hdr_data = 1'b1;
                if (noc_ctovr_fr_udp_val) begin
                    data_state_next = META;
                end
            end
            META: begin
                fr_udp_noc_ctovr_rdy = 1'b1;
                ctrl_datap_store_meta_data = 1'b1;

                if (noc_ctovr_fr_udp_val) begin
                    output_meta = 1'b1;
                    ctrl_datap_cnt_flit = 1'b1;
                    data_state_next = DATA_PASS;
                end
            end
            DATA_PASS: begin
                fr_udp_noc_ctovr_rdy = dst_fr_udp_data_rdy;
                fr_udp_dst_data_val = noc_ctovr_fr_udp_val;

                if (dst_fr_udp_data_rdy & noc_ctovr_fr_udp_val) begin
                    ctrl_datap_cnt_flit = 1'b1;
                    if (datap_ctrl_last_data) begin
                        fr_udp_dst_data_last = 1'b1;
                        data_state_next = WAIT_META;
                    end
                end
            end
            WAIT_META: begin
                if (meta_state_reg == WAIT_DATA) begin
                    data_state_next = READY;
                end
            end
            default: begin
                fr_udp_noc_ctovr_rdy = 'X;
                fr_udp_dst_data_val = 'X;

                ctrl_datap_store_hdr_data = 'X;
                ctrl_datap_store_meta_data = 'X;

                output_meta = 'X;

                data_state_next = UND;
            end
        endcase
    end

    always_comb begin
        fr_udp_dst_meta_val = 1'b0;

        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (output_meta) begin
                    meta_state_next = META_OUT;
                end
            end
            META_OUT: begin
                fr_udp_dst_meta_val = 1'b1;
                if (dst_fr_udp_meta_rdy) begin
                    meta_state_next = WAIT_DATA;
                end
            end
            WAIT_DATA: begin
                if (data_state_reg == WAIT_META) begin
                    meta_state_next = WAITING;
                end
            end
            default: begin
                fr_udp_dst_meta_val = 'X;

                meta_state_next = UNDEF;
            end
        endcase
    end
endmodule
