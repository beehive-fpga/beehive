`include "packet_defs.vh"
`include "state_defs.vh"
`include "noc_defs.vh"
`include "soc_defs.vh"
import noc_struct_pkg::*;
module rd_circ_buf #(
     parameter BUF_PTR_W=-1
    ,parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
) (
     input clk
    ,input rst
    
    ,output logic                                   rd_buf_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]           rd_buf_noc0_data
    ,input                                          noc0_rd_buf_rdy
   
    ,input                                          noc0_rd_buf_val
    ,input          [`NOC_DATA_WIDTH-1:0]           noc0_rd_buf_data
    ,output logic                                   rd_buf_noc0_rdy

    ,input                                          src_rd_buf_req_val
    ,input          [`FLOW_ID_W-1:0]                src_rd_buf_req_flowid
    ,input          [BUF_PTR_W-1:0]                 src_rd_buf_req_offset
    ,input          [`MSG_DATA_SIZE_WIDTH-1:0]      src_rd_buf_req_size
    ,output logic                                   rd_buf_src_req_rdy

    ,output logic                                   rd_buf_src_data_val
    ,output logic   [`MAC_INTERFACE_W-1:0]          rd_buf_src_data
    ,output logic                                   rd_buf_src_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]           rd_buf_src_data_padbytes
    ,input                                          src_rd_buf_data_rdy
);
    logic                                   ctrl_datapath_rd_req_val;
    mem_req_struct                          ctrl_datapath_rd_req_data;
    logic                                   datapath_ctrl_rd_req_rdy;

    logic                                   datapath_ctrl_resp_data_val;
    logic                                   datapath_ctrl_resp_data_last;
    logic   [`MAC_PADBYTES_W-1:0]           datapath_ctrl_resp_data_padbytes;
    logic                                   ctrl_datapath_resp_data_rdy;
    
    logic   [`MAC_INTERFACE_BYTES_W-1:0]    mem_data_shift_bytes;

    logic                                   write_upper;
    logic                                   shift_upper;
    logic                                   shift_lower;
    logic                                   shift_lower_zeros;
    
    rd_circ_buf_datapath #(
         .SRC_X         (SRC_X      )
        ,.SRC_Y         (SRC_Y      )
        ,.DST_DRAM_X    (DST_DRAM_X )
        ,.DST_DRAM_Y    (DST_DRAM_Y )
        ,.FBITS         (FBITS      )
    ) datapath (
         .clk   (clk)
        ,.rst   (rst)

        ,.rd_buf_noc0_val               (rd_buf_noc0_val                )
        ,.rd_buf_noc0_data              (rd_buf_noc0_data               )
        ,.noc0_rd_buf_rdy               (noc0_rd_buf_rdy                )
                                                                                
        ,.noc0_rd_buf_val               (noc0_rd_buf_val                )
        ,.noc0_rd_buf_data              (noc0_rd_buf_data               )
        ,.rd_buf_noc0_rdy               (rd_buf_noc0_rdy                )

        ,.rd_buf_src_data                (rd_buf_src_data                 )

        ,.ctrl_datapath_rd_req_val          (ctrl_datapath_rd_req_val           )
        ,.ctrl_datapath_rd_req_data         (ctrl_datapath_rd_req_data          )
        ,.datapath_ctrl_rd_req_rdy          (datapath_ctrl_rd_req_rdy           )
                                                                                
        ,.datapath_ctrl_resp_data_val       (datapath_ctrl_resp_data_val        )
        ,.datapath_ctrl_resp_data_last      (datapath_ctrl_resp_data_last       )
        ,.datapath_ctrl_resp_data_padbytes  (datapath_ctrl_resp_data_padbytes   )
        ,.ctrl_datapath_resp_data_rdy       (ctrl_datapath_resp_data_rdy        )
                                                                                
        ,.mem_data_shift_bytes              (mem_data_shift_bytes               )
                                                                                
        ,.write_upper                       (write_upper                        )
        ,.shift_upper                       (shift_upper                        )
        ,.shift_lower                       (shift_lower                        )
        ,.shift_lower_zeros                 (shift_lower_zeros                  )
    );

    rd_circ_buf_ctrl #( 
        .BUF_PTR_W  (BUF_PTR_W)
    ) ctrl (
         .clk   (clk)
        ,.rst   (rst)

        ,.src_rd_buf_req_val             (src_rd_buf_req_val              )
        ,.src_rd_buf_req_flowid          (src_rd_buf_req_flowid           )
        ,.src_rd_buf_req_offset          (src_rd_buf_req_offset           )
        ,.src_rd_buf_req_size            (src_rd_buf_req_size             )
        ,.rd_buf_src_req_rdy             (rd_buf_src_req_rdy              )

        ,.ctrl_datapath_rd_req_val          (ctrl_datapath_rd_req_val           )
        ,.ctrl_datapath_rd_req_data         (ctrl_datapath_rd_req_data          )
        ,.datapath_ctrl_rd_req_rdy          (datapath_ctrl_rd_req_rdy           )

        ,.datapath_ctrl_resp_data_val       (datapath_ctrl_resp_data_val        )
        ,.datapath_ctrl_resp_data_last      (datapath_ctrl_resp_data_last       )
        ,.datapath_ctrl_resp_data_padbytes  (datapath_ctrl_resp_data_padbytes   )
        ,.ctrl_datapath_resp_data_rdy       (ctrl_datapath_resp_data_rdy        )

        ,.rd_buf_src_data_val            (rd_buf_src_data_val             )
        ,.rd_buf_src_data_last           (rd_buf_src_data_last            )
        ,.rd_buf_src_data_padbytes       (rd_buf_src_data_padbytes        )
        ,.src_rd_buf_data_rdy            (src_rd_buf_data_rdy             )

        ,.mem_data_shift_bytes              (mem_data_shift_bytes               )

        ,.write_upper                       (write_upper                        )
        ,.shift_upper                       (shift_upper                        )
        ,.shift_lower                       (shift_lower                        )
        ,.shift_lower_zeros                 (shift_lower_zeros                  )
    );
endmodule

