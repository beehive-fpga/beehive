import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.log import SimLog

import scapy
from scapy.volatile import RandIP, RandShort

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

async def reset(dut):
    dut.rst.setimmediatevalue(0)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

def create_udp_frame(payload_len, use_ether):
    test_packet = None
    if use_ether:
        test_packet = Ether()/IP()/UDP()
        test_packet["Ethernet"].dst = "00:0a:35:0d:4d:c6"
        test_packet["Ethernet"].src = "00:90:fb:60:e1:e7"
    else:
        test_packet = IP()/UDP()

    test_packet["IP"].flags = "DF"
    test_packet["IP"].dst = "198.0.0.7"
    test_packet["IP"].src = "198.0.0.5"

    test_packet["UDP"].sport = 54240
    test_packet["UDP"].dport = 65432

    payload_bytes = bytearray([random.randint(65, 65+26) for i in range(0, payload_len)])
    test_packet = test_packet/Raw(payload_bytes)

    return test_packet

def pad_packet(packet_buffer, min_pkt_size):
    if len(packet_buffer) < min_pkt_size:
        padding = min_pkt_size - len(packet_buffer)
        pad_bytes = bytearray([0] * padding)
        packet_buffer.extend(pad_bytes)

def python_hash_version(key):
    a = (0xdeadbefb + int.from_bytes(key[8:12], byteorder="big")) & 0xffffffff
    b = (0xdeadbefb + int.from_bytes(key[4:8], byteorder="big")) & 0xffffffff
    c = (0xdeadbefb + int.from_bytes(key[0:4], byteorder="big")) & 0xffffffff

    # print(f"round 0: a: {a}, b: {b}, c: {c}")

    # round 1
    lower_bits_b = (b & 0x0003ffff) << 14
    high_bits_b = (b >> 18) & 0x00003fff
    mix_b = lower_bits_b + high_bits_b
    # print(f"mix b: {mix_b}")

    c = ((c ^ b) - mix_b) & 0xffffffff

    # print(f"round 1: a: {a}, b: {b}, c: {c}")

    # round 2
    # capture the lower 21 bits
    lower_bits_c = (c & 0x001fffff) << 11
    # capture the upper 11
    high_bits_c = (c >> 21) & 0x000007ff
    mix_c = lower_bits_c + high_bits_c
    a = ((a ^ c) - mix_c) & 0xffffffff
    # print(f"round 2: a: {a}, b: {b}, c: {c}")

    # round 3
    lower_bits_a = (a & 0x0000007f) << 25
    high_bits_a = (a >> 7) & 0x01ffffff

    mix_a = lower_bits_a + high_bits_a
    b = ((b ^ a) - mix_a) & 0xffffffff
    # print(f"round 3: a: {a}, b: {b}, c: {c}")

    # round 4
    lower_bits_b = (b & 0x0000ffff) << 16
    high_bits_b = (b >> 16) & 0x0000ffff
    mix_b = lower_bits_b + high_bits_b

    c = ((c ^ b) - mix_b) & 0xffffffff
    # print(f"round 4: a: {a}, b: {b}, c: {c}")

    # round 5
    low_c = (c & 0x0fffffff) << 4
    high_c = (c >> 28) & 0x0000000f
    mix_c = low_c + high_c
    # print(f"mix_c: {mix_c}")

    a = ((a ^ c) - mix_c) & 0xffffffff
    # print(f"round 5: a: {a}, b: {b}, c: {c}")

    # round 6
    low_a = (a & 0x0003ffff) << 14
    high_a = (a >> 18) & 0x00003fff
    mix_a = low_a + high_a

    b = ((b ^ a) - mix_a) & 0xffffffff
    # print(f"round 6: a: {a}, b: {b}, c: {c}")

    # final
    low_b = (b & 0x000000ff) << 24
    high_b = (b >> 8) & 0x00ffffff
    mix_b = low_b + high_b

    hashed = ((c ^ b) - mix_b) & 0xffffffff
    # print(f"final: a: {a}, b: {b}, c: {c}, hashed: {hashed}")
    return hashed

def extract_hash_tuple_bytearray(pkt):
    hash_tuple = bytearray([])
    hash_tuple.extend(socket.inet_pton(socket.AF_INET, pkt["IP"].src))
    hash_tuple.extend(pkt["UDP"].sport.to_bytes(2, byteorder="big"))
    hash_tuple.extend(socket.inet_pton(socket.AF_INET, pkt["IP"].dst))
    hash_tuple.extend(pkt["UDP"].dport.to_bytes(2, byteorder="big"))

    return hash_tuple

