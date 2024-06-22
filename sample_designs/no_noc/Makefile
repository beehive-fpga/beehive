# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/no_noc_top.sv
COMPILE_ARGS += "-f $(PWD)/test_udp_echo.flist"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = no_noc_top

# MODULE is the basename of the Python test file
MODULE = tb_no_noc_echo

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(BEEHIVE_PROJECT_ROOT)/cocotb_testing/udp_echo

.PHONY: gen_filelist
gen_filelist:
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=default --no-export uwcse:beehive:no_noc_udp_echo
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_no_noc_udp_echo_0.1/default-modelsim/uwcse_beehive_no_noc_udp_echo_0.1.eda.yml \
		--output_file=test_udp_echo.flist


.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add pyhp_generator $(BEEHIVE_PROJECT_ROOT)/tile_generator
	fusesoc library add network_tiles $(BEEHIVE_PROJECT_ROOT)/network_tiles/
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add udp_echo_app $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/apps/udp_echo
	fusesoc library add udp_echo_app_stats $(BEEHIVE_PROJECT_ROOT)/apps/udp_echo_app
	fusesoc library add echo_app $(BEEHIVE_PROJECT_ROOT)/sample_designs/no_noc
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_topology $(BEEHIVE_PROJECT_ROOT)/cocotb_testing/udp_echo/include
	fusesoc library add basejump $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/basejump_files
	fusesoc library add buckfast_front $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/frontend
	fusesoc library add buckfast_common_inc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/include/common
	fusesoc library add buckfast_common $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common
	fusesoc library add beehive_noc $(BEEHIVE_PROJECT_ROOT)/beehive_noc
	fusesoc library add tcp $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw
