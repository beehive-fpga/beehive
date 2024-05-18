`include "simple_log_udp_noc_read_defs.svh"
module simple_log_udp_noc_read #(
     parameter SRC_X = -1
    ,parameter SRC_Y = -1
    ,parameter ADDR_W = -1
    ,parameter RESP_DATA_STRUCT_W = -1
    ,parameter CLIENT_ADDR_W = -1
)(
     input clk
    ,input rst
    
    ,input                                      ctovr_reader_in_val
    ,input          [`NOC_DATA_WIDTH-1:0]       ctovr_reader_in_data
    ,output logic                               reader_in_ctovr_rdy
    
    ,output logic                               reader_out_vrtoc_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]       reader_out_vrtoc_data
    ,input                                      vrtoc_reader_out_rdy

    ,output logic                               log_rd_req_val
    ,output logic   [ADDR_W-1:0]                log_rd_req_addr
    
    ,input  logic                               log_rd_resp_val
    ,input  logic   [RESP_DATA_STRUCT_W-1:0]    log_rd_resp_data

    ,input  logic   [ADDR_W-1:0]                curr_wr_addr
    ,input  logic                               has_wrapped
);
    
    logic                   ctrl_datap_store_meta;
    logic                   ctrl_datap_store_req;
    logic                   ctrl_datap_store_log_resp;
    simple_log_resp_sel_e   ctrl_datap_output_flit_sel;

    logic                   datap_ctrl_rd_meta;

    simple_log_udp_noc_read_datap #(
         .SRC_X                 (SRC_X              )
        ,.SRC_Y                 (SRC_Y              )
        ,.ADDR_W                (ADDR_W             )
        ,.RESP_DATA_STRUCT_W    (RESP_DATA_STRUCT_W )
        ,.CLIENT_ADDR_W         (CLIENT_ADDR_W      )
    ) datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.ctovr_reader_in_data          (ctovr_reader_in_data           )

        ,.reader_out_vrtoc_data         (reader_out_vrtoc_data          )

        ,.log_rd_req_addr               (log_rd_req_addr                )

        ,.log_rd_resp_data              (log_rd_resp_data               )

        ,.curr_wr_addr                  (curr_wr_addr                   )
        ,.has_wrapped                   (has_wrapped                    )

        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta          )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req           )
        ,.ctrl_datap_store_log_resp     (ctrl_datap_store_log_resp      )
        ,.ctrl_datap_output_flit_sel    (ctrl_datap_output_flit_sel     )

        ,.datap_ctrl_rd_meta            (datap_ctrl_rd_meta             )
    );

    simple_log_udp_noc_read_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )
        
        ,.ctovr_reader_in_val           (ctovr_reader_in_val        )
        ,.reader_in_ctovr_rdy           (reader_in_ctovr_rdy        )

        ,.reader_out_vrtoc_val          (reader_out_vrtoc_val       )
        ,.vrtoc_reader_out_rdy          (vrtoc_reader_out_rdy       )

        ,.ctrl_datap_store_meta         (ctrl_datap_store_meta      )
        ,.ctrl_datap_store_req          (ctrl_datap_store_req       )
        ,.ctrl_datap_store_log_resp     (ctrl_datap_store_log_resp  )
        ,.ctrl_datap_output_flit_sel    (ctrl_datap_output_flit_sel )

        ,.datap_ctrl_rd_meta            (datap_ctrl_rd_meta         )

        ,.log_rd_req_val                (log_rd_req_val             )

        ,.log_rd_resp_val               (log_rd_resp_val            )
    );

endmodule
