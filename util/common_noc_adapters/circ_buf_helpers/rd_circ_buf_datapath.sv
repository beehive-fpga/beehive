`include "packet_defs.vh"
`include "state_defs.vh"
`include "noc_defs.vh"
`include "soc_defs.vh"
import noc_struct_pkg::*;
module rd_circ_buf_datapath #( 
     parameter SRC_X = 0
    ,parameter SRC_Y = 0
    ,parameter DST_DRAM_X = 0
    ,parameter DST_DRAM_Y = 0
    ,parameter FBITS = 0
) (
     input clk
    ,input rst
    
    // I/O for the NoC
    ,output logic                                   rd_buf_noc0_val
    ,output logic   [`NOC_DATA_WIDTH-1:0]           rd_buf_noc0_data
    ,input                                          noc0_rd_buf_rdy
   
    ,input                                          noc0_rd_buf_val
    ,input          [`NOC_DATA_WIDTH-1:0]           noc0_rd_buf_data
    ,output logic                                   rd_buf_noc0_rdy

    ,output logic   [`MAC_INTERFACE_W-1:0]          rd_buf_src_data
    
    ,input                                          ctrl_datapath_rd_req_val
    ,input  mem_req_struct                          ctrl_datapath_rd_req_data
    ,output logic                                   datapath_ctrl_rd_req_rdy

    ,output logic                                   datapath_ctrl_resp_data_val
    ,output logic                                   datapath_ctrl_resp_data_last
    ,output logic   [`MAC_PADBYTES_W-1:0]           datapath_ctrl_resp_data_padbytes
    ,input  logic                                   ctrl_datapath_resp_data_rdy
    
    ,input          [`MAC_INTERFACE_BYTES_W-1:0]    mem_data_shift_bytes

    ,input  logic                                   write_upper
    ,input  logic                                   shift_upper
    ,input  logic                                   shift_lower
    ,input  logic                                   shift_lower_zeros
);

    logic   [`MAC_INTERFACE_W-1:0]      shift_upper_reg;
    logic   [`MAC_INTERFACE_W-1:0]      shift_upper_next;
    logic   [`MAC_INTERFACE_W-1:0]      shift_lower_reg;
    logic   [`MAC_INTERFACE_W-1:0]      shift_lower_next;
    logic   [(2*`MAC_INTERFACE_W)-1:0]  shift_data;
    logic   [(2*`MAC_INTERFACE_W)-1:0]  shifted_data;

    logic   [`MAC_INTERFACE_W-1:0]      datapath_ctrl_resp_data;
    logic   [`MAC_INTERFACE_BITS_W-1:0] datapath_ctrl_resp_data_mask_shift;
    logic   [`MAC_INTERFACE_W-1:0]      datapath_ctrl_resp_data_mask;
    logic   [`MAC_INTERFACE_W-1:0]      datapath_ctrl_resp_data_masked;

    logic   [`MAC_INTERFACE_BITS_W-1:0] mem_data_shift_bits;
    logic   [`MAC_INTERFACE_W-1:0]      mem_data_masked;

    assign mem_data_shift_bits = mem_data_shift_bytes << 3;
    assign shift_data = {shift_upper_reg, shift_lower_reg};
    assign shifted_data = shift_data << mem_data_shift_bits;
    assign rd_buf_src_data = shifted_data[(2*`MAC_INTERFACE_W)-1 -: `MAC_INTERFACE_W];


    assign datapath_ctrl_resp_data_mask_shift = datapath_ctrl_resp_data_padbytes << 3;
    assign datapath_ctrl_resp_data_mask = datapath_ctrl_resp_data_last 
                                ? {(`MAC_INTERFACE_W){1'b1}} << datapath_ctrl_resp_data_mask_shift
                                : {(`MAC_INTERFACE_W){1'b1}};
    assign datapath_ctrl_resp_data_masked = datapath_ctrl_resp_data & datapath_ctrl_resp_data_mask;


    always_ff @(posedge clk) begin
        if (rst) begin
            shift_upper_reg <= '0;
            shift_lower_reg <= '0;
        end
        else begin
            shift_upper_reg <= shift_upper_next;
            shift_lower_reg <= shift_lower_next;
        end
    end

    always_comb begin
        shift_upper_next = shift_upper_reg;
        if (write_upper) begin
            shift_upper_next = datapath_ctrl_resp_data_masked;
        end
        else if (shift_upper) begin
            shift_upper_next = shift_lower_reg;
        end
        else begin
            shift_upper_next = shift_upper_reg;
        end
    end

    always_comb begin
        shift_lower_next = shift_lower_reg;
        if (shift_lower_zeros) begin
            shift_lower_next = '0;
        end
        else if (shift_lower) begin
            shift_lower_next = datapath_ctrl_resp_data_masked;
        end
        else begin
            shift_lower_next = shift_lower_reg;
        end
    end


    rd_mem_noc_module #(
         .SRC_X     (SRC_X      )
        ,.SRC_Y     (SRC_Y      )
        ,.DST_DRAM_X(DST_DRAM_X )
        ,.DST_DRAM_Y(DST_DRAM_Y )
        ,.FBITS     (FBITS      )
    ) rd_mem_req (
         .clk   (clk)
        ,.rst   (rst)

        ,.rd_mem_noc_req_noc0_val   (rd_buf_noc0_val                )
        ,.rd_mem_noc_req_noc0_data  (rd_buf_noc0_data               )
        ,.noc_rd_mem_req_noc0_rdy   (noc0_rd_buf_rdy                )
                                                                         
        ,.noc_rd_mem_resp_noc0_val  (noc0_rd_buf_val                )
        ,.noc_rd_mem_resp_noc0_data (noc0_rd_buf_data               )
        ,.rd_mem_noc_resp_noc0_rdy  (rd_buf_noc0_rdy                )

        ,.src_rd_mem_req_val        (ctrl_datapath_rd_req_val           )
        ,.src_rd_mem_req_entry      (ctrl_datapath_rd_req_data          )
        ,.rd_mem_src_req_rdy        (datapath_ctrl_rd_req_rdy           )

        ,.rd_mem_src_resp_val       (datapath_ctrl_resp_data_val        )
        ,.rd_mem_src_resp_data      (datapath_ctrl_resp_data            )
        ,.rd_mem_src_resp_last      (datapath_ctrl_resp_data_last       )
        ,.rd_mem_src_resp_padbytes  (datapath_ctrl_resp_data_padbytes   )
        ,.src_rd_mem_resp_rdy       (ctrl_datapath_resp_data_rdy        )
    );
endmodule
