# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

CORE_NAME=tcp_open_loop

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_$(CORE_NAME)_top

# MODULE is the basename of the Python test file
MODULE = tb_$(CORE_NAME)_top

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/tb_tcp_open_loop_top.sv
COMPILE_ARGS += -f $(PWD)/$(CORE_NAME).flist

ifeq "$(SIM)" "verilator"
	COMPILE_ARGS += -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-SELRANGE -Wno-MODDUP -Wno-IMPLICIT
endif

FLIST_NAME = $(CORE_NAME).flist
TOP_CORE_NAME = uwcse:beehive:$(CORE_NAME):0.1

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(PWD)
export DESIGN_ROOT=$(BEEHIVE_DESIGN_ROOT)

include $(BEEHIVE_PROJECT_ROOT)/util/scripts/fusesoc_file_gen/Makefile

.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add pyhp_generator $(BEEHIVE_PROJECT_ROOT)/tile_generator
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add tcp $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_slow
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add buckfast_common $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common
	fusesoc library add beehive_noc $(BEEHIVE_PROJECT_ROOT)/beehive_noc
	fusesoc library add buckfast_front $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/frontend
	fusesoc library add buckfast_data_move $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/recv_pipe
	fusesoc library add tcp_log_test $(BEEHIVE_PROJECT_ROOT)/sample_designs/$(CORE_NAME)
