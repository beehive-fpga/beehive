module tcp_msg_req_ctrl (
     input clk
    ,input rst

    ,input  logic                           src_msg_req_val
    ,output logic                           msg_req_src_rdy

    ,output logic                           msg_req_dst_val
    ,input  logic                           dst_msg_req_rdy

    ,input  logic                           monitor_msg_req_val
    ,output logic                           msg_req_monitor_rdy

    ,output logic                           msg_req_monitor_val
    ,input  logic                           monitor_msg_req_rdy

    ,output logic                           ctrl_datap_store_inputs
    ,output logic                           ctrl_datap_send_hdr
    ,output logic                           ctrl_datap_store_rsp_body

    ,input  logic                           datap_ctrl_cmd_type
);

    typedef enum logic[2:0] {
        READY = 3'd0,
        SEND_HDR = 3'd1,
        SEND_BODY = 3'd2,
        RECV_HDR = 3'd3,
        RECV_BODY = 3'd4,
        NOTIF = 3'd5,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
        end
        else begin
            state_reg <= state_next
        end
    end

    always_comb begin
        msg_req_src_rdy = 1'b0;
        msg_req_monitor_rdy = 1'b0;
        msg_req_monitor_val = 1'b0;
        msg_req_dst_val = 1'b0;

        ctrl_datap_store_inputs = 1'b0;
        ctrl_datap_send_hdr = 1'b0;
        ctrl_datap_store_rsp_body = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                ctrl_datap_store_inputs = 1'b1;
                msg_req_src_rdy = 1'b1;
                if (src_msg_req_val) begin
                    state_next = SEND_HDR;
                end
            end
            SEND_HDR: begin
                msg_req_monitor_val = 1'b1;
                ctrl_datap_send_hdr = 1'b1;
                if (monitor_msg_req_rdy) begin
                    state_next = SEND_BODY;
                end
            end
            SEND_BODY: begin
                msg_req_monitor_val = 1'b1;
                if (monitor_msg_req_rdy) begin
                    if (datap_ctrl_cmd_type == TCP_PTR_UPDATE) begin
                        state_next = READY;
                    end
                    else begin
                        state_next = RECV_HDR;
                    end
                end
            end
            RECV_HDR: begin
                msg_req_monitor_rdy = 1'b1;
                if (monitor_msg_req_val) begin
                    state_next = RECV_BODY;
                end
            end
            RECV_BODY: begin
                msg_req_monitor_rdy = 1'b1;
                if (monitor_msg_req_val) begin
                    state_next = NOTIF;
                end
            end
            NOTIF: begin
                msg_req_dst_val = 1'b1;
                if (dst_msg_req_rdy) begin
                    state_next = READY;
                end
            end
        endcase
    end
endmodule