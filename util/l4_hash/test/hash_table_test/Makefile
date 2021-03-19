# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

FLIST_NAME = "test_l4_hash_table.flist"
TOP_CORE_PKG = "test_l4_hash_table"

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess
VERILOG_SOURCES += $(PWD)/hash_table_test.sv
COMPILE_ARGS += "-f $(PWD)/$(FLIST_NAME)"

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = hash_table_test

# MODULE is the basename of the Python test file
MODULE = tb_hash_table

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

export BEEHIVE_DESIGN_ROOT=$(PWD)

.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add pyhp_generator $(BEEHIVE_PROJECT_ROOT)/tile_generator
	fusesoc library add network_components $(BEEHIVE_PROJECT_ROOT)/network_tiles
	fusesoc library add parser_components $(BEEHIVE_PROJECT_ROOT)/util/l4_field_extract
	fusesoc library add hash_components $(BEEHIVE_PROJECT_ROOT)/util/l4_hash

.PHONY: gen_filelist
gen_filelist:
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=sim --no-export uwcse:beehive:$(TOP_CORE_PKG)
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_$(TOP_CORE_PKG)_0.1/sim-modelsim/uwcse_beehive_$(TOP_CORE_PKG)_0.1.eda.yml \
		--output_file=$(FLIST_NAME)

