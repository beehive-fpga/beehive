`include "mrp_defs.svh"
module dealloc_arbiter (
     input  logic                   mrp_tx_dealloc_msg_finalize_val
    ,input          mrp_req_key     mrp_tx_dealloc_msg_finalize_key
    ,input          [CONN_ID_W-1:0] mrp_tx_dealloc_msg_finalize_conn_id
    ,output logic                   dealloc_mrp_tx_msg_finalize_rdy

    ,input                          mrp_rx_cam_wr_val
    ,input                          mrp_rx_cam_wr_clear
    ,input          mrp_req_key     mrp_rx_cam_wr_key
    ,input          [CONN_ID_W-1:0] mrp_rx_cam_wr_data
    ,input                          mrp_rx_conn_id_fifo_wr_req
    ,input          [CONN_ID_W-1:0] mrp_rx_conn_id_fifo_wr_data

    ,output logic   [MAX_CONNS-1:0] arbiter_cam_wr_val
    ,output logic                   arbiter_cam_wr_clear
    ,output         mrp_req_key     arbiter_cam_wr_key
    ,output logic   [CONN_ID_W-1:0] arbiter_cam_wr_data
    ,output logic                   arbiter_conn_id_fifo_wr_req
    ,output logic   [CONN_ID_W-1:0] arbiter_conn_id_fifo_wr_data
);
    logic rx_val;

    assign rx_val = mrp_rx_cam_wr_val | mrp_rx_conn_id_fifo_wr_req;

    assign dealloc_mrp_tx_msg_finalize_rdy = ~rx_val;

    assign arbiter_cam_wr_val = rx_val 
                           ? mrp_rx_cam_wr_val << mrp_rx_cam_wr_data
                           : mrp_tx_dealloc_msg_finalize_val << mrp_tx_dealloc_msg_finalize_conn_id;
    
    assign arbiter_cam_wr_clear = rx_val
                                ? mrp_rx_cam_wr_clear
                                : 1'b1;
    assign arbiter_cam_wr_key = rx_val
                                ? mrp_rx_cam_wr_key
                                : mrp_tx_dealloc_msg_finalize_key;
    assign arbiter_cam_wr_data = mrp_rx_cam_wr_data;

    assign arbiter_conn_id_fifo_wr_req = rx_val
                                        ? mrp_rx_conn_id_fifo_wr_req
                                         : mrp_tx_dealloc_msg_finalize_val;
    assign arbiter_conn_id_fifo_wr_data = rx_val
                                        ? mrp_rx_conn_id_fifo_wr_data
                                        : mrp_tx_dealloc_msg_finalize_conn_id;
endmodule
