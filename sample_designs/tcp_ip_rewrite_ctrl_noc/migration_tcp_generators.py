from collections import deque
import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")

from tcp_driver import RequestGenerator
from tcp_automaton_driver import RequestGenReturn

class MigrationEchoDescrip():
    def __init__(self, payload, last):
        self.payload = payload
        self.last = last

class MigrationEcho(RequestGenerator):
    def __init__(self, logger, random_seed, input_queue, client_len_bytes,
            mac_bytes):
        super().__init__(random_seed)

        self.logger = logger
        self.input_queue = input_queue
        self.client_len_bytes = client_len_bytes
        self.mac_bytes = mac_bytes
        self.save_payload = []
        self.req_lens = deque()
        self.sent_req = 0
        self.finished_req = 0
        self.finished = False

    def get_payload(self):
        # nothing to send yet
        #print(f"Requests num: {self.input_queue.qsize()}")
        if self.input_queue.empty():
            return None

        self.logger.debug(f"getting payload {self.sent_req}")
        echo_descrip = self.input_queue.get_nowait()
        echo_payload = echo_descrip.payload

        self.save_payload.extend(echo_payload)
        self.req_lens.append(len(echo_payload))

        req_server_rd_len = bytearray(len(echo_payload).to_bytes(
            self.client_len_bytes, "big"))
        req_server_wr_len = bytearray(len(echo_payload).to_bytes(
            self.client_len_bytes, "big"))
        req_server_last_req = bytearray(echo_descrip.last.to_bytes(1, "big"))
        req_padding = bytearray([0] * (self.mac_bytes - 1 - (self.client_len_bytes * 2)))

        req = req_server_rd_len
        req.extend(req_server_wr_len)
        req.extend(req_server_last_req)
        req.extend(req_padding)
        req.extend(echo_payload)

        self.sent_req += 1
        self.finished = echo_descrip.last

        return req

    def process_payload(self, payload):
        self.recv_buf.extend(payload)

        next_req_len = self.req_lens[0]

        if len(self.recv_buf) >= next_req_len:
            # compare the buffers
            # compare the buffers
            self.logger.debug(f"Save payload: {self.save_payload[:next_req_len]}")
            self.logger.debug(f"Recv payload: {self.recv_buf[:next_req_len]}")
            if self.save_payload[:next_req_len] != self.recv_buf[:next_req_len]:
                self.logger.info("Echoed bufs not equal")
                raise RuntimeError()
            else:
                self.save_payload = self.save_payload[next_req_len:]
                self.recv_buf = self.recv_buf[next_req_len:]
                self.req_lens.popleft()
                self.finished_req += 1
                self.logger.info(f"Finished request {self.finished_req}")
                if self.finished & (self.finished_req == self.sent_req):
                    self.logger.info("Finished all requests")
                    return RequestGenReturn.DONE
                else:
                    return RequestGenReturn.CORRECT
        else:
            return RequestGenReturn.WAITING


class RewriteDesc(RequestGenerator):
    def __init__(self, client_old_addr, client_port, server_port,
            client_new_addr):
        self.client_old_addr = client_old_addr
        self.client_port = client_port
        self.server_port = server_port
        self.client_new_addr = client_new_addr

class RewriteUpdate(RequestGenerator):
    def __init__(self, logger, random_seed, input_queue, mac_bytes):
        super().__init__(random_seed)

        self.logger = logger
        self.input_queue = input_queue
        self.mac_bytes = mac_bytes

        self.finished_req = 0

    def get_payload(self):
        if self.input_queue.empty():
            return None

        rewrite_req = self.input_queue.get_nowait()

        # assemble the request. the ours and theirs are from the point of the
        # view of the FPGA/server
        # IP addresses are 4 bytes, port numbers are 2
        req_padding = self.mac_bytes - (4 * 2) - (2 * 2)
        their_ip_bytes = socket.inet_aton(rewrite_req.client_new_addr)
        their_port_bytes = rewrite_req.client_port.to_bytes(2, "big")
        our_port_bytes = rewrite_req.server_port.to_bytes(2, "big")
        rewrite_addr_bytes = socket.inet_aton(rewrite_req.client_old_addr)
        padding = bytearray([0] * req_padding)

        req = []
        req.extend(their_ip_bytes)
        req.extend(their_port_bytes)
        req.extend(our_port_bytes)
        req.extend(rewrite_addr_bytes)
        req.extend(padding)

        return req

    def process_payload(self, payload):
        self.recv_buf.extend(payload)

        if len(self.recv_buf) >= self.mac_bytes:
            # look at just the byte for the status
            status = self.recv_buf[0]

            if status != 0:
                raise RuntimeError()

            # trim the recv buf
            self.recv_buf = self.recv_buf[self.mac_bytes:]
            self.finished_req += 1
            return RequestGenReturn.CORRECT
        else:
            return RequestGenReturn.WAITING

