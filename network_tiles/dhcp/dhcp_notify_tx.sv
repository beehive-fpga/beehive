`include "dhcp_tile_defs.svh"

// Pushes a 2-flit NoC notification (header + 1 data flit) to a single
// subscriber. Triggered by a one-cycle `notify_start`; the latched
// msg_type (DHCP_IP_BIND for now) and yiaddr ride for the whole burst,
// so the FSM is free to move on. `notify_done` pulses one cycle after
// the data flit handshakes.
//
// Step 7 sends to a single subscriber so cocotb can verify the bytes
// landing on the NoC TX path. A multi-subscriber walk drops in here
// whenever real consumers exist downstream.
module dhcp_notify_tx #(
    parameter int                                 NOC_DATA_W = `NOC_DATA_WIDTH,
    parameter logic [`MSG_DST_X_WIDTH-1:0]        SRC_X      = '0,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]        SRC_Y      = '0,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0]    SRC_FBITS  = PKT_IF_FBITS,
    parameter logic [`MSG_DST_X_WIDTH-1:0]        SUB_X      = '0,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]        SUB_Y      = '0,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0]    SUB_FBITS  = PKT_IF_FBITS
) (
    input  logic clk,
    input  logic rst,

    input  logic                          notify_start,
    input  logic [`MSG_TYPE_WIDTH-1:0]    notify_msg_type,
    input  logic [`IP_ADDR_W-1:0]         notify_yiaddr,

    output logic                          noc_val,
    output logic [NOC_DATA_W-1:0]         noc_data,
    input  logic                          noc_rdy,

    output logic                          notify_done
);
    typedef enum logic [1:0] {
        IDLE     = 2'd0,
        SEND_HDR = 2'd1,
        SEND_DAT = 2'd2,
        UND      = 'X
    } state_e;

    state_e state_reg, state_next;

    logic [`MSG_TYPE_WIDTH-1:0] msg_type_reg, msg_type_next;
    logic [`IP_ADDR_W-1:0]      yiaddr_reg,   yiaddr_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg    <= IDLE;
            msg_type_reg <= '0;
            yiaddr_reg   <= '0;
        end else begin
            state_reg    <= state_next;
            msg_type_reg <= msg_type_next;
            yiaddr_reg   <= yiaddr_next;
        end
    end

    beehive_noc_hdr_flit hdr_flit;
    always_comb begin
        hdr_flit                       = '0;
        hdr_flit.core.core.dst_chip_id = '0;
        hdr_flit.core.core.dst_x_coord = SUB_X;
        hdr_flit.core.core.dst_y_coord = SUB_Y;
        hdr_flit.core.core.dst_fbits   = SUB_FBITS;
        // 1 data flit, no metadata flits.
        hdr_flit.core.core.msg_len     = `MSG_LENGTH_WIDTH'd1;
        hdr_flit.core.core.msg_type    = msg_type_reg;
        hdr_flit.core.core.src_chip_id = '0;
        hdr_flit.core.core.src_x_coord = SRC_X;
        hdr_flit.core.core.src_y_coord = SRC_Y;
        hdr_flit.core.core.src_fbits   = SRC_FBITS;
        hdr_flit.core.metadata_flits   = '0;
    end

    logic [NOC_DATA_W-1:0] data_flit;
    always_comb begin
        data_flit = '0;
        // Place yiaddr at the most-significant bytes of the flit.
        data_flit[NOC_DATA_W-1 -: `IP_ADDR_W] = yiaddr_reg;
    end

    always_comb begin
        state_next    = state_reg;
        msg_type_next = msg_type_reg;
        yiaddr_next   = yiaddr_reg;
        noc_val       = 1'b0;
        noc_data      = '0;
        notify_done   = 1'b0;

        case (state_reg)
            IDLE: begin
                if (notify_start) begin
                    msg_type_next = notify_msg_type;
                    yiaddr_next   = notify_yiaddr;
                    state_next    = SEND_HDR;
                end
            end
            SEND_HDR: begin
                noc_val  = 1'b1;
                noc_data = hdr_flit;
                if (noc_rdy) state_next = SEND_DAT;
            end
            SEND_DAT: begin
                noc_val  = 1'b1;
                noc_data = data_flit;
                if (noc_rdy) begin
                    notify_done = 1'b1;
                    state_next  = IDLE;
                end
            end
            default: begin
                state_next = UND;
            end
        endcase
    end
endmodule
