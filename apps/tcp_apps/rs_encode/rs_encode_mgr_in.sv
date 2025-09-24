`include "noc_defs.vh"
module rs_encode_mgr_in 
import tcp_rs_encode_pkg::*;
import tcp_pkg::*;
import mem_msg_pkg::*;
(
     input  clk
    ,input  rst
    
    ,input  logic                                   active_q_encode_in_empty
    ,input  logic   [FLOWID_W-1:0]                  active_q_encode_in_rd_data
    ,output logic                                   encode_in_active_q_rd_req

    ,output logic                                   encode_in_msg_req_req_val
    ,output tcp_msg_req                             encode_in_msg_req_req_data
    ,input  logic                                   msg_req_encode_in_req_rdy

    ,input  logic                                   msg_req_encode_in_rsp_val
    ,input  tcp_msg_resp                            msg_req_encode_in_rsp_data
    ,output logic                                   encode_in_msg_req_rsp_rdy
    
    ,output                                         encode_in_rd_buf_req_val
    ,output vaddr_t                                 encode_in_rd_buf_req_base_addr
    ,output         [PAYLOAD_PTR_W-1:0]             encode_in_rd_buf_req_offset
    ,output         [`MSG_DATA_SIZE_WIDTH-1:0]      encode_in_rd_buf_req_size
    ,input  logic                                   rd_buf_encode_in_req_rdy

    ,input  logic                                   rd_buf_encode_in_data_val
    ,input  logic   [`NOC_DATA_WIDTH-1:0]           rd_buf_encode_in_data
    ,input  logic                                   rd_buf_encode_in_data_last
    ,input  logic   [`NOC_DATA_BYTES_W-1:0]         rd_buf_encode_in_data_padbytes
    ,output                                         encode_in_rd_buf_data_rdy
    
    ,output                                         encode_in_stream_encoder_req_val
    ,output        [ENCODER_NUM_REQ_BLOCKS-1:0]     encode_in_stream_encoder_req_num_blocks
    ,input  logic                                   stream_encoder_encode_in_req_rdy

    ,output                                         encode_in_stream_encoder_req_data_val
    ,output         [`NOC_DATA_WIDTH-1:0]           encode_in_stream_encoder_req_data
    ,input  logic                                   stream_encoder_encode_in_req_data_rdy

    ,output logic                                   encode_in_rx_cap_rd_req_val
    ,output logic   [FLOWID_W-1:0]                  encode_in_rx_cap_rd_req_addr
    ,input  logic                                   rx_cap_encode_in_rd_req_rdy

    ,input  logic                                   rx_cap_encode_in_rd_rsp_val
    ,input  logic   [CAP_TABLE_INDEX_W-1:0]         rx_cap_encode_in_rd_rsp_data
    ,output logic                                   encode_in_rx_cap_rd_rsp_rdy

    ,output logic                                   in_out_meta_val
    ,output tcp_rs_metadata                         in_out_meta_data
    ,input  logic                                   out_in_meta_rdy
);
    
    logic                                   ctrl_datap_store_flowid;
    logic                                   ctrl_datap_store_offset;
    logic                                   ctrl_datap_store_cap_id;
    logic                                   ctrl_datap_store_req;
    cmd_type_e                              ctrl_datap_msg_req_cmd;

    rs_encode_mgr_in_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.active_q_encode_in_empty              (active_q_encode_in_empty             )
        ,.encode_in_active_q_rd_req             (encode_in_active_q_rd_req            )

        ,.encode_in_msg_req_req_val             (encode_in_msg_req_req_val            )
        ,.msg_req_encode_in_req_rdy             (msg_req_encode_in_req_rdy            )

        ,.msg_req_encode_in_rsp_val             (msg_req_encode_in_rsp_val            )
        ,.encode_in_msg_req_rsp_rdy             (encode_in_msg_req_rsp_rdy            )

        ,.encode_in_rd_buf_req_val              (encode_in_rd_buf_req_val             )
        ,.rd_buf_encode_in_req_rdy              (rd_buf_encode_in_req_rdy             )

        ,.rd_buf_encode_in_data_val             (rd_buf_encode_in_data_val            )
        ,.rd_buf_encode_in_data_last            (rd_buf_encode_in_data_last           )
        ,.encode_in_rd_buf_data_rdy             (encode_in_rd_buf_data_rdy            )

        ,.encode_in_stream_encoder_req_val      (encode_in_stream_encoder_req_val     )
        ,.stream_encoder_encode_in_req_rdy      (stream_encoder_encode_in_req_rdy     )

        ,.encode_in_stream_encoder_req_data_val (encode_in_stream_encoder_req_data_val)
        ,.stream_encoder_encode_in_req_data_rdy (stream_encoder_encode_in_req_data_rdy)

        ,.encode_in_rx_cap_rd_req_val           (encode_in_rx_cap_rd_req_val          )
        ,.rx_cap_encode_in_rd_req_rdy           (rx_cap_encode_in_rd_req_rdy          )

        ,.rx_cap_encode_in_rd_rsp_val           (rx_cap_encode_in_rd_rsp_val          )
        ,.encode_in_rx_cap_rd_rsp_rdy           (encode_in_rx_cap_rd_rsp_rdy          )

        ,.in_out_meta_val                       (in_out_meta_val                      )
        ,.out_in_meta_rdy                       (out_in_meta_rdy                      )

        ,.ctrl_datap_store_flowid               (ctrl_datap_store_flowid              )
        ,.ctrl_datap_store_offset               (ctrl_datap_store_offset              )
        ,.ctrl_datap_store_cap_id               (ctrl_datap_store_cap_id              )
        ,.ctrl_datap_store_req                  (ctrl_datap_store_req                 )
        ,.ctrl_datap_msg_req_cmd                (ctrl_datap_msg_req_cmd               )
    );
    
    rs_encode_mgr_in_datap datap (
         .clk                                    (clk   )
        ,.rst                                    (rst)
        
        ,.active_q_encode_in_rd_data             (active_q_encode_in_rd_data                )
                                                  
                                                  
        ,.encode_in_msg_req_req_data             (encode_in_msg_req_req_data                )
                                                  
        ,.msg_req_encode_in_rsp_data             (msg_req_encode_in_rsp_data                )
                                                  
        ,.encode_in_rd_buf_req_base_addr         (encode_in_rd_buf_req_base_addr            )
        ,.encode_in_rd_buf_req_offset            (encode_in_rd_buf_req_offset               )
        ,.encode_in_rd_buf_req_size              (encode_in_rd_buf_req_size                 )
                                                  
        ,.rd_buf_encode_in_data                  (rd_buf_encode_in_data                     )
        ,.rd_buf_encode_in_data_last             (rd_buf_encode_in_data_last                )
        ,.rd_buf_encode_in_data_padbytes         (rd_buf_encode_in_data_padbytes            )
                                                  
        ,.encode_in_stream_encoder_req_num_blocks(encode_in_stream_encoder_req_num_blocks   )
                                                  
        ,.encode_in_stream_encoder_req_data      (encode_in_stream_encoder_req_data         )
                                                  
        ,.encode_in_rx_cap_rd_req_addr           (encode_in_rx_cap_rd_req_addr              )
                                                  
        ,.rx_cap_encode_in_rd_rsp_data           (rx_cap_encode_in_rd_rsp_data              )
                                                  
        ,.in_out_meta_data                       (in_out_meta_data                          )
                                                  
        ,.ctrl_datap_store_flowid                (ctrl_datap_store_flowid                   )
        ,.ctrl_datap_store_offset                (ctrl_datap_store_offset                   )
        ,.ctrl_datap_store_cap_id                (ctrl_datap_store_cap_id                   )
        ,.ctrl_datap_store_req                   (ctrl_datap_store_req                      )
        ,.ctrl_datap_send_hdr                    (ctrl_datap_send_hdr                       )
    
    );
endmodule