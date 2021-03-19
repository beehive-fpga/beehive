/*
 * The wiring of this module is quite funky, since we don't actually want to
 * fully split the request. In fact, only one ctrl should be active at any time
 * to prevent weird memory collisions
 */
`include "masked_mem_defs.svh"
module masked_mem_controller_rd_pipe #(
     parameter MEM_DATA_W = -1
    ,parameter MEM_ADDR_W = -1
    ,parameter MEM_WR_MASK_W = MEM_DATA_W/8
    ,parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter SIM_TEST = 0
)(
     input clk
    ,input rst
    
    ,input                                  noc0_ctovr_controller_val
    ,input          [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_controller_data
    ,output logic                           controller_noc0_ctovr_rdy

    ,output logic                           controller_noc0_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   controller_noc0_vrtoc_data
    ,input                                  noc0_vrtoc_controller_rdy

    ,output logic                           wr_resp_noc_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]   wr_resp_noc_vrtoc_data
    ,input                                  noc_wr_resp_vrtoc_rdy

    ,input  logic                           noc_ctovr_rd_req_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]   noc_ctovr_rd_req_data
    ,output logic                           rd_req_noc_ctovr_rdy

    ,output logic                           controller_mem_write_en
    ,output logic   [MEM_ADDR_W-1:0]        controller_mem_addr
    ,output logic   [MEM_DATA_W-1:0]        controller_mem_wr_data
    ,output logic   [MEM_WR_MASK_W-1:0]     controller_mem_byte_en
    ,output logic   [7-1:0]                 controller_mem_burst_cnt
    ,input                                  mem_controller_rdy

    ,output logic                           controller_mem_read_en
    ,input                                  mem_controller_rd_data_val
    ,input          [MEM_DATA_W-1:0]        mem_controller_rd_data
    ,output                                 controller_mem_rd_data_rdy
);

    localparam PIPE_STAGES = 3;
    localparam PIPE_STAGES_W = $clog2(PIPE_STAGES);

    logic                           rd_ctrl_datap_store_state;
    logic                           rd_ctrl_datap_update_state;
    logic                           rd_ctrl_datap_hdr_flit_out;
    logic                           rd_ctrl_datap_incr_sent_flits;

    logic                           datap_rd_ctrl_last_read;
    logic                           datap_rd_ctrl_last_read_out;
    logic                           datap_rd_ctrl_last_flit;
    logic                           datap_rd_ctrl_read_aligned;
    
    logic                           rd_ctrl_fifo_wr_req;
    logic                           fifo_rd_ctrl_full;
    
    logic                           rd_ctrl_fifo_rd_req;
    logic   [PIPE_STAGES_W:0]       fifo_rd_ctrl_num_els;

    logic                           wr_ctrl_datap_store_state;
    logic                           wr_ctrl_datap_update_state;
    logic                           wr_ctrl_datap_hdr_flit_out;
    logic                           wr_ctrl_datap_store_rem_reg;
    logic                           wr_ctrl_datap_shift_regs;
    logic                           wr_ctrl_datap_incr_recv_flits;
    logic                           wr_ctrl_datap_first_wr;
    
    logic                           datap_wr_ctrl_last_flit;
    logic                           datap_wr_ctrl_last_write;
    logic                           datap_wr_ctrl_wr_aligned;
    
    logic                           noc0_ctovr_rd_val;	
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_rd_data;	
    logic                           rd_noc0_ctovr_rdy;	
    
    logic                           noc0_ctovr_wr_val;	
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_ctovr_wr_data;	
    logic                           wr_noc0_ctovr_rdy;	
    
    logic   [`NOC_DATA_WIDTH-1:0]   noc0_datap_data;
    logic   [`NOC_DATA_WIDTH-1:0]   datap_noc0_data;

    logic                           rd_ctrl_rd_in_progress;
    logic                           wr_ctrl_wr_in_progress;
    
    logic                           wr_noc0_vrtoc_val;
    logic                           rd_noc0_vrtoc_val;

    logic wr_splitter_rdy;
    logic wr_splitter_val;
    logic rd_splitter_rdy;
    logic rd_splitter_val;

    assign controller_noc0_vrtoc_data = datap_noc0_data;

    assign wr_splitter_rdy = wr_noc0_ctovr_rdy & ~rd_ctrl_rd_in_progress;
    assign noc0_ctovr_wr_val = wr_splitter_val & ~rd_ctrl_rd_in_progress;

    assign noc0_ctovr_rd_val = rd_splitter_val & ~wr_ctrl_wr_in_progress;
    assign rd_splitter_rdy = rd_noc0_ctovr_rdy & ~wr_ctrl_wr_in_progress;

    assign controller_noc0_vrtoc_val = rd_noc0_vrtoc_val | wr_noc0_vrtoc_val;

    beehive_noc_msg_type_splitter #(
         .MSG_TYPE_W        (`MSG_TYPE_WIDTH    )
        ,.NOC_DATA_W        (`NOC_DATA_WIDTH    )
        ,.MSG_PAYLOAD_LEN   (`PAYLOAD_LEN       )
        ,.MSG_LEN_HI        (`MSG_LENGTH_HI     )
        ,.MSG_LEN_LO        (`MSG_LENGTH_LO     )
        ,.MSG_TYPE_HI       (`MSG_TYPE_HI       )
        ,.MSG_TYPE_LO       (`MSG_TYPE_LO       )
        ,.num_targets       (2)
        ,.msg_type0         (`MSG_TYPE_LOAD_MEM )
        ,.msg_type1         (`MSG_TYPE_STORE_MEM)
    ) msg_splitter (
         .clk   (clk    )
        ,.rst_n (~rst   )
    
        ,.src_splitter_vr_noc_val   (noc0_ctovr_controller_val  )
        ,.src_splitter_vr_noc_dat   (noc0_ctovr_controller_data )
        ,.splitter_src_vr_noc_rdy   (controller_noc0_ctovr_rdy  )
    
        ,.splitter_dst0_vr_noc_val  (rd_splitter_val            )
        ,.splitter_dst0_vr_noc_dat  (noc0_ctovr_rd_data         )
        ,.dst0_splitter_vr_noc_rdy  (rd_splitter_rdy            )
    
        ,.splitter_dst1_vr_noc_val  (wr_splitter_val            )
        ,.splitter_dst1_vr_noc_dat  (noc0_ctovr_wr_data         )
        ,.dst1_splitter_vr_noc_rdy  (wr_splitter_rdy            )
    
        ,.splitter_dst2_vr_noc_val  ()
        ,.splitter_dst2_vr_noc_dat  ()
        ,.dst2_splitter_vr_noc_rdy  ('0)
    
        ,.splitter_dst3_vr_noc_val  ()
        ,.splitter_dst3_vr_noc_dat  ()
        ,.dst3_splitter_vr_noc_rdy  ('0)
    
        ,.splitter_dst4_vr_noc_val  ()
        ,.splitter_dst4_vr_noc_dat  ()
        ,.dst4_splitter_vr_noc_rdy  ('0)
    );


    assign noc0_datap_data = noc0_ctovr_wr_val
                            ? noc0_ctovr_wr_data
                            : noc0_ctovr_rd_data;
    masked_mem_rd_pipe_datap #(
         .MEM_DATA_W    (MEM_DATA_W )
        ,.MEM_ADDR_W    (MEM_ADDR_W )
        ,.SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.PIPE_STAGES   (PIPE_STAGES)
        ,.SIM_TEST      (SIM_TEST   )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )
    
        ,.noc0_ctovr_controller_data    (noc0_ctovr_controller_data     )
                                                                        
        ,.controller_noc0_vrtoc_data    (datap_noc0_data                )
                                                                        
        ,.wr_resp_noc_vrtoc_data        (wr_resp_noc_vrtoc_data         )

        ,.noc_ctovr_rd_req_data         (noc_ctovr_rd_req_data          )
                                                                        
        ,.controller_mem_addr           (controller_mem_addr            )
        ,.controller_mem_wr_data        (controller_mem_wr_data         )
        ,.controller_mem_byte_en        (controller_mem_byte_en         )
        ,.controller_mem_burst_cnt      (controller_mem_burst_cnt       )
                                                                        
        ,.mem_controller_rd_data        (mem_controller_rd_data         )
                                                                        
        ,.rd_ctrl_datap_store_state     (rd_ctrl_datap_store_state      )
        ,.rd_ctrl_datap_update_state    (rd_ctrl_datap_update_state     )
        ,.rd_ctrl_datap_hdr_flit_out    (rd_ctrl_datap_hdr_flit_out     )
        ,.rd_ctrl_datap_incr_sent_flits (rd_ctrl_datap_incr_sent_flits  )
                                                                        
        ,.rd_ctrl_fifo_wr_req           (rd_ctrl_fifo_wr_req            )
        ,.fifo_rd_ctrl_full             (fifo_rd_ctrl_full              )
                                                                        
        ,.rd_ctrl_fifo_rd_req           (rd_ctrl_fifo_rd_req            )
        ,.fifo_rd_ctrl_num_els          (fifo_rd_ctrl_num_els           )
                                                                        
        ,.datap_rd_ctrl_last_read       (datap_rd_ctrl_last_read        )
        ,.datap_rd_ctrl_last_flit       (datap_rd_ctrl_last_flit        )
        ,.datap_rd_ctrl_last_read_out   (datap_rd_ctrl_last_read_out    )
        ,.datap_rd_ctrl_read_aligned    (datap_rd_ctrl_read_aligned     )
                                                                        
        ,.wr_ctrl_datap_store_state     (wr_ctrl_datap_store_state      )
        ,.wr_ctrl_datap_update_state    (wr_ctrl_datap_update_state     )
        ,.wr_ctrl_datap_hdr_flit_out    (wr_ctrl_datap_hdr_flit_out     )
        ,.wr_ctrl_datap_store_rem_reg   (wr_ctrl_datap_store_rem_reg    )
        ,.wr_ctrl_datap_shift_regs      (wr_ctrl_datap_shift_regs       )
        ,.wr_ctrl_datap_incr_recv_flits (wr_ctrl_datap_incr_recv_flits  )
        ,.wr_ctrl_datap_first_wr        (wr_ctrl_datap_first_wr         )
                                                                        
        ,.datap_wr_ctrl_last_flit       (datap_wr_ctrl_last_flit        )
        ,.datap_wr_ctrl_last_write      (datap_wr_ctrl_last_write       )
        ,.datap_wr_ctrl_wr_aligned      (datap_wr_ctrl_wr_aligned       )
    );

    logic   ctrl_noc_rd_ctrl_val;
    logic   rd_ctrl_ctrl_noc_rdy; 

    assign rd_req_noc_ctovr_rdy = rd_ctrl_ctrl_noc_rdy & ~wr_ctrl_wr_in_progress;
    assign ctrl_noc_rd_ctrl_val = noc_ctovr_rd_req_val & ~wr_ctrl_wr_in_progress;

    masked_mem_rd_pipe_ctrl #(
        .PIPE_STAGES (3)
    ) rd_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_controller_val     (ctrl_noc_rd_ctrl_val           )
        ,.controller_noc0_ctovr_rdy     (rd_ctrl_ctrl_noc_rdy           )
    
        ,.controller_noc0_vrtoc_val     (rd_noc0_vrtoc_val              )
        ,.noc0_vrtoc_controller_rdy     (noc0_vrtoc_controller_rdy      )
    
        ,.controller_mem_read_en        (controller_mem_read_en         )
        ,.mem_controller_rdy            (mem_controller_rdy             )
        ,.mem_controller_rd_data_val    (mem_controller_rd_data_val     )
        ,.controller_mem_rd_data_rdy    (controller_mem_rd_data_rdy     )
                                                                        
        ,.rd_ctrl_rd_in_progress        (rd_ctrl_rd_in_progress         )
                                                                        
        ,.rd_ctrl_datap_store_state     (rd_ctrl_datap_store_state      )
        ,.rd_ctrl_datap_update_state    (rd_ctrl_datap_update_state     )
        ,.rd_ctrl_datap_hdr_flit_out    (rd_ctrl_datap_hdr_flit_out     )
        ,.rd_ctrl_datap_incr_sent_flits (rd_ctrl_datap_incr_sent_flits  )
    
        ,.rd_ctrl_fifo_wr_req           (rd_ctrl_fifo_wr_req            )
        ,.fifo_rd_ctrl_full             (fifo_rd_ctrl_full              )
                                                                        
        ,.rd_ctrl_fifo_rd_req           (rd_ctrl_fifo_rd_req            )
        ,.fifo_rd_ctrl_num_els          (fifo_rd_ctrl_num_els           )
                                                                        
        ,.datap_rd_ctrl_last_read       (datap_rd_ctrl_last_read        )
        ,.datap_rd_ctrl_last_flit       (datap_rd_ctrl_last_flit        )
        ,.datap_rd_ctrl_last_read_out   (datap_rd_ctrl_last_read_out    )
        ,.datap_rd_ctrl_first_read      (datap_rd_ctrl_first_read       )
        ,.datap_rd_ctrl_read_aligned    (datap_rd_ctrl_read_aligned     )
    );

    masked_mem_wr_ctrl wr_ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.noc0_ctovr_controller_val     (noc0_ctovr_wr_val              )
        ,.controller_noc0_ctovr_rdy     (wr_noc0_ctovr_rdy              )
                                         
        ,.controller_noc0_vrtoc_val     (wr_noc0_vrtoc_val              )
        ,.noc0_vrtoc_controller_rdy     (noc0_vrtoc_controller_rdy      )
    
        ,.wr_resp_noc_vrtoc_val         (wr_resp_noc_vrtoc_val          )
        ,.noc_wr_resp_vrtoc_rdy         (noc_wr_resp_vrtoc_rdy          )

        ,.wr_ctrl_wr_in_progress        (wr_ctrl_wr_in_progress         )
                                                                        
        ,.controller_mem_write_en       (controller_mem_write_en        )
        ,.mem_controller_rdy            (mem_controller_rdy             )
                                                                        
        ,.wr_ctrl_datap_store_state     (wr_ctrl_datap_store_state      )
        ,.wr_ctrl_datap_update_state    (wr_ctrl_datap_update_state     )
        ,.wr_ctrl_datap_hdr_flit_out    (wr_ctrl_datap_hdr_flit_out     )
        ,.wr_ctrl_datap_store_rem_reg   (wr_ctrl_datap_store_rem_reg    )
        ,.wr_ctrl_datap_shift_regs      (wr_ctrl_datap_shift_regs       )
        ,.wr_ctrl_datap_incr_recv_flits (wr_ctrl_datap_incr_recv_flits  )
        ,.wr_ctrl_datap_first_wr        (wr_ctrl_datap_first_wr         )
        ,.datap_wr_ctrl_last_flit       (datap_wr_ctrl_last_flit        )
        ,.datap_wr_ctrl_last_write      (datap_wr_ctrl_last_write       )
        ,.datap_wr_ctrl_wr_aligned      (datap_wr_ctrl_wr_aligned       )
    );
endmodule
