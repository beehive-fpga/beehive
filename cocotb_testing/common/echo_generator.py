import logging
from collections import deque
from tcp_driver import DataBufStatus, DataBuf, RequestGenerator, RequestGenReturn
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer
from tcp_open_bw_log_read import TCPOpenBwLogEntry

class EchoGenerator(RequestGenerator):
    POLL_PERIOD = 4
    SEND_PERIOD = 4
    def __init__(self, logger, random_seed, done_event, cycle_time, data_width, req_len, resp_len,
            client_len_bytes, num_reqs=10):
        super().__init__(random_seed, logger, done_event)
        self.total_num_req = num_reqs#self.rng.randint(2, 9)

        self.finished_req = 0
        self.sent_req = 0
        self.save_payload = []
        self.req_lens = deque()
        self.logger = logger
        self.logger.setLevel(logging.DEBUG)
        self.client_len_bytes = client_len_bytes
        self.req_len = req_len
        self.resp_len = resp_len
        self.data_width = data_width
        self.data_bytes = int(self.data_width/8)
        self.cycle_time = cycle_time

        self.send_measurements = []
        self.recv_measurements = []

    def check_if_done(self):
        if self.finished_req == self.total_num_req:
            return RequestGenReturn.DONE
        else:
            return RequestGenReturn.CORRECT

    async def get_payload(self):
        tot_bytes = 0
        while True:
            # if we've sent all the requests, just don't return a payload
            if self.sent_req == self.total_num_req:
                break

            payload = bytearray([(i % 32) + 65 for i in range(0, self.req_len)])
            last_req = self.sent_req == (self.total_num_req-1)
            self.logger.debug(f"last req: {last_req}")
            req_server_rd_len = bytearray(self.req_len.to_bytes(self.client_len_bytes, "big"))
            req_server_wr_len = bytearray(self.resp_len.to_bytes(
                self.client_len_bytes, "big"))
            req_server_last_req = bytearray(last_req.to_bytes(1, "big"))
            req_padding = bytearray([0] * (self.data_bytes - 1 - (self.client_len_bytes * 2)))
            req = req_server_rd_len
            req.extend(req_server_wr_len)
            req.extend(req_server_last_req)
            req.extend(req_padding)
            req.extend(payload)

            status = self.send_buf.append(req)
            self.logger.info(f"App payload: {status}")

            if status == DataBufStatus.OK:
                self.sent_req += 1
                curr_time = get_sim_time(units='ns')
                tot_bytes += self.req_len
                cycles = int(curr_time/self.cycle_time)
                cycles_bytes = cycles.to_bytes(TCPOpenBwLogEntry.TIMESTAMP_BYTES, byteorder="big")
                tot_bytes_bytes = tot_bytes.to_bytes(TCPOpenBwLogEntry.BYTES_RECV_BYTES,
                                byteorder="big")
                entry_bytearray = cycles_bytes + tot_bytes_bytes
                self.send_measurements.append(TCPOpenBwLogEntry(entry_bytearray))

                resp_payload = bytearray([(i % 32) + 65 for i in range(0, self.resp_len)])
                self.save_payload.extend(resp_payload)
                self.req_lens.append(self.resp_len)

            await Timer(EchoGenerator.SEND_PERIOD, units="ns")

    async def process_payload(self):
        data_buf = []
        tot_bytes = 0

        while True:
            (result, buf) = self.recv_buf.remove()
            if result == DataBufStatus.OK:
                data_buf.extend(buf)
                next_req_len = self.req_lens[0]
                while len(data_buf) >= next_req_len:
                    self.logger.debug(f"Save payload: {self.save_payload[:next_req_len]}")
                    self.logger.debug(f"Recv payload: {data_buf[:next_req_len]}")

                    if self.save_payload[:next_req_len] != data_buf[:next_req_len]:
                        self.logger.info("Echoed bufs not equal")
                        raise RuntimeError()
                    else:
                        self.save_payload = self.save_payload[next_req_len:]
                        data_buf = data_buf[next_req_len:]
                        self.req_lens.popleft()
                        self.finished_req += 1
                        self.logger.info(f"Finished request {self.finished_req}")

                        curr_time = get_sim_time(units="ns")
                        tot_bytes += next_req_len
                        cycles = int(curr_time/self.cycle_time)
                        cycles_bytes = cycles.to_bytes(TCPOpenBwLogEntry.TIMESTAMP_BYTES, byteorder="big")
                        tot_bytes_bytes = tot_bytes.to_bytes(TCPOpenBwLogEntry.BYTES_RECV_BYTES,
                                        byteorder="big")
                        entry_bytearray = cycles_bytes + tot_bytes_bytes
                        self.recv_measurements.append(TCPOpenBwLogEntry(entry_bytearray))

                        if self.check_if_done() == RequestGenReturn.DONE:
                            break

                    if len(self.req_lens) > 0:
                        next_req_len = self.req_lens[0]
                    else:
                        break
            await Timer(EchoGenerator.POLL_PERIOD, units="ns")

