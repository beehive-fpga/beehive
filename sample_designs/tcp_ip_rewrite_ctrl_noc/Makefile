# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/tb_tcp_ip_rewrite.sv
COMPILE_ARGS += "-f $(PWD)/test_tcp_ip_rewrite.flist"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tb_tcp_ip_rewrite

# MODULE is the basename of the Python test file
MODULE = tb_tcp_ip_rewrite

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(PWD)

.PHONY: gen_filelist
gen_filelist:
	export BEEHIVE_DESIGN_ROOT=$(PWD)
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=sim --no-export uwcse:beehive:tcp_ip_rewrite
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_tcp_ip_rewrite_0.1/sim-modelsim/uwcse_beehive_tcp_ip_rewrite_0.1.eda.yml \
		--output_file=test_tcp_ip_rewrite.flist

.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add pyhp_generator $(BEEHIVE_PROJECT_ROOT)/tile_generator
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add tcp_log_test $(BEEHIVE_PROJECT_ROOT)/sample_designs/tcp_ip_rewrite_ctrl_noc
