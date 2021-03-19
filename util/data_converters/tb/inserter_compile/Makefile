# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

all: run_param_test

run_param_test:
	pytest -o log_cli=True test_inserter_compile.py

