from simple_bytes_time_log_read import SimpleBytesTimeLogRead, SimpleBytesTimeLogEntry
from simple_bytes_time_log_read import SimpleBytesTimeLogReq, SimpleBytesTimeLogResp

class UDPAppLogRead(SimpleBytesTimeLogRead):
    async def read_log(self):
        entries = await super().read_log(UDPAppLogReq, UDPAppLogResp)

        return entries


class UDPAppLogReq(SimpleBytesTimeLogReq):
    def __init__(self, num_entries_w, client_addr_bytes, addr, read_metadata = False):
        super().__init__(num_entries_w, client_addr_bytes, addr,
                read_metadata=read_metadata)

class UDPAppLogResp(SimpleBytesTimeLogResp):
    def __init__(self, recv_bytearray, num_entries_w, client_addr_bytes):
        super().__init__(recv_bytearray, num_entries_w, client_addr_bytes,
                UDPAppLogEntry)

class UDPAppLogEntry(SimpleBytesTimeLogEntry):
    TIMESTAMP_BYTES = 8
    BYTES_RECV_BYTES = 8

    def __init__(self, recv_bytearray):
        super().__init__(recv_bytearray, self.TIMESTAMP_BYTES,
                self.BYTES_RECV_BYTES)

