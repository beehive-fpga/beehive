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

from inserter_compile import inserter_test

def iterate_insert_widths(base_run_args):
    data_bytes = int(base_run_args["parameters"]["DATA_W"]/8)
    for i in range(1, data_bytes+1):
        logging.info(f"===Testing insert width of {i}===")
        base_run_args["parameters"]["INSERT_W"] = i * 8
        base_run_args["sim_build"] = f"sim_build_{i}"
        run(**base_run_args)


def test_inserter_compile():
    base_run_args = {}
    base_run_args["toplevel"] = "inserter_compile"
    base_run_args["module"] = "inserter_compile"

    base_run_args["verilog_sources"] = [
            os.path.join("..", "..", "inserter_compile.sv")]

    base_run_args["sim_args"] = ["-voptargs=+acc"]

    base_run_args["parameters"] = {
        "DATA_W": 512
    }
    base_run_args["waves"] = 1

    iterate_insert_widths(base_run_args)

if __name__ == "__main__":
    test_inserter_compile()
