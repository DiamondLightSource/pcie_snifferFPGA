onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/clk
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/rst_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/pop_data
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_dat
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_dat_lt
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_trem_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tsof_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tdst_rdy_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_td
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_teof_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tsrc_rdy_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tsrc_dsc_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/trn_tdst_dsc_n
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/bmd_64_tx_state
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_addr_o
add wave -noupdate -radix unsigned /bmd_tx_engine_tb/uut/xy_buf_dat_i
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_addr
add wave -noupdate -radix hexadecimal /bmd_tx_engine_tb/uut/xy_buf_addr_next
add wave -noupdate /bmd_tx_engine_tb/uut/mwr_start_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 272
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {21 us}
