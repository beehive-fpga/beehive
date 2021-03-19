# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

export COCOTB_RESOLVE_X=ZEROS 

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/tb_tcp_pull_echo_top.sv
COMPILE_ARGS += "-f $(PWD)/test_tcp_pull_echo.flist"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_tcp_pull_echo_top

# MODULE is the basename of the Python test file
MODULE = tb_tcp_pull_echo_top

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

modelsim:
	rm -f sw_to_hw.txt hw_to_sw.txt
	vsim -c -do run_sim.do

.PHONY: gen_filelist
gen_filelist:
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=sim --no-export uwcse:beehive:tcp_pull_echo
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_tcp_pull_echo_0.1/sim-modelsim/uwcse_beehive_tcp_pull_echo_0.1.eda.yml \
		--output_file=test_tcp_pull_echo.flist


.PHONY: init_fusesoc
init_fusesoc:
	fusesoc library add tcp_pull_echo $(BEEHIVE_PROJECT_ROOT)/apps/tcp_apps/echo_app/build
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include

.PHONY: gen_files
gen_files:
	python $(BEEHIVE_PROJECT_ROOT)/tile_generator/pyhp.py tcp_pull_echo_top_gen.sv.pyv > tcp_pull_echo_top.sv
	python $(BEEHIVE_PROJECT_ROOT)/tile_generator/pyhp.py include/beehive_topology_gen.sv.pyv > include/beehive_topology.sv

