SIM ?= Questa
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/dhcp_client_top_gen.sv
COMPILE_ARGS += -f $(PWD)/test_dhcp_client.flist

ifeq "$(SIM)" "verilator"
    COMPILE_ARGS += -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-SELRANGE -Wno-MODDUP -Wno-IMPLICIT -Wno-TIMESCALEMOD
endif

SIM_ARGS = -voptargs=+acc
TOPLEVEL = dhcp_client_top
MODULE = tb_dhcp_client
FLIST_NAME = test_dhcp_client.flist
TOP_CORE_NAME = uwcse:beehive:dhcp_client:0.1

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
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add beehive_apps $(BEEHIVE_PROJECT_ROOT)/apps
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_noc $(BEEHIVE_PROJECT_ROOT)/beehive_noc
	fusesoc library add buckfast_front $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/frontend
	fusesoc library add buckfast_common $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/common
	fusesoc library add tcp_inc $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw/include/tcp
	fusesoc library add beehive_topology $(BEEHIVE_PROJECT_ROOT)/cocotb_testing/dhcp_client/include
	fusesoc library add dhcp_client $(BEEHIVE_PROJECT_ROOT)/cocotb_testing/dhcp_client

clean::
	rm -rf build/ generated/ modelsim.ini results.xml transcript vsim.wlf __pycache__
