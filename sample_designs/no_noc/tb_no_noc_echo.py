import logging
import random

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine
from cocotb.log import SimLog
from cocotb.utils import get_sim_time
import scapy

from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP, TCP
from scapy.packet import Raw

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/udp_echo")
from tb_udp_echo import bandwidth_log_test, sanity_test, TB

from tcp_driver import TCPFourTuple
from udp_app_log_read import UDPAppLogRead, UDPAppLogEntry
from eth_latency_log_read import EthLatencyLogRead, EthLatencyLogEntry

MAC_W = 512
MAC_BYTES = int(MAC_W/8)
MIN_PKT_SIZE=64
MSS_SIZE=9100
CLOCK_CYCLE_TIME = 4

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

@cocotb.test()
async def test_wrapper(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_startframe.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=MAC_W))
    dut.mac_engine_rx_endframe.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)
    dut.mac_engine_rx_frame_size.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    # Create the interfaces
    cocotb.start_soon(Clock(dut.clk, CLOCK_CYCLE_TIME, units='ns').start())
    tb = TB(dut)

    await reset(dut)
    #await sanity_test(tb)
    await bandwidth_log_test(tb, runtime=10000, buffer_size=2048)

