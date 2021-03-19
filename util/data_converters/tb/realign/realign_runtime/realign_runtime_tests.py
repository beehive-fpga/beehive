import sys, os
import logging

from cocotb_test.simulator import run
import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

sys.path.append("..")
from realign_tests import TB, run_data_buf_size_test, reset

sys.path.append(os.environ["BEEHIVE_PROJECT_ROOT"] + "/util/data_converters/tb/realign")
from realign_tests import TB, run_data_buf_size_test, reset

# pytest tries to run anything starting with test...can also use
# @pytest.mark.skip
@cocotb.test()
async def realign_runtime_test(dut):
    tb = TB(dut)
    
    cocotb.start_soon(Clock(dut.clk, tb.CLOCK_CYCLE_TIME, units='ns').start())
    
    dut.src_realign_data_val.setimmediatevalue(0)
    dut.src_realign_data.setimmediatevalue(BinaryValue(value=0,
        n_bits=dut.src_realign_data.value.n_bits))
    dut.src_realign_data_padbytes.setimmediatevalue(0)
    dut.src_realign_data_last.setimmediatevalue(0)

    dut.dst_realign_data_rdy.setimmediatevalue(0)

    await reset(dut)

    realign_bytes = int(dut.src_realign_data.value.n_bits/8)

    for i in range(0, realign_bytes):
        cocotb.log.info(f"===Testing realign width {i}===")
        dut.realign_bytes.setimmediatevalue(i)
        await RisingEdge(dut.clk)
        await run_data_buf_size_test(tb, i)

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

    realign_bytes = int(dut.src_realign_data.value.n_bits/8)

    cocotb.log.info(f"===Testing with delays===")
    dut.realign_bytes.setimmediatevalue(4)
    await RisingEdge(dut.clk)
    await run_data_buf_size_test(tb, 4, max_rand_delay_in=6,
            max_rand_delay_out=6)

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

    realign_bytes = int(dut.src_realign_data.value.n_bits/8)

    cocotb.log.info(f"===Testing with backpressure===")
    dut.realign_bytes.setimmediatevalue(4)
    await RisingEdge(dut.clk)
    await run_data_buf_size_test(tb, 4, max_rand_delay_out=6)

def get_base_run_args():
    base_run_args = {}
    base_run_args["toplevel"] = "realign_runtime_wrap"
    base_run_args["module"] = "realign_runtime_tests"

    base_run_args["verilog_sources"] = [
                os.path.join(".", "realign_runtime_wrap.sv"),
                os.path.join(os.environ["BEEHIVE_PROJECT_ROOT"], "protocols",
                    "tcp_hw", "common", "fifo", "peek_fifo_1r1w.sv"),
                os.path.join("..", "..", "..", "realign_runtime.sv"),
                os.path.join("..", "..", "..", "data_masker.sv")
            ]

    base_run_args["sim_args"] = ["-voptargs=+acc"]

    base_run_args["parameters"] = {
        "DATA_W": 512,
        "BUF_STAGES": 4,
    }
    base_run_args["waves"] = 1

    return base_run_args

def test_realign_widths():
    base_run_args = get_base_run_args()
    base_run_args["testcase"] = "realign_runtime_test"
    base_run_args["sim_build"] = f"sim_build_buf_sizes"
    run(**base_run_args)

def test_realign_valrdy():
    base_run_args = get_base_run_args()
    base_run_args["testcase"] = "val_rdy_test"
    base_run_args["sim_build"] = f"sim_build_val_rdy"
    run(**base_run_args)

def test_realign_backpressure():
    base_run_args = get_base_run_args()
    base_run_args["testcase"] = "backpressure_test"
    base_run_args["sim_build"] = f"sim_build_val_rdy"
    run(**base_run_args)
