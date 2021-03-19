vlog -f udp_echo.flist -sv +dumpon
vsim -voptargs=+acc -lib work udp_echo_top 
