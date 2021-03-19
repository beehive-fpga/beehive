import logging
from time import sleep

class NetworkLogReader():
    def __init__(self, num_entries_w, client_addr_bytes, dst_tuple, sock,
            resp_size):
        self.num_entries_w = num_entries_w
        self.num_entries = 1 << num_entries_w
        self.client_addr_bytes = client_addr_bytes
        self.dst_tuple = dst_tuple
        self.sock = sock
        self.resp_size = resp_size


    def read_log(self, LogReqClass, LogRespClass):
        logging.info("Reading number of requests for log at port "
                f"{self.dst_tuple[1]}")
        meta_req = LogReqClass(self.num_entries_w, self.client_addr_bytes, 0,
                read_metadata=True)
        meta_req_bytes = meta_req.get_req_bytearray()

        self.sock.sendto(meta_req_bytes, self.dst_tuple)

        data, addr = self.sock.recvfrom(self.resp_size)
        log_resp = LogRespClass(data, self.num_entries_w,
                self.client_addr_bytes)

        num_reads = log_resp.num_written_entries
        if num_reads > 256:
            print(f"Log has wrapped")
            num_reads = 256

        print(f"Found {num_reads} entries")

        entries = []

        for i in range(0, num_reads):
            print(f"Reading entry {i}")
            data_req = LogReqClass(self.num_entries_w, self.client_addr_bytes,
                    i, read_metadata=False)
            data_req_bytes = data_req.get_req_bytearray()

            self.sock.sendto(data_req_bytes, self.dst_tuple)

            data, addr = self.sock.recvfrom(self.resp_size)

            log_resp = LogRespClass(data, self.num_entries_w,
                    self.client_addr_bytes)
            entries.append(log_resp.log_entry)

        return entries

