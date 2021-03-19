vlog -f ip_encap_tcp_pull_echo_sim.flist -sv +dumpon
vsim -voptargs=+acc -lib work ip_encap_tcp_pull_echo_top_sim
log * -r
