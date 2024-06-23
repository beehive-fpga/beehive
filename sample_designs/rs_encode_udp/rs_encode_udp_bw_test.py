import cocotb
import os

from cocotb.triggers import Event, RisingEdge
from cocotb.utils import get_sim_time

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

from tcp_driver import TCPFourTuple
from rs_encode_req_lib import RSEncodeReqLib, RSEncodeConstants
from udp_app_log_read import UDPAppLogRead, UDPAppLogEntry

async def bw_test_recv_loop(tb, in_filename, parity_filename, done_event):

    data_blocks = bytearray()
    num_blocks = 0
    with open(in_filename, "r") as input_file:
        for line in input_file:
            block_bytes = bytes.fromhex(line)
            data_blocks.extend(block_bytes)
            num_blocks += 1

    ref_parity = bytearray()
    with open(parity_filename, "r") as ref_file:
        for line in ref_file:
            parity_bytes = bytes.fromhex(line)
            ref_parity.extend(parity_bytes)

    requests_recv = 0
    while not done_event.is_set():
        tb.log.info(f"Waiting for request {requests_recv}")
        res = await tb.output_op.recv_frame()
        chk_res_pkt = Ether(res)
        chk_res_payload = chk_res_pkt["Raw"].load

        resp_len_expected = ((num_blocks * RSEncodeConstants.BLOCK_SIZE) +
                (RSEncodeConstants.RS_T * num_blocks))
        assert len(chk_res_payload) == resp_len_expected

        data = chk_res_payload[:num_blocks*RSEncodeConstants.BLOCK_SIZE]
        parity = chk_res_payload[num_blocks*RSEncodeConstants.BLOCK_SIZE:]

        assert data == data_blocks, (f"expected: {data_blocks}\nreceived: "
            f"{data}")
        assert parity == ref_parity, (f"expected: "
            f"{ref_parity}\nreceived: {parity}")

        requests_recv += 1

    res = done_event.data
    tb.log.info(f"Requests sent {res}")

    while requests_recv <= res:
        tb.log.info(f"Waiting for remaining request {requests_recv}")

        resp_bytes = await tb.output_op.recv_frame()
        chk_res_pkt = Ether(resp_bytes)
        chk_res_payload = chk_res_pkt["Raw"].load

        resp_len_expected = ((num_blocks * RSEncodeConstants.BLOCK_SIZE) +
                (RSEncodeConstants.RS_T * num_blocks))
        assert len(chk_res_payload) == resp_len_expected

        data = chk_res_payload[:num_blocks*RSEncodeConstants.BLOCK_SIZE]
        parity = chk_res_payload[num_blocks*RSEncodeConstants.BLOCK_SIZE:]

        assert data == data_blocks, (f"expected: {data_blocks}\nreceived: "
            f"{data}")
        assert parity == ref_parity, (f"expected: "
            f"{ref_parity}\nreceived: {parity}")

        requests_recv += 1



async def bw_test_send_loop(tb, run_cycles, in_filename, done_event):
    packet_times = []
    rs_enc_lib = RSEncodeReqLib(tb.MAC_BYTES, 4)
    data_blocks = bytearray()
    num_blocks = 0
    with open(in_filename, "r") as input_file:
        for line in input_file:
            block_bytes = bytes.fromhex(line)
            data_blocks.extend(block_bytes)
            num_blocks += 1

    tot_bytes = 0
    init_time = get_sim_time(units='ns')
    cycles_elapsed = 0
    requests_sent = 0

    test_req = rs_enc_lib.get_rs_req_buffer(num_blocks, data_blocks)
    test_udp = create_udp_frame(0)
    test_udp = test_udp/Raw(test_req)

    test_packet_bytes = bytearray(test_udp.build())

    while cycles_elapsed < run_cycles:
        tb.log.info(f"Sending request {requests_sent}")

        send_task = cocotb.start_soon(tb.input_op.xmit_frame(test_packet_bytes))

        await send_task

        tb.log.info(f"Sent request {requests_sent}")
        start_time_ns = get_sim_time(units='ns')
        tot_bytes += len(test_req)

        cycles = int((start_time_ns)/tb.CLOCK_CYCLE_TIME)
        cycles_bytes = cycles.to_bytes(UDPAppLogEntry.TIMESTAMP_BYTES, byteorder="big")
        tot_bytes_bytes = tot_bytes.to_bytes(UDPAppLogEntry.BYTES_RECV_BYTES,
                        byteorder="big")
        entry_bytearray = cycles_bytes + tot_bytes_bytes
        packet_times.append(UDPAppLogEntry(entry_bytearray))
        cycles_elapsed = int((get_sim_time(units='ns') - init_time)/tb.CLOCK_CYCLE_TIME)
        requests_sent += 1

    tb.log.info(f"Send {requests_sent}")
    done_event.set(data=requests_sent-1)

    return packet_times

async def rs_encode_single_tile_bw_test(tb, input_filename, parity_filename, cycles=10000):
    done_event = Event()

    send_task = cocotb.start_soon(bw_test_send_loop(tb, cycles, input_filename,
        done_event))
    recv_task = cocotb.start_soon(bw_test_recv_loop(tb, input_filename,
        parity_filename, done_event))

    packet_times = await send_task
    await recv_task
    log_four_tuple = TCPFourTuple(our_ip = "198.0.0.5",
                                our_port = 55000,
                                their_ip = "198.0.0.7",
                                their_port = 60000)
    log_reader = UDPAppLogRead(8, 2, tb, log_four_tuple)
    ref_intervals = log_reader.calculate_bws(packet_times, tb.CLOCK_CYCLE_TIME)
    tb.log.debug(ref_intervals)

    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)
    await RisingEdge(tb.dut.clk)


def create_udp_frame(payload_len):
    test_packet = Ether()/IP()/UDP()
    test_packet["Ethernet"].dst = "00:0a:35:0d:4d:c6"
    test_packet["Ethernet"].src = "00:90:fb:60:e1:e7"

    test_packet["IP"].flags = "DF"
    test_packet["IP"].dst = "198.0.0.7"
    test_packet["IP"].src = "198.0.0.5"

    test_packet["UDP"].sport = 54240
    test_packet["UDP"].dport = 65432

    if payload_len != 0:
        payload_bytes = bytearray([random.randint(65, 65+26) for i in range(0, payload_len)])
        test_packet = test_packet/Raw(payload_bytes)

    return test_packet
