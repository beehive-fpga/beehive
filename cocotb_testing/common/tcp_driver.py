import logging

from random import Random
from enum import Enum
from abc import ABC, abstractmethod

import cocotb

from cocotb.triggers import Combine, First

class TCPDriver():
    def __init__(self):
        self.flow_dict = {}

    @abstractmethod
    def get_packet_to_send(self):
        pass


    @abstractmethod
    def recv_packet(self):
        pass

class TCPState(Enum):
    START = 0
    SYN_SENT = 1
    SEND_ACK = 2
    EST = 3
    RT = 4
    FIN_WAIT = 5

class TCPSeqNum:
    def __init__(self, value):
        self.value = value
        self.max_value = 1 << 32
        self.mask = self.max_value - 1

    def __sub__(self, other):
        if not isinstance(other, TCPSeqNum):
            raise TypeError("other must be an instance of TCPSeqNum")

        value = (self.value - other.value) & self.mask
        return TCPSeqNum(value)

    def __add__(self, other):
        if not isinstance(other, TCPSeqNum):
            raise TypeError("other must be an instance of TCPSeqNum. other is "
                    f"{type(other)}")

        value = (self.value + other.value) & self.mask
        return TCPSeqNum(value)

    def __eq__(self, other):
        return isinstance(other, TCPSeqNum) and (self.value == other.value)

    def __lt__(self, other):
        if not isinstance(other, TCPSeqNum):
            raise TypeError("other must be an instance of TCPSeqNum")
        raw_sub = self - other
        # extract sign bit
        sign_bit = (raw_sub.value & 0x080000000) >> 31
        # return yes if it is a negative number
        return (sign_bit == 1)

    def __le__(self, other):
        if not isinstance(other, TCPSeqNum):
            raise TypeError("other must be an instance of TCPSeqNum")

        return (self < other) or (self == other)

    def __ge__(self, other):
        if not isinstance(other, TCPSeqNum):
            raise TypeError("other must be an instance of TCPSeqNum")

        raw_sub = self - other
        # extract sign bit
        sign_bit = (raw_sub.value & 0x080000000) >> 31
        # return yes if it is a positive number OR zero
        return (sign_bit == 0)

    def __gt__(self, other):
        if not isinstance(other, TCPSeqNum):
            raise TypeError("other must be an instance of TCPSeqNum")

        return (self >= other) and not (self == other)

    def __int__(self):
        return self.value

    def __index__(self):
        return self.__int__()

    def __hash__(self):
        return hash(self.value)

    def __repr__(self):
        return f"TCPSeqNum: {self.value}"


class TCPFourTuple:
    def __init__(self, our_ip, our_port, their_ip, their_port):
        self.our_ip = our_ip
        self.our_port = our_port
        self.their_ip = their_ip
        self.their_port = their_port

    def __repr__(self):
        return (f"our_ip: {self.our_ip}, our_port: {self.our_port}\n"
                f"their_ip: {self.their_ip}, their_port: {self.their_port}")

    def __hash__(self):
        return hash((self.our_ip, self.our_port, self.their_ip, self.their_port))

    def __eq__(self, other):
        return (self.our_ip == other.our_ip
                and self.our_port == other.our_port
                and self.their_ip == other.their_ip
                and self.their_port == other.their_port)

class RequestGenReturn(Enum):
    CORRECT = 0
    INCORRECT = 1
    DONE = 2
    WAITING = 3

class RequestGenerator:
    def __init__(self, random_seed, logger, done_event, buf_max_size=(1<<16)-1):
        self.rng = Random(random_seed)

        self.buf_max_size = buf_max_size
        self.recv_buf = DataBuf(self.buf_max_size)
        self.send_buf = SendDataBuf(self.buf_max_size)

        self.logger = logger
        self.logger.setLevel(logging.DEBUG)
        self.done_event = done_event

    async def get_payload(self):
        pass

    async def process_payload(self):
        pass

    def run_app(self):
        send_loop = cocotb.start_soon(self.get_payload())
        recv_loop = cocotb.start_soon(self.process_payload())
        self.logger.debug("App starting loops")
        return First(self.done_event.wait(), send_loop, recv_loop)

class DataBufStatus(Enum):
    OK = 0
    SIZE_ERROR = 1

class DataBuf():
    def __init__(self, max_size):
        self.max_size = max_size
        self.bufs = []
        self.space_used = 0

    def peek_front_size(self):
        if len(self.bufs) == 0:
            return None
        else:
            return len(self.bufs[0])

    def grab_partial_front(self, size):
        if len(self.bufs) == 0:
            return (DataBufStatus.SIZE_ERROR, None)
        else:
            if len(self.bufs[0]) < size:
                return (DataBufStatus.SIZE_ERROR, None)
            elif len(self.bufs[0]) == size:
                return self.remove()
            else:
                ret_buf = (self.bufs[0])[:size]
                self.bufs[0] = self.bufs[0][size:]
                self.space_used -= size
                return (DataBufStatus.OK, ret_buf)

    def get_space_free(self):
        return self.max_size - self.space_used

    def append(self, buffer):
        space_free = self.get_space_free()
        status = DataBufStatus.OK
        if space_free < len(buffer):
            status = DataBufStatus.SIZE_ERROR
        else:
            self.bufs.append(buffer)
            self.space_used += len(buffer)
            status = DataBufStatus.OK
        return status

    def remove(self):
        if len(self.bufs) == 0:
            return (DataBufStatus.SIZE_ERROR, None)
        else:
            ret_buf = self.bufs.pop(0)
            self.space_used -= len(ret_buf)
            return (DataBufStatus.OK, ret_buf)

class SendDataBuf(DataBuf):
    def __init__(self, max_size):
        super().__init__(max_size)
        self.send_buf_index = 0

    def peek_send_size(self):
        if self.send_buf_index == len(self.bufs):
            return None
        else:
            return len(self.bufs[self.send_buf_index])

    def ack_data(self, num_bytes):
        num_bytes_left = num_bytes
        while num_bytes_left > 0:
            next_buf_len = self.peek_front_size()
            buf = None
            if num_bytes_left >= next_buf_len:
                (status, buf) = self.remove()
                self.send_buf_index -= 1
            else:
                (status, buf) = self.grab_partial_front(num_bytes_left)
            num_bytes_left -= len(buf)
            print(f"bytes left to trim: {num_bytes_left}")

    def send_data(self, num_bytes):
        next_send_size = self.peek_send_size()
        if num_bytes > next_send_size:
            return (DataBufStatus.SIZE_ERROR, None)
        if num_bytes == next_send_size:
            next_buf = self.bufs[self.send_buf_index]
            self.send_buf_index += 1
            return (DataBufStatus.OK, next_buf)
        # otherwise we have to split buffers
        else:
            whole_buf = self.bufs.pop(self.send_buf_index)
            ret_buf = whole_buf[:num_bytes]
            back_buf = whole_buf[num_bytes:]
            self.bufs.insert(self.send_buf_index, ret_buf)
            self.bufs.insert(self.send_buf_index + 1, back_buf)
            self.send_buf_index += 1
            return (DataBufStatus.OK, ret_buf)


    def reset_for_retransmit(self):
        self.send_buf_index = 0

