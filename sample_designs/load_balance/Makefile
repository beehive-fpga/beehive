# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess

FLIST_NAME = load_balance_test.flist
TOP_CORE_PKG = load_balance_test

VERILOG_SOURCES += $(PWD)/load_balance_top_gen.sv
COMPILE_ARGS += "-f $(PWD)/$(FLIST_NAME)"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = load_balance_top

# MODULE is the basename of the Python test file
MODULE = tb_load_balance

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(PWD)

.PHONY: gen_filelist
gen_filelist:
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=sim --no-export uwcse:beehive:$(TOP_CORE_PKG)
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_$(TOP_CORE_PKG)_0.1/sim-modelsim/uwcse_beehive_$(TOP_CORE_PKG)_0.1.eda.yml \
		--output_file=$(FLIST_NAME)

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
	fusesoc library add load_balance_test $(BEEHIVE_PROJECT_ROOT)/sample_designs/load_balance
	fusesoc library add basejump $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/basejump_files
	fusesoc library add buckfast_common_inc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/include/common
	fusesoc library add buckfast_common $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common
	fusesoc library add buckfast_noc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/noc_stuff
	fusesoc library add buckfast_front $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/frontend

