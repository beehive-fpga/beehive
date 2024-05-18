import logging
from collections import deque
from tcp_driver import DataBufStatus, DataBuf, RequestGenerator, RequestGenReturn
from cocotb.utils import get_sim_time
from cocotb.triggers import Timer, Event

from bitfields import AbstractStruct, bitfield

class StatsLogEntry():
    PACKET_ID_W = 64
    PACKET_ID_BYTES = int(PACKET_ID_W/8)
    XY_WIDTH = 8
    PACKET_NUM_W = PACKET_ID_W - (2 * XY_WIDTH)
    TIMESTAMP_W = 64
    TIMESTAMP_BYTES = int(TIMESTAMP_W/8)

    def __init__(self, init_bytearray=None):
        if init_bytearray is not None:
            # verify it's long enough
            if len(init_bytearray) < self.PACKET_ID_BYTES + self.TIMESTAMP_BYTES:
                raise ValueError("Bytearray is too short")

            self.packet_id = init_bytearray[0:StatsLogEntry.PACKET_ID_BYTES]
            self.timestamp = init_bytearray[StatsLogEntry.PACKET_ID_BYTES:StatsLogEntry.PACKET_ID_BYTES+StatsLogEntry.TIMESTAMP_BYTES]


    def get_len_bytes():
        return (StatsLogEntry.PACKET_ID_BYTES) + (StatsLogEntry.TIMESTAMP_BYTES)

    def __repr__(self):
        return f"Packet ID: {self.packet_id}, timestamp: {self.timestamp}"

    

class StatsReq(AbstractStruct):
    XY_WIDTH = 8
    def __init__(self, x=0, y=0):
        self.bitfields = [
            bitfield("x_coord", StatsReq.XY_WIDTH, value=x),
            bitfield("y_coord", StatsReq.XY_WIDTH, value=y)
        ]
        self.bitfield_indices = {
            "x_coord": 0,
            "y_coord": 1,
        }

        super().__init__(init_bitstring=None)
    
    def to_bytearray(self):
        binstr = self.toBinaryString()
        hexstr_width = int(self.getWidth()/4)
        hexstr = "{0:0{width}x}".format(int(binstr,2), width=hexstr_width)
        payload_bytes = bytearray.fromhex(hexstr)
    
        return payload_bytes

class StatsChecker(RequestGenerator):
    POLL_PERIOD = 4
    SEND_PERIOD = 4
    HDR_BYTES = 64

    def __init__(self, logger, random_seed, done_event, tiles):
        super().__init__(random_seed, logger, done_event)
        self.tiles = tiles
        self.index = 0
        self.got_resp = Event()
        self.sent_packet = Event()

    async def get_payload(self):
        while self.index < len(self.tiles): 
            self.logger.info(f"Reading for tile {self.index}")
            await self.got_resp.wait()

            tile = self.tiles[self.index]
    
            stats_req = tile.to_bytearray()
    
            status = DataBufStatus.SIZE_ERROR
            while status != DataBufStatus.OK:
                await Timer(StatsChecker.SEND_PERIOD, units="ns")
                status = self.send_buf.append(stats_req)
            
            self.index += 1
            self.got_resp.clear()
            self.sent_packet.set()

    def check_if_done(self):
        if self.done_event.is_set():
            return RequestGenReturn.DONE
        else:
            return RequestGenReturn.CORRECT


    async def collect_resp(self):
        result = DataBufStatus.SIZE_ERROR
        buf = []
        while result != DataBufStatus.OK:
            await Timer(StatsChecker.POLL_PERIOD, units="ns")
            (result, buf) = self.recv_buf.remove()

        return buf


    async def process_payload(self):
        data_buf = bytearray([])

        while True:
            await self.sent_packet.wait()
            # go and retrieve the length header
            while len(data_buf) < StatsChecker.HDR_BYTES:
                self.logger.info(f"Waiting to receive a packet")
                buf = await self.collect_resp()
                self.logger.info(f"Received packet of size{len(buf)}")
                data_buf.extend(buf)

            # okay, check the size of the log entries
            bytes_size = int.from_bytes(buf[StatsChecker.HDR_BYTES-8:StatsChecker.HDR_BYTES], byteorder="big")
            # trim the buffer
            data_buf = data_buf[StatsChecker.HDR_BYTES:]

            self.logger.info(f"Looking for {bytes_size} bytes of entries")

            while len(data_buf) < bytes_size:
                buf = await self.collect_resp()
                self.logger.info(f"Received packet of size {len(buf)}")
                data_buf.extend(buf)

            # okay now iterate through and make log entries
            bytes_processed = 0
            log_entries = []

            while bytes_processed < bytes_size:
                log_entries.append(StatsLogEntry(data_buf[bytes_processed:bytes_processed
                    + StatsLogEntry.get_len_bytes()]))
                bytes_processed += StatsLogEntry.get_len_bytes()

            # trim all the bytes from the buffer
            data_buf = data_buf[bytes_processed:]
            print(data_buf)

            self.sent_packet.clear()
            self.got_resp.set()

            self.logger.info(f"Finished index {self.index - 1}")
            self.logger.info(f"Stats entries: {log_entries}")

            if (self.index == len(self.tiles)):
                self.logger.info("setting done event")
                self.done_event.set()

        

