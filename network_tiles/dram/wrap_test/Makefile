# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/tb_mem_wrap_valrdy.sv
VERILOG_SOURCES += $(PWD)/../masked_mem_wrap_valrdy.sv

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_mem_wrap_valrdy

# MODULE is the basename of the Python test file
MODULE = tb_mem_wrap_valrdy

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

