`include "dhcp_tile_defs.svh"

// Pushes a 2-flit NoC notification (header + 1 data flit) to up to two
// subscribers in sequence. On notify_start the FSM walks:
//   SEND_HDR(0) -> SEND_DAT(0) -> [if NUM_SUBSCRIBERS==2]
//   SEND_HDR(1) -> SEND_DAT(1) -> IDLE
// The latched msg_type (DHCP_IP_BIND / DHCP_IP_EXPIRE) and yiaddr ride
// for the whole walk; the FSM is free to move on as soon as the last
// flit handshakes. notify_done pulses one cycle after the final
// subscriber's data flit handshakes.
//
// Two subscribers is the maximum today (IP RX + IP TX in the dhcp_client
// harness). Extending to N is straightforward but every extra subscriber
// adds the same 2 NoC flits per lease event.
module dhcp_notify_tx #(
    parameter int                                 NOC_DATA_W      = `NOC_DATA_WIDTH,
    parameter int                                 NUM_SUBSCRIBERS = 1,
    parameter logic [`MSG_DST_X_WIDTH-1:0]        SRC_X           = '0,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]        SRC_Y           = '0,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0]    SRC_FBITS       = PKT_IF_FBITS,
    // Subscriber 0 (always used).
    parameter logic [`MSG_DST_X_WIDTH-1:0]        SUB_0_X         = '0,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]        SUB_0_Y         = '0,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0]    SUB_0_FBITS     = PKT_IF_FBITS,
    // Subscriber 1 (only addressed when NUM_SUBSCRIBERS >= 2).
    parameter logic [`MSG_DST_X_WIDTH-1:0]        SUB_1_X         = '0,
    parameter logic [`MSG_DST_Y_WIDTH-1:0]        SUB_1_Y         = '0,
    parameter logic [`MSG_DST_FBITS_WIDTH-1:0]    SUB_1_FBITS     = PKT_IF_FBITS
) (
    input  logic clk,
    input  logic rst,

    input  logic                          notify_start,
    input  logic [`MSG_TYPE_WIDTH-1:0]    notify_msg_type,
    input  logic [`IP_ADDR_W-1:0]         notify_yiaddr,

    // Single-subscriber dst override. When override_dst_en is high at
    // the IDLE -> SEND_HDR latch cycle, the FSM ignores SUB_0/SUB_1
    // params and sends ONE burst addressed at (override_dst_x,
    // override_dst_y). Intended for DHCP_IP_QUERY responses, which
    // need to target the querier's runtime coords.
    input  logic                                override_dst_en,
    input  logic [`MSG_DST_X_WIDTH-1:0]         override_dst_x,
    input  logic [`MSG_DST_Y_WIDTH-1:0]         override_dst_y,
    input  logic [`MSG_DST_FBITS_WIDTH-1:0]     override_dst_fbits,

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
    // 1-bit subscriber index (0 or 1). Wider when NUM_SUBSCRIBERS > 2.
    logic                       sub_idx_reg,  sub_idx_next;

    // Latched override at the burst-start handshake. When 1, the FSM
    // walks a single subscriber (the overridden coords) and ignores
    // SUB_0/SUB_1.
    logic                                override_active_reg, override_active_next;
    logic [`MSG_DST_X_WIDTH-1:0]         override_x_reg,      override_x_next;
    logic [`MSG_DST_Y_WIDTH-1:0]         override_y_reg,      override_y_next;
    logic [`MSG_DST_FBITS_WIDTH-1:0]     override_fbits_reg,  override_fbits_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg           <= IDLE;
            msg_type_reg        <= '0;
            yiaddr_reg          <= '0;
            sub_idx_reg         <= 1'b0;
            override_active_reg <= 1'b0;
            override_x_reg      <= '0;
            override_y_reg      <= '0;
            override_fbits_reg  <= '0;
        end else begin
            state_reg           <= state_next;
            msg_type_reg        <= msg_type_next;
            yiaddr_reg          <= yiaddr_next;
            sub_idx_reg         <= sub_idx_next;
            override_active_reg <= override_active_next;
            override_x_reg      <= override_x_next;
            override_y_reg      <= override_y_next;
            override_fbits_reg  <= override_fbits_next;
        end
    end

    // Per-subscriber address selection. Override path wins when active.
    logic [`MSG_DST_X_WIDTH-1:0]     cur_dst_x;
    logic [`MSG_DST_Y_WIDTH-1:0]     cur_dst_y;
    logic [`MSG_DST_FBITS_WIDTH-1:0] cur_dst_fbits;
    always_comb begin
        if (override_active_reg) begin
            cur_dst_x     = override_x_reg;
            cur_dst_y     = override_y_reg;
            cur_dst_fbits = override_fbits_reg;
        end else if (sub_idx_reg == 1'b0) begin
            cur_dst_x     = SUB_0_X;
            cur_dst_y     = SUB_0_Y;
            cur_dst_fbits = SUB_0_FBITS;
        end else begin
            cur_dst_x     = SUB_1_X;
            cur_dst_y     = SUB_1_Y;
            cur_dst_fbits = SUB_1_FBITS;
        end
    end

    beehive_noc_hdr_flit hdr_flit;
    always_comb begin
        hdr_flit                       = '0;
        hdr_flit.core.core.dst_chip_id = '0;
        hdr_flit.core.core.dst_x_coord = cur_dst_x;
        hdr_flit.core.core.dst_y_coord = cur_dst_y;
        hdr_flit.core.core.dst_fbits   = cur_dst_fbits;
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
        data_flit[NOC_DATA_W-1 -: `IP_ADDR_W] = yiaddr_reg;
    end

    // True after the FINAL subscriber's data flit handshakes. Override
    // mode is always single-subscriber regardless of NUM_SUBSCRIBERS.
    logic at_last_subscriber;
    assign at_last_subscriber = override_active_reg
                             || (NUM_SUBSCRIBERS == 1)
                             || (sub_idx_reg == 1'b1);

    always_comb begin
        state_next           = state_reg;
        msg_type_next        = msg_type_reg;
        yiaddr_next          = yiaddr_reg;
        sub_idx_next         = sub_idx_reg;
        override_active_next = override_active_reg;
        override_x_next      = override_x_reg;
        override_y_next      = override_y_reg;
        override_fbits_next  = override_fbits_reg;

        noc_val     = 1'b0;
        noc_data    = '0;
        notify_done = 1'b0;

        case (state_reg)
            IDLE: begin
                if (notify_start) begin
                    msg_type_next        = notify_msg_type;
                    yiaddr_next          = notify_yiaddr;
                    sub_idx_next         = 1'b0;
                    override_active_next = override_dst_en;
                    override_x_next      = override_dst_x;
                    override_y_next      = override_dst_y;
                    override_fbits_next  = override_dst_fbits;
                    state_next           = SEND_HDR;
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
                    if (at_last_subscriber) begin
                        notify_done = 1'b1;
                        state_next  = IDLE;
                    end else begin
                        sub_idx_next = sub_idx_reg + 1'b1;
                        state_next   = SEND_HDR;
                    end
                end
            end
            default: state_next = UND;
        endcase
    end
endmodule
