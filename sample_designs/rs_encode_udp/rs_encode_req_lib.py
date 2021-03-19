class RSEncodeConstants():
    BLOCK_SIZE = 192
    RS_N = 255
    RS_K = 223
    RS_T = RS_N - RS_K

class RSEncodeReqLib():
    def __init__(self, bus_bytes, num_blocks_bytes):
        self.bus_bytes = bus_bytes
        self.num_blocks_bytes = num_blocks_bytes

    def get_rs_req_header(self, num_blocks):
        req_hdr = bytearray(num_blocks.to_bytes(self.num_blocks_bytes, "big"))
        padding = bytearray([0]*(self.bus_bytes - self.num_blocks_bytes))
        req_hdr.extend(padding)

        return req_hdr

    def get_rs_req_buffer(self, num_blocks, payload):
        req = self.get_rs_req_header(num_blocks)
        req.extend(payload)
        return req

