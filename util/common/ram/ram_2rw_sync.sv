`include "bsg_defines.v"
// A 2rw RAM
// Follows the WRITE_FIRST model from the Xilinx BRAMs where the write data
// on a port is put onto the corresponding output port
// Write-Write collisions: have undefined behavior
// Write-Read collsions: the data on the read port is invalid

// By default we let them read/write the same address
module bsg_mem_2rw_sync #(parameter width_p=-1
                           , parameter els_p=-1
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter harden_p=0
                           , parameter enable_clock_gating_p=0
                           , parameter use_1r1w=0
                           )
   ( input  clk_i
    ,input  reset_i

    ,input                      w0_i
    ,input [width_p-1:0]        w0_data_i

    ,input [addr_width_lp-1:0]  addr0_i
    ,input                      v0_i

    ,output logic [width_p-1:0] r0_data_o
    
    ,input                      w1_i
    ,input [width_p-1:0]        w1_data_i

    ,input [addr_width_lp-1:0]  addr1_i
    ,input                      v1_i

    ,output logic [width_p-1:0] r1_data_o
);

    wire clk_lo;
    logic [width_p-1:0] r0_data;
    logic [width_p-1:0] r1_data;

    generate
        if (enable_clock_gating_p) begin
           bsg_clkgate_optional icg
             (.clk_i( clk_i )
             ,.en_i(v0_i | v1_i)
             ,.bypass_i( 1'b0 )
             ,.gated_clock_o( clk_lo )
             );
        end
        else begin
           assign clk_lo = clk_i;
        end
    endgenerate

    // write to port 1, read from port 0
    always_comb begin
        if ((addr1_i == addr0_i) && (v0_i && ~w0_i) && (v1_i && w1_i)) begin
            r0_data_o = `BSG_UNDEFINED_IN_SIM(r0_data); 
        end
        else begin
            r0_data_o = r0_data;
        end
    end
    
    // write to port 0, read from port 1
    always_comb begin
        if ((addr1_i == addr0_i) && (v0_i && ~w0_i) && (v1_i && w1_i)) begin
            r1_data_o = `BSG_UNDEFINED_IN_SIM(r1_data);
        end
        else begin
            r1_data_o = r1_data;
        end
    end
    
    ram_1rw1w_sync #(
         .width_p   (width_p)
        ,.els_p     (els_p)
        ,.use_1r1w  (use_1r1w)
    ) bank0 (
         .clk_i     (clk_i)
        ,.reset_i   (reset_i)
    
        ,.w0_i      (w0_i       )
        ,.w0_data_i (w0_data_i  )

        ,.addr0_i   (addr0_i    )
        ,.v0_i      (v0_i       )
    
        ,.r0_data_o (r0_data    )
    
        ,.w1_i      (w1_i       )
        ,.w1_data_i (w1_data_i  )
    
        ,.addr1_i   (addr1_i    )
        ,.v1_i      (v1_i       )
    );
    
    ram_1rw1w_sync #(
         .width_p   (width_p)
        ,.els_p     (els_p)
        ,.use_1r1w  (use_1r1w)
    ) bank1 (
         .clk_i     (clk_i)
        ,.reset_i   (reset_i)
        
        ,.w0_i      (w1_i       )
        ,.w0_data_i (w1_data_i  )

        ,.addr0_i   (addr1_i    )
        ,.v0_i      (v1_i       )
    
        ,.r0_data_o (r1_data    )
    
        ,.w1_i      (w0_i       )
        ,.w1_data_i (w0_data_i  )
    
        ,.addr1_i   (addr0_i    )
        ,.v1_i      (v0_i       )
    );

//synopsys translate_off

    always_ff @(posedge clk_lo) begin
        if (w0_i & v0_i) begin
            assert (addr0_i < els_p)
              else $error("%m: port 0 invalid address %x to %m of size %x\n", addr0_i, els_p);
        end
        
        //assert (~((addr1_i == addr0_i) && (v1_i && ~w1_i) && (v0_i && w0_i) && (~read_write_same_addr_p)))
        //    else $error("%m: port 1 read, port 0 write.  Attempt to read and write same address");
        //
        //assert (~((addr1_i == addr0_i) && (v0_i && ~w0_i) && (v1_i && w1_i) && (~read_write_same_addr_p)))
        //    else $error("%m: port 0 read, port 1 write.  Attempt to read and write same address");
        
        if (w1_i & v1_i) begin
              assert (addr1_i < els_p)
                else $error("%m: port 1 invalid address %x to %m of size %x\n", addr1_i, els_p);
        end

        if ((w0_i & v0_i) & (w1_i & v1_i)) begin
              assert (addr1_i != addr0_i)
                else $error("%m: Attempt to write same address %x\n", addr0_i);
        end
    end

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, harden_p=%d (%m)"
         ,width_p,els_p,harden_p);
     end

//synopsys translate_on

endmodule
