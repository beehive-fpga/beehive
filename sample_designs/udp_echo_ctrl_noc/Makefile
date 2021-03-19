# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/udp_echo_top.sv
COMPILE_ARGS += "-f $(PWD)/test_udp_echo.flist"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = udp_echo_top

# MODULE is the basename of the Python test file
MODULE = tb_udp_echo

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(PWD)

.PHONY: gen_filelist
gen_filelist:
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=fpga --no-export uwcse:beehive:udp_echo
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_udp_echo_0.1/fpga-vivado/uwcse_beehive_udp_echo_0.1.eda.yml \
		--output_file=test_udp_echo.flist


.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add pyhp_generator $(BEEHIVE_PROJECT_ROOT)/tile_generator
	fusesoc library add udp_echo $(BEEHIVE_PROJECT_ROOT)/cocotb_testing/udp_echo
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add udp_echo_test $(BEEHIVE_PROJECT_ROOT)/sample_designs/udp_echo_ctrl_noc


