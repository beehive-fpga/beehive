module ip_encap_tx_ctrl (
     input clk
    ,input rst

    ,input  logic                               src_ip_encap_tx_meta_val
    ,output logic                               ip_encap_src_tx_meta_rdy

    ,input  logic                               src_ip_encap_tx_data_val
    ,input  logic                               src_ip_encap_tx_data_last
    ,output logic                               ip_encap_src_tx_data_rdy
    
    ,output logic                               ip_encap_dst_tx_meta_val
    ,input  logic                               dst_ip_encap_tx_meta_rdy
    
    ,output logic                               ip_encap_dst_tx_data_val
    ,input  logic                               dst_ip_encap_tx_data_rdy

    ,output logic                               ctrl_datap_store_inputs
    ,output logic                               ctrl_datap_store_ips

    ,output logic                               ctrl_ip_dir_cam_read_val
    ,input  logic                               ip_dir_cam_ctrl_read_hit

    ,output logic                               ctrl_ip_hdr_assemble_val
    ,input  logic                               ip_hdr_assemble_ctrl_rdy
);

    typedef enum logic[1:0] {
        READY = 2'd0,
        LOOKUP_PHYS_IP = 2'd1,
        OUTPUT = 2'd2,
        TX_WAIT = 2'd3,
        UND = 'X
    } state_e;

    typedef enum logic[1:0] {
        WAITING = 2'd0,
        HDR_OUT = 2'd1,
        META_OUT = 2'd2,
        META_TX_WAIT = 2'd3,
        UNDEF = 'X
    } meta_state_e;

    state_e state_reg;
    state_e state_next;

    meta_state_e meta_state_reg;
    meta_state_e meta_state_next;

    logic   hdr_out_req;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            meta_state_reg <= WAITING;
        end
        else begin
            state_reg <= state_next;
            meta_state_reg <= meta_state_next;
        end
    end

    always_comb begin
        ip_encap_src_tx_meta_rdy = 1'b0;

        ip_encap_dst_tx_data_val = 1'b0;
        ip_encap_src_tx_data_rdy = 1'b0;

        hdr_out_req = 1'b0;
        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_store_ips = 1'b0;
        ctrl_ip_dir_cam_read_val = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ip_encap_src_tx_meta_rdy = 1'b1;
                ctrl_datap_store_inputs = 1'b1;
                if (src_ip_encap_tx_meta_val) begin
                    hdr_out_req = 1'b1;
                    state_next = LOOKUP_PHYS_IP;
                end
                else begin
                    state_next = READY;
                end
            end
            LOOKUP_PHYS_IP: begin
                ctrl_ip_dir_cam_read_val = 1'b1;
                ctrl_datap_store_ips = 1'b1;

                if (ip_dir_cam_ctrl_read_hit) begin
                    state_next = OUTPUT;
                end
                else begin
                    state_next = LOOKUP_PHYS_IP;
                end
            end
            OUTPUT: begin
                ip_encap_dst_tx_data_val = src_ip_encap_tx_data_val;
                ip_encap_src_tx_data_rdy = dst_ip_encap_tx_data_rdy;
                if (src_ip_encap_tx_data_val & dst_ip_encap_tx_data_rdy) begin
                    if (src_ip_encap_tx_data_last) begin
                        state_next = TX_WAIT;
                    end
                    else begin
                        state_next = OUTPUT;
                    end
                end
                else begin
                    state_next = OUTPUT;
                end
            end
            TX_WAIT: begin
                if (meta_state_reg == META_TX_WAIT) begin
                    state_next = READY;
                end
                else begin
                    state_next = TX_WAIT;
                end
            end
            default: begin
                ip_encap_src_tx_meta_rdy = 'X;

                ip_encap_dst_tx_data_val = 'X;
                ip_encap_src_tx_data_rdy = 'X;

                hdr_out_req = 'X;
                ctrl_datap_store_inputs = 'X;
                ctrl_datap_store_ips = 'X;
                ctrl_ip_dir_cam_read_val = 'X;

                state_next = UND;
            end
        endcase
    end

    always_comb begin
        ctrl_ip_hdr_assemble_val = 1'b0;

        ip_encap_dst_tx_meta_val = 1'b0;

        meta_state_next = meta_state_reg;
        case (meta_state_reg)
            WAITING: begin
                if (hdr_out_req) begin
                    meta_state_next = HDR_OUT;
                end
                else begin
                    meta_state_next = WAITING;
                end
            end
            HDR_OUT: begin
                if (ip_hdr_assemble_ctrl_rdy) begin
                    ctrl_ip_hdr_assemble_val = 1'b1;
                    meta_state_next = META_OUT;
                end
                else begin
                    meta_state_next = HDR_OUT;
                end
            end
            META_OUT: begin
                ip_encap_dst_tx_meta_val = 1'b1;
                if (dst_ip_encap_tx_meta_rdy) begin
                    meta_state_next = META_TX_WAIT;
                end
                else begin
                    meta_state_next = META_OUT;
                end
            end
            META_TX_WAIT: begin
                if (state_reg == TX_WAIT) begin
                    meta_state_next = WAITING;
                end
                else begin
                    meta_state_next = META_TX_WAIT;
                end
            end
            default: begin
                ctrl_ip_hdr_assemble_val = 'X;

                ip_encap_dst_tx_meta_val = 'X;

                meta_state_next = UNDEF;
            end
        endcase
    end

endmodule
