import random 
import sys, os
import logging
from cocotb_test.simulator import run

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, ReadOnly, Combine, ClockCycles
from cocotb.triggers import with_timeout, Event, First, Join
from cocotb.log import SimLog

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/cocotb_testing/common")
from simple_padbytes_bus import SimplePadbytesFrame
from simple_padbytes_bus import SimplePadbytesBus
from simple_padbytes_bus import SimplePadbytesBusSource
from simple_padbytes_bus import SimplePadbytesBusSink

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/util/data_converters/tb/realign")
from realign_tests import TB, run_data_buf_size_test, reset

# pytest tries to run anything starting with test...can also use
# @pytest.mark.skip
@cocotb.test()
async def realign_compile_test(dut):
    tb = TB(dut)
    
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    
    dut.src_realign_data_val.setimmediatevalue(0)
    dut.src_realign_data.setimmediatevalue(BinaryValue(value=0,
        n_bits=dut.src_realign_data.value.n_bits))
    dut.src_realign_data_padbytes .setimmediatevalue(0)
    dut.src_realign_data_last.setimmediatevalue(0)

    dut.dst_realign_data_rdy.setimmediatevalue(0)

    await reset(dut)

    realign_w = dut.REALIGN_W.value
    realign_bytes = int(realign_w/8)

    await run_data_buf_size_test(tb, realign_bytes)

@cocotb.test()
async def val_rdy_test(dut):
    tb = TB(dut)
    
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    
    dut.src_realign_data_val.setimmediatevalue(0)
    dut.src_realign_data.setimmediatevalue(BinaryValue(value=0,
        n_bits=dut.src_realign_data.value.n_bits))
    dut.src_realign_data_padbytes .setimmediatevalue(0)
    dut.src_realign_data_last.setimmediatevalue(0)

    dut.dst_realign_data_rdy.setimmediatevalue(0)

    await reset(dut)

    realign_w = dut.REALIGN_W.value
    realign_bytes = int(realign_w/8)

    await run_data_buf_size_test(tb, realign_bytes, max_rand_delay_in=4,
            max_rand_delay_out=4)

@cocotb.test()
async def backpressure_test(dut):
    tb = TB(dut)
    
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    
    dut.src_realign_data_val.setimmediatevalue(0)
    dut.src_realign_data.setimmediatevalue(BinaryValue(value=0,
        n_bits=dut.src_realign_data.value.n_bits))
    dut.src_realign_data_padbytes .setimmediatevalue(0)
    dut.src_realign_data_last.setimmediatevalue(0)

    dut.dst_realign_data_rdy.setimmediatevalue(0)

    await reset(dut)

    realign_w = dut.REALIGN_W.value
    realign_bytes = int(realign_w/8)

    await run_data_buf_size_test(tb, realign_bytes, max_rand_delay_out=4)

def test_realign_widths():
    base_run_args = get_base_args()
    data_bytes = int(base_run_args["parameters"]["DATA_W"]/8)
    base_run_args["testcase"] = "realign_compile_test"
    for i in range(1, data_bytes):
        logging.warning(f"===Testing realign width of {i}===")
        base_run_args["parameters"]["REALIGN_W"] = i * 8
        base_run_args["sim_build"] = f"sim_build_{i}"
        run(**base_run_args)

def test_realign_compile_valrdy():
    base_run_args = get_base_args()
    base_run_args["testcase"] = "val_rdy_test"
    base_run_args["parameters"]["REALIGN_W"] = 8
    base_run_args["sim_build"] = f"sim_build_val_rdy"
    run(**base_run_args)

def test_realign_compile_backpressure():
    base_run_args = get_base_args()
    base_run_args["testcase"] = "backpressure_test"
    base_run_args["parameters"]["REALIGN_W"] = 8
    base_run_args["sim_build"] = f"sim_build_val_rdy"
    run(**base_run_args)

def get_base_args():
    base_run_args = {}
    base_run_args["toplevel"] = "realign_compile_wrap"
    base_run_args["module"] = "test_realign_compile"

    base_run_args["verilog_sources"] = [
                os.path.join(".", "realign_compile_wrap.sv"),
                os.path.join(os.environ["BEEHIVE_PROJECT_ROOT"], "protocols",
                    "tcp_hw", "common", "fifo", "peek_fifo_1r1w.sv"),
                os.path.join("..", "..", "..", "realign_compile.sv"),
                os.path.join("..", "..", "..", "data_masker.sv")
            ]

    base_run_args["sim_args"] = ["-voptargs=+acc"]

    base_run_args["parameters"] = {
        "DATA_W": 512,
        "BUF_STAGES": 4,
    }
    base_run_args["waves"] = 1
    return base_run_args


if __name__ == "__main__":
    test_realign_compile()
