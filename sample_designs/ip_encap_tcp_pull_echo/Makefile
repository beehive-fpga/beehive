
modelsim:
	rm -f sw_to_hw.txt hw_to_sw.txt
	vsim -c -do run_sim.do

gen_files:
	python $(BEEHIVE_PROJECT_ROOT)/tile_generator/pyhp.py ip_encap_tcp_pull_echo_top_gen.sv.pyv > ip_encap_tcp_pull_echo_top.sv
	python $(BEEHIVE_PROJECT_ROOT)/tile_generator/pyhp.py include/beehive_topology_gen.sv.pyv > include/beehive_topology.sv

