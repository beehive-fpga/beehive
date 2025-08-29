# Makefile

# defaults
SIM ?= Questa
TOPLEVEL_LANG ?= verilog

# This is already in the flist, but cocotb needs to receive at least one Verilog 
# source file I guess to kick the compilation. There's probably a better way to 
# hand it a dummy file, but just give it the top level for now I guess

FLIST_NAME = beehive_vr_test.flist
TOP_CORE_NAME = uwcse:beehive:beehive_vr_test:0.1

VERILOG_SOURCES += $(PWD)/beehive_vr_top_gen.sv
COMPILE_ARGS += -f $(PWD)/$(FLIST_NAME)

ifeq "$(SIM)" "verilator"
	COMPILE_ARGS += -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-SELRANGE -Wno-MODDUP -Wno-IMPLICIT
endif

SIM_ARGS = -voptargs=+acc
# SCRIPT_FILE = wave.do
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = beehive_vr_top

# MODULE is the basename of the Python test file
MODULE = tb_beehive_vr

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
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add buckfast_common $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common
	fusesoc library add beehive_noc $(BEEHIVE_PROJECT_ROOT)/beehive_noc
	fusesoc library add buckfast_front $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/frontend
	fusesoc library add tcp_inc	$(BEEHIVE_PROJECT_ROOT)/protocols/tcp_slow/include
	fusesoc library add beehive_vr $(BEEHIVE_PROJECT_ROOT)/sample_designs/beehive_vr
