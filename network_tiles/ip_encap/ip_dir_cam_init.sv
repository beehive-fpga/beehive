`include "ip_encap_tx_defs.svh"
module ip_dir_cam_init #(
     parameter CAM_ELS = -1
    ,parameter CAM_ELS_W = `BSG_SAFE_CLOG2(CAM_ELS)
    ,parameter INIT_CAM_ELS=-1
    ,parameter INIT_CAM_ELS_W = `BSG_SAFE_CLOG2(CAM_ELS)
)(
     input  clk
    ,input  rst

    ,output logic   [CAM_ELS-1:0]       init_wr_cam_val
    ,output logic                       init_wr_cam_set
    ,output logic   [`IP_ADDR_W-1:0]    init_wr_cam_tag
    ,output logic   [`IP_ADDR_W-1:0]    init_wr_cam_data
    ,input  logic                       wr_cam_init_rdy
);

    typedef enum logic[1:0] {
        READY = 2'b0,
        WRITING = 2'b1,
        DONE = 2'd2,
        UND = 'X
    } state_e;

    state_e state_reg;
    state_e state_next;

    logic   incr_rd_addr;
    logic   cam_wr_val;

    logic   [INIT_CAM_ELS_W-1:0] rom_rd_addr_reg;
    logic   [INIT_CAM_ELS_W-1:0] rom_rd_addr_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= READY;
            rom_rd_addr_reg <= '0;
        end
        else begin
            state_reg <= state_next;
            rom_rd_addr_reg <= rom_rd_addr_next;
        end
    end

    assign rom_rd_addr_next = incr_rd_addr
                            ? rom_rd_addr_reg + 1'b1
                            : rom_rd_addr_reg;

    assign init_wr_cam_val = {{(CAM_ELS-1){1'b0}}, cam_wr_val} << rom_rd_addr_reg;

    // just in case we're gonna have issues when CAM_ELS itself can't be stored in
    // CAM_ELS_W (ex CAM_ELS = 2)
    logic   [INIT_CAM_ELS_W:0] loop_end;
    assign loop_end = INIT_CAM_ELS - 1;

    always_comb begin
        init_wr_cam_set = 1'b0;
        cam_wr_val = 1'b0;

        incr_rd_addr = 1'b0;

        state_next = state_reg;
        case (state_reg)
            READY: begin
                state_next = WRITING;
            end
            WRITING: begin
                init_wr_cam_set = 1'b1;
                cam_wr_val = 1'b1;
                if (wr_cam_init_rdy) begin
                    incr_rd_addr = 1'b1;
                    if (rom_rd_addr_reg == loop_end) begin
                        state_next = DONE;
                    end
                    else begin
                        state_next = WRITING;
                    end
                end
                else begin
                    state_next = WRITING;
                end
            end
            DONE: begin
                state_next = DONE;
            end
            default: begin
                init_wr_cam_set = 'X;

                incr_rd_addr = 'X;

                state_next = UND;
            end
        endcase
    end

	ip_tags_rom #(
		 .width_p       (`IP_ADDR_W     )
        ,.addr_width_p  (INIT_CAM_ELS_W )
	) ip_tags (
		 .addr_i	(rom_rd_addr_reg    )
  		,.data_o	(init_wr_cam_tag    )
 	);
	
    ip_data_rom #(
		 .width_p       (`IP_ADDR_W     )
        ,.addr_width_p  (INIT_CAM_ELS_W )
	) ip_data (
		 .addr_i	(rom_rd_addr_reg    )
  		,.data_o	(init_wr_cam_data   )
 	);

endmodule
