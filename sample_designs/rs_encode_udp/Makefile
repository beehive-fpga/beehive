# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

include Makefile.rs_encode_udp

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = rs_encode_udp_top

# MODULE is the basename of the Python test file
MODULE = tb_rs_encode_udp

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(PWD)

VERILOG_SOURCES += $(PWD)/rs_encode_udp_top_gen.sv


.PHONY: gen_filelist
gen_filelist:
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=fpga --no-export uwcse:beehive:rs_encode_udp_design
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=cocotb_sim\
		--edam_file=build/uwcse_beehive_rs_encode_udp_design_0.1/fpga-vivado/uwcse_beehive_rs_encode_udp_design_0.1.eda.yml \
		--output_file=Makefile.rs_encode_udp


.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add pyhp_generator $(BEEHIVE_PROJECT_ROOT)/tile_generator
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add beehive_topology $(BEEHIVE_PROJECT_ROOT)/sample_designs/rs_encode_udp/include
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add basejump $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/basejump_files
	fusesoc library add buckfast_common_inc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/include/common
	fusesoc library add buckfast_common $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common
	fusesoc library add beehive_noc $(BEEHIVE_PROJECT_ROOT)/beehive_noc
	fusesoc library add buckfast_front $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/frontend
	fusesoc library add tcp $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_slow
	fusesoc library add rs_encode_udp $(BEEHIVE_PROJECT_ROOT)/sample_designs/rs_encode_udp
