import logging

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.log import SimLog

import sys
import os
sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common/")
from simple_val_rdy import SimpleValRdyBus, SimpleValRdyBusSource, SimpleValRdyBusSink
from tcp_log_replay import TCPLogReplay

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = SimLog("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.input_bus = SimpleValRdyBus(dut, {"val": "inject_logger_replay_rx_val",
                                                "data": "inject_logger_replay_rx_data",
                                                "rdy": "logger_replay_inject_rx_rdy"},
                                                data_width = 256)
        self.input_op = SimpleValRdyBusSource(self.input_bus, dut.clk)
        self.output_bus = SimpleValRdyBus(dut, {"val": "logger_replay_inject_tx_val",
                                                "data": "logger_replay_inject_tx_data",
                                                "rdy": "inject_logger_replay_tx_rdy"},
                                                data_width = 256)
        self.output_op = SimpleValRdyBusSink(self.output_bus, dut.clk)

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
async def run_tcp_log_replay(dut):
    # Set some initial values
    dut.inject_logger_replay_rx_val.setimmediatevalue(0)
    dut.inject_logger_replay_rx_data.setimmediatevalue(0)
    dut.inject_logger_replay_tx_rdy.setimmediatevalue(0)

    cocotb.start_soon(Clock(dut.clk, 4, units='ns').start())

    tb = TB(dut)
    await reset(dut)

    log_replay = TCPLogReplay("maybe_stuck/rx_log.csv", 52800, 1024,
            "maybe_stuck/tx_log_trimmed.csv", 64, 2, tb, 4)
    send_task = cocotb.start_soon(log_replay.run_rx_trace())
    recv_task = cocotb.start_soon(log_replay.run_tx_trace())

    await Combine(send_task, recv_task)
