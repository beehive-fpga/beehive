export BEEHIVE_DESIGN_ROOT=$(PWD)

CORE_NAME=vr_app_test

.PHONY: gen_filelist
gen_filelist:
	export BEEHIVE_DESIGN_ROOT=$(PWD)
	fusesoc --config=$(PWD)/fusesoc.conf run --setup --target=sim --no-export uwcse:beehive:$(CORE_NAME)
	python3 $(BEEHIVE_PROJECT_ROOT)/util/scripts/generate_filelist.py --target=flist \
		--edam_file=build/uwcse_beehive_$(CORE_NAME)_0.1/sim-modelsim/uwcse_beehive_$(CORE_NAME)_0.1.eda.yml \
		--output_file=$(CORE_NAME).flist

.PHONY: init_fusesoc
init_fusesoc:
	echo "[main]" > fusesoc.conf
	echo "cache_root = $(PWD)" >> fusesoc.conf
	fusesoc library add tcp $(BEEHIVE_PROJECT_ROOT)/protocols/tcp_hw
	fusesoc library add beehive_util $(BEEHIVE_PROJECT_ROOT)/util
	fusesoc library add beehive_msgs $(BEEHIVE_PROJECT_ROOT)/include
	fusesoc library add beehive_vr	 $(BEEHIVE_PROJECT_ROOT)/apps/beehive-vr-tile/beehive-vr
	fusesoc library add vr_test		 $(BEEHIVE_DESIGN_ROOT)
