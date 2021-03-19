vlog -f beehive_top_sim.flist -sv +dumpon
vsim -voptargs=+acc -lib work beehive_sim_top
log * -r
