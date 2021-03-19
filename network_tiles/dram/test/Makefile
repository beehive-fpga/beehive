# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/tb_mem_controller.sv
COMPILE_ARGS += "-f $(PWD)/test_mem_controller.flist"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_mem_controller

# MODULE is the basename of the Python test file
MODULE = tb_mem_controller

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: gen_filelist
gen_filelist:
	export BEEHIVE_DESIGN_ROOT=$(PWD)
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=sim --no-export uwcse:beehive:mem_controller_test
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_mem_controller_test_0.1/sim-modelsim/uwcse_beehive_mem_controller_test_0.1.eda.yml \
		--output_file=test_mem_controller.flist

.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add basejump $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/basejump_files
	fusesoc library add buckfast_common_inc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/include/common
	fusesoc library add buckfast_fifo $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common/fifo
	fusesoc library add buckfast_ram $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common/ram
	fusesoc library add buckfast_noc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/noc_stuff
