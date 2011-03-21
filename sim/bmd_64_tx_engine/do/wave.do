onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/clk
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/rst_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/init_rst_i
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/pop_data
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/mwr_start_i
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/xy_buf_addr
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/xy_buf_addr_next
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/cur_wr_count
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/bmd_64_tx_state
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/cur_mwr_dw_count
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/xy_buf_addr_o
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/xy_buf_dat_i
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/xy_buf_dat_lt
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_td
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_trem_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_tsof_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_teof_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_tsrc_rdy_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_tsrc_dsc_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_tdst_rdy_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_tdst_dsc_n
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_tbuf_av
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/data_slr
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/trn_data
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/rd_en
add wave -noupdate -radix hexadecimal /bmd_64_tx_engine_tb/uut/xy_buf_addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {5705809 ps} {6072260 ps}
