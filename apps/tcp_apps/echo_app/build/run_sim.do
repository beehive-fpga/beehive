vlog -f test_tcp_pull_echo.flist -sv +dumpon
vsim -voptargs=+acc -lib work tcp_pull_echo_sim_top
log * -r
