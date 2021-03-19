onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /udp_echo_top/clk
add wave -noupdate /udp_echo_top/rst
add wave -noupdate /udp_echo_top/mac_engine_rx_val
add wave -noupdate /udp_echo_top/mac_engine_rx_data
add wave -noupdate /udp_echo_top/mac_engine_rx_startframe
add wave -noupdate /udp_echo_top/mac_engine_rx_frame_size
add wave -noupdate /udp_echo_top/mac_engine_rx_endframe
add wave -noupdate /udp_echo_top/mac_engine_rx_padbytes
add wave -noupdate /udp_echo_top/ip_rx_1_0/rx_noc_out/ip_format_ip_rx_out_rx_hdr_val
add wave -noupdate /udp_echo_top/ip_rx_1_0/rx_noc_out/ctrl/state_reg
add wave -noupdate /udp_echo_top/ip_rx_1_0/rx_noc_out/ip_rx_out_noc0_vrtoc_val
add wave -noupdate /udp_echo_top/udp_rx_2_0/udp_rx_noc_in/noc0_ctovr_udp_rx_in_val
add wave -noupdate /udp_echo_top/udp_rx_2_0/udp_rx_noc_in/udp_rx_in_udp_formatter_rx_hdr_val
add wave -noupdate /udp_echo_top/udp_rx_2_0/rx_udp_formatter/src_udp_formatter_rx_hdr_val
add wave -noupdate /udp_echo_top/udp_rx_2_0/udp_rx_noc_out/ctrl/state_reg
add wave -noupdate /udp_echo_top/udp_rx_2_0/rx_udp_formatter/udp_formatter_dst_rx_hdr_val
add wave -noupdate /udp_echo_top/udp_rx_2_0/rx_udp_formatter/input_ctrl/state_reg
add wave -noupdate /udp_echo_top/eth_rx_0_0/eth_rx_noc_out/ctrl/state_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {94198 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 710
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 80
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {336453 ps}
