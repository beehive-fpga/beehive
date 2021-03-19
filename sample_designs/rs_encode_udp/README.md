# Overview
This runs Reed-Solomon encoding on the data in a UDP frame. It doesn't currently
support UDP fragmentation (we don't in general support UDP fragmentation
either). The Reed-Solomon hardware is currently fixed to use a (255, 223)
encoding, because we use an 8-bit codeword. I think it's using the BCH view
(rather than the original view) as defined by Wikipedia.

# Modifying the constants
Currently, you can only modify the number of data bytes in a block, because
the codeword size is fixed. While you always need 223 bytes to run encoding on,
some of those can be defined as 0s (padding).

Constants for this design are in two places (sorry!). The first are the hardware
constants, which are located in
`apps/rs_encode_mrp_tile/rs_encode_mrp/reed_solomon_encoder/src/include/rs_encode_pkg.sv`.
`RS_DATA_PADDING` should be defined as the number of actual data bytes in the
block of 223 bytes. The second place is in
`sample_designs/rs_encode_udp/rs_encode_req_lib.py`. `BLOCK_SIZE` should be set
to the number of actual data bytes in the block of 223 bytes. Sorry this is
confusing.

# Running the thing
The overall flow is approximately the same (initialize FuseSoC, generate
filelist, run simulation). However, because the Reed-Solomon encoder is written
in VHDL, the filelist had to be done as a Makefile that then gets included.
However, this Makefile is generated. This means that the very first time you run
this test, you need to tell the main Makefile not to include the filelist
Makefile. Open it and on line 15, comment out the include. Run the init and
generate the filelist. Then reopen the Makefile and uncomment out line 15.
Proceed with running the simulation as normal.


