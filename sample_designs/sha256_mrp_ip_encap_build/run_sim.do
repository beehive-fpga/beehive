vlog -f sha256_mrp_ip_encap_top_sim.flist -sv +dumpon
vsim -voptargs=+acc -lib work sha256_mrp_ip_encap_top_sim
log * -r
