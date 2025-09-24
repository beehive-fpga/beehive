module rs_encode_mgr_out
import tcp_pkg::*;
import mem_msg_pkg::*;
(
     input clk
    ,input rst
    
    ,input  logic                               encode_out_active_q_wr_val
    ,input  logic   [FLOWID_W-1:0]              encode_out_active_q_wr_data
    ,output logic                               active_q_encode_out_rdy

    ,output logic                               encode_out_msg_req_req_val
    ,output tcp_msg_req                         encode_out_msg_req_req_data
    ,input  logic                               msg_req_encode_out_req_rdy

    ,input  logic                               msg_req_encode_out_rsp_val
    ,input  tcp_msg_resp                        msg_req_encode_out_rsp_data
    ,output logic                               encode_out_msg_req_rsp_rdy
    
    ,output                                     encode_out_wr_buf_req_val
    ,output vaddr_t                             encode_out_wr_buf_req_base_addr
    ,output         [BUF_PTR_W-1:0]             encode_out_wr_buf_req_wr_ptr
    ,output         [`MSG_DATA_SIZE_WIDTH-1:0]  encode_out_wr_buf_req_size
    ,input  logic                               wr_buf_encode_out_req_rdy
    
    ,output                                     encode_out_wr_buf_req_data_val
    ,output          [`NOC_DATA_WIDTH-1:0]      encode_out_wr_buf_req_data
    ,input  logic                               wr_buf_encode_out_req_data_rdy
    
    ,output logic                               wr_buf_encode_out_req_done
    ,input  logic                               encode_out_wr_buf_done_rdy
    
    ,input  logic                               stream_encoder_out_resp_data_val
    ,input  logic   [DATA_W-1:0]                stream_encoder_out_resp_data
    ,input  logic                               stream_encoder_out_resp_last
    ,output logic                               out_stream_encoder_resp_data_rdy
    
    ,output logic                               encode_out_tx_cap_rd_req_val
    ,output logic   [FLOWID_W-1:0]              encode_out_tx_cap_rd_req_addr
    ,input  logic                               tx_cap_encode_out_rd_req_rdy

    ,input  logic                               tx_cap_encode_out_rd_rsp_val
    ,input  logic   [CAP_TABLE_INDEX_W-1:0]     tx_cap_encode_out_rd_rsp_data
    ,output logic                               encode_out_tx_cap_rd_rsp_rdy
    
    ,input  logic                               in_out_meta_val
    ,input  tcp_rs_metadata                     in_out_meta_data
    ,output logic                               out_in_meta_rdy

);
    
    logic                                   ctrl_datap_store_meta;
    logic                                   ctrl_datap_store_offset;
    logic                                   ctrl_datap_store_cap_id;
    cmd_type_e                              ctrl_datap_msg_req_cmd;

    rs_encode_mgr_out_ctrl ctrl (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.encode_out_active_q_wr_val        (encode_out_active_q_wr_val         )
        ,.active_q_encode_out_rdy           (active_q_encode_out_rdy            )

        ,.encode_out_msg_req_req_val        (encode_out_msg_req_req_val         )
        ,.msg_req_encode_out_req_rdy        (msg_req_encode_out_req_rdy         )

        ,.msg_req_encode_out_rsp_val        (msg_req_encode_out_rsp_val         )
        ,.encode_out_msg_req_rsp_rdy        (encode_out_msg_req_rsp_rdy         )

        ,.encode_out_wr_buf_req_val         (encode_out_wr_buf_req_val          )
        ,.wr_buf_encode_out_req_rdy         (wr_buf_encode_out_req_rdy          )

        ,.encode_out_wr_buf_req_data_val    (encode_out_wr_buf_req_data_val     )
        ,.wr_buf_encode_out_req_data_rdy    (wr_buf_encode_out_req_data_rdy     )

        ,.wr_buf_encode_out_req_done        (wr_buf_encode_out_req_done         )
        ,.encode_out_wr_buf_done_rdy        (encode_out_wr_buf_done_rdy         )

        ,.stream_encoder_out_resp_data_val  (stream_encoder_out_resp_data_val   )
        ,.out_stream_encoder_resp_data_rdy  (out_stream_encoder_resp_data_rdy   )

        ,.encode_out_tx_cap_rd_req_val      (encode_out_tx_cap_rd_req_val       )
        ,.tx_cap_encode_out_rd_req_rdy      (tx_cap_encode_out_rd_req_rdy       )

        ,.tx_cap_encode_out_rd_rsp_val      (tx_cap_encode_out_rd_rsp_val       )
        ,.encode_out_tx_cap_rd_rsp_rdy      (encode_out_tx_cap_rd_rsp_rdy       )

        ,.in_out_meta_val                   (in_out_meta_val                    )
        ,.out_in_meta_rdy                   (out_in_meta_rdy                    )

        ,.ctrl_datap_store_meta             (ctrl_datap_store_meta              )
        ,.ctrl_datap_store_offset           (ctrl_datap_store_offset            )
        ,.ctrl_datap_store_cap_id           (ctrl_datap_store_cap_id            )
        ,.ctrl_datap_msg_req_cmd            (ctrl_datap_msg_req_cmd             )
    );

    rs_encode_mgr_out_datap datap (
         .clk   (clk    )
        ,.rst   (rst    )

        ,.encode_out_active_q_wr_data       (encode_out_active_q_wr_data        )

        ,.encode_out_msg_req_req_data       (encode_out_msg_req_req_data        )

        ,.msg_req_encode_out_rsp_data       (msg_req_encode_out_rsp_data        )

        ,.encode_out_wr_buf_req_base_addr   (encode_out_wr_buf_req_base_addr    )
        ,.encode_out_wr_buf_req_wr_ptr      (encode_out_wr_buf_req_wr_ptr       )
        ,.encode_out_wr_buf_req_size        (encode_out_wr_buf_req_size         )

        ,.encode_out_wr_buf_req_data        (encode_out_wr_buf_req_data         )

        ,.stream_encoder_out_resp_data      (stream_encoder_out_resp_data       )

        ,.encode_out_tx_cap_rd_req_addr     (encode_out_tx_cap_rd_req_addr      )

        ,.tx_cap_encode_out_rd_rsp_data     (tx_cap_encode_out_rd_rsp_data      )

        ,.in_out_meta_data                  (in_out_meta_data                   )

        ,.ctrl_datap_store_meta             (ctrl_datap_store_meta              )
        ,.ctrl_datap_store_offset           (ctrl_datap_store_offset            )
        ,.ctrl_datap_store_cap_id           (ctrl_datap_store_cap_id            )
        ,.ctrl_datap_msg_req_cmd            (ctrl_datap_msg_req_cmd             )
    );
endmodule