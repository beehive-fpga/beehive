import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly
import scapy

import sys
sys.path.append("../common")
from beehive_bus import BeehiveBusFrame
from beehive_bus import BeehiveBus
from beehive_bus import BeehiveBusSource
from beehive_bus import BeehiveBusSink

from scapy.layers.l2 import Ether

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


#@cocotb.test()
async def basic_test(dut):
    """Try sending one frame"""

    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=256))
    dut.mac_engine_rx_last.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    cocotb.fork(Clock(dut.clk, 10, units='ns').start())

    await reset(dut)

    # Create the frame
    test_packet = Ether()
    test_packet["Ethernet"].dst = "24:be:05:bf:5b:91"
    test_packet["Ethernet"].src = "e0:07:1b:6f:fc:c1"
    test_packet["Ethernet"].type = 0x806
    test_packet_bytes = test_packet.build()
    data_value = BinaryValue(n_bits=256)
    data_value.buff = test_packet_bytes

    dut.mac_engine_rx_data.value = data_value;
    dut.mac_engine_rx_last.value = 1
    dut.mac_engine_rx_padbytes.value = 32 - len(test_packet_bytes)
    dut.mac_engine_rx_val.value = 1

    # Req transaction example
    while True:
        await ReadOnly()
        if dut.engine_mac_rx_rdy.value == 1:
            break
        await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.mac_engine_rx_val.value = 0

    # Resp transaction example
    await RisingEdge(dut.engine_mac_tx_val)
    dut.mac_engine_tx_rdy.value = 1
    bus_val = dut.engine_mac_tx_data.value
    good_bytes = 32 - dut.engine_mac_tx_padbytes.value
    good_bytes_array = bus_val.buff[0:good_bytes]

    assert (good_bytes_array == test_packet_bytes)


   # while True:
   #     if dut.engine_mac_tx_val.value == 1:
   #         break;
   #     await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

@cocotb.test()
async def bus_test(dut):
    # Set some initial values
    dut.mac_engine_rx_val.setimmediatevalue(0)
    dut.mac_engine_rx_data.setimmediatevalue(BinaryValue(value=0, n_bits=256))
    dut.mac_engine_rx_last.setimmediatevalue(0)
    dut.mac_engine_rx_padbytes.setimmediatevalue(0)

    dut.mac_engine_tx_rdy.setimmediatevalue(0)

    # Create the interfaces

    cocotb.fork(Clock(dut.clk, 10, units='ns').start())

    await reset(dut)

    # Create the frame
    test_packet = Ether()
    test_packet["Ethernet"].dst = "24:be:05:bf:5b:91"
    test_packet["Ethernet"].src = "e0:07:1b:6f:fc:c1"
    test_packet["Ethernet"].type = 0x806
    test_packet_bytes = test_packet.build()

    input_frame = BeehiveBusFrame(data=test_packet_bytes, last=1, padbytes=32 -
            len(test_packet_bytes))

    input_bus = BeehiveBus(dut, {"val": "mac_engine_rx_val",
                                 "data": "mac_engine_rx_data",
                                 "last": "mac_engine_rx_last",
                                 "padbytes": "mac_engine_rx_padbytes",
                                 "rdy": "engine_mac_rx_rdy"})
    input_op = BeehiveBusSource(input_bus, dut.clk)

    output_bus = BeehiveBus(dut, {"val": "engine_mac_tx_val",
                                  "data": "engine_mac_tx_data",
                                  "last": "engine_mac_tx_last",
                                  "padbytes": "engine_mac_tx_padbytes",
                                  "rdy": "mac_engine_tx_rdy"})
    output_op = BeehiveBusSink(output_bus, dut.clk)
    await input_op.send_req(input_frame)

    output_frame = await output_op.recv_resp()
    output_repr = repr(output_frame)
    print(output_repr)

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)





