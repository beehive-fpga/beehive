from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from math import ceil
import csv

import cocotb
from cocotb.log import SimLog
import logging
from cocotb.triggers import ClockCycles
from cocotb.binary import BinaryValue
from cocotb.utils import get_sim_time

from tcp_logger_read import TCPLoggerEntry

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from noc_helpers import BeehiveHdrFlit, BeehiveIPFlit, BeehiveNoCConstants
from simple_val_rdy import SimpleValRdyFrame
from timer_progress import TimerProgress

class TCPLogReplay():
    def __init__(self, rx_log_file, total_req_bytes, rx_req_size,
            tx_log_file, tx_resp_size, client_addr_bytes, tb, clock_cycle_ns):
        self.clock_cycle_ns = clock_cycle_ns

        self.rx_entries = self.read_log_file(rx_log_file)
        self._add_rx_payload(self.rx_entries, total_req_bytes, rx_req_size,
                tx_resp_size, client_addr_bytes)
        self.tx_entries = self.read_log_file(tx_log_file)
        self._add_tx_payload(self.tx_entries)
        self.tb = tb

        self.check_fields = ["sport", "dport", "seq", "ack", "flags"]

        start_time = min((self.rx_entries[0].timestamp, self.tx_entries[0].timestamp))

        self._adjust_time_stamps(start_time, self.rx_entries)
        self._adjust_time_stamps(start_time, self.tx_entries)
        self.step_time = 10000

    def read_log_file(self, filename):
        entries = []
        with open(filename) as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                buffer = bytearray()
                buffer.extend(bytearray.fromhex(row["timestamp"][2:]))
                buffer.extend(bytearray.fromhex(row["tcp_len"][2:]))
                buffer.extend(bytearray.fromhex(row["tcp_hdr"][2:]))
                entry = TCPLoggerEntry(buffer)
                entries.append(entry)
        return entries

    def _adjust_time_stamps(self, start_time, entries):
        for entry in entries:
            entry.timestamp = entry.timestamp - start_time

        # now turn everything into nanoseconds
        for entry in entries:
            entry.timestamp = entry.timestamp * self.clock_cycle_ns

    def _calc_cycles_wait(self, sim_start_time, next_time):
        offset_time = next_time + sim_start_time
        time_until = offset_time - get_sim_time(units="ns")
        if time_until < 0:
            raise RuntimeError("Somehow we're lagging behind")
        elif (time_until % self.clock_cycle_ns) != 0:
            raise RuntimeError("We need to wait a non integral number of cycles")
        else:
            return int(time_until/self.clock_cycle_ns)

    async def run_rx_trace(self):
        sim_time_start_ns = get_sim_time(units="ns")
        rx_progress_timer = TimerProgress(self.tb.log, timer_name="rx_timer")
        if self.rx_entries[0].timestamp != 0:
            cycles_wait = self._calc_cycles_wait(sim_time_start_ns,
                    self.rx_entries[0].timestamp)
            await rx_progress_timer.arm_timer(cycles_wait, self.step_time,
                    self.tb.dut.clk)

        for i in range(0, len(self.rx_entries)):
            self.tb.log.debug(f"Sending entry {i}")
            entry = self.rx_entries[i]
            self.tb.log.debug(f"Packet header: {entry.tcp_hdr.show2(dump=True)}")

            await self._xmit_noc_msg(entry)

            if i < (len(self.rx_entries) - 1):
                cycles_wait = self._calc_cycles_wait(sim_time_start_ns,
                                            self.rx_entries[i + 1].timestamp)
                if (cycles_wait != 0):
                    await rx_progress_timer.arm_timer(cycles_wait, self.step_time,
                        self.tb.dut.clk)


    async def run_tx_trace(self):
        sim_time_start_ns = get_sim_time(units="ns")
        tx_progress_timer = TimerProgress(self.tb.log, timer_name="tx_timer")
        if self.tx_entries[0].timestamp != 0:
            cycles_wait = self._calc_cycles_wait(sim_time_start_ns,
                    self.tx_entries[0].timestamp)
            await tx_progress_timer.arm_timer(cycles_wait,
                    self.step_time, self.tb.dut.clk)

        for i in range(0, len(self.tx_entries)):
            self.tb.log.debug(f"Waiting for entry {i}")
            entry = self.tx_entries[i]

            tcp_buf = await self._recv_noc_msg()
            self.tb.log.debug(f"Got entry {i}")
            recv_TCP = TCP(tcp_buf)

            self._check_TCP_pkt(recv_TCP, entry.tcp_hdr)

            if i < (len(self.tx_entries) - 1):
                cycles_wait = self._calc_cycles_wait(sim_time_start_ns,
                        self.tx_entries[i + 1].timestamp)
                await tx_progress_timer.arm_timer(cycles_wait, self.step_time,
                        self.tb.dut.clk)


    async def _xmit_noc_msg(self, entry):
        noc_hdr_flit = BeehiveHdrFlit()
        noc_ip_flit = BeehiveIPFlit()

        data_buf = entry.tcp_hdr.build()
        num_data_flits = ceil(len(data_buf)/(BeehiveNoCConstants.NOC_DATA_W/8))

        # fill in the header flit
        noc_hdr_flit.set_field("dst_x", 1)
        noc_hdr_flit.set_field("dst_y", 2)
        noc_hdr_flit.set_field("dst_fbits", "1000")
        noc_hdr_flit.set_field("msg_length", 1 + num_data_flits)
        noc_hdr_flit.set_field("src_x", 1)
        noc_hdr_flit.set_field("src_y", 1)
        noc_hdr_flit.set_field("metadata_flits", 1)
        noc_hdr_flit_bin = noc_hdr_flit.assemble_flit()

        # fill in the metadata flit
        noc_ip_flit.set_field("src_ip", "198.19.100.17")
        noc_ip_flit.set_field("dst_ip", "198.19.100.18")
        noc_ip_flit.set_field("payload_len", len(data_buf))
        noc_ip_flit.set_field("protocol", 6)
        noc_ip_flit_bin = noc_ip_flit.assemble_flit()

        req_values = SimpleValRdyFrame(data=noc_hdr_flit_bin.buff)
        await self.tb.input_op.send_req(req_values)

        req_values = SimpleValRdyFrame(data=noc_ip_flit_bin.buff)
        await self.tb.input_op.send_req(req_values)

        await self.tb.input_op.send_buf(data_buf)

    async def _recv_noc_msg(self):
        hdr_flit = await self.tb.output_op.recv_resp()
        self.tb.log.debug("Received hdr flit")
        ip_flit = await self.tb.output_op.recv_resp()

        hdr_flit_cast = BeehiveHdrFlit()
        hdr_flit_cast.flit_from_bitstring(hdr_flit.data.binstr)

        ip_flit_cast = BeehiveIPFlit()
        ip_flit_cast.flit_from_bitstring(ip_flit.data.binstr)

        num_flits = hdr_flit_cast.msg_length.integer - 1

        self.tb.log.debug(f"Num data flits: {num_flits}")
        data_buf = bytearray()
        for i in range(0, num_flits):
            recv_data = await self.tb.output_op.recv_resp()
            data_buf.extend(recv_data.data.buff)

        data_buf_len = ip_flit_cast.payload_len.integer
        self.tb.log.debug(f"Recv pkt len is {data_buf_len}")
        self.tb.log.debug(f"Recv pkt is {data_buf.hex()}")


        return data_buf[:data_buf_len]


    def _add_rx_payload(self, rx_entries, total_bytes_send, rx_req_len,
            tx_resp_len, client_addr_bytes):
        flow_map = {}
        # Find the request length
        payload = bytearray([(i % 32) + 65 for i in range(0, rx_req_len)])
        req_server_rd_len = bytearray(rx_req_len.to_bytes(client_addr_bytes, "big"))
        req_server_wr_len = bytearray(tx_resp_len.to_bytes(client_addr_bytes, "big"))
        req_padding = bytearray([0] * (32 - (2 * client_addr_bytes)))
        req = req_server_rd_len
        req.extend(req_server_wr_len)
        req.extend(req_padding)
        req.extend(payload)

        last_req = req.copy()
        last_req[2*client_addr_bytes] = 1

        for entry in rx_entries:
            if entry.tcp_hdr.flags == "S":
                # create some fake payload
                payload_len = entry.pkt_len - 20
                if payload_len > 0:
                    payload = bytearray([(i % 32) + 65 for i in range(0, payload_len)])
                    entry.tcp_hdr = entry.tcp_hdr/Raw(payload)
                    flow_map[entry.tcp_hdr.sport] = entry.tcp_hdr.seq
                # clear the checksum so it gets recalculated
                # do some fucked up stuff just to get the chksum
                entry.tcp_hdr.chksum = None
                ip_blank = IP()
                ip_blank.src = "198.19.100.17"
                ip_blank.dst = "198.19.100.18"
                # build to recalculate checksum
                build_bytes = (ip_blank/entry.tcp_hdr.copy()).build()
                # cast it back to a packet
                built_pkt = IP(build_bytes)
                # now just only grab TCP again
                entry.tcp_hdr = built_pkt["TCP"]
            else:
                msg_buffer = bytearray(entry.pkt_len - 20)
                buffer_offset_start = entry.tcp_hdr.seq - flow_map[entry.tcp_hdr.sport] - 1
                for i in range(0, entry.pkt_len-20):
                    # if we're sending the last request
                    if buffer_offset_start + i + len(req) >= total_bytes_send:
                        msg_buffer[i] = last_req[(i + buffer_offset_start) % len(req)]
                    else:
                        msg_buffer[i] = req[(i + buffer_offset_start)%len(req)]

                entry.tcp_hdr = entry.tcp_hdr/Raw(msg_buffer)

    def _add_tx_payload(self, tx_entries):
        flow_map = {}
        for entry in tx_entries:
            if (entry.tcp_hdr.dport) not in flow_map:
                flow_map[entry.tcp_hdr.dport] = entry.tcp_hdr.seq

            payload_len = entry.pkt_len - 20
            if payload_len > 0:
                buffer_offset_start = entry.tcp_hdr.seq - flow_map[entry.tcp_hdr.dport] - 1
                payload = bytearray([((buffer_offset_start + i) % 32) + 65 for i in range(0, payload_len)])
                entry.tcp_hdr = entry.tcp_hdr/Raw(payload)

    def _check_TCP_pkt(self, recv_pkt, ref_pkt):
        for field in self.check_fields:
            ref_attr = getattr(ref_pkt, field)
            recv_attr = getattr(recv_pkt,field)

            if ref_attr != recv_attr:
                raise RuntimeError((f"Field {field} doesn't match\n",
                                    f"Ref field: {ref_attr}\n",
                                    f"Recv field: {recv_attr}\n"))

        recv_pkt_has_payload = "Raw" in recv_pkt
        ref_pkt_has_payload = "Raw" in ref_pkt
        if recv_pkt_has_payload != ref_pkt_has_payload:
            raise RuntimeError((f"Payloads don't match. recv_pkt: {recv_pkt_has_payload}"
                f"ref_pkt: {ref_pkt_has_payload}"))
        elif "Raw" in recv_pkt:
            ref_load = ref_pkt["Raw"].load
            recv_load = recv_pkt["Raw"].load
            if ref_load != recv_load:
                raise RuntimeError(("Payload contents don't match\n"
                    f"recv: {recv_load}\n"
                    f"ref: {ref_load}"))
