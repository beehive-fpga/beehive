from enum import Enum
import cocotb
from cocotb.log import SimLog
from cocotb.triggers import Timer
from cocotb.utils import get_sim_time

import logging

from tcp_driver import RequestGenerator, RequestGenReturn, DataBuf, DataBufStatus

from tcp_open_bw_log_read import TCPOpenBwLogEntry

class ClientDir(Enum):
    SEND = 0
    RECV = 1

class OpenLoopGenerator(RequestGenerator):
    FIELD_BYTES = 4
    DIR_BYTES = 1
    RESP_BYTES = 64
    POLL_PERIOD = 1
    SEND_PERIOD = 1
    FLAG_BYTES = 1
    def __init__(self, random_seed, logger, done_event, cycle_time, data_width, buf_size, direction,
            num_reqs, num_conns, setup_conn, should_copy, buf_max_size):
        super().__init__(random_seed, logger, done_event,
                buf_max_size=buf_max_size)

        self.cycle_time = cycle_time

        self.num_reqs = num_reqs
        self.setup_conn = setup_conn
        self.num_conns = num_conns
        self.data_width = data_width
        self.data_bytes = int(self.data_width/8)
        self.buf_size = buf_size
        self.direction = direction
        self.sent_setup = False
        self.setup_resp = False
        self.curr_op_num = 0
        self.should_copy = should_copy

        self.send_measurements = []
        self.recv_measurements = []


    def check_if_done(self):
        if (self.curr_op_num >= self.num_reqs):
            return RequestGenReturn.DONE
        else:
            return RequestGenReturn.CORRECT

    async def get_payload(self):
        if self.setup_conn:
            if not self.sent_setup:
                self.logger.info("Sending setup request")
                # put together the request header
                req = []
                req.extend(self.num_reqs.to_bytes(self.FIELD_BYTES, "big"))
                req.extend(self.buf_size.to_bytes(self.FIELD_BYTES, "big"))
                req.extend(self.num_conns.to_bytes(self.FIELD_BYTES, "big"))
                req.extend(self.direction.value.to_bytes(self.DIR_BYTES, "big"))
                req.extend(int(self.should_copy).to_bytes(self.FLAG_BYTES, "big"))
                self.send_buf.append(req)
                self.sent_setup = True
        else:
            tot_bytes = 0
            start_logging = False
            while True:
                if (self.setup_resp):
                    break
                await Timer(OpenLoopGenerator.SEND_PERIOD, units="ns")

            self.logger.info("Starting app body")
            while True:
                if (self.direction == ClientDir.SEND):
                    if (self.curr_op_num < self.num_reqs):
                        payload = bytearray([(self.curr_op_num % 256) for i in range(0,self.buf_size)])
                        status = self.send_buf.append(payload)
        #                self.logger.info(f"App payload {self.curr_op_num}: {status}")
        #                self.logger.info(f"Send buf space used: {self.send_buf.space_used}")

                        if status == DataBufStatus.OK:
                            self.curr_op_num += 1
                            if start_logging:
                                curr_time = get_sim_time(units='ns')
                                tot_bytes += self.buf_size
                                cycles = int(curr_time/self.cycle_time)
                                cycles_bytes = cycles.to_bytes(TCPOpenBwLogEntry.TIMESTAMP_BYTES, byteorder="big")
                                tot_bytes_bytes = tot_bytes.to_bytes(TCPOpenBwLogEntry.BYTES_RECV_BYTES,
                                                byteorder="big")
                                entry_bytearray = cycles_bytes + tot_bytes_bytes
                                self.send_measurements.append(TCPOpenBwLogEntry(entry_bytearray))
                        else:
                            start_logging = True
                await Timer(OpenLoopGenerator.SEND_PERIOD, units="ns")


    async def process_payload(self):
        data_buf = bytearray([])
        tot_bytes = 0
        if self.setup_conn:
            while True:
                (result, buf) = self.recv_buf.remove()
                if result == DataBufStatus.OK:
                    data_buf.extend(buf)
                    if len(data_buf) >= self.RESP_BYTES:
                        if (data_buf[self.RESP_BYTES-1] != 1):
                            raise RuntimeError()
                        else:
                            data_buf = data_buf[self.RESP_BYTES:]
                            self.setup_resp = True
                await Timer(OpenLoopGenerator.POLL_PERIOD, units="ns")
        else:
            log_period_ns = 500 * self.cycle_time
            start_time = get_sim_time(units="ns")
            last_logged_time = start_time
            while True:
                (result, buf) = self.recv_buf.remove()
                if result == DataBufStatus.OK:
                    self.logger.info(f"App payload: {buf}")
                    if (self.direction == ClientDir.SEND):
                        raise RuntimeError("Shouldn't have received payload")
                    if not self.setup_resp:
                        raise RuntimeError("Received payload before setup finished")

                    data_buf.extend(buf)
                    data_dequeued = False
                    while len(data_buf) >= self.buf_size:
                        data_dequeued = True
                        rep_count = int(self.buf_size/self.FIELD_BYTES)
                        ref_payload = bytearray([])
                        for i in range(0, rep_count):
                            ref_payload.extend(self.curr_op_num.to_bytes(self.FIELD_BYTES,
                                "big"))
                        #if ref_payload != data_buf[:self.buf_size]:
                            pass
                            #raise RuntimeError("Bufs weren't equal\n"
                            #        f"Expected:{ref_payload}\n"
                            #        f"Received:{data_buf[:self.buf_size]}")
                        #else:
                        data_buf = data_buf[self.buf_size:]
                        self.curr_op_num += 1
                        tot_bytes += self.buf_size
                        self.logger.info(f"App op {self.curr_op_num}")

                        if self.curr_op_num == self.num_reqs:
                            self.logger.info("App all done")

                curr_time = get_sim_time(units="ns")
                diff_time = curr_time - last_logged_time
                if diff_time > log_period_ns:
                    last_logged_time = curr_time
                    cycles = int(curr_time/self.cycle_time)
                    cycles_bytes = cycles.to_bytes(TCPOpenBwLogEntry.TIMESTAMP_BYTES, byteorder="big")
                    tot_bytes_bytes = tot_bytes.to_bytes(TCPOpenBwLogEntry.BYTES_RECV_BYTES,
                                    byteorder="big")
                    entry_bytearray = cycles_bytes + tot_bytes_bytes
                    self.recv_measurements.append(TCPOpenBwLogEntry(entry_bytearray))
                await Timer(OpenLoopGenerator.POLL_PERIOD, units="ns")


